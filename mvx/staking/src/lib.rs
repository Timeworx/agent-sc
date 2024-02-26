#![no_std]

multiversx_sc::imports!();
multiversx_sc::derive_imports!();

const PERC_APR: u32 = 15;
const MIN_STAKE: u64 = 100;
const WITHDRAW_EPOCHS: u64 = 10;

#[derive(Clone, TypeAbi, TopEncode, TopDecode, NestedEncode, NestedDecode)]
pub struct StakeData<M : ManagedTypeApi> {
    pub epoch: u64,
    pub address: ManagedAddress<M>
}

#[derive(Clone, TypeAbi, TopEncode, TopDecode, NestedEncode, NestedDecode)]
pub struct UnstakeData {
    pub epoch: u64
}


#[multiversx_sc::contract]
pub trait Staking: multiversx_sc_modules::default_issue_callbacks::DefaultIssueCallbacksModule {
    #[init]
    fn init(&self) {
        // TODO: this shouldn't be done for all updates
        self.min_stake().set(BigUint::from(MIN_STAKE));
    }

    #[payable("EGLD")]
    #[only_owner]
    #[endpoint(setupStaking)]
    fn setup_staking(
        &self, 
        #[payment] issue_cost: BigUint<Self::Api>,
        token_display_name: ManagedBuffer<Self::Api>,
        token_ticker: ManagedBuffer<Self::Api>,
    ) {
        if self.staking_token().is_empty() {
            self.staking_token().issue_and_set_all_roles(
                EsdtTokenType::Meta,
                issue_cost,
                token_display_name,
                token_ticker,
                18,
                None
            );
        }
    }

    #[payable("EGLD")]
    #[only_owner]
    #[endpoint(setupUnstaking)]
    fn setup_unstaking(
        &self, 
        #[payment] issue_cost: BigUint<Self::Api>,
        token_display_name: ManagedBuffer<Self::Api>,
        token_ticker: ManagedBuffer<Self::Api>,
    ) {
        if self.unstaking_token().is_empty() {
            self.unstaking_token().issue_and_set_all_roles(
                EsdtTokenType::Meta,
                issue_cost,
                token_display_name,
                token_ticker,
                18,
                None
            );
        }
    }

    #[payable("*")]
    #[only_owner]
    #[endpoint(fund)]
    fn fund(&self) {
        let payment = self.call_value().single_esdt();

        if !self.token().is_empty() {
            self.token().require_same_token(&payment.token_identifier);
        } else {
            self.token().set_token_id(payment.token_identifier);
        }
    }

    #[payable("TIX-75a921")]
    #[endpoint(stake)]
    fn stake(
        &self,
    ) {
        self.stake_other(self.blockchain().get_caller());
    }

    #[payable("TIX-75a921")]
    #[endpoint(stakeOther)]
    fn stake_other(
        &self,
        address: ManagedAddress<Self::Api>,
    ) {
        let value = self.call_value().single_esdt();
        if self.token().is_empty() {
            self.token().set_token_id(value.token_identifier);
        }
        let amount = value.amount;

        self.gen_stake_tokens(&amount, &address, true);
    }

    #[payable("*")]
    #[endpoint(stakeMore)]
    fn stake_more(
        &self,
        restake_rewards: OptionalValue<bool>,
    ) {
        self.stake_more_other(self.blockchain().get_caller(), restake_rewards);
    }

