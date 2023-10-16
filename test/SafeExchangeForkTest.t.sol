// Copyright (c) Peter Robinson 2023
// SPDX-License-Identifier: BSD
// Use 0.7.6 to be compatible with Open Zeppelin 3.4.0
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



contract SafeExchangeForkTest is Test {
    address public constant CONTRACT_FOR_SALE = 0xAcB3C6a43D15B907e8433077B6d38Ae40936fe2c;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    uint256 public constant HUGE_AMOUNT = 100 ether;
    uint256 public constant OFFER_AMOUNT1 = 7 ether;
    uint256 public constant OFFER_AMOUNT2 = 5 ether;
    uint256 public constant BONUS_AMOUNT1 = 3 ether;
    uint256 public constant BONUS_AMOUNT2 = 1 ether;
    SafeExchange public safeExchange;
    ContractForSale public contractForSale;

    address buyer = makeAddr("buyer");
    address seller = 0x2A00CA38FB9B821edeA2478DA31d97B0f83347fe;
    address newAdmin = makeAddr("newAdmin");

    address other1 = 0x81f482C74CaEBafA2EC727136e159794BE11d758;
    address other2 = 0xc69347a086035d088981AF735816d43A830234B3;
    address other3 = 0xB33c8D383BBe37C65ca30D92d71A512C4112c3a3;


    function setUp() public {
        string memory RPC_URL = vm.envString("RPC");
        vm.createSelectFork(RPC_URL);

        contractForSale = ContractForSale(CONTRACT_FOR_SALE);

        vm.deal(buyer, HUGE_AMOUNT);
        vm.startPrank(buyer);
        safeExchange = new SafeExchange{value: OFFER_AMOUNT1 + BONUS_AMOUNT1}(newAdmin, seller, address(contractForSale), OFFER_AMOUNT1);
        vm.stopPrank();

        // Remove other admins
        vm.startPrank(other1);
        contractForSale.renounceRole(DEFAULT_ADMIN_ROLE, other1);
        vm.stopPrank();
        vm.startPrank(other2);
        contractForSale.renounceRole(DEFAULT_ADMIN_ROLE, other2);
        vm.stopPrank();
        vm.startPrank(other3);
        contractForSale.renounceRole(DEFAULT_ADMIN_ROLE, other3);
        vm.stopPrank();
    }

    function testInit() public {
        // Check the set-up of the contract for sale.
        assertEq(contractForSale.getRoleMemberCount(DEFAULT_ADMIN_ROLE), 1, "Incorrect number of admins1");
        assertTrue(contractForSale.hasRole(DEFAULT_ADMIN_ROLE, seller), "Seller not admin");

        // Check the initial configuration of the same exchange contract.
       assertEq(address(safeExchange).balance, OFFER_AMOUNT1 + BONUS_AMOUNT1, "Incorrect balance");
       assertEq(safeExchange.offer(), OFFER_AMOUNT1, "Incorrect offer");
       assertEq(safeExchange.bonus(), BONUS_AMOUNT1, "Incorrect bonus");
       assertEq(safeExchange.buyer(), buyer, "Buyer in contract not buyer");
       assertEq(safeExchange.seller(), seller, "Seller in contract not seller");
       assertEq(safeExchange.newAdmin(), newAdmin, "New admin not set correctly");
       assertEq(address(safeExchange.contractForSale()), address(contractForSale), "Contract for sale incorrect address");
    }


    function testInitBadOffer() public {
        vm.deal(buyer, HUGE_AMOUNT);
        vm.startPrank(buyer);
        vm.expectRevert('Offer smaller than value');
        safeExchange = new SafeExchange{value: OFFER_AMOUNT1}(newAdmin, seller, address(contractForSale), OFFER_AMOUNT1 + 1);
    }

    function testInitNoBonus() public {
        vm.startPrank(buyer);
        safeExchange = new SafeExchange{value: OFFER_AMOUNT1}(newAdmin, seller, address(contractForSale), OFFER_AMOUNT1);
       assertEq(safeExchange.bonus(), 0, "Incorrect bonus");
    }

    function testInitNoOffer() public {
        vm.startPrank(buyer);
        safeExchange = new SafeExchange{value: BONUS_AMOUNT1}(newAdmin, seller, address(contractForSale), 0);
       assertEq(safeExchange.offer(), 0, "Incorrect offer");
    }

    function testIncreaseOffer() public {
        safeExchange.increaseOffer{value: OFFER_AMOUNT2}();
        assertEq(safeExchange.offer(), OFFER_AMOUNT1 + OFFER_AMOUNT2, "Incorrect offer");
    }

    function testDecreaseOffer() public {
        vm.startPrank(buyer);
        safeExchange.decreaseOffer(OFFER_AMOUNT2);
        assertEq(safeExchange.offer(), OFFER_AMOUNT1 - OFFER_AMOUNT2, "Incorrect offer");
        assertEq(buyer.balance, HUGE_AMOUNT - OFFER_AMOUNT1 - BONUS_AMOUNT1 + OFFER_AMOUNT2, "Incorrect buyer balance");
    }

    function testDecreaseOfferBadAuth() public {
        vm.startPrank(seller);
        vm.expectRevert('Not buyer');
        safeExchange.decreaseOffer(OFFER_AMOUNT2);
    }

    function testDecreaseOfferTooMuch() public {
        vm.startPrank(buyer);
        vm.expectRevert('Amount greater than offer');
        safeExchange.decreaseOffer(OFFER_AMOUNT1 + 1);
    }

    function testExchange() public {
        uint256 sellerOriginalBalance = seller.balance;

        prepareForExchange();
        vm.startPrank(seller, seller);
        safeExchange.exchange(OFFER_AMOUNT1);
        vm.stopPrank();
        assertEq(buyer.balance, HUGE_AMOUNT - OFFER_AMOUNT1 - BONUS_AMOUNT1, "Incorrect buyer balance");
        assertEq(seller.balance, OFFER_AMOUNT1 + sellerOriginalBalance, "Incorrect seller balance");

        assertEq(contractForSale.getRoleMemberCount(DEFAULT_ADMIN_ROLE), 1, "Incorrect number of admins2");
        assertTrue(contractForSale.hasRole(DEFAULT_ADMIN_ROLE, newAdmin), "newAdmin not admin");
        assertEq(safeExchange.offer(), 0, "Offer not cleared");
    }

    function testExchangeBadAuth() public {
        prepareForExchange();
        vm.startPrank(buyer, buyer);
        vm.expectRevert('Not seller');
        safeExchange.exchange(OFFER_AMOUNT1);
    }

    function testExchangeNotEOA() public {
        prepareForExchange();
        vm.startPrank(seller, buyer);
        vm.expectRevert('Not an EOA');
        safeExchange.exchange(OFFER_AMOUNT1);
    }

    function testExchangeFrontRun() public {
        prepareForExchange();

        // Just before the seller calls exchange, decrease the offer
        vm.startPrank(buyer);
        safeExchange.decreaseOffer(OFFER_AMOUNT2);
        vm.stopPrank();

        vm.startPrank(seller, seller);
        vm.expectRevert("Insufficient funds");
        safeExchange.exchange(OFFER_AMOUNT1);
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
        safeExchange.exchange(OFFER_AMOUNT1);
    }

    function testRegainOwnership() public {
        prepareForExchange();
        vm.startPrank(seller);
        safeExchange.regainOwnership();
        assertEq(contractForSale.getRoleMemberCount(DEFAULT_ADMIN_ROLE), 1, "Incorrect number of admins3");
        assertTrue(contractForSale.hasRole(DEFAULT_ADMIN_ROLE, seller), "seller not admin");
    }

    function testRegainOwnershipBadAuth() public {
        prepareForExchange();
        vm.startPrank(buyer);
        vm.expectRevert("Not seller");
        safeExchange.regainOwnership();
        // Check contract is still admin.
        assertEq(contractForSale.getRoleMemberCount(DEFAULT_ADMIN_ROLE), 1, "Incorrect number of admins4");
        assertTrue(contractForSale.hasRole(DEFAULT_ADMIN_ROLE, address(safeExchange)), "safeExchange not admin");
    }

    function testRegainOwnershipAfterExchange() public {
        // Execute the exchange
        prepareForExchange();
        vm.startPrank(seller, seller);
        safeExchange.exchange(OFFER_AMOUNT1);
        vm.stopPrank();

        // Now try to regain ownership
        vm.startPrank(seller);
        vm.expectRevert("AccessControl: sender must be an admin to grant");
        safeExchange.regainOwnership();
    }

    function testIncreaseBonus() public {
        safeExchange.increaseBonus{value: BONUS_AMOUNT2}();
        assertEq(safeExchange.bonus(), BONUS_AMOUNT1 + BONUS_AMOUNT2, "Incorrect bonus");
    }

    function testDecreaseBonus() public {
        vm.startPrank(buyer);
        safeExchange.decreaseBonus(BONUS_AMOUNT2);
        assertEq(safeExchange.bonus(), BONUS_AMOUNT1 - BONUS_AMOUNT2, "Incorrect bonus");
        assertEq(buyer.balance, HUGE_AMOUNT - OFFER_AMOUNT1 - BONUS_AMOUNT1 + BONUS_AMOUNT2, "Incorrect buyer balance");
    }

    function testDecreaseBonusBadAuth() public {
        vm.startPrank(seller);
        vm.expectRevert('Not buyer');
        safeExchange.decreaseBonus(BONUS_AMOUNT2);
    }

    function testDecreaseBonusTooMuch() public {
        vm.startPrank(buyer);
        vm.expectRevert('Amount greater than bonus');
        safeExchange.decreaseBonus(BONUS_AMOUNT1 + 1);
    }

    function testBonusPayment() public {
        uint256 sellerOriginalBalance = seller.balance;

        prepareForExchange();
        vm.startPrank(seller, seller);
        safeExchange.exchange(OFFER_AMOUNT1);
        vm.stopPrank();
        vm.startPrank(buyer);
        safeExchange.payBonusPayment();
        vm.stopPrank();
        assertEq(seller.balance, OFFER_AMOUNT1 + BONUS_AMOUNT1 + sellerOriginalBalance, "Incorrect seller balance");
        assertEq(safeExchange.bonus(), 0, "Bonus not cleared");
    }

    function testBonusBadAuth() public {
        prepareForExchange();
        vm.startPrank(seller, seller);
        safeExchange.exchange(OFFER_AMOUNT1);
        vm.stopPrank();
        vm.startPrank(seller);
        vm.expectRevert("Not buyer");
        safeExchange.payBonusPayment();
    }


    function prepareForExchange() private {
        vm.startPrank(seller, seller);
        contractForSale.grantRole(DEFAULT_ADMIN_ROLE, address(safeExchange));
        contractForSale.renounceRole(DEFAULT_ADMIN_ROLE, seller);
        assertEq(contractForSale.getRoleMemberCount(DEFAULT_ADMIN_ROLE), 1, "Incorrect number of admins5");
        assertTrue(contractForSale.hasRole(DEFAULT_ADMIN_ROLE, address(safeExchange)), "safeExchange not admin");
        vm.stopPrank();
    }
}

