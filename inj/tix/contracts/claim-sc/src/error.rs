use cosmwasm_std::StdError;
use cosmwasm_std::VerificationError;
use thiserror::Error;

#[derive(Error, Debug)]
pub enum ContractError {
    #[error("{0}")]
    Std(#[from] StdError),

    #[error("Unauthorized")]
    Unauthorized {},

    #[error("InvalidSignature: {0}")]
    InvalidSignature(String),

    #[error("Semver parsing error: {0}")]
    SemVer(String),

    #[error("Missing tokens")]
    EmptyBalance {},

    #[error("Wrong token")]
    WrongToken {},
}

impl From<cw1_whitelist::ContractError> for ContractError {
    fn from(err: cw1_whitelist::ContractError) -> Self {
        match err {
            cw1_whitelist::ContractError::Std(error) => ContractError::Std(error),
            cw1_whitelist::ContractError::Unauthorized {} => ContractError::Unauthorized {},
        }
    }
}

impl From<semver::Error> for ContractError {
    fn from(err: semver::Error) -> Self {
        Self::SemVer(err.to_string())
    }
}

impl From<VerificationError> for ContractError {
    fn from(err: VerificationError) -> Self {
        Self::InvalidSignature(err.to_string())
    }
}
