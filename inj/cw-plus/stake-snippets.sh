#!/bin/bash

INJ_ADDRESS=inj1rw3qvamxgmvyexuz2uhyfa4hukvtvteznxjvke
CHAIN_ID="injective-888"
CODE_ID="4574"
SC_ADDRESS="inj13jvhty2curhx7f40fm0s4m97um7kedu8n9y8j3"
NODE="https://k8s.testnet.tm.injective.network:443"
# CHAIN_ID="injective-1"
# CODE_ID=""
# SC_ADDRESS=""

deploy() {
    yes $KEYPASSWD | injectived tx wasm store artifacts/cw20_stake.wasm \
    --from=$INJ_ADDRESS \
    --chain-id=$CHAIN_ID \
    --yes --fees=10000000000000000inj --gas=20000000 \
    --node=$NODE
}

instantiate() {
    local INIT='{"name":"Timeworx Stake","symbol":"STIX","decimals":6,"initial_balances":[{"address":"inj1rw3qvamxgmvyexuz2uhyfa4hukvtvteznxjvke","amount":"0"}],"mint":{"minter":"inj1rw3qvamxgmvyexuz2uhyfa4hukvtvteznxjvke"},"marketing":{},"config":{"apr":150,"tix_denom":"factory/inj1rw3qvamxgmvyexuz2uhyfa4hukvtvteznxjvke/tix","unstake_duration":864000}}'

    yes $KEYPASSWD | injectived tx wasm instantiate \
    $CODE_ID "$INIT" --label="Timeworx.io Token" \
    --from=$INJ_ADDRESS \
    --chain-id=$CHAIN_ID \
    --yes --gas-prices=500000000inj --gas=20000000 --admin=$INJ_ADDRESS \
    --node=$NODE
}

updateConfig() {
    local MSG='{"update_config":{"config":{"apr":150,"tix_denom":"factory/inj1rw3qvamxgmvyexuz2uhyfa4hukvtvteznxjvke/tix","unstake_duration":864000}}}'
    # local MSG='{"update_config":{"config":{"apr":160,"tix_denom":"factory/inj1rw3qvamxgmvyexuz2uhyfa4hukvtvteznxjvke/tix","unstake_duration":60}}}'

    yes $KEYPASSWD | injectived tx wasm execute \
    $SC_ADDRESS "$MSG" \
    --from=$INJ_ADDRESS \
    --chain-id=$CHAIN_ID \
    --yes --gas-prices=500000000inj --gas=20000000 \
    --node=$NODE
}

migrate() {
    local MIGRATE='{}'

    yes $KEYPASSWD | injectived tx wasm migrate \
    $SC_ADDRESS $CODE_ID "$MIGRATE" \
    --from=$INJ_ADDRESS \
    --chain-id=$CHAIN_ID \
    --yes --gas-prices=500000000inj --gas=20000000 \
    --node=$NODE
}

setMarketing() {
    local MSG='{"update_marketing":{"project":"https://timeworx.io","description":"Staking token for the Timeworx.io data processing platform","marketing":"inj1rw3qvamxgmvyexuz2uhyfa4hukvtvteznxjvke"}}'

    yes $KEYPASSWD | injectived tx wasm execute \
    $SC_ADDRESS "$MSG" \
    --from=$INJ_ADDRESS \
    --chain-id=$CHAIN_ID \
    --yes --gas-prices=500000000inj --gas=20000000 \
    --node=$NODE
}

getSCAddress() {
    injectived query wasm list-contract-by-code $CODE_ID \
    --chain-id=$CHAIN_ID \
    --node=$NODE \
    --output json | jq -r '.contracts[-1]'
}

getState() {
    injectived query wasm contract-state all $SC_ADDRESS \
    --output json \
    --node=$NODE
}

getSCTix() {
    yes $KEYPASSWD | injectived query bank balances $SC_ADDRESS --node=$NODE
}

mint() {
    local MINT='{"mint":{"recipient":"inj13jvhty2curhx7f40fm0s4m97um7kedu8n9y8j3","amount":"10000000000"}}'

    yes $KEYPASSWD | injectived tx wasm execute \
    $SC_ADDRESS "$MINT" \
    --from=$INJ_ADDRESS \
    --chain-id=$CHAIN_ID \
    --yes --gas-prices=500000000inj --gas=20000000 \
    --node=$NODE
}

stake() {
    local MSG='{"stake":{}}'

    yes $KEYPASSWD | injectived tx wasm execute \
    $SC_ADDRESS "$MSG" \
    --amount 1000000factory/inj1rw3qvamxgmvyexuz2uhyfa4hukvtvteznxjvke/tix \
    --from=$INJ_ADDRESS \
    --chain-id=$CHAIN_ID \
    --yes --gas-prices=500000000inj --gas=20000000 \
    --node=$NODE
}

getStake() {
    local QUERY='{"get_stake":{"address":"inj1rw3qvamxgmvyexuz2uhyfa4hukvtvteznxjvke"}}'

    injectived query wasm contract-state smart $SC_ADDRESS "$QUERY" \
    --node=$NODE \
    --output json
}

getStix() {
    local QUERY='{"balance":{"address":"inj1rw3qvamxgmvyexuz2uhyfa4hukvtvteznxjvke"}}'

    injectived query wasm contract-state smart $SC_ADDRESS "$QUERY" \
    --node=$NODE \
    --output json
}

claim() {
    local MSG='{"claim":{}}'

    yes $KEYPASSWD | injectived tx wasm execute \
    $SC_ADDRESS "$MSG" \
    --from=$INJ_ADDRESS \
    --chain-id=$CHAIN_ID \
    --yes --gas-prices=500000000inj --gas=20000000 \
    --node=$NODE
}

restake() {
    local MSG='{"restake":{}}'

    yes $KEYPASSWD | injectived tx wasm execute \
    $SC_ADDRESS "$MSG" \
    --from=$INJ_ADDRESS \
    --chain-id=$CHAIN_ID \
    --yes --gas-prices=500000000inj --gas=20000000 \
    --node=$NODE
}

unstake() {
    local MSG='{"unstake":{"value":"1000000"}}'

    yes $KEYPASSWD | injectived tx wasm execute \
    $SC_ADDRESS "$MSG" \
    --from=$INJ_ADDRESS \
    --chain-id=$CHAIN_ID \
    --yes --gas-prices=500000000inj --gas=20000000 \
    --node=$NODE
}

getUnstake() {
    local QUERY='{"get_unstake":{"address":"inj1rw3qvamxgmvyexuz2uhyfa4hukvtvteznxjvke"}}'

    injectived query wasm contract-state smart $SC_ADDRESS "$QUERY" \
    --node=$NODE \
    --output json
}

withdraw() {
    local MSG='{"withdraw":{}}'

    yes $KEYPASSWD | injectived tx wasm execute \
    $SC_ADDRESS "$MSG" \
    --from=$INJ_ADDRESS \
    --chain-id=$CHAIN_ID \
    --yes --gas-prices=500000000inj --gas=20000000 \
    --node=$NODE
}

mint() {
    MINT='{"mint":{"recipient":"inj13jvhty2curhx7f40fm0s4m97um7kedu8n9y8j3","amount":"10000000000000000000000000"}}'

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
    local QUERY='{"balance":{"address":"inj13jvhty2curhx7f40fm0s4m97um7kedu8n9y8j3"}}'

    injectived query wasm contract-state smart $SC_ADDRESS "$QUERY" \
    --node=https://k8s.testnet.tm.injective.network:443 \
    --output json
}
