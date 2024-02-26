WALLET="wallets/test-wallet.pem"
WALLET_OTHER="wallets/test-wallet.pem"
DEPLOY_TRANSACTION=$(mxpy data load --key=deployTransaction-devnet)
PROXY="https://devnet-gateway.multiversx.com"
CHAIN_ID="D"
SC_ADDRESS="erd1qqqqqqqqqqqqqpgqdh0jtl4xcehvrlam2avhl9duplxza0ym9rsqnusrnf"
WASM_PATH="output/claim-sc.wasm"
TIX="TIX-3308a8"
TIX_HEX=`atohex TIX-3308a8`

deploy() {
    mxpy --verbose contract deploy --bytecode=${WASM_PATH} --recall-nonce --pem=${WALLET} \
    --gas-limit=50000000 \
    --send --outfile="deploy-devnet.interaction.json" --proxy=${PROXY} --chain=${CHAIN_ID} || return

    TRANSACTION=$(mxpy data parse --file="deploy-devnet.interaction.json" --expression="data['emittedTransactionHash']")
    ADDRESS=$(mxpy data parse --file="deploy-devnet.interaction.json" --expression="data['contractAddress']")

    mxpy data store --key=address-devnet --value=${ADDRESS}
    mxpy data store --key=deployTransaction-devnet --value=${TRANSACTION}

    echo ""
    echo "Smart contract address: ${ADDRESS}"
}

upgrade() {
    mxpy --verbose contract upgrade ${SC_ADDRESS} --bytecode=${WASM_PATH} --recall-nonce --pem=${WALLET} --gas-limit=100000000 \
    --send --proxy=${PROXY} --chain=${CHAIN_ID}
}

setSigner() {
    local WALLET_PUB_KEY="0xffda9519703c2942d12b844ca7e95926c0978828adaa0b3a8d4bf865221f28e0" # test-wallet.pem

    mxpy --verbose contract call ${SC_ADDRESS} --recall-nonce --pem=${WALLET} \
    --gas-limit=3000000 --value=0 --function="setSigner" \
    --arguments ${WALLET_PUB_KEY} \
    --send --proxy=${PROXY} --chain=${CHAIN_ID}
}

setStakingSc() {
    local STAKE_SC="erd1qqqqqqqqqqqqqpgqxmyzl93sghnrmy2vzspamk47dyjpsgrx9rsq24xmup"

    mxpy --verbose contract call ${SC_ADDRESS} --recall-nonce --pem=${WALLET} \
    --gas-limit=3000000 --value=0 --function="setStakingSc" \
    --arguments ${STAKE_SC} \
    --send --proxy=${PROXY} --chain=${CHAIN_ID}
}

setMintingSc() {
    local MINT_SC="erd1qqqqqqqqqqqqqpgq6hazfnz2mkxqple9xsvxl7nwpqtf8zym9rsqfsjp36"

    mxpy --verbose contract call ${SC_ADDRESS} --recall-nonce --pem=${WALLET} \
    --gas-limit=3000000 --value=0 --function="setMintingSc" \
    --arguments ${MINT_SC} \
    --send --proxy=${PROXY} --chain=${CHAIN_ID}
}

claim() {
    local PAYLOAD="0x2c3586526c7c0000"
    local SIGNATURE="0x44BBFDE12A7E502EA335FA810BDA5F80BCFB9F0773547649A9FF585F306CED6A0879C425135C11D506EAE8F5D340A8CF81D5EFA39A5B048B78748A0A7127B80E"

    mxpy --verbose contract call ${SC_ADDRESS} --recall-nonce --pem=${WALLET} \
    --gas-limit=20000000 --value=0 --function="claim" \
    --arguments ${PAYLOAD} ${SIGNATURE} \
    --send --proxy=${PROXY} --chain=${CHAIN_ID}
}

