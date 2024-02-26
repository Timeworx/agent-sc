#![no_std]

use staking::ProxyTrait as _;

multiversx_sc::imports!();
multiversx_sc::derive_imports!();

#[derive(Clone, TypeAbi, TopEncode, TopDecode, NestedEncode, NestedDecode)]
pub struct ClaimedValue<M : ManagedTypeApi> {
    pub timestamp: u64,
    pub nonce: u64,
    pub value: BigUint<M>
}

#[multiversx_sc::contract]
pub trait TixClaim {
    #[init]
    fn init(
        &self
    ) {
    }

    #[only_owner]
    #[endpoint(setSigner)]
    fn set_signer(
        &self,
        address: ManagedAddress
    ) {
        self.signer().set(address);
    }

    #[endpoint(claim)]
    fn claim(
        &self,
        value: BigUint,
        signature: ManagedBuffer
    ) {
        self.require_claim_sig(&value, &signature);        

        let caller = self.blockchain().get_caller();
        let nonce = self.get_last_claim_nonce(&caller) + 1;

        self.send().direct_esdt(&caller, &self.token().get_token_id(), 0, &value);

        self.last_claim(&caller).set(
            ClaimedValue {
                timestamp: self.blockchain().get_block_timestamp(),
                nonce,
                value
            }
        );
    }

    #[endpoint(stake)]
    fn stake(
        &self,
        value: BigUint,
        signature: ManagedBuffer
    ) {
        self.require_claim_sig(&value, &signature);        

        let caller = self.blockchain().get_caller();
        let nonce = self.get_last_claim_nonce(&caller) + 1;

        self.last_claim(&caller).set(
            ClaimedValue {
                timestamp: self.blockchain().get_block_timestamp(),
                nonce,
                value: value.clone()
            }
        );

        let stokens: ManagedVec<EsdtTokenPayment<Self::Api>> = ManagedVec::new();

        let token = self.token();
        self.staking_proxy(self.staking_sc().get())
            .stake_other(self.blockchain().get_caller())
            .with_esdt_transfer((
                token.get_token_id(),
                0,
                value
            ))
            .async_call()
            .with_callback(self.callbacks().stake_callback(caller, stokens))
            .call_and_exit();
    }

    #[payable("*")]
    #[endpoint(stakeMore)]
    fn stake_more(
        &self,
        value: BigUint,
        signature: ManagedBuffer,
        restake_rewards: OptionalValue<bool>,
    ) {
        self.require_claim_sig(&value, &signature);
        
        let stokens: ManagedVec<EsdtTokenPayment<Self::Api>> = self.call_value().all_esdt_transfers();

        let caller = self.blockchain().get_caller();
        let nonce = self.get_last_claim_nonce(&caller) + 1;

        self.last_claim(&caller).set(
            ClaimedValue {
                timestamp: self.blockchain().get_block_timestamp(),
                nonce,
                value: value.clone()
            }
        );

        let token = self.token();
        self.staking_proxy(self.staking_sc().get())
            .stake_more_other(self.blockchain().get_caller(), restake_rewards)
            .with_multi_token_transfer(stokens.clone())
            .with_esdt_transfer((
                token.get_token_id(),
                0,
                value
            ))
            .async_call()
            .with_callback(self.callbacks().stake_callback(caller, stokens))
            .call_and_exit();
    }

    #[endpoint(earnPunchcard)]
    fn earn_punchcard(
        &self,
        value: BigUint,
        value_to_return: BigUint,
        brand_id: ManagedBuffer,
        tier: ManagedBuffer,
        signature: ManagedBuffer
    ) {
        self.require_claim_sig(&(&value + &value_to_return), &signature);        

        let caller = self.blockchain().get_caller();
        let nonce = self.get_last_claim_nonce(&caller) + 1;

        self.last_claim(&caller).set(
            ClaimedValue {
                timestamp: self.blockchain().get_block_timestamp(),
                nonce,
                value: value.clone() + value_to_return.clone()
            }
        );

        if value_to_return > 0 {
            self.send().direct_esdt(&caller, &self.token().get_token_id(), 0, &value_to_return);
        }

        let token = self.token();
        self.minting_proxy(self.minting_sc().get())
            .buy_random_nft_delegated(brand_id, tier, caller, 1u32)
            .with_esdt_transfer((
                token.get_token_id(),
                0,
                value.clone()
            ))
            .async_call()
            .with_callback(self.callbacks().mint_callback(self.blockchain().get_caller(), value))
            .call_and_exit();
    }

