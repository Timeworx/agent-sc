multiversx_sc::imports!();

#[multiversx_sc::module]
pub trait AdminWhitelistModule:
    crate::common_storage::CommonStorageModule
{
    #[only_owner]
    #[endpoint(addUserToAdminList)]
    fn add_user_to_admin_list(&self, address: ManagedAddress) {
        self.admin_whitelist().add(&address);
    }

    #[only_owner]
    #[endpoint(removeUserFromAdminList)]
    fn remove_user_from_admin_list(&self, address: ManagedAddress) {
        self.admin_whitelist().remove(&address);
    }

    fn require_caller_is_admin(&self) {
        let caller = self.blockchain().get_caller();
        let sc_owner = self.blockchain().get_owner_address();
        if caller == sc_owner {
            return;
        }

        self.admin_whitelist().require_whitelisted(&caller);
    }

    fn check_permissions(&self) {
        let is_managed = self.is_managed().get();
        if is_managed {
            self.require_caller_is_admin();
        }
    }

    #[storage_mapper("adminWhitelist")]
    fn admin_whitelist(&self) -> WhitelistMapper<Self::Api, ManagedAddress>;
}
