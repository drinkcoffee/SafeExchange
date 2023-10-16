// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "forge-std/Test.sol";
import "../src/SafeExchange.sol";
import "../src/oz340/AccessControl.sol";


// Contract to be used to test the ability to sell a contract.
contract ContractForSale is AccessControl {
    constructor() {
        _setupRole(AccessControl.DEFAULT_ADMIN_ROLE, msg.sender);
    }
}



contract SafeExchangeTest is Test {
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    uint256 public constant HUGE_AMOUNT = 100 ether;
    uint256 public constant AMOUNT1 = 7 ether;
    uint256 public constant AMOUNT2 = 5 ether;
    SafeExchange public safeExchange;
    ContractForSale public contractForSale;

    address buyer = makeAddr("buyer");
    address seller = makeAddr("seller");
    address newAdmin = makeAddr("newAdmin");


    function setUp() public {
        vm.startPrank(seller);
        contractForSale = new ContractForSale();
        vm.stopPrank();

        vm.deal(buyer, HUGE_AMOUNT);
        vm.startPrank(buyer);
        safeExchange = new SafeExchange{value: AMOUNT1}(newAdmin, seller, address(contractForSale));
        vm.stopPrank();
    }

    function testInit() public {
        // Check the set-up of the contract for sale.
        assertEq(contractForSale.getRoleMemberCount(DEFAULT_ADMIN_ROLE), 1, "Incorrect number of admins");
        assertTrue(contractForSale.hasRole(DEFAULT_ADMIN_ROLE, seller), "Seller not admin");

        // Check the initial configuration of the same exchange contract.
       assertEq(address(safeExchange).balance, AMOUNT1, "Incorrect balance");
       assertEq(safeExchange.price(), AMOUNT1, "Incorrect price");
       assertEq(safeExchange.buyer(), buyer, "Buyer in contract not buyer");
       assertEq(safeExchange.seller(), seller, "Seller in contract not seller");
       assertEq(safeExchange.newAdmin(), newAdmin, "New admin not set correctly");
       assertEq(address(safeExchange.contractForSale()), address(contractForSale), "Contract for sale incorrect address");
       assertEq(safeExchange.exchangeCompletedBySeller(), address(0), "exchangeCompletedBySeller not set correctly");
    }

    function testIncreaseOffer() public {
        safeExchange.increaseOffer{value: AMOUNT2}();
        assertEq(safeExchange.price(), AMOUNT1 + AMOUNT2, "Incorrect price");
    }

    function testDecreaseOffer() public {
        vm.startPrank(buyer);
        safeExchange.decreaseOffer(AMOUNT2);
        assertEq(safeExchange.price(), AMOUNT1 - AMOUNT2, "Incorrect price");
        assertEq(buyer.balance, HUGE_AMOUNT - AMOUNT1 + AMOUNT2, "Incorrect buyer balance");
    }

    function testDecreaseOfferBadAuth() public {
        vm.startPrank(seller);
        vm.expectRevert('Not buyer');
        safeExchange.decreaseOffer(AMOUNT2);
    }

    function testDecreaseOfferTooMuch() public {
        vm.startPrank(buyer);
        vm.expectRevert('Transfer failed');
        safeExchange.decreaseOffer(AMOUNT1 + 1);
    }

    function testExchange() public {
        prepareForExchange();
        vm.startPrank(seller, seller);
        safeExchange.exchange(AMOUNT1);
        assertEq(buyer.balance, HUGE_AMOUNT - AMOUNT1, "Incorrect buyer balance");
        assertEq(seller.balance, AMOUNT1, "Incorrect seller balance");

        assertEq(contractForSale.getRoleMemberCount(DEFAULT_ADMIN_ROLE), 1, "Incorrect number of admins");
        assertTrue(contractForSale.hasRole(DEFAULT_ADMIN_ROLE, newAdmin), "newAdmin not admin");
    }

    function testExchangeBadAuth() public {
        prepareForExchange();
        vm.startPrank(buyer, buyer);
        vm.expectRevert('Not seller');
        safeExchange.exchange(AMOUNT1);
    }

    function testExchangeNotEOA() public {
        prepareForExchange();
        vm.startPrank(seller, buyer);
        vm.expectRevert('Not an EOA');
        safeExchange.exchange(AMOUNT1);
    }

    function testExchangeFrontRun() public {
        prepareForExchange();

        // Just before the seller calls exchange, decrease the offer
        vm.startPrank(buyer);
        safeExchange.decreaseOffer(AMOUNT2);
        vm.stopPrank();

        vm.startPrank(seller, seller);
        vm.expectRevert("Insufficient funds");
        safeExchange.exchange(AMOUNT1);
    }

    function testExchangeTwoAdmins() public {
        vm.startPrank(seller, seller);
        contractForSale.grantRole(DEFAULT_ADMIN_ROLE, address(safeExchange));
        // Don't renounce admin
        // contractForSale.renounceRole(DEFAULT_ADMIN_ROLE, seller);
        assertTrue(contractForSale.hasRole(DEFAULT_ADMIN_ROLE, address(safeExchange)), "safeExchange not admin");
        vm.stopPrank();

        vm.startPrank(seller, seller);
        vm.expectRevert("Too many admins");
        safeExchange.exchange(AMOUNT1);
    }

    function testRegainOwnership() public {
        prepareForExchange();
        vm.startPrank(seller);
        safeExchange.regainOwnership();
        assertEq(contractForSale.getRoleMemberCount(DEFAULT_ADMIN_ROLE), 1, "Incorrect number of admins");
        assertTrue(contractForSale.hasRole(DEFAULT_ADMIN_ROLE, seller), "seller not admin");
    }

    function testRegainOwnershipBadAuth() public {
        prepareForExchange();
        vm.startPrank(buyer);
        vm.expectRevert("Not seller");
        safeExchange.regainOwnership();
        // Check contract is still admin.
        assertEq(contractForSale.getRoleMemberCount(DEFAULT_ADMIN_ROLE), 1, "Incorrect number of admins");
        assertTrue(contractForSale.hasRole(DEFAULT_ADMIN_ROLE, address(safeExchange)), "safeExchange not admin");
    }


    function prepareForExchange() private {
        vm.startPrank(seller, seller);
        contractForSale.grantRole(DEFAULT_ADMIN_ROLE, address(safeExchange));
        contractForSale.renounceRole(DEFAULT_ADMIN_ROLE, seller);
        assertEq(contractForSale.getRoleMemberCount(DEFAULT_ADMIN_ROLE), 1, "Incorrect number of admins");
        assertTrue(contractForSale.hasRole(DEFAULT_ADMIN_ROLE, address(safeExchange)), "safeExchange not admin");
        vm.stopPrank();
    }
}
