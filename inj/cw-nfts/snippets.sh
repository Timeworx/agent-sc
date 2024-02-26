#!/bin/bash

INJ_ADDRESS=inj1rw3qvamxgmvyexuz2uhyfa4hukvtvteznxjvke

CHAIN_ID="injective-888"
MINTER_CODE_ID="3885"
CODE_ID="3886"
MINTER_SC_ADDRESS="inj19rhfqlgugscsvs5p8pgyqg7gg5qqc8kx4v7682"
SC_ADDRESS="inj10r9gvgr8rvd0da7zawca08njefmygt042pwsse"
# CHAIN_ID="injective-1"
# CODE_ID=""
# SC_ADDRESS=""

deployMinter() {
    yes $KEYPASSWD | injectived tx wasm store artifacts/cw721_metadata_onchain.wasm \
    --from=$INJ_ADDRESS \
    --chain-id=$CHAIN_ID \
    --yes --fees=10000000000000000inj --gas=20000000 \
    --node=https://k8s.testnet.tm.injective.network:443
}

deployFixedPrice() {
    yes $KEYPASSWD | injectived tx wasm store artifacts/cw721_fixed_price.wasm \
    --from=$INJ_ADDRESS \
    --chain-id=$CHAIN_ID \
    --yes --fees=10000000000000000inj --gas=20000000 \
    --node=https://k8s.testnet.tm.injective.network:443
}

instantiate() {
    local INIT='{"owner":"inj1rw3qvamxgmvyexuz2uhyfa4hukvtvteznxjvke","max_tokens":1000,"unit_price":"1000000000","name":"Punchcard","symbol":"PUNCH","token_code_id":3885,"tix_denom":"factory/inj1rw3qvamxgmvyexuz2uhyfa4hukvtvteznxjvke/tix","token_uri":"https://timeworx.io/punchcard.json","extension":{"image":"https://ipfs.io/ipfs/bafybeic7kwpnwupdb7xemee35ulkxfww6moqoa4ez6fm6542sepen2ewiu/{{TOKEN_ID}}.png","description":"Timeworx.io Punchcard","name":"Employee #{{TOKEN_ID}}"}}'

    yes $KEYPASSWD | injectived tx wasm instantiate \
    $CODE_ID "$INIT" --label="Timeworx.io Punchcard" \
    --from=$INJ_ADDRESS \
    --chain-id=$CHAIN_ID \
    --yes --gas-prices=500000000inj --gas=20000000 --admin=$INJ_ADDRESS \
    --node=https://k8s.testnet.tm.injective.network:443
}

migrate() {
    local MIGRATE='{}'

    yes $KEYPASSWD | injectived tx wasm migrate \
    $SC_ADDRESS $CODE_ID "$MIGRATE" \
    --from=$INJ_ADDRESS \
    --chain-id=$CHAIN_ID \
    --yes --gas-prices=500000000inj --gas=20000000 \
    --node=https://k8s.testnet.tm.injective.network:443
}

getMinterSCAddress() {
    injectived query wasm list-contract-by-code $MINTER_CODE_ID \
    --chain-id=$CHAIN_ID \
    --node=https://k8s.testnet.tm.injective.network:443 \
    --output json | jq -r '.contracts[-1]'
}

getSCAddress() {
    injectived query wasm list-contract-by-code $CODE_ID \
    --chain-id=$CHAIN_ID \
    --node=https://k8s.testnet.tm.injective.network:443 \
    --output json | jq -r '.contracts[-1]'
}

buy() {
    local SEND='{"for_sender":{}}'

    yes $KEYPASSWD | injectived tx wasm execute \
    --amount 1000000000factory/inj1rw3qvamxgmvyexuz2uhyfa4hukvtvteznxjvke/tix \
    $SC_ADDRESS "$SEND" \
    --from=$INJ_ADDRESS \
    --chain-id=$CHAIN_ID \
    --yes --gas-prices=500000000inj --gas=20000000 \
    --node=https://k8s.testnet.tm.injective.network:443 --yes
}

earn() {
    local SEND='{"for_address":{"address":"inj1rw3qvamxgmvyexuz2uhyfa4hukvtvteznxjvke"}}'

    yes $KEYPASSWD | injectived tx wasm execute \
    --amount 1000000000factory/inj1rw3qvamxgmvyexuz2uhyfa4hukvtvteznxjvke/tix \
    $SC_ADDRESS "$SEND" \
    --from=$INJ_ADDRESS \
    --chain-id=$CHAIN_ID \
    --yes --gas-prices=500000000inj --gas=20000000 \
    --node=https://k8s.testnet.tm.injective.network:443 --yes
}

getNftsForAddress() {
    local TOKENS='{"tokens":{"owner":"inj1ulq0hawxak0rfmy0nqk2qdh9pqn08m4jqfqr9v"}}'

    injectived query wasm contract-state smart $MINTER_SC_ADDRESS "$TOKENS" \
    --node=https://k8s.testnet.tm.injective.network:443 \
    --output json
}

getNftInfo() {
    local NFT_INFO='{"nft_info":{"token_id":"1"}}'

    injectived query wasm contract-state smart $MINTER_SC_ADDRESS "$NFT_INFO" \
    --node=https://k8s.testnet.tm.injective.network:443 \
    --output json
}
