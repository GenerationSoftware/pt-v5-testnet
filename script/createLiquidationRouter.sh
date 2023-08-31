forge create \
    --rpc-url $OPTIMISM_GOERLI_RPC_URL \
    --constructor-args 0x9A57732A346ad4d1aFC16dC0A84FE27a7B9426ce \
    --private-key $PRIVATE_KEY \
    --etherscan-api-key $OPTIMISM_ETHERSCAN_API_KEY \
    --verify \
    lib/pt-v5-cgda-liquidator/src/LiquidationRouter.sol:LiquidationRouter