    #[payable("*")]
    #[endpoint(stakeMoreOther)]
    fn stake_more_other(
        &self,
        address: ManagedAddress<Self::Api>,
        restake_rewards: OptionalValue<bool>,
    ) {
        let all_tokens: ManagedVec<EsdtTokenPayment<Self::Api>> = self.call_value().all_esdt_transfers();
        let value = all_tokens.get(all_tokens.len() - 1);
        let all_stokens = all_tokens.slice(0, all_tokens.len() - 1).unwrap();

        let (stokens, merge_claimable) = self.merge_stakes_internal(&all_stokens, false, false);

        if self.token().is_empty() {
            self.token().set_token_id(value.token_identifier.clone());
        } else {
            self.token().require_same_token(&value.token_identifier);
        }
        self.staking_token().require_same_token(&stokens.token_identifier);


        let amount = match restake_rewards {
            OptionalValue::Some(true) => {
                let claimable = self.get_claimable(
                    &self.blockchain().get_sc_address(),
                    &stokens.amount,
                    &stokens.token_identifier,
                    stokens.token_nonce
                ) + merge_claimable;

                self.staking_token().nft_burn(stokens.token_nonce, &stokens.amount);

                value.amount + &stokens.amount + claimable
            }
            _ => {
                self.send_claimable(&stokens, &address, false);

                if merge_claimable > 0 {
                    self.send().direct_esdt(
                        &self.blockchain().get_caller(),
                        &self.token().get_token_id(),
                        0,
                        &merge_claimable
                    );
                }

                value.amount + &stokens.amount
            }
        };
        self.gen_stake_tokens(&amount, &address, true);
    }

    #[payable("*")]
    #[endpoint(claim)]
    fn claim(
        &self
    ) {
        self.merge_stakes_internal(&self.call_value().all_esdt_transfers(), true, true);
    }

    #[payable("*")]
    #[endpoint(stakeRewards)]
    fn stake_rewards(
        &self
    ) {
        let all_stokens: ManagedVec<EsdtTokenPayment<Self::Api>> = self.call_value().all_esdt_transfers();

        let (value, merge_claimable) = self.merge_stakes_internal(&all_stokens, false, false);
        
        let claimable = self.get_claimable(
            &self.blockchain().get_sc_address(),
            &value.amount,
            &value.token_identifier,
            value.token_nonce
        ) + merge_claimable;
        require!(claimable > 0, "Nothing to restake");

        let amount = &value.amount + &claimable;

        self.staking_token().nft_burn(value.token_nonce, &value.amount);

        self.gen_stake_tokens(&amount, &self.blockchain().get_caller(), true);
    }

    #[payable("*")]
    #[endpoint(mergeStakes)]
    fn merge_stakes(
        &self
    ) {
        self.merge_stakes_internal(&self.call_value().all_esdt_transfers(), true, true);
    }

    fn merge_stakes_internal(
        &self,
        stakes: &ManagedVec<EsdtTokenPayment<Self::Api>>,
        send_stoken: bool,
        send_claimable: bool
    ) -> (EsdtTokenPayment, BigUint) {
        if stakes.len() > 1 {
            let staking_token_id = self.staking_token().get_token_id();
            let mut total_amount = BigUint::zero();

            let mut claimable = BigUint::zero();

            for stake in stakes {
                require!(staking_token_id == stake.token_identifier, "Wrong staking token");

                total_amount += &stake.amount;

                claimable += self.get_claimable(
                    &self.blockchain().get_sc_address(),
                    &stake.amount,
                    &stake.token_identifier,
                    stake.token_nonce
                );

                self.staking_token().nft_burn(stake.token_nonce, &stake.amount);
            }

            let (ti, nonce) = self.gen_stake_tokens(&total_amount, &self.blockchain().get_caller(), send_stoken);

            if send_claimable && claimable > 0 {
                self.send().direct_esdt(
                    &self.blockchain().get_caller(),
                    &self.token().get_token_id(),
                    0,
                    &claimable
                );
            }

            (EsdtTokenPayment::new(ti, nonce, total_amount), claimable)
        } else {
            let stoken = stakes.get(0);
            if send_stoken {
                self.send().direct_esdt(
                    &self.blockchain().get_caller(),
                    &stoken.token_identifier,
                    stoken.token_nonce,
                    &stoken.amount
                );
            }

            let claimable = self.get_claimable(
                &self.blockchain().get_sc_address(),
                &stoken.amount,
                &stoken.token_identifier,
                stoken.token_nonce
            );
            if send_claimable && claimable > 0 {
                self.send().direct_esdt(
                    &self.blockchain().get_caller(),
                    &self.token().get_token_id(),
                    0,
                    &claimable
                );
            }

            (stakes.get(0), claimable)
        }
    }

