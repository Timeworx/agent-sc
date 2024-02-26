use cosmwasm_schema::cw_serde;
use cosmwasm_std::{Addr, Uint128, Binary};
use cw_storage_plus::{Item, Map};

#[cw_serde]
pub struct Config {
    pub owner: Addr,
    pub cw721_addr: Addr,
    pub signer: Binary,
    pub tix_denom: String,
    pub stake_sc: Addr,
}

pub const CONFIG: Item<Config> = Item::new("config");

#[cw_serde]
#[derive(Default)]
pub struct ClaimedValue {
    pub timestamp: u64,
    pub nonce: u64,
    pub value: Uint128,
}
pub const CLAIMED_VALUES: Map<&Addr, ClaimedValue> = Map::new("claimed_value");

#[cw_serde]
pub struct AdminList {
    pub admins: Vec<Addr>,
    pub mutable: bool,
}