stake() {
    local VALUE="0x29a2241af62c0000" # 3 * 10^18
    local SIGNATURE="0x14568c2e1d919d1fe23813e1a7b65bc023efcc7b9a3ceac7f03b2a80bb4cde610c2b1eaebb0aa546aad0b0a5161b86669d063682ab29511ce0100d48947fd105"

    mxpy --verbose contract call ${SC_ADDRESS} --recall-nonce --pem=${WALLET} \
    --gas-limit=20000000 --value=0 --function="stake" \
    --arguments ${VALUE} ${SIGNATURE} \
    --send --proxy=${PROXY} --chain=${CHAIN_ID}
}

claimOther() {
    local PAYLOAD="0x2c3586526c7c0000"
    local SIGNATURE="0x44BBFDE12A7E502EA335FA810BDA5F80BCFB9F0773547649A9FF585F306CED6A0879C425135C11D506EAE8F5D340A8CF81D5EFA39A5B048B78748A0A7127B80E"

    mxpy --verbose contract call ${SC_ADDRESS} --recall-nonce --pem=${WALLET_OTHER} \
    --gas-limit=7000000 --value=0 --function="claim" \
    --arguments ${PAYLOAD} ${SIGNATURE} \
    --send --proxy=${PROXY} --chain=${CHAIN_ID}
}

claimOtherSignature() {
    local PAYLOAD="0x2C3586526C7C0000"
    local SIGNATURE="0x52169FDA1A58883CC2016F18E16B3453B5952AA8B6ADF86A5435DCBFD9AEFBDC135E1779A55EDD0DB25DCADD19B5FDC4209F7D0117812BDCA26B923094629E0E"

    mxpy --verbose contract call ${SC_ADDRESS} --recall-nonce --pem=${WALLET_OTHER} \
    --gas-limit=7000000 --value=0 --function="claim" \
    --arguments ${PAYLOAD} ${SIGNATURE} \
    --proxy=${PROXY} --chain=${CHAIN_ID}
}

invalidClaim() {
    local PAYLOAD="0x4d79207365636f6e642074657374206d657373616765" # Wrong message
    local SIGNATURE="0x319a17ae97d6c2395909407108c234466488fe63a517773c2ff0dd9ee77530ae5781f97ed30532d8cacb2cf279c847b987af62fb75217d90867ac9a3a5e77707"

    mxpy --verbose contract call ${SC_ADDRESS} --recall-nonce --pem=${WALLET} \
    --gas-limit=10000000 --value=0 --function="claim" \
    --arguments ${PAYLOAD} ${SIGNATURE} \
    --send --proxy=${PROXY} --chain=${CHAIN_ID}
}

fund() {
    local VALUE="0x152d02c7e14af6800000" # 100k
    local FUNC="0x66756e64" # fund
    mxpy --verbose contract call ${SC_ADDRESS} --recall-nonce --pem=${WALLET} \
    --gas-limit=10000000 --value=0 --function="ESDTTransfer" \
    --arguments $TIX_HEX $VALUE $FUNC \
    --send --proxy=${PROXY} --chain=${CHAIN_ID}
}

send() {
    local DEST="a3a963b8239d8a3c3a93a81f32ac98766fd17f92f739c9133a56da913c4d25bc"

    mxpy --verbose contract call ${DEST} --recall-nonce --pem=${WALLET} \
        --gas-limit=300000 --value=0 --function="ESDTTransfer" \
        --arguments 0x5449582d373561393231 0x3635c9adc5dea00000 \
        --send --proxy=${PROXY} --chain=${CHAIN_ID}
}

lastClaim() {
    local ADDR="0xffda9519703c2942d12b844ca7e95926c0978828adaa0b3a8d4bf865221f28e0" # test-wallet.pem
    # local ADDR="0x38760fff520f126cf5bd25a969c73a3f860cf45bcba6af1ce0335d7c4461d654" # test-wallet-2.pem

    mxpy --verbose contract query ${SC_ADDRESS}  \
    --function="getLastClaim" \
    --arguments $ADDR \
    --proxy=${PROXY}
}

lastError() {
    mxpy --verbose contract query ${SC_ADDRESS}  \
    --function="getLastError" \
    --proxy=${PROXY}
}
