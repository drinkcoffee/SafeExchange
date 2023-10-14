// SPDX-License-Identifier: BSD
pragma solidity ^0.8.19;

contract Bounty {
    uint256 public constant BOUNTY = 10 ether;
    uint256 public constant BOUNTY_PERIOD = 1 days;

    address public owner;
    address public newAdmin;
    uint256 public start;

    error NotCorrectBounty();

    constructor(address _newAdmin) payable {
        if (msg.value != BOUNTY) {
            revert NotCorrectBounty();
        }
        owner = msg.sender;
        newAdmin = _newAdmin;
        start = block.timestamp;
    }

    // NOTE: transaction must be sent by the account with DEFAULT ADMIN on the business logic contract
    function claim() external {
        // TODO call to business logic contract to 
        // TODO 1. call getRoleMemberCount and check the number of DEFAULT_ADMIN_ROLE is now 1 
        // TODO 2. grantRole DEFAULT_ADMIN_ROLE for newAdmin
        // TODO 3. renounceRole DEFAULT_ADMIN_ROLE for msg.sender
        // Send the BOUNTY to msg.sender
    }


    function refund() external {
        // TODO check is owner
        // TODO check if after BOUNTY PERIOD
        // Transfer $ to owner
        // TOOD add static analysis override
        selfdestruct(payable(owner));

    }
}