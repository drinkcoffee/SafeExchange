# Test plan for SafeExchange contract

The following are unit tests for SafeExchange.sol. 

| Test name                       |Description                                        | Happy Case |
|---------------------------------| --------------------------------------------------|------------|
| testInit                        | Check constructor sets values appropriately.      | Yes        |
| testInitBadOffer                | Offer below msg.value                             | No         |
| testInitNoBonus                 | No bonus, only offer.                             | Yes        |
| testInitNoOffer                 | No offer, only bonus.                             | Yes        |
| testIncreaseOffer               | Check ability to add value to the contract.       | Yes        |
| testDecreaseOffer               | Check ability to remove value from the contract.  | Yes        |
| testDecreaseOfferBadAuth        | Bad auth for decreaseOffer.                       | No         |
| testDecreaseOfferTooMuch        | Attempt to decrease to a negative balance.        | No         |
| testExchange                    | Execute exchange.                                 | Yes        |
| testExchangeBadAuth             | Bad auth for exchange.                            | No         |
| testExchangeNotEOA              | Call exchange via a contract fails.               | No         |
| testExchangeFrontRun            | Amount being less that expected fails.            | No         |
| testExchangeTwoAdmins           | Exchange with a second admin will fail.           | No         |
| testRegainOwnership             | Allow seller to transfer admin back if the don't call exchange. | Yes      |
| testRegainOwnershipBadAuth      | Bad auth for regainOwnership                      | No         |
| testIncreaseBonus               | Check ability to add value to the contract.       | Yes        |
| testDecreaseBonus               | Check ability to remove value from the contract.  | Yes        |
| testDecreaseBonusBadAuth        | Bad auth for decreaseBonus.                       | No         |
| testDecreaseBonusTooMuch        | Attempt to decrease to a negative balance.        | No         |
| testBonusPayment                | Execute exchange and then bonus payment.          | Yes        |
| testBonusPaymentBadAuth         | Bad auth for payBonusPayment.                     | No         |


