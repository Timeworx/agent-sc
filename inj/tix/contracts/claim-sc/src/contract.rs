#[cfg(not(feature = "library"))]
use cosmwasm_std::entry_point;
use cosmwasm_std::{ensure, Api, Addr, Binary, Deps, DepsMut, Env, MessageInfo, Response, StdResult, Uint128, Empty, CanonicalAddr, BankMsg, Coin, WasmMsg, to_json_binary, StdError};
use cw2::{get_contract_version, set_contract_version};

use crate::error::ContractError;
use crate::msg::{ExecuteMsg, InstantiateMsg, QueryMsg, Send721Msg, DebugResponse, StakeMsg};
use crate::state::{Config, ClaimedValue, CONFIG, CLAIMED_VALUES};

use semver::Version;

use cw1_whitelist::{
    contract::{
        execute_freeze, execute_update_admins, instantiate as whitelist_instantiate,
    },
    state::ADMIN_LIST,
};

// version info for migration info
const CONTRACT_NAME: &str = "crates.io:timeworx-claim-sc";
const CONTRACT_VERSION: &str = env!("CARGO_PKG_VERSION");

#[cfg_attr(not(feature = "library"), entry_point)]
pub fn instantiate(
    mut deps: DepsMut,
    env: Env,
    info: MessageInfo,
    msg: InstantiateMsg,
) -> Result<Response, ContractError> {
    set_contract_version(deps.storage, CONTRACT_NAME, CONTRACT_VERSION)?;

    let whitelist_result = whitelist_instantiate(deps.branch(), env, info.clone(), msg.whitelist)?;

    let owner = msg
        .owner
        .and_then(|s| deps.api.addr_validate(s.as_str()).ok())
        .unwrap_or(info.sender);
    let config = Config {
        owner: owner.clone(),
        cw721_addr: deps.api.addr_validate(msg.cw721_addr.as_str())?,
        signer: Binary::from_base64(&msg.signer)?,
        tix_denom: msg.tix_denom.clone(),
        stake_sc: deps.api.addr_validate(msg.stake_sc.as_str())?,
    };
    CONFIG.save(deps.storage, &config)?;

    Ok(Response::new()
        .add_attribute("method", "instantiate")
        .add_attribute("owner", owner)
        .add_attribute("cw721_addr", msg.cw721_addr)
        .add_attribute("tix_denom", msg.tix_denom)
        .add_attributes(whitelist_result.attributes))
}

#[cfg_attr(not(feature = "library"), entry_point)]
pub fn execute(
    deps: DepsMut,
    env: Env,
    info: MessageInfo,
    msg: ExecuteMsg,
) -> Result<Response, ContractError> {
    match msg {
        ExecuteMsg::Freeze {} => Ok(execute_freeze(deps, env, info)?),
        ExecuteMsg::Unfreeze {} => execute_unfreeze(deps, env, info),
        ExecuteMsg::UpdateAdmins { admins } => Ok(execute_update_admins(deps, env, info, admins)?),
        ExecuteMsg::Claim { 
            value,
            signature,
        } => execute_claim(deps, env, info, value, signature),
        ExecuteMsg::EarnPunchcard { 
            value,
            value_to_return,
            signature,
        } => execute_earn(deps, env, info, value, value_to_return, signature),
        ExecuteMsg::UpdateConfig { 
            owner,
            cw721_addr,
            signer,
            tix_denom,
            stake_sc,
        } => execute_update_config(deps, info, owner, cw721_addr, signer, tix_denom, stake_sc),
        ExecuteMsg::StakeEarnings {
            value,
            signature,
        } => execute_stake(deps, env, info, value, signature)
    }
}

pub fn execute_unfreeze(
    deps: DepsMut,
    _env: Env,
    info: MessageInfo,
) -> Result<Response, ContractError> {
    let config = CONFIG.load(deps.storage)?;
    let mut admin_cfg = ADMIN_LIST.load(deps.storage)?;

    if !(config.owner != info.sender.as_ref()) {
        Err(ContractError::Unauthorized {})
    } else {
        admin_cfg.mutable = true;
        ADMIN_LIST.save(deps.storage, &admin_cfg)?;

        let res = Response::new().add_attribute("action", "unfreeze");
        Ok(res)
    }
}

