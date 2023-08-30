forge create \
    --rpc-url $OPTIMISM_GOERLI_RPC_URL \
    --constructor-args 0xC64bb8Fe4f023B650940D05E79c35454e12A111F 0x34963D0f2B10a4C0a437A0fae57E43E5D296D108 900 300 10000000000000000000000 \
    --private-key $PRIVATE_KEY \
    --etherscan-api-key $OPTIMISM_ETHERSCAN_API_KEY \
    --verify \
    lib/pt-v5-draw-auction/src/RngRelayAuction.sol:RngRelayAuction