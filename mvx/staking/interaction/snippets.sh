WALLET="wallets/test-wallet.pem"
WALLET_ADDR="erd1lldf2xts8s5595fts3x2062eymqf0zpg4k4qkw5df0ux2gsl9rsq5j5l5j"
WALLET_OTHER="wallets/test-wallet.pem"
DEPLOY_TRANSACTION=$(erdpy data load --key=deployTransaction-devnet)
PROXY="https://devnet-gateway.multiversx.com"
CHAIN_ID="D"
SC_ADDRESS="erd1qqqqqqqqqqqqqpgqxmyzl93sghnrmy2vzspamk47dyjpsgrx9rsq24xmup"
STOKEN="STIX-0bb006"
STOKEN_HEX=`atohex STIX-0bb006`
UTOKEN="UTIX-b9480e"
UTOKEN_HEX=`atohex UTIX-b9480e`
TIX="TIX-3308a8"
TIX_HEX=`atohex TIX-3308a8`
WASM_PATH="output/staking.wasm"

deploy() {
    mxpy --verbose contract deploy --bytecode=${WASM_PATH} --recall-nonce --pem=${WALLET} \
    --gas-limit=60000000 \
    --send --outfile="deploy-devnet.interaction.json" --proxy=${PROXY} --chain=${CHAIN_ID} || return

    TRANSACTION=$(erdpy data parse --file="deploy-devnet.interaction.json" --expression="data['emittedTransactionHash']")
    ADDRESS=$(erdpy data parse --file="deploy-devnet.interaction.json" --expression="data['contractAddress']")

    erdpy data store --key=address-devnet --value=${ADDRESS}
    erdpy data store --key=deployTransaction-devnet --value=${TRANSACTION}

    echo ""
    echo "Smart contract address: ${ADDRESS}"
}

upgrade() {
    mxpy --verbose contract upgrade ${SC_ADDRESS} --bytecode=${WASM_PATH} --recall-nonce --pem=${WALLET} --gas-limit=100000000 \
    --send --proxy=${PROXY} --chain=${CHAIN_ID}
}

setupStaking() {
    local TOKEN_NAME="0x5374616b6564544958" # StakedTIX
    local TOKEN_TICKER="0x53544958" # STIX

    local VALUE="50000000000000000" # 0.05
    local GAS_LIMIT="60000000" # 60 mil

    erdpy --verbose contract call ${SC_ADDRESS} --recall-nonce \
    --pem=${WALLET} \
    --gas-limit=$GAS_LIMIT --value=$VALUE --function="setupStaking" \
    --arguments $TOKEN_NAME $TOKEN_TICKER \
    --send --proxy=$PROXY --chain=$CHAIN_ID
}

setupUnstaking() {
    local TOKEN_NAME="0x556e7374616b6564544958" # UnstakedTIX
    local TOKEN_TICKER="0x55544958" # UTIX

    local VALUE="50000000000000000" # 0.05
    local GAS_LIMIT="60000000" # 60 mil

    erdpy --verbose contract call ${SC_ADDRESS} --recall-nonce \
    --pem=${WALLET} \
    --gas-limit=$GAS_LIMIT --value=$VALUE --function="setupUnstaking" \
    --arguments $TOKEN_NAME $TOKEN_TICKER \
    --send --proxy=$PROXY --chain=$CHAIN_ID
}

getStakingToken() {
    erdpy --verbose contract query ${SC_ADDRESS}  \
    --function="getStakingToken" \
    --proxy=${PROXY}
}

getUnstakingToken() {
    erdpy --verbose contract query ${SC_ADDRESS}  \
    --function="getUnstakingToken" \
    --proxy=${PROXY}
}

stake() {
    local TOKEN_ID=$TIX_HEX
    local VALUE="0x8ac7230489e80000" # 10000000000000000000
    local FUNC="0x7374616b65" # stake

    local GAS_LIMIT="10000000" # 10 mil

    erdpy --verbose contract call ${SC_ADDRESS} --recall-nonce \
    --pem=${WALLET} \
    --gas-limit=$GAS_LIMIT --value=0 --function="ESDTTransfer" \
    --arguments $TOKEN_ID $VALUE $FUNC \
    --send --proxy=$PROXY --chain=$CHAIN_ID
}

claim() {
    local TOKEN_ID=$STOKEN_HEX
    local NONCE="0x11"
    local VALUE="0x8ac7230489e80000" # 10000000000000000000
    local FUNC="0x636c61696d" # claim

    local GAS_LIMIT="10000000" # 10 mil

    erdpy --verbose contract call $WALLET_ADDR --recall-nonce \
    --pem=${WALLET} \
    --gas-limit=$GAS_LIMIT --value=0 --function="ESDTNFTTransfer" \
    --arguments $TOKEN_ID $NONCE $VALUE $SC_ADDRESS $FUNC \
    --send --proxy=$PROXY --chain=$CHAIN_ID
}

stakeRewards() {
    local TOKEN_ID=$STOKEN_HEX
    local NONCE="0x13"
    local VALUE="0x8ac7230489e80000" # 10000000000000000000
    local FUNC="0x7374616b6552657761726473" # stakeRewards

    local GAS_LIMIT="10000000" # 10 mil

    erdpy --verbose contract call $WALLET_ADDR --recall-nonce \
    --pem=${WALLET} \
    --gas-limit=$GAS_LIMIT --value=0 --function="ESDTNFTTransfer" \
    --arguments $TOKEN_ID $NONCE $VALUE $SC_ADDRESS $FUNC \
    --send --proxy=$PROXY --chain=$CHAIN_ID
}

