// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.28;

import {Fallback} from "../../src/week2/Fallback.sol";
import {Test} from "forge-std/Test.sol";

contract FallbackTest is Test {
    Fallback fb;

    function setUp() public {
        fb = new Fallback();
        vm.deal(address(this), 5 ether);
    }

    // Two ways to trigger fallback:
    // 1. Send ETH with some random calldata that doesn't match any function
    // 2. Call a function that doesn't exist on the contract

    function testFallback() public {
        (bool success, ) = address(fb).call{value: 1 ether}("");
        require(success, "Fallback called");
    }
} 