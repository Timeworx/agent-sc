use cosmwasm_schema::{cw_serde, QueryResponses};
use cosmwasm_std::{Addr, Uint128};
use cw721_metadata_onchain::Extension;

#[cw_serde]
pub struct InstantiateMsg {
    pub owner: Addr,
    pub max_tokens: u32,
    pub unit_price: Uint128,
    pub name: String,
    pub symbol: String,
    pub token_code_id: u64,
    pub tix_denom: String,
    pub token_uri: String,
    pub extension: Extension,
}

#[cw_serde]
pub enum ExecuteMsg {
    ForSender {},
    ForAddress {
        address: String,
    },
}

#[cw_serde]
#[derive(QueryResponses)]
pub enum QueryMsg {
    #[returns(ConfigResponse)]
    GetConfig {},
}

#[cw_serde]
pub struct ConfigResponse {
    pub owner: Addr,
    pub tix_denom: String,
    pub cw721_address: Option<Addr>,
    pub max_tokens: u32,
    pub unit_price: Uint128,
    pub name: String,
    pub symbol: String,
    pub token_uri: String,
    pub extension: Extension,
    pub unused_token_id: u32,
}