unstake() {
    local TOKEN_ID=$STOKEN_HEX
    local NONCE="0x41"
    local VALUE="0x1bc16d674ec80000" # 2
    local FUNC="0x756e7374616b65" # unstake

    local GAS_LIMIT="10000000" # 10 mil

    erdpy --verbose contract call $WALLET_ADDR --recall-nonce \
    --pem=${WALLET} \
    --gas-limit=$GAS_LIMIT --value=0 --function="ESDTNFTTransfer" \
    --arguments $TOKEN_ID $NONCE $VALUE $SC_ADDRESS $FUNC \
    --send --proxy=$PROXY --chain=$CHAIN_ID
}

withdraw() {
    local TOKEN_ID=$UTOKEN_HEX
    local NONCE="0x06"
    # local VALUE="0x8ac7230489e80000" # 10000000000000000000
    local VALUE="0x8af2eff752ceee76"
    local FUNC="0x7769746864726177" # withdraw

    local GAS_LIMIT="10000000" # 10 mil

    erdpy --verbose contract call $WALLET_ADDR --recall-nonce \
    --pem=${WALLET} \
    --gas-limit=$GAS_LIMIT --value=0 --function="ESDTNFTTransfer" \
    --arguments $TOKEN_ID $NONCE $VALUE $SC_ADDRESS $FUNC \
    --send --proxy=$PROXY --chain=$CHAIN_ID
}

merge2() {
    local TOKEN_ID=$STOKEN_HEX
    local NUM_TOKENS="0x02"
    local NONCE1="0x13"
    local VALUE1="0xd23e26f787abd"
    local NONCE2="0x15"
    local VALUE2="0x8ae5cc14e35673b9"
    local FUNC="0x6d657267655374616b6573" # mergeStakes

    local GAS_LIMIT="10000000" # 10 mil

    erdpy --verbose contract call $WALLET_ADDR --recall-nonce \
    --pem=${WALLET} \
    --gas-limit=$GAS_LIMIT --value=0 --function="MultiESDTNFTTransfer" \
    --arguments $SC_ADDRESS $NUM_TOKENS $TOKEN_ID $NONCE1 $VALUE1 $TOKEN_ID $NONCE2 $VALUE2 $FUNC \
    --send --proxy=$PROXY --chain=$CHAIN_ID
}

merge3() {
    local TOKEN_ID=$STOKEN_HEX
    local NUM_TOKENS="0x03" # 3
    local NONCE1="0x09"
    local VALUE1="0x1bc16d674ec80000" # 2
    local NONCE2="0x0a"
    local VALUE2="0x4563918244f40000" # 5
    local NONCE3="0x0d"
    local VALUE3="0x6124fee993bc0000" # 7
    local FUNC="0x6d657267655374616b6573" # mergeStakes

    local GAS_LIMIT="10000000" # 10 mil

    erdpy --verbose contract call $WALLET_ADDR --recall-nonce \
    --pem=${WALLET} \
    --gas-limit=$GAS_LIMIT --value=0 --function="MultiESDTNFTTransfer" \
    --arguments $SC_ADDRESS $NUM_TOKENS $TOKEN_ID $NONCE1 $VALUE1 $TOKEN_ID $NONCE2 $VALUE2 $TOKEN_ID $NONCE3 $VALUE3 $FUNC \
    --send --proxy=$PROXY --chain=$CHAIN_ID
}

fund() {
    local VALUE="0x152d02c7e14af6800000" # 100k
    local FUNC="0x66756e64" # fund
    mxpy --verbose contract call ${SC_ADDRESS} --recall-nonce --pem=${WALLET} \
    --gas-limit=10000000 --value=0 --function="ESDTTransfer" \
    --arguments $TIX_HEX $VALUE $FUNC \
    --send --proxy=${PROXY} --chain=${CHAIN_ID}
}

burnStake() {
    local TOKEN_ID=$STOKEN_HEX
    local NONCE="0x01" # 01
    local VALUE="0x8ac7230489e80000" # 10000000000000000000
    local FUNC="0x6275726e5374616b65" # burnStake

    local GAS_LIMIT="10000000" # 10 mil

    erdpy --verbose contract call $WALLET_ADDR --recall-nonce \
    --pem=${WALLET} \
    --gas-limit=$GAS_LIMIT --value=0 --function="ESDTNFTTransfer" \
    --arguments $TOKEN_ID $NONCE $VALUE $SC_ADDRESS $FUNC \
    --send --proxy=$PROXY --chain=$CHAIN_ID
}

getClaimable() {
    local VALUE="0xb72fd2103b280000"
    local EPOCH="0x1a9a3f5"

    erdpy --verbose contract query ${SC_ADDRESS}  \
    --function="getClaimable" \
    --arguments $VALUE $EPOCH \
    --proxy=${PROXY}
}

getUnstakeData() {
    local EPOCH="0x1a9a3f5"

    erdpy --verbose contract query ${SC_ADDRESS}  \
    --function="getUnstakeData" \
    --arguments $EPOCH \
    --proxy=${PROXY}
}

getEpoch() {
    erdpy --verbose contract query ${SC_ADDRESS}  \
    --function="getEpoch" \
    --proxy=${PROXY}
}
