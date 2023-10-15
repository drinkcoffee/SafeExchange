// SPDX-License-Identifier: BSD
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract SafeExchange {
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    address public owner;
    address public newAdmin;
    AccessControl public contractForSale;

    event Exchanged(address seller);

    error NotCorrectAmount();
    error NotAnEOA(address account);
    error TransferFailed();
    error TooManyAdmins(uint256 _numAdmins);

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
        if (msg.sender != tx.origin) {
            revert NotAnEOA(msg.sender);
        }

        // Check that the number of admins is 1. The issue that we are guarding against is there being 
        // two admins, of which only one is revoked.
        uint256 numAdmins = contractForSale.getRoleMemberCount(DEFAULT_ADMIN_ROLE);
        if (numAdmins != 1) {
            revert TooManyAdmins(numAdmins);
        }

        // Grant role DEFAULT_ADMIN_ROLE to the newAdmin.
        contractForSale.grantRole(DEFAULT_ADMIN_ROLE, newAdmin);

        // Renounce DEFAULT_ADMIN_ROLE role for msg.sender
        contractForSale.renounceRole(DEFAULT_ADMIN_ROLE, msg.sender);

        // Send price to msg.sender
        (bool success, ) = payable(msg.sender).call{value: price()}("");
        if (!success) {
            revert TransferFailed();
        }

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