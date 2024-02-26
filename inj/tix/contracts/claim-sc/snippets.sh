#!/bin/bash

INJ_ADDRESS=inj1rw3qvamxgmvyexuz2uhyfa4hukvtvteznxjvke
CHAIN_ID="injective-888"
CODE_ID="3680"
SC_ADDRESS="inj1q5fle0aaa0lwq8ph70c6m745xvuv978mnpayz9"
CW721_ADDRESS="inj10r9gvgr8rvd0da7zawca08njefmygt042pwsse"
SIGNER_ADDRESS=$INJ_ADDRESS
# CHAIN_ID="injective-1"
# CODE_ID=""
# SC_ADDRESS=""

getSCAddress() {
    injectived query wasm list-contract-by-code $CODE_ID \
    --chain-id=$CHAIN_ID \
    --node=https://k8s.testnet.tm.injective.network:443 \
    --output json | jq -r '.contracts[-1]'
}

getLastClaim() {
    local QUERY='{"last_claim":{"address":"inj1ulq0hawxak0rfmy0nqk2qdh9pqn08m4jqfqr9v"}}'

    injectived query wasm contract-state smart $SC_ADDRESS "$QUERY" \
    --node=https://k8s.testnet.tm.injective.network:443 \
    --output json
}

debug() {
    local QUERY='{"debug":{}}'

    injectived query wasm contract-state smart $SC_ADDRESS "$QUERY" \
    --node=https://k8s.testnet.tm.injective.network:443 \
    --output json
}

updateConfig() {
    local MSG='{"update_config":{"owner":"inj1rw3qvamxgmvyexuz2uhyfa4hukvtvteznxjvke","cw721_addr":"inj10r9gvgr8rvd0da7zawca08njefmygt042pwsse","signer":"/9qVGXA8KULRK4RMp+lZJsCXiCitqgs6jUv4ZSIfKOA=","tix_denom":"factory/inj1rw3qvamxgmvyexuz2uhyfa4hukvtvteznxjvke/tix","stake_sc":"inj13jvhty2curhx7f40fm0s4m97um7kedu8n9y8j3"}}'

    yes $KEYPASSWD | injectived tx wasm execute \
    $SC_ADDRESS "$MSG" \
    --from=$INJ_ADDRESS \
    --chain-id=$CHAIN_ID \
    --yes --gas-prices=500000000inj --gas=20000000 \
    --node=https://k8s.testnet.tm.injective.network:443
}

earnPunchcard() {
    local MSG='{"earn_punchcard":{"value":"1000000000","value_to_return":"1000000","signature":"DCTzaADvHp+XNsp8Jxbl4k2yrls1JZj9sZsSqzaE9we8mBQV3hfHqx9by0uLMlWsRxSPpu1nF9AnIDH06BQKCg=="}}'

    yes $KEYPASSWD | injectived tx wasm execute \
    $SC_ADDRESS "$MSG" \
    --from=$INJ_ADDRESS \
    --chain-id=$CHAIN_ID \
    --yes --gas-prices=500000000inj --gas=20000000 \
    --node=https://k8s.testnet.tm.injective.network:443
}

claim() {
    local MSG='{"claim":{"value":"1000000","signature":"Cgl9IgrNqYdHQBC3Md5c9Rpx0MxEmxRevzHMiwJffYwcGrasDtJUDKF/ZhQ3rpRHrCT9ExtEdpJtbAWai1tUAA=="}}'

    yes $KEYPASSWD | injectived tx wasm execute \
    $SC_ADDRESS "$MSG" \
    --from=$INJ_ADDRESS \
    --chain-id=$CHAIN_ID \
    --yes --gas-prices=500000000inj --gas=20000000 \
    --node=https://k8s.testnet.tm.injective.network:443
}
