// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.28;

import "../../src/week2/DelegateCall.sol";
import {Test} from "forge-std/Test.sol";

contract DelegateCallTest is Test {
    Logic logic;
    Proxy proxy;

    function setUp() public {
        logic = new Logic();
        proxy = new Proxy();
    }

    // delegatecall executes another contract's code but modifies the caller's own storage.
    function testDelegateCall() public {
        uint256 num = 5;
        logic.setVarsDelegateCall(address(proxy), num);
        assertEq(logic.num(), num);
        assertEq(proxy.num(), 0);
    }
}