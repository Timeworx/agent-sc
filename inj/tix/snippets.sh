    #!/bin/bash

INJ_ADDRESS=inj1rw3qvamxgmvyexuz2uhyfa4hukvtvteznxjvke
CHAIN_ID="injective-888"
SC_ADDRESS="inj1q5fle0aaa0lwq8ph70c6m745xvuv978mnpayz9"
CW20_ADDRESS="inj1n9hcmejg2mfkkyyzze82nk9fdls5g32ykga47l"
CW721_ADDRESS="inj1apw808z69m8apz50975a4ay98tlahhl49e9dpu"
SIGNER_ADDRESS=$INJ_ADDRESS
# CHAIN_ID="injective-1"
# CODE_ID=""
# SC_ADDRESS=""
# CW20_ADDRESS=""

deploy() {
    yes $KEYPASSWD | injectived tx wasm store artifacts/claim_sc.wasm \
    --from=$INJ_ADDRESS \
    --chain-id=$CHAIN_ID \
    --yes --fees=10000000000000000inj --gas=20000000 \
    --node=https://k8s.testnet.tm.injective.network:443
}

instantiate() {
    local SIGNER_BYTES="Aw4RAAwdGwYIGwwEGQYcAgocFwQJHRUXHBYMCwwLGQI="
    local INIT='{"whitelist":{"admins":["{{ADMIN_ADDRESS}}"],"mutable":true},"owner":"{{ADMIN_ADDRESS}}","cw20_addr":"{{CW20_ADDRESS}}","cw721_addr":"{{CW721_ADDRESS}}","signer":"{{SIGNER_ADDRESS}}"}'
    INIT="${INIT//"{{ADMIN_ADDRESS}}"/$INJ_ADDRESS}"
    INIT="${INIT//"{{CW20_ADDRESS}}"/$CW20_ADDRESS}"
    INIT="${INIT//"{{CW721_ADDRESS}}"/$CW721_ADDRESS}"
    INIT="${INIT//"{{SIGNER_ADDRESS}}"/$SIGNER_BYTES}"

    yes $KEYPASSWD | injectived tx wasm instantiate \
    3887 "$INIT" --label="Timeworx.io Claim SC" \
    --from=$INJ_ADDRESS \
    --chain-id=$CHAIN_ID \
    --yes --gas-prices=500000000inj --gas=20000000 --admin=$INJ_ADDRESS \
    --node=https://k8s.testnet.tm.injective.network:443
}

migrate() {
    local MIGRATE='{}'

    yes $KEYPASSWD | injectived tx wasm migrate \
    $SC_ADDRESS 4320 "$MIGRATE" \
    --from=$INJ_ADDRESS \
    --chain-id=$CHAIN_ID \
    --yes --gas-prices=500000000inj --gas=20000000 \
    --node=https://k8s.testnet.tm.injective.network:443
}
