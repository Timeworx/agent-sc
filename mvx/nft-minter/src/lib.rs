#![no_std]

multiversx_sc::imports!();

use hex_literal::hex;

pub mod admin_whitelist;
pub mod brand_creation;
pub mod common_storage;
pub mod events;
pub mod nft_attributes_builder;
pub mod nft_marketplace_interactor;
pub mod nft_minting;
pub mod nft_tier;
pub mod royalties;
pub mod views;

const ESDT_ROLE_NFT_UPDATE_ATTRIBUTES: &[u8] = b"ESDTRoleNFTUpdateAttributes";
static NFT_SC_ADDRESS: [u8; 32] = hex!("000000000000000000010000000000000000000000000000000000000002ffff");

#[multiversx_sc::contract]
pub trait NftMinter:
    common_storage::CommonStorageModule
    + admin_whitelist::AdminWhitelistModule
    + brand_creation::BrandCreationModule
    + nft_minting::NftMintingModule
    + nft_tier::NftTierModule
    + nft_attributes_builder::NftAttributesBuilderModule
    + royalties::RoyaltiesModule
    + nft_marketplace_interactor::NftMarketplaceInteractorModule
    + views::ViewsModule
    + events::EventsModule
{
    // #[init]
    // fn init(
    //     &self,
    //     royalties_claim_address: ManagedAddress,
    //     mint_payments_claim_address: ManagedAddress,
    //     max_nfts_per_transaction: usize,
    //     is_managed: bool,

    // ) {
    //     self.royalties_claim_address().set(&royalties_claim_address);
    //     self.mint_payments_claim_address().set(&mint_payments_claim_address);
    //     self.set_max_nfts_per_transaction(max_nfts_per_transaction);
    //     self.is_managed().set(&is_managed);
    // }

    #[init]
    fn init(&self) {
    }

    #[only_owner]
    #[endpoint(setMaxNftsPerTransaction)]
    fn set_max_nfts_per_transaction(&self, max: usize) {
        self.max_nfts_per_transaction().set(max);
    }

    #[only_owner]
    #[endpoint(setUpdateAttributesRole)]
    fn nft_set_update_attributes_role(
        &self,
        target: ManagedAddress,
        token_id: TokenIdentifier,
    ) {
        self.call_update_proxy(ManagedAddress::from(NFT_SC_ADDRESS))
            .set_special_role(token_id, target, ESDT_ROLE_NFT_UPDATE_ATTRIBUTES)
            .async_call()
            .call_and_exit()
    }

    #[proxy]
    fn call_update_proxy(&self, sc_address: ManagedAddress) -> nft_proxy::Proxy<Self::Api>;
}

mod nft_proxy {
    multiversx_sc::imports!();

    #[multiversx_sc::proxy]
    pub trait NftContract {
		#[endpoint(setSpecialRole)]
		fn set_special_role(&self, token_id: TokenIdentifier, target: ManagedAddress, arg: ManagedBuffer);
    }
}
