#!/bin/bash

INJ_ADDRESS=inj1rw3qvamxgmvyexuz2uhyfa4hukvtvteznxjvke
# INJ_ADDRESS=inj1mf3x77h5ynafa57ga92rkp3hhwru5l63awf59v
CHAIN_ID="injective-888"
CLAIM_SC_ADDRESS="inj1q5fle0aaa0lwq8ph70c6m745xvuv978mnpayz9"
STAKE_SC_ADDRESS="inj13jvhty2curhx7f40fm0s4m97um7kedu8n9y8j3"
NODE="https://k8s.testnet.tm.injective.network:443"
# NODE="http://tm.injective.network:443"

setupTix() {
    yes $KEYPASSWD | injectived tx tokenfactory create-denom tix \
    --from=$INJ_ADDRESS --chain-id=$CHAIN_ID --node=$NODE \
    --gas-prices=500000000inj --gas 1000000 --yes
}

setTixMetadata() {
    yes $KEYPASSWD | injectived tx tokenfactory set-denom-metadata \
    "Timeworx.io utility token" 'factory/inj1rw3qvamxgmvyexuz2uhyfa4hukvtvteznxjvke/tix' TIX Timeworx.io TIX https://bafkreieshvbryakbvkcjdz2doarrpycsaaepcgtwtjolviuufvcfimcpya.ipfs.nftstorage.link '' '[{"denom":"factory/inj1rw3qvamxgmvyexuz2uhyfa4hukvtvteznxjvke/tix","exponent":0,"aliases":["microTIX"]},{"denom":"TIX","exponent":6,"aliases":["TIX"]}]' \
    --from=$INJ_ADDRESS --chain-id=$CHAIN_ID --node=$NODE \
    --gas-prices=500000000inj --gas 1000000 --yes
}

mintTix() {
    yes $KEYPASSWD | injectived tx tokenfactory mint 1000000000000factory/$INJ_ADDRESS/tix \
    --from=$INJ_ADDRESS --chain-id=$CHAIN_ID --node=$NODE \
    --gas-prices=500000000inj --gas 200000 --yes
}

topupClaimSC() {
    yes $KEYPASSWD | injectived tx bank send $INJ_ADDRESS $CLAIM_SC_ADDRESS 1000000000000factory/$INJ_ADDRESS/tix \
    --from=$INJ_ADDRESS --chain-id=$CHAIN_ID --node=$NODE \
    --gas-prices=500000000inj --gas 100000 --yes
}

topupStakeSC() {
    yes $KEYPASSWD | injectived tx bank send $INJ_ADDRESS $STAKE_SC_ADDRESS 1000000000000factory/$INJ_ADDRESS/tix \
    --from=$INJ_ADDRESS --chain-id=$CHAIN_ID --node=$NODE \
    --gas-prices=500000000inj --gas 100000 --yes
}

sendTix() {
    yes $KEYPASSWD | injectived tx bank send $INJ_ADDRESS inj1ulq0hawxak0rfmy0nqk2qdh9pqn08m4jqfqr9v 10000000000factory/$INJ_ADDRESS/tix \
    --from=$INJ_ADDRESS --chain-id=$CHAIN_ID --node=$NODE \
    --gas-prices=500000000inj --gas 100000 --yes
}

sendInj() {
    yes $KEYPASSWD | injectived tx bank send $INJ_ADDRESS inj1ulq0hawxak0rfmy0nqk2qdh9pqn08m4jqfqr9v 1000000000000000000inj \
    --from=$INJ_ADDRESS --chain-id=$CHAIN_ID --node=$NODE \
    --gas-prices=500000000inj --gas 100000 --yes
}

query() {
    yes $KEYPASSWD | injectived query bank balances $INJ_ADDRESS --node=$NODE
}