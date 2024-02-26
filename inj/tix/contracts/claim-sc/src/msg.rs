use cosmwasm_schema::{cw_serde, QueryResponses};
use cosmwasm_std::{Uint128, Addr};
use cw1_whitelist::msg::InstantiateMsg as WhitelistIntantiateMsg;

use crate::state::ClaimedValue;

#[cw_serde]
pub struct InstantiateMsg {
    pub whitelist: WhitelistIntantiateMsg,
    pub owner: Option<String>,
    pub cw721_addr: String,
    pub signer: String,
    pub tix_denom: String,
    pub stake_sc: String,
}

#[cw_serde]
pub enum ExecuteMsg {
    /// Freeze will make a mutable contract immutable, must be called by an admin
    Freeze {},
    Unfreeze {},
    /// UpdateAdmins will change the admin set of the contract, must be called by an existing admin,
    /// and only works if the contract is mutable
    UpdateAdmins { admins: Vec<String> },
    StakeEarnings {
        value: Uint128,
        signature: String,
    },
    Claim {
        value: Uint128,
        signature: String,
    },
    EarnPunchcard {
        value: Uint128,
        value_to_return: Uint128,
        signature: String,
    },
    UpdateConfig {
        owner: Option<String>,
        cw721_addr: String,
        signer: String,
        tix_denom: String,
        stake_sc: Addr,
    },
}

#[cw_serde]
pub enum Send721Msg {
    ForSender {},
    ForAddress {
        address: String,
    },
}

#[cw_serde]
pub enum StakeMsg {
    Stake { address: String },
    RestakeAndStake { address: String },
    ClaimAndStake { address: String },
}

#[cw_serde]
#[derive(QueryResponses)]
pub enum QueryMsg {
    #[returns(ClaimedValue)]
    LastClaim {
        address: String,
    },
    #[returns(DebugResponse)]
    Debug {},
}

#[cw_serde]
pub struct DebugResponse {
    pub string: String
}
