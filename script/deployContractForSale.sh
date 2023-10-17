#!/bin/bash

echo PKEY: $PKEY
echo RPC URL: $RPC
echo APIKEY: $APIKEY

forge create --rpc-url $RPC \
    --private-key $PKEY \
    --etherscan-api-key $APIKEY \
    --verify \
    test/SafeExchange.t.sol:ContractForSale
