WALLET="wallets/test-wallet.pem"
ADDRESS=$(erdpy data load --key=address-devnet)
DEPLOY_TRANSACTION=$(erdpy data load --key=deployTransaction-devnet)
PROXY="https://devnet-gateway.multiversx.com"
CHAIN_ID=D
TREASURY="0xffda9519703c2942d12b844ca7e95926c0978828adaa0b3a8d4bf865221f28e0"
SC_ADDRESS="erd1qqqqqqqqqqqqqpgq6hazfnz2mkxqple9xsvxl7nwpqtf8zym9rsqfsjp36"
WASM_PATH="output/nft-minter.wasm"
TIX="TIX-3308a8"
TIX_HEX=`atohex TIX-3308a8`
PUNCH="PUNCH-2642f7"

deploy() {
    mxpy --verbose contract deploy --bytecode=${WASM_PATH} --recall-nonce --pem=${WALLET} \
    --gas-limit=120000000 \
    --arguments $TREASURY $TREASURY 0x01 0x00 \
    --send --outfile="deploy-devnet.interaction.json" --proxy=${PROXY} --chain=${CHAIN_ID} \
    --wait-result || return

    TRANSACTION=$(erdpy data parse --file="deploy-devnet.interaction.json" --expression="data['emittedTransactionHash']")
    ADDRESS=$(erdpy data parse --file="deploy-devnet.interaction.json" --expression="data['contractAddress']")

    erdpy data store --key=address-devnet --value=${ADDRESS}
    erdpy data store --key=deployTransaction-devnet --value=${TRANSACTION}

    echo ""
    echo "Smart contract address: ${ADDRESS}"
}

upgrade() {
    mxpy --verbose contract upgrade ${SC_ADDRESS} --bytecode=${WASM_PATH} --recall-nonce --pem=${WALLET} --gas-limit=200000000 \
    --send --proxy=${PROXY} --chain=${CHAIN_ID}
}

issue() {
    local COLLECTION_HASH="0x6261667962656963376b77706e77757064623778656d65653335756c6b78667777366d6f716f6134657a36666d36353432736570656e3265776975"
    local BRAND_ID="0x50554e434833" # PUNCH4
    local MEDIA_TYPE="0x706e67" # png
    local ROYALTIES="0x3e8" # 10
    local MINT_START="0x00" # 0
    local MINT_END="0x64f1ca81" # 1693567617
    local PRICE_TOKEN_ID=$TIX_HEX
    local NFT_NAME="0x50756e63686361726473" # Punchcards
    local NFT_TICKER="0x50554e4348" # PUNCH
    local WHITELIST_END="0x00" # 0
    # local TAGS="0x00" # none
    local TIER_NAME="0x414c504841" # ALPHA
    local TIER_SIZE="0x3e9" # 1001
    local TIER_PRICE="0x3635c9adc5dea00000" # 1000

    local VALUE="50000000000000000" # 0.05
    local GAS_LIMIT="100000000" # 100mil

    mxpy --verbose contract call ${SC_ADDRESS} --recall-nonce --pem=${WALLET} \
    --gas-limit=$GAS_LIMIT --value=$VALUE --function="issueTokenForBrand" \
    --arguments $COLLECTION_HASH $BRAND_ID $MEDIA_TYPE $ROYALTIES $MINT_START $MINT_END $PRICE_TOKEN_ID $NFT_NAME $NFT_TICKER \
    $WHITELIST_END $TIER_NAME $TIER_SIZE $TIER_PRICE \
    --send --proxy=${PROXY} --chain=${CHAIN_ID}
}

buy() {
    local TOKEN_ID=$TIX_HEX
    local TOKEN_QTY="0x3635c9adc5dea00000" # 1000

    local FUNC="0x62757952616e646f6d4e6674" # buyRandomNft
    local BRAND_ID="0x50554e434831" # PUNCH1
    local TIER_NAME="0x504f43" # POC

    local GAS_LIMIT="10000000" # 10mil

    erdpy --verbose contract call ${ADDRESS} --recall-nonce --pem=${WALLET} \
    --gas-limit=$GAS_LIMIT --value=0 --function="ESDTTransfer" \
    --arguments $TOKEN_ID $TOKEN_QTY $FUNC $BRAND_ID $TIER_NAME \
    --send --proxy=${PROXY} --chain=${CHAIN_ID} \
    --wait-result
}

setUniqueFilename() {
    local BRAND_ID="0x74657374" # test
    local FILENAME="0x756e6971756566696c656e616d65"

    local GAS_LIMIT="5000000" # 5mil

    erdpy --verbose contract call ${ADDRESS} --recall-nonce --pem=${WALLET} \
    --gas-limit=$GAS_LIMIT --value=0 --function="setUniqueFilename" \
    --arguments $BRAND_ID $FILENAME \
    --send --proxy=${PROXY} --chain=${CHAIN_ID} \
    --wait-result
}

getRoyaltiesAddress() {
    erdpy --verbose contract query ${ADDRESS} --proxy=${PROXY} \
     --function="getRoyaltiesClaimAddress"
}

getTags() {
    erdpy --verbose contract query ${ADDRESS} --proxy=${PROXY} \
     --function="getTags"
}

getAllBrandsInfo() {
    erdpy --verbose contract query ${ADDRESS} --proxy=${PROXY} \
     --function="getAllBrandsInfo"
}
