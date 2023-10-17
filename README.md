# Safe Exchange
Contract for exchanging the `DEFAULT_ADMIN_ROLE` of a contract for some amount of Ether.

## Usage

The happy case process is:

* Buyer and seller agree off-line about terms.
* Buyer deploys `SafeExchange`, indicating contract to be purchased, and the new admin to be give `DEFAULT_ADMIN_ROLE`, and an offer amount. The amount sent with the transaction is this offer amount plus an optional bonus amount.
* Seller adds the safeExchange contract as a `DEFAULT_ADMIN_ROLE` for the contract being sold.
* Seller renounces their `DEFAULT_ADMIN_ROLE` role for the contract being sold.
* Seller calls `exchange` to sell the contract.

Optional additional steps to pay a bonus payment (which can be repeated multiple times):

* Buyer calls `payBonusPayment` to send the bonus payment to the address that called `exchange` in the steps above.

If the `exchange` function fails, or the seller changes their mind after switching ownership of the contract to be sold to the SafeExchange contract, they can regain control of the contract being sold by calling:

* `regainOwnership`


## Testing

The test plan for the code is [here](./test/README.md).

To run the tests:

```
foundry test
```
