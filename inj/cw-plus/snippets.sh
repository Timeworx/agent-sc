#!/bin/bash

INJ_ADDRESS=inj1rw3qvamxgmvyexuz2uhyfa4hukvtvteznxjvke
CHAIN_ID="injective-888"
CODE_ID="2941"
SC_ADDRESS="inj1n9hcmejg2mfkkyyzze82nk9fdls5g32ykga47l"
# CHAIN_ID="injective-1"
# CODE_ID=""
# SC_ADDRESS=""

deployTix() {
    yes $KEYPASSWD | injectived tx wasm store artifacts/cw20_base.wasm \
    --from=$INJ_ADDRESS \
    --chain-id=$CHAIN_ID \
    --yes --fees=10000000000000000inj --gas=20000000 \
    --node=https://k8s.testnet.tm.injective.network:443
}

instantiateTix() {
    local INIT='{"name":"Timeworx","symbol":"TIX","decimals":18,"initial_balances":[{"address":"inj1rw3qvamxgmvyexuz2uhyfa4hukvtvteznxjvke","amount":"100000"}],"mint":{"minter":"inj1rw3qvamxgmvyexuz2uhyfa4hukvtvteznxjvke"},"marketing":{}}'

    yes $KEYPASSWD | injectived tx wasm instantiate \
    $CODE_ID "$INIT" --label="Timeworx.io Token" \
    --from=$INJ_ADDRESS \
    --chain-id=$CHAIN_ID \
    --yes --gas-prices=500000000inj --gas=20000000 --admin=$INJ_ADDRESS \
    --node=https://k8s.testnet.tm.injective.network:443
}

setMarketing() {
    local MSG='{"update_marketing":{"project":"https://timeworx.io","description":"Utility token for the Timeworx.io data processing platform","marketing":"inj1rw3qvamxgmvyexuz2uhyfa4hukvtvteznxjvke"}}'

    yes $KEYPASSWD | injectived tx wasm execute \
    $SC_ADDRESS "$MSG" \
    --from=$INJ_ADDRESS \
    --chain-id=$CHAIN_ID \
    --yes --gas-prices=500000000inj --gas=20000000 \
    --node=https://k8s.testnet.tm.injective.network:443
}

# uploadLogo() {

# }

getSCAddress() {
    injectived query wasm list-contract-by-code $CODE_ID \
    --chain-id=$CHAIN_ID \
    --node=https://k8s.testnet.tm.injective.network:443 \
    --output json | jq -r '.contracts[-1]'
}

getState() {
    injectived query wasm contract-state all $SC_ADDRESS \
    --output json \
    --node=https://k8s.testnet.tm.injective.network:443
}

mint() {
    MINT='{"mint":{"recipient":"inj1q5fle0aaa0lwq8ph70c6m745xvuv978mnpayz9","amount":"100000000000000000000000"}}'

    yes $KEYPASSWD | injectived tx wasm execute \
    $SC_ADDRESS "$MINT" \
    --from=$INJ_ADDRESS \
    --chain-id=$CHAIN_ID \
    --yes --gas-prices=500000000inj --gas=20000000 \
    --node=https://k8s.testnet.tm.injective.network:443
}

transfer() {
    TRANSFER='{"transfer":{"recipient":"inj1rw3qvamxgmvyexuz2uhyfa4hukvtvteznxjvke","amount":"1000000000000000000"}}'

    yes $KEYPASSWD | injectived tx wasm execute \
    $SC_ADDRESS "$TRANSFER" \
    --from=$INJ_ADDRESS \
    --chain-id=$CHAIN_ID \
    --yes --gas-prices=500000000inj --gas=20000000 \
    --node=https://k8s.testnet.tm.injective.network:443
}

balance() {
    local QUERY='{"balance":{"address":"inj1ulq0hawxak0rfmy0nqk2qdh9pqn08m4jqfqr9v"}}'

    injectived query wasm contract-state smart $SC_ADDRESS "$QUERY" \
    --node=https://k8s.testnet.tm.injective.network:443 \
    --output json
}
