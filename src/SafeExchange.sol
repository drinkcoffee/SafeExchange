// SPDX-License-Identifier: BSD
// Use 0.7.6 to be compatible with Open Zeppelin 3.4.0
pragma solidity ^0.7.6;

import "./oz340/AccessControl.sol";

contract SafeExchange {
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    address public owner;
    address public newAdmin;
    AccessControl public contractForSale;

    event Exchanged(address seller);


    constructor(address _newAdmin, address _contractForSale) payable {
        owner = msg.sender;
        newAdmin = _newAdmin;
        contractForSale = AccessControl(_contractForSale);
    }

    // Seller calls this, to exchange control of admin rights for the PRICE
    // NOTE: transaction must be sent by the account with DEFAULT ADMIN on the business logic contract
    function exchange() external {
        // Prevent contract accounts calling this. This prevents MultiCall contracts possibly 
        // doing something "extra" in the same transaction.
        require(msg.sender == tx.origin, "Not an EOA");

        // Check that the number of admins is 1. The issue that we are guarding against is there being 
        // two admins, of which only one is revoked.
        uint256 numAdmins = contractForSale.getRoleMemberCount(DEFAULT_ADMIN_ROLE);
        require(numAdmins == 1, "Too many admins");

        // Grant role DEFAULT_ADMIN_ROLE to the newAdmin.
        contractForSale.grantRole(DEFAULT_ADMIN_ROLE, newAdmin);

        // Renounce DEFAULT_ADMIN_ROLE role for msg.sender
        contractForSale.renounceRole(DEFAULT_ADMIN_ROLE, msg.sender);

        // Send price to msg.sender
        (bool success, ) = payable(msg.sender).call{value: price()}("");
        require(success, "Transfer failed");

        emit Exchanged(msg.sender);
    }


    function refund() external {
        // TODO check is owner
        // TODO check if after BOUNTY PERIOD
        // Transfer $ to owner
        // TOOD add static analysis override
        selfdestruct(payable(owner));

    }

    /**
     * Price is the amount being offered for the admin account
     */
    function price() public view returns (uint256) {
        return address(this).balance;
    }
}