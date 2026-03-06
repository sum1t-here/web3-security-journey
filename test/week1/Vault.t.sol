// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {Vault} from "../../src/week1/Vault.sol";

contract VaultTest is Test {
    Vault public vault;
    address alice = makeAddr("alice");

    function setUp() public {
        vault = new Vault();
        vm.deal(alice, 10 ether);
    }

    function testDeposit() public {
        vm.prank(alice);
        vault.deposit{value: 1 ether}();
        assertEq(vault.balanceOf(alice), 1 ether);
    }

    function testWithdraw() public {
        vm.startPrank(alice);
        vault.deposit{value: 1 ether}();
        vault.withdraw(1 ether);
        assertEq(vault.balanceOf(alice), 0);
        vm.stopPrank();
    }

    function testWithdraw_InsufficientBalance() public {
        vm.startPrank(alice);
        vault.deposit{value: 1 ether}();
        vm.expectRevert("Insufficient balance");
        vault.withdraw(2 ether);
        vm.stopPrank();
    }

    function testWithdraw_ZeroAmount() public {
        vm.startPrank(alice);
        vault.deposit{value: 1 ether}();
        vm.expectRevert("Amount must be greater than 0");
        vault.withdraw(0);
        vm.stopPrank();
    }
}

/**
 * @notice Attacker contract to exploit the vault contract
 * @dev This contract exploits the vault contract by withdrawing more than the deposited amount
 */
contract Attacker {
    Vault public vault;

    constructor(address _vault) {
        vault = Vault(_vault);
    }

    /**
     * @notice Function to attack the vault contract
     * @dev This function attacks the vault contract by withdrawing more than the deposited amount
     */
    function attack() public payable {
        vault.deposit{value: 1 ether}();
        vault.withdraw(1 ether);
    }

    /**
     * @notice Receive function to receive ETH from the vault contract
     * @dev This function receives ETH from the vault contract
     */
    receive() external payable {
        vault.withdraw(1 ether);
    }
}

/**
 * @notice Test contract to test the vault contract
 * @dev This contract tests the vault contract by withdrawing more than the deposited amount
 */
contract AttackerTest is Test {
    Vault public vault;
    Attacker public attacker;

    function setUp() public {
        vault = new Vault();
        attacker = new Attacker(address(vault));
        vm.deal(address(attacker), 10 ether);
    }

    /**
     * @notice Test function to test the vault contract
     * @dev This function tests the vault contract by withdrawing more than the deposited amount
     */
    function testAttack() public {
        vm.startPrank(address(attacker));
        vm.expectRevert("Withdrawal failed");
        attacker.attack{value: 1 ether}();
        vm.stopPrank();
    }
}
