// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import "../../src/week2/TxOrigin.sol";

contract TxOriginTest is Test {
    Vault vault;
    Attack attack;
    address owner = makeAddr("owner");
    address attacker = makeAddr("attacker");

    function setUp() public {
        vault = new Vault(owner);
        attack = new Attack(vault, attacker);
    }

    function testAttack() public {
        vm.deal(address(vault), 1 ether);
        vm.prank(address(attacker), owner);
        attack.attack();
        assertEq(address(vault).balance, 0);
        assertEq(address(attacker).balance, 1 ether);
    }
}
