// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "forge-std/Test.sol";
import "../src/SafeExchange.sol";

contract SafeExchangeTest is Test {
    uint256 public constant AMOUNT1 = 5 ether;
    SafeExchange public safeExchange;

    address buyer = makeAddr("buyer");
    address seller = makeAddr("seller");
    address newAdmin = makeAddr("newAdmin");
    



    function setUp() public {
        vm.deal(buyer, AMOUNT1);

        vm.startPrank(buyer);
        safeExchange = new SafeExchange{value: AMOUNT1}(newAdmin, address(0));
    }

    function testConstructor() public {
       assertEq(address(safeExchange).balance, AMOUNT1, "Incorrect balance");
    }

}
