multiversx_sc::imports!();

use crate::{
    common_storage::{BrandId},
};

pub type TierName<M> = ManagedBuffer<M>;

const VEC_MAPPER_FIRST_ITEM_INDEX: usize = 1;
pub const MAX_TIERS_PER_BRAND: usize = 5;

#[multiversx_sc::module]
pub trait NftTierModule:
    crate::common_storage::CommonStorageModule
{
    fn get_next_random_id(
        &self,
        brand_id: &BrandId<Self::Api>,
        tier: &TierName<Self::Api>,
    ) -> UniqueId {
        if self.is_unlimited(brand_id, tier) {
            let next_id = self.next_id(brand_id, tier).get();
            self.next_id(brand_id, tier).update(|id| *id += 1);
            next_id
        } else {
            let mut id_mapper = self.available_ids(brand_id, tier);
            let last_id_index = id_mapper.len();
            require!(last_id_index > 0, "No more NFTs available for brand");

            let rand_index = self.get_random_usize(VEC_MAPPER_FIRST_ITEM_INDEX, last_id_index + 1);
            let rand_id = id_mapper.swap_remove(rand_index);
            let id_offset = self.nft_id_offset_for_tier(brand_id, tier).get();

            rand_id + id_offset
        }
    }

    fn is_unlimited(
        &self,
        brand_id: &BrandId<Self::Api>,
        tier: &TierName<Self::Api>,
    ) -> bool {
        self.total_nfts(&brand_id, &tier).get() == 0
    }

    /// range is [min, max)
    fn get_random_usize(&self, min: usize, max: usize) -> usize {
        let mut rand_source = RandomnessSource::new();
        rand_source.next_usize_in_range(min, max)
    }

    #[view(getNftTiersForBrand)]
    #[storage_mapper("nftTiersForBrand")]
    fn nft_tiers_for_brand(
        &self,
        brand_id: &BrandId<Self::Api>,
    ) -> UnorderedSetMapper<TierName<Self::Api>>;

    #[view(nftIdOffsetForTier)]
    #[storage_mapper("nftIdOffsetForTier")]
    fn nft_id_offset_for_tier(
        &self,
        brand_id: &BrandId<Self::Api>,
        tier: &TierName<Self::Api>,
    ) -> SingleValueMapper<usize>;

    #[storage_mapper("availableIds")]
    fn available_ids(
        &self,
        brand_id: &BrandId<Self::Api>,
        tier: &TierName<Self::Api>,
    ) -> UniqueIdMapper<Self::Api>;

    #[storage_mapper("totalNfts")]
    fn total_nfts(
        &self,
        brand_id: &BrandId<Self::Api>,
        tier: &TierName<Self::Api>,
    ) -> SingleValueMapper<usize>;

    #[storage_mapper("nextId")]
    fn next_id(
        &self,
        brand_id: &BrandId<Self::Api>,
        tier: &TierName<Self::Api>,
    ) -> SingleValueMapper<usize>;
}
