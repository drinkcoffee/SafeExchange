// SPDX-License-Identifier: BSD
pragma solidity ^0.8.19;

contract SafeExchange {
    uint256 public constant PRICE = 10 ether;
    uint256 public constant PERIOD = 1 days;

    address public owner;
    address public newAdmin;
    uint256 public start;

    event Exchanged(address seller);

    error NotCorrectAmount();
    error NotAnEOA(address account);

    constructor(address _newAdmin) payable {
        if (msg.value != PRICE) {
            revert NotCorrectAmount();
        }
        owner = msg.sender;
        newAdmin = _newAdmin;
        start = block.timestamp;
    }

    // Seller calls this, to exchange control of admin rights for the PRICE
    // NOTE: transaction must be sent by the account with DEFAULT ADMIN on the business logic contract
    function exchange() external {
        // Prevent contract accounts calling this.
        if (msg.sender != tx.origin) {
            revert NotAnEOA(msg.sender);
        }

        // TODO call to business logic contract to 
        // TODO 1. call getRoleMemberCount and check the number of DEFAULT_ADMIN_ROLE is now 1 
        // TODO 2. grantRole DEFAULT_ADMIN_ROLE for newAdmin
        // TODO 3. renounceRole DEFAULT_ADMIN_ROLE for msg.sender
        // Send the BOUNTY to msg.sender

        emit Exchanged(msg.sender);
    }


    function refund() external {
        // TODO check is owner
        // TODO check if after BOUNTY PERIOD
        // Transfer $ to owner
        // TOOD add static analysis override
        selfdestruct(payable(owner));

    }
}