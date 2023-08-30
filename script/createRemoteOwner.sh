forge create \
    --rpc-url $OPTIMISM_GOERLI_RPC_URL \
    --constructor-args 5 0xc5165406dB791549f0D2423D1483c1EA10A3A206 0x7C210BE12BcEf8090610914189A0De43e2192Ea0 \
    --private-key $PRIVATE_KEY \
    --etherscan-api-key $OPTIMISM_ETHERSCAN_API_KEY \
    --verify \
    lib/pt-v5-draw-auction/lib/remote-owner/src/RemoteOwner.sol:RemoteOwner