    #[payable("*")]
    #[endpoint(unstake)]
    fn unstake(
        &self
    ) {
        let value = self.call_value().single_esdt();
        require!(self.staking_token().get_token_id() == value.token_identifier, "Wrong staking token");

        self.send_claimable(&value, &self.blockchain().get_caller(), false);

        let unstake_data = UnstakeData {
            epoch: self.get_epoch()
        };

        let mut encoded_unstake_data = ManagedBuffer::new();
        if unstake_data.top_encode(&mut encoded_unstake_data).is_err() {
            sc_panic!("Failed to serialize unstake data");
        }

        let unstake_tokens = self.unstaking_token().nft_create(
            value.amount.clone(),
            &encoded_unstake_data
        );

        self.send().direct_esdt(
            &self.blockchain().get_caller(),
            &unstake_tokens.token_identifier,
            unstake_tokens.token_nonce,
            &unstake_tokens.amount
        );
    }

    #[payable("*")]
    #[endpoint(unstake_merge)]
    fn unstake_merge(
        &self,
        value: BigUint,
    ) {
        let stokens: ManagedVec<EsdtTokenPayment<Self::Api>> = self.call_value().all_esdt_transfers();

        let (merged_stokens, _) = self.merge_stakes_internal(&stokens, false, true);
        self.staking_token().nft_burn(merged_stokens.token_nonce, &value);

        let unstake_data = UnstakeData {
            epoch: self.get_epoch()
        };

        let mut encoded_unstake_data = ManagedBuffer::new();
        if unstake_data.top_encode(&mut encoded_unstake_data).is_err() {
            sc_panic!("Failed to serialize unstake data");
        }

        let unstake_tokens = self.unstaking_token().nft_create(
            value.clone(),
            &encoded_unstake_data
        );

        self.send().direct_esdt(
            &self.blockchain().get_caller(),
            &unstake_tokens.token_identifier,
            unstake_tokens.token_nonce,
            &unstake_tokens.amount
        );

        let remaining_amount = merged_stokens.amount - value;
        self.send().direct_esdt(
            &self.blockchain().get_caller(),
            &merged_stokens.token_identifier,
            merged_stokens.token_nonce,
            &remaining_amount
        );
    }

    #[payable("*")]
    #[endpoint(withdraw)]
    fn withdraw(
        &self
    ) {
        let value = self.call_value().single_esdt();
        require!(self.unstaking_token().get_token_id() == value.token_identifier, "Wrong unstaking token");

        let token_data = self.blockchain().get_esdt_token_data(
            &self.blockchain().get_sc_address(),
            &value.token_identifier,
            value.token_nonce
        );
        let unstake_data: UnstakeData = token_data.decode_attributes();

        let cur_epoch = self.get_epoch();
        require!(cur_epoch - unstake_data.epoch >= WITHDRAW_EPOCHS, "Funds cannot be withdrawn yet");

        self.send().direct_esdt(
            &self.blockchain().get_caller(),
            &self.token().get_token_id(),
            0,
            &value.amount
        );

        self.unstaking_token().nft_burn(value.token_nonce, &value.amount);
    }

    #[payable("*")]
    #[endpoint(burnStake)]
    fn burn_stake(
        &self
    ) {
        let value = self.call_value().single_esdt();
        require!(self.staking_token().get_token_id() == value.token_identifier, "Wrong staking token");

        self.staking_token().nft_burn(value.token_nonce, &value.amount);
    }

