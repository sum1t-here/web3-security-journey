// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import "../../src/week1/MyToken.sol";

contract MyTokenTest is Test {
    MyToken token;
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");

    function setUp() public {
        token = new MyToken();
    }

    function test_InitialSupply() public {
        assertEq(token.totalSupply(), 1000000 * 10 ** 18);
    }

    function test_Transfer() public {
        token.transfer(alice, 100);
        assertEq(token.balanceOf(alice), 100);
        assertEq(token.balanceOf(address(this)), 1000000 * 10 ** 18 - 100);
    }

    function test_Transfer_InsufficientBalance() public {
        // transfer 100 tokens to alice
        token.transfer(alice, 100);

        // alice tries to transfer 1000 tokens to bob
        vm.prank(alice);
        vm.expectRevert("Insufficient balance");
        token.transfer(bob, 1000);
    }

    function test_Transfer_ZeroAddress() public {
        vm.expectRevert("Invalid address");
        token.transfer(address(0), 100);
    }

    function test_Approve() public {
        token.approve(alice, 100);
        assertEq(token.allowance(address(this), alice), 100);
    }

    function test_TransferFrom() public {
        // approve 100 tokens to alice
        token.transfer(alice, 100);

        // alice approves bob to spend 50
        vm.prank(alice);
        token.approve(bob, 50);

        // bob spends 30 on behalf of alice
        vm.prank(bob);
        token.transferFrom(alice, bob, 30);

        assertEq(token.balanceOf(bob), 30);
        assertEq(token.allowance(alice, bob), 20);
    }

    function test_TransferFrom_ExceedsAllowance() public {
        // approve 100 tokens to alice
        token.approve(alice, 100);

        // alice approves bob to spend 50
        vm.prank(alice);
        token.approve(bob, 50);

        // bob tries to spend 60 on behalf of alice
        vm.prank(bob);
        vm.expectRevert("Insufficient balance");
        token.transferFrom(alice, bob, 60);
    }

    // FUZZ: test transfer never creates tokens out of thin air
    function testFuzz_TransferConservesSupply(uint256 amount) public {
        // bound the amount to be within the range of 0 and the total supply
        amount = bound(amount, 0, token.balanceOf(address(this)));

        uint256 supplyBefore = token.totalSupply();

        token.transfer(alice, amount);

        // total supply must never change
        assertEq(token.totalSupply(), supplyBefore);

        // balances must always add up to total supply
        assertEq(token.balanceOf(address(this)) + token.balanceOf(alice), supplyBefore);
    }
}
