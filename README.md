# Safe Exchange
Contract for exchanging the `DEFAULT_ADMIN_ROLE` of a contract for some amount of Ether.


The happy case process is:

* Buyer and seller agree off-line about terms.
* Buyer deploys `SafeExchange`, indicating contract to be purchased, and the new admin to be give `DEFAULT_ADMIN_ROLE`, and is sent with the amount to be offered.
* Seller adds the safeExchange contract as a `DEFAULT_ADMIN_ROLE`.
* Seller renounces their `DEFAULT_ADMIN_ROLE` role.
* Seller calls `exchange` to sell the contract.

Optional additional steps to pay a bonus payment (which can be repeated multiple times):

* Buyer adds more funds to the contract using `increaseOffer`.
* Seller calls `payBonusPayment` to receive those additional funds.
