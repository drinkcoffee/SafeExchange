#!/bin/bash

echo PKEY: $PKEY
echo RPC URL: $RPC
echo APIKEY: $APIKEY

# Constructor args are: address of new admin, address of seller, address of contract being sold, offer amount
forge create --rpc-url $RPC \
    --constructor-args 0xE0069DDcAd199C781D54C0fc3269c94cE90364E2  0x52a64516247f10f05D5c9E3AC20De57090813852 0xd12c0bc68E9A2E04131d7f6D1ab826E856Fdf26a 2000000000000000000 \
    --value 3000000000000000000 \
    --private-key $PKEY \
    --etherscan-api-key $APIKEY \
    --verify \
    src/SafeExchange.sol:SafeExchange
