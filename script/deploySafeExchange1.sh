#!/bin/bash

echo PKEY: $PKEY
echo RPC URL: $RPC
echo APIKEY: $APIKEY

# Constructor args are: address of new admin, address of seller, address of contract being sold, offer amount
forge create --rpc-url $RPC \
    --constructor-args 0xE0069DDcAd199C781D54C0fc3269c94cE90364E2  0x2A00CA38FB9B821edeA2478DA31d97B0f83347fe 0xAcB3C6a43D15B907e8433077B6d38Ae40936fe2c 0000000000000000000 \
    --value 3000000000000000000 \
    --private-key $PKEY \
    --etherscan-api-key $APIKEY \
    --verify \
    src/SafeExchange.sol:SafeExchange