    fn gen_stake_tokens(
        &self,
        amount: &BigUint<Self::Api>,
        address: &ManagedAddress<Self::Api>,
        send: bool
    ) -> (TokenIdentifier, u64) {
        let epoch = self.get_epoch();
        let stake_data = StakeData {
            epoch,
            address: address.clone()
        };

        let mut encoded_stake_data = ManagedBuffer::new();
        if stake_data.top_encode(&mut encoded_stake_data).is_err() {
            sc_panic!("Failed to serialize stake data");
        }

        let stokens = self.staking_token().nft_create(
            amount.clone(),
            &encoded_stake_data
        );
        let ti = stokens.token_identifier;

        if send {
            self.send().direct_esdt(
                address,
                &ti,
                stokens.token_nonce,
                &stokens.amount
            );
        }

        (ti, stokens.token_nonce)
    }

    fn send_claimable(
        &self,
        stokens: &EsdtTokenPayment,
        address: &ManagedAddress<Self::Api>,
        send_staking: bool
    ) {
        let claimable = self.get_claimable(
            &self.blockchain().get_sc_address(),
            &stokens.amount,
            &stokens.token_identifier,
            stokens.token_nonce
        );

        let funds = self.token().get_balance();

        require!(funds >= claimable, "Not enough funds, please contact the owner");
        
        if claimable > 0 {
            self.send().direct_esdt(
                &address,
                &self.token().get_token_id(),
                0,
                &claimable
            );
        }

        self.staking_token().nft_burn(stokens.token_nonce, &stokens.amount);

        if send_staking {
            self.gen_stake_tokens(&stokens.amount, &address, true);
        }
    }

    fn get_claimable(
        &self,
        owner: &ManagedAddress<Self::Api>,
        value: &BigUint<Self::Api>,
        ti: &TokenIdentifier,
        nonce: u64
    ) -> BigUint {
        let token_data = self.blockchain().get_esdt_token_data(
            owner,
            ti,
            nonce
        );
        let stake_data: StakeData<Self::Api> = token_data.decode_attributes();
        
        let cur_epoch = self.get_epoch();
        let mut num_epochs = 0u64;
        if cur_epoch > stake_data.epoch {
            num_epochs = cur_epoch - stake_data.epoch;
        }
    
        value * num_epochs * PERC_APR / 36500u32
    }

    #[view(getEpoch)]
    fn get_epoch(
        &self
    ) -> u64 {
        self.blockchain().get_block_epoch()
        // self.blockchain().get_block_timestamp() / 60
    }

    #[view(getClaimable)]
    fn get_claimable_data(
        &self,
        value: BigUint<Self::Api>,
        epoch: u64
    ) -> BigUint {
        let cur_epoch = self.get_epoch();
        let mut num_epochs = 0u64;
        if cur_epoch > epoch {
            num_epochs = cur_epoch - epoch;
        }
    
        value * num_epochs * PERC_APR / 36500u32
    }

    #[view(getUnstakeData)]
    fn get_unstake_data(
        &self,
        epoch: u64
    ) -> MultiValue2<bool, u64> {
        let cur_epoch = self.get_epoch();

        let mut epochs_passed = 0;
        if cur_epoch > epoch {
            epochs_passed = cur_epoch - epoch;
        }

        MultiValue2::from((epochs_passed >= WITHDRAW_EPOCHS, WITHDRAW_EPOCHS - epochs_passed - 1))
    }

    #[storage_mapper("minStake")]
    fn min_stake(&self) -> SingleValueMapper<BigUint>;

    #[storage_mapper("isSetUp")]
    fn is_set_up(&self) -> SingleValueMapper<bool>;

    #[storage_mapper("tokenId")]
    fn token(&self) -> FungibleTokenMapper<Self::Api>;

    #[view(getStakingToken)]
    #[storage_mapper("stakingToken")]
    fn staking_token(&self) -> NonFungibleTokenMapper<Self::Api>;

    #[view(getUnstakingToken)]
    #[storage_mapper("unstakingToken")]
    fn unstaking_token(&self) -> NonFungibleTokenMapper<Self::Api>;
}