pub fn execute_stake(
    deps: DepsMut,
    env: Env,
    info: MessageInfo,
    value: Uint128,
    signature: String,
) -> Result<Response, ContractError> {
    let config: Config = CONFIG.load(deps.storage)?;

    let sig_msg = require_claim_sig(&deps, &info, value, signature)?;

    let sender = info.sender;

    let stake_msg = WasmMsg::Execute {
        contract_addr: config.stake_sc.into_string(),
        msg: to_json_binary(&StakeMsg::Stake { address: sender.to_string() })?,
        funds: [Coin::new(value.into(), config.tix_denom)].to_vec(),
    };

    CLAIMED_VALUES.update(deps.storage, &sender, |claimed_value| -> Result<_, StdError> {
        let claimed_value = claimed_value.unwrap_or_default();
        Ok(ClaimedValue {
            timestamp: env.block.time.nanos(),
            nonce: claimed_value.nonce + 1,
            value: value
        })
    })?;

    Ok(
        Response::new()
            .add_attribute("action", "stake")
            .add_message(stake_msg)
            .add_attributes(sig_msg.attributes)
    )
}

pub fn execute_claim(
    deps: DepsMut,
    env: Env,
    info: MessageInfo,
    value: Uint128,
    signature: String,
) -> Result<Response, ContractError> {
    let config: Config = CONFIG.load(deps.storage)?;

    let sig_msg = require_claim_sig(&deps, &info, value, signature)?;

    let sender = info.sender;

    let claim_msg = BankMsg::Send {
        to_address: sender.clone().into_string(),
        amount: [Coin::new(value.into(), config.tix_denom)].to_vec()
    };

    CLAIMED_VALUES.update(deps.storage, &sender, |claimed_value| -> Result<_, StdError> {
        let claimed_value = claimed_value.unwrap_or_default();
        Ok(ClaimedValue {
            timestamp: env.block.time.nanos(),
            nonce: claimed_value.nonce + 1,
            value: value
        })
    })?;

    Ok(
        Response::new()
            .add_message(claim_msg)
            .add_attribute("action", "execute_claim")
            .add_attribute("claimer", sender)
            .add_attribute("value", value)
            .add_attributes(sig_msg.attributes)
    )
}

pub fn execute_earn(
    deps: DepsMut,
    env: Env,
    info: MessageInfo,
    value: Uint128,
    value_to_return: Uint128,
    signature: String,
) -> Result<Response, ContractError> {
    let config: Config = CONFIG.load(deps.storage)?;

    let total_value = value + value_to_return;

    let sig_msg = require_claim_sig(&deps, &info, total_value, signature)?;

    let sender = info.sender;

    let claim_msg = BankMsg::Send {
        to_address: sender.clone().into_string(),
        amount: [Coin::new(value_to_return.into(), config.tix_denom.clone())].to_vec()
    };

    let cw721msg = Send721Msg::ForAddress { address: sender.clone().into_string() };
    let mint_msg = WasmMsg::Execute {
        contract_addr: config.cw721_addr.clone().into_string(),
        msg: to_json_binary(&cw721msg)?,
        funds: [Coin::new(value.into(), config.tix_denom)].to_vec(),
    };

    CLAIMED_VALUES.update(deps.storage, &sender, |claimed_value| -> Result<_, StdError> {
        let claimed_value = claimed_value.unwrap_or_default();
        Ok(ClaimedValue {
            timestamp: env.block.time.nanos(),
            nonce: claimed_value.nonce + 1,
            value: value
        })
    })?;

    Ok(
        Response::new()
            .add_message(claim_msg)
            .add_message(mint_msg)
            .add_attribute("action", "execute_earn")
            // .add_attribute("claimer", sender)
            .add_attribute("value", value)
            .add_attribute("value_to_return", value_to_return)
            .add_attributes(sig_msg.attributes)
    )
}

fn require_claim_sig(
    deps: &DepsMut,
    info: &MessageInfo,
    value: Uint128,
    signature: String
) -> Result<Response, ContractError> {
    let config: Config = CONFIG.load(deps.storage)?;
    let signer = config.signer;
    let claimed_value = last_claim_mut(deps, info.sender.clone().into_string())?;

    let caller = deps.api.addr_canonicalize(info.sender.as_str())?;
    let nonce = claimed_value.nonce + 1;

    let message = [nonce.to_be_bytes().as_slice(), value.to_be_bytes().as_slice(), caller.as_slice()].concat();

    let signature_bin = Binary::from_base64(signature.as_str())?;

    match deps.api.ed25519_verify(message.as_slice(), &signature_bin.as_slice(), signer.as_slice()) {
        Ok(result) => {
            if result {
                Ok(Response::new())
            } else {
                Err(ContractError::InvalidSignature(result.to_string()))
            }
            // Ok(
            //     Response::new()
            //         .add_attribute("signature valid", result.to_string())
            //         .add_attribute("value", value)
            //         .add_attribute("message", Binary::from(message.as_slice()).to_base64())
            //         .add_attribute("signature", Binary::from(signature_bin.as_slice()).to_base64())
            //         .add_attribute("signer", Binary::from(signer.as_slice()).to_base64())
            // )
        },
        Err(_error) => Err(_error.into()),
    }
}

