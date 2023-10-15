# Test plan for SafeExchange contract

The following are unit tests for SafeExchange.sol. 

| Test name                       |Description                                        | Happy Case |
|---------------------------------| --------------------------------------------------|------------|
| testInit                        | Check constructor sets values appropriately.      | Yes        |
| testIncreaseOffer               | Check ability to add value to the contract.       | Yes        |
| testDecreaseOffer               | Check ability to remove value from the contract.  | Yes        |
| testGoodBye                     | Check ability to kill contract.                   | Yes        |
| testExchange                    | Execute exchange.                                 | Yes        |
| testBonusPayment                | Execute exchange and then bonus payment.          | Yes        |
| testNotEOA                      | Call exchange via a contract fails.               | No         |
| testFrontRun                    | Amount being less that expected fails.            | No         |
| testTwoAdmins                   | Exchange with a second admin will fail.           | No         |
| testNoAdmin                     | Fail attempts to use a non-admin with exchange.   | No         |
|