    fn require_claim_sig(
        &self,
        value: &BigUint,
        signature: &ManagedBuffer
    ) {
        let signer = self.signer().get();
        let key = signer.as_managed_buffer();
        let caller = self.blockchain().get_caller();
        let nonce = self.get_last_claim_nonce(&caller) + 1;

        let mut data = ManagedBuffer::new_from_bytes(&nonce.to_be_bytes());
        data.append(&value.to_bytes_be_buffer());
        data.append(&caller.as_managed_buffer());

        //For EI-1-2: let signature_is_valid = self.crypto().verify_ed25519(&key, &data, &signature);
        let signature_is_valid = self.crypto().verify_ed25519_legacy(
            &key.to_boxed_bytes().as_slice(),
            &data.to_boxed_bytes().as_slice(),
            &signature.to_boxed_bytes().as_slice()
        );
        require!(signature_is_valid, "Invalid claim");
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

    #[only_owner]
    #[endpoint(setStakingSc)]
    fn set_staking_sc(
        &self,
        address: ManagedAddress
    ) {
        self.staking_sc().set(address);
    }

    #[only_owner]
    #[endpoint(setMintingSc)]
    fn set_minting_sc(
        &self,
        address: ManagedAddress
    ) {
        self.minting_sc().set(address);
    }

    fn get_last_claim_nonce(
        &self,
        address: &ManagedAddress
    ) -> u64 {
        if !self.last_claim(address).is_empty() {
            self.last_claim(&address).get().nonce
        } else {
            0
        }
    }

    // views
    #[view(getLastClaim)]
    fn get_last_claim(
        &self,
        address: ManagedAddress,
    ) -> MultiValue3<u64, u64, BigUint> {
        let last_claim = if self.last_claim(&address).is_empty() {
            ClaimedValue {
                timestamp: self.blockchain().get_block_timestamp(),
                nonce: 0,
                value: BigUint::zero(),
            }
        } else {
            self.last_claim(&address).get()
        };
        MultiValue3::from((last_claim.timestamp, last_claim.nonce, last_claim.value))
    }

    #[callback]
    fn stake_callback(
        &self,
        caller: ManagedAddress,
        stokens: ManagedVec<EsdtTokenPayment<Self::Api>>,
        #[call_result] result: ManagedAsyncCallResult<()>
    ) {
        match result {
            ManagedAsyncCallResult::Ok(()) => {},
            ManagedAsyncCallResult::Err(err) => {
                // log the error in storage
                self.err_storage().set(&err.err_msg);

                for stoken in &stokens {
                    self.send().direct_esdt(
                        &caller,
                        &stoken.token_identifier,
                        stoken.token_nonce,
                        &stoken.amount
                    );
                }
            },
        }
    }

    #[callback]
    fn mint_callback(
        &self,
        caller: ManagedAddress,
        value: BigUint,
        #[call_result] result: ManagedAsyncCallResult<()>
    ) {
        match result {
            ManagedAsyncCallResult::Ok(()) => {},
            ManagedAsyncCallResult::Err(err) => {
                // log the error in storage
                self.err_storage().set(&err.err_msg);
                self.send().direct_esdt(
                    &caller,
                    &self.token().get_token_id(),
                    0,
                    &value
                );
            },
        }
    }

    #[proxy]
    fn staking_proxy(&self, sc_address: ManagedAddress) -> staking::Proxy<Self::Api>;

    #[proxy]
    fn minting_proxy(&self, sc_address: ManagedAddress) -> nft_minter::Proxy<Self::Api>;

    #[storage_mapper("staking_sc")]
    fn staking_sc(&self) -> SingleValueMapper<ManagedAddress>;

    #[storage_mapper("minting_sc")]
    fn minting_sc(&self) -> SingleValueMapper<ManagedAddress>;

    #[storage_mapper("lastClaim")]
    fn last_claim(&self, address: &ManagedAddress) -> SingleValueMapper<ClaimedValue<Self::Api>>;

    #[storage_mapper("signer")]
    fn signer(&self) -> SingleValueMapper<ManagedAddress>;

    #[storage_mapper("tokenId")]
    fn token(&self) -> FungibleTokenMapper<Self::Api>;

    #[view(getLastError)]
    #[storage_mapper("errStorage")]
    fn err_storage(&self) -> SingleValueMapper<ManagedBuffer>;
}

mod nft_minter {
    multiversx_sc::imports!();

    #[multiversx_sc::proxy]
    pub trait NftMinterContract {
		#[endpoint(buyRandomNftDelegated)]
		fn buy_random_nft_delegated(
            &self,
            brand_id: ManagedBuffer,
            tier: ManagedBuffer,
            caller: ManagedAddress,
            opt_nfts_to_buy: OptionalValue<usize>
        );
    }
}