pub fn execute_update_config(
    deps: DepsMut,
    info: MessageInfo,
    owner: Option<String>,
    cw721_addr: String,
    signer: String,
    tix_denom: String,
    stake_sc: Addr,
) -> Result<Response, ContractError> {
    let cfg = ADMIN_LIST.load(deps.storage)?;
    if !cfg.can_modify(info.sender.as_ref()) {
        Err(ContractError::Unauthorized {})
    } else {
        let owner = owner
            .and_then(|s| deps.api.addr_validate(s.as_str()).ok())
            .unwrap_or(info.sender);
        let config = Config {
            owner: owner.clone(),
            cw721_addr: deps.api.addr_validate(cw721_addr.as_str())?,
            signer: Binary::from_base64(&signer)?,
            tix_denom: tix_denom.clone(),
            stake_sc: stake_sc.clone(),
        };
        CONFIG.save(deps.storage, &config)?;

        Ok(
            Response::new()
                .add_attribute("action", "execute_set_signer")
                .add_attribute("owner", owner)
                .add_attribute("cw721_addr", cw721_addr)
                .add_attribute("signer", signer)
                .add_attribute("tix_denom", tix_denom)
                .add_attribute("stake_sc", stake_sc.to_string())
        )
    }
}

// Utils

pub fn ensure_admin(
    deps: &DepsMut,
    info: &MessageInfo,
) -> Result<(), ContractError> {
    let cfg = ADMIN_LIST.load(deps.storage)?;
    ensure!(cfg.is_admin(&info.sender), ContractError::Unauthorized {});
    Ok(())
}

pub fn map_validate(api: &dyn Api, admins: &[String]) -> StdResult<Vec<Addr>> {
    admins.iter().map(|addr| api.addr_validate(addr)).collect()
}

#[cfg_attr(not(feature = "library"), entry_point)]
pub fn query(deps: Deps, _env: Env, msg: QueryMsg) -> StdResult<Binary> {
    match msg {
        QueryMsg::LastClaim { address } => to_json_binary(&last_claim(&deps, address)?),
        QueryMsg::Debug {} => to_json_binary(&debug_query(deps)?)
    }
}

fn last_claim(
    deps: &Deps,
    address: String
) -> StdResult<ClaimedValue> {
    match CLAIMED_VALUES.load(deps.storage, &deps.api.addr_validate(&address)?) {
        Ok(claimed_value) => Ok(claimed_value),
        Err(_error) => Ok(ClaimedValue { timestamp: 0, nonce: 0, value: Uint128::zero() })
    }
}

fn last_claim_mut(
    deps: &DepsMut,
    address: String
) -> StdResult<ClaimedValue> {
    match CLAIMED_VALUES.load(deps.storage, &deps.api.addr_validate(&address)?) {
        Ok(claimed_value) => Ok(claimed_value),
        Err(_error) => Ok(ClaimedValue { timestamp: 0, nonce: 0, value: Uint128::zero() })
    }
}

fn debug_query(
    deps: Deps,
) -> StdResult<DebugResponse> {
    let config: Config = CONFIG.load(deps.storage)?;

    // let nonce: u64 = 1;
    // let value: Uint128 = Uint128::from(3000000000000000000u128);
    // let caller = deps.api.addr_canonicalize("inj1rw3qvamxgmvyexuz2uhyfa4hukvtvteznxjvke")?;

    // let message = [nonce.to_be_bytes().as_slice(), value.to_be_bytes().as_slice(), caller.as_slice()].concat();

    Ok(
        DebugResponse {
            string: deps.api.addr_humanize(&CanonicalAddr(config.signer))?.into_string()
            // string: Binary::from(message.as_slice()).to_base64()
        }
    )
}

#[cfg_attr(not(feature = "library"), entry_point)]
pub fn migrate(deps: DepsMut, _env: Env, _msg: Empty) -> Result<Response, ContractError> {
    let version: Version = CONTRACT_VERSION.parse()?;
    let storage_version: Version = get_contract_version(deps.storage)?.version.parse()?;

    if storage_version < version {
        set_contract_version(deps.storage, CONTRACT_NAME, CONTRACT_VERSION)?;
    }

    Ok(Response::new())
}

#[cfg(test)]
mod tests {}
