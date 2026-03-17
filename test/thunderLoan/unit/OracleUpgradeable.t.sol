// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {BaseTest} from "./BaseTest.t.sol";

contract OracleUpgradeableTest is BaseTest {
    function testInitializationOracle() public {
        assertEq(thunderLoan.getPoolFactoryAddress(), address(mockPoolFactory));
    }

    function testGetPrice() public {
        assertEq(thunderLoan.getPrice(address(tokenA)), 1e18);
    }
}
