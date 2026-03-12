// SPDX-License-Identifier: MIT
pragma solidity 0.8.34;

import { Test, console } from "forge-std/Test.sol";
import { TSwapPool } from "../../../src/audits/tSwap/PoolFactory.sol";
import { ERC20Mock } from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";

contract TSwapPoolTest is Test {
    TSwapPool pool;
    ERC20Mock poolToken;
    ERC20Mock weth;

    address liquidityProvider = makeAddr("liquidityProvider");
    address user = makeAddr("user");

    function setUp() public {
        poolToken = new ERC20Mock();
        weth = new ERC20Mock();
        pool = new TSwapPool(address(poolToken), address(weth), "LTokenA", "LA");

        weth.mint(liquidityProvider, 200e18);
        poolToken.mint(liquidityProvider, 200e18);

        weth.mint(user, 10e18);
        poolToken.mint(user, 10e18);
    }

    function testDeposit() public {
        vm.startPrank(liquidityProvider);
        weth.approve(address(pool), 100e18);
        poolToken.approve(address(pool), 100e18);
        pool.deposit(100e18, 100e18, 100e18, uint64(block.timestamp));

        assertEq(pool.balanceOf(liquidityProvider), 100e18);
        assertEq(weth.balanceOf(liquidityProvider), 100e18);
        assertEq(poolToken.balanceOf(liquidityProvider), 100e18);

        assertEq(weth.balanceOf(address(pool)), 100e18);
        assertEq(poolToken.balanceOf(address(pool)), 100e18);
    }

    function testDepositSwap() public {
        vm.startPrank(liquidityProvider);
        weth.approve(address(pool), 100e18);
        poolToken.approve(address(pool), 100e18);
        pool.deposit(100e18, 100e18, 100e18, uint64(block.timestamp));
        vm.stopPrank();

        vm.startPrank(user);
        poolToken.approve(address(pool), 10e18);
        // After we swap, there will be ~110 tokenA, and ~91 WETH
        // 100 * 100 = 10,000
        // 110 * ~91 = 10,000
        uint256 expected = 9e18;

        pool.swapExactInput(poolToken, 10e18, weth, expected, uint64(block.timestamp));
        assert(weth.balanceOf(user) >= expected);
    }

    function testWithdraw() public {
        vm.startPrank(liquidityProvider);
        weth.approve(address(pool), 100e18);
        poolToken.approve(address(pool), 100e18);
        pool.deposit(100e18, 100e18, 100e18, uint64(block.timestamp));

        pool.approve(address(pool), 100e18);
        pool.withdraw(100e18, 100e18, 100e18, uint64(block.timestamp));

        assertEq(pool.totalSupply(), 0);
        assertEq(weth.balanceOf(liquidityProvider), 200e18);
        assertEq(poolToken.balanceOf(liquidityProvider), 200e18);
    }

    function testCollectFees() public {
        vm.startPrank(liquidityProvider);
        weth.approve(address(pool), 100e18);
        poolToken.approve(address(pool), 100e18);
        pool.deposit(100e18, 100e18, 100e18, uint64(block.timestamp));
        vm.stopPrank();

        vm.startPrank(user);
        uint256 expected = 9e18;
        poolToken.approve(address(pool), 10e18);
        pool.swapExactInput(poolToken, 10e18, weth, expected, uint64(block.timestamp));
        vm.stopPrank();

        vm.startPrank(liquidityProvider);
        pool.approve(address(pool), 100e18);
        pool.withdraw(100e18, 90e18, 100e18, uint64(block.timestamp));
        assertEq(pool.totalSupply(), 0);
        assert(weth.balanceOf(liquidityProvider) + poolToken.balanceOf(liquidityProvider) > 400e18);
    }

    function test_InvariantBroken() public {
        vm.startPrank(liquidityProvider);
        weth.approve(address(pool), 100e18);
        poolToken.approve(address(pool), 100e18);
        pool.deposit(100e18, 100e18, 100e18, uint64(block.timestamp));
        vm.stopPrank();

        uint256 outputWeth = 1e17;

        vm.startPrank(user);
        poolToken.approve(address(pool), 10e18);
        poolToken.mint(user, 100e18);
        pool.swapExactOutput(poolToken, weth, outputWeth, uint64(block.timestamp));
        pool.swapExactOutput(poolToken, weth, outputWeth, uint64(block.timestamp));
        pool.swapExactOutput(poolToken, weth, outputWeth, uint64(block.timestamp));
        pool.swapExactOutput(poolToken, weth, outputWeth, uint64(block.timestamp));
        pool.swapExactOutput(poolToken, weth, outputWeth, uint64(block.timestamp));
        pool.swapExactOutput(poolToken, weth, outputWeth, uint64(block.timestamp));
        pool.swapExactOutput(poolToken, weth, outputWeth, uint64(block.timestamp));
        pool.swapExactOutput(poolToken, weth, outputWeth, uint64(block.timestamp));
        pool.swapExactOutput(poolToken, weth, outputWeth, uint64(block.timestamp));

        int256 startingY = int256(weth.balanceOf(address(pool)));
        int256 expectedDeltaY = int256(-1) * int256(outputWeth); 

        pool.swapExactOutput(poolToken, weth, outputWeth, uint64(block.timestamp));

        uint256 endingY = weth.balanceOf(address(pool));
        int256 actualDeltaY = int256(endingY) - int256(startingY);
        assertEq(actualDeltaY, expectedDeltaY);
    }

    function test_WrongFeeChargedInSwapExactOutput() public {
        vm.startPrank(liquidityProvider);
        weth.approve(address(pool), 100e18);
        poolToken.approve(address(pool), 100e18);
        pool.deposit(100e18, 100e18, 100e18, uint64(block.timestamp));
        vm.stopPrank();

        uint256 outputWeth = 1e17;

        // correct formula (0.3% fee) uses 1000 not 10000
        uint256 correctInputAmount = (
            (poolToken.balanceOf(address(pool)) * outputWeth * 1000) /
            ((weth.balanceOf(address(pool)) - outputWeth) * 997)
        );

        // what the contract actually charges (10000 instead of 1000)
        uint256 actualInputAmount = pool.getInputAmountBasedOnOutput(
            outputWeth,
            poolToken.balanceOf(address(pool)),
            weth.balanceOf(address(pool))
        );

        console.log("correct input (0.3% fee) :", correctInputAmount);
        console.log("actual input  (91.3% fee):", actualInputAmount);
        console.log("overcharge               :", actualInputAmount - correctInputAmount);

        assertGt(actualInputAmount, correctInputAmount);

        vm.startPrank(user);
        poolToken.approve(address(pool), type(uint256).max);
        poolToken.mint(user, 100e18);

        uint256 userPoolTokenBefore = poolToken.balanceOf(user);
        pool.swapExactOutput(poolToken, weth, outputWeth, uint64(block.timestamp));
        uint256 userPoolTokenAfter = poolToken.balanceOf(user);

        uint256 actualPaid = userPoolTokenBefore - userPoolTokenAfter;

        console.log("user paid poolTokens     :", actualPaid);
        console.log("user should have paid    :", correctInputAmount);

        assertGt(actualPaid, correctInputAmount);
        vm.stopPrank();
    }

    function test_SwapExactOutputNoSlippageProtection() public {
        vm.startPrank(liquidityProvider);
        weth.approve(address(pool), 100e18);
        poolToken.approve(address(pool), 100e18);
        pool.deposit(100e18, 100e18, 100e18, uint64(block.timestamp));
        vm.stopPrank();

        // mint user enough poolTokens to handle price change
        poolToken.mint(user, 100e18);

        uint256 outputWeth = 1e18;

        uint256 expectedInputAmount = pool.getInputAmountBasedOnOutput(
            outputWeth,
            poolToken.balanceOf(address(pool)),
            weth.balanceOf(address(pool))
        );
        console.log("expected input at current price:", expectedInputAmount);

        // simulate large trade that drains weth reserves (price impact)
        address frontrunner = makeAddr("frontrunner");
        poolToken.mint(frontrunner, 1000e18);
        vm.startPrank(frontrunner);
        poolToken.approve(address(pool), type(uint256).max);
        // frontrunner buys a lot of weth, moving the price
        pool.swapExactInput(
            poolToken,
            70e18,
            weth,
            1,
            uint64(block.timestamp)
        );
        vm.stopPrank();

        // no maxInputAmount param means user has no protection
        uint256 actualInputAmount = pool.getInputAmountBasedOnOutput(
            outputWeth,
            poolToken.balanceOf(address(pool)),
            weth.balanceOf(address(pool))
        );
        console.log("actual input after price move :", actualInputAmount);
        console.log("extra poolTokens paid         :", actualInputAmount - expectedInputAmount);

        vm.startPrank(user);
        poolToken.approve(address(pool), type(uint256).max);

        uint256 userPoolTokenBefore = poolToken.balanceOf(user);
        // user has no way to set a maxInputAmount — tx goes through at any price
        pool.swapExactOutput(poolToken, weth, outputWeth, uint64(block.timestamp));
        uint256 userPoolTokenAfter = poolToken.balanceOf(user);

        uint256 actualPaid = userPoolTokenBefore - userPoolTokenAfter;
        console.log("user actually paid            :", actualPaid);
        console.log("user expected to pay          :", expectedInputAmount);

        // user paid more than they expected — no slippage protection
        assertGt(actualPaid, expectedInputAmount);
        vm.stopPrank();
    }

    function test_SwapExactInputReturnsZero() public {
        vm.startPrank(liquidityProvider);
        weth.approve(address(pool), 100e18);
        poolToken.approve(address(pool), 100e18);
        pool.deposit(100e18, 100e18, 100e18, uint64(block.timestamp));
        vm.stopPrank();

        vm.startPrank(user);
        poolToken.approve(address(pool), type(uint256).max);

        uint256 expectedOutput = pool.getOutputAmountBasedOnInput(
            10e18,
            poolToken.balanceOf(address(pool)),
            weth.balanceOf(address(pool))
        );
        console.log("expected output :", expectedOutput);

        uint256 actualReturn = pool.swapExactInput(
        poolToken,
            10e18,
            weth,
            1,
            uint64(block.timestamp)
        );
        console.log("actual return   :", actualReturn);
        assertEq(actualReturn, 0);

        assertGt(weth.balanceOf(user), 0);
        console.log("weth received   :", weth.balanceOf(user));
        vm.stopPrank();
    }

    function test_SellPoolTokensMismatch() public {
        vm.startPrank(liquidityProvider);
        weth.approve(address(pool), 100e18);
        poolToken.approve(address(pool), 100e18);
        pool.deposit(100e18, 100e18, 100e18, uint64(block.timestamp));
        vm.stopPrank();

        vm.startPrank(user);
        poolToken.approve(address(pool), 10e18);
        
        uint256 poolTokensToSell = 10e18;

        uint256 expectedWeth = pool.getOutputAmountBasedOnInput(
            poolTokensToSell,
            poolToken.balanceOf(address(pool)),
            weth.balanceOf(address(pool))
        );

        console.log("expected weth out        :", expectedWeth);
        console.log("pool tokens user has     :", poolToken.balanceOf(user));

        uint256 userPoolTokenBefore = poolToken.balanceOf(user);
        uint256 userWethBefore = weth.balanceOf(user);

        pool.sellPoolTokens(poolTokensToSell);

        uint256 userPoolTokenAfter = poolToken.balanceOf(user);
        uint256 userWethAfter = weth.balanceOf(user);

        uint256 actualPoolTokensSold = userPoolTokenBefore - userPoolTokenAfter;
        uint256 actualWethReceived = userWethAfter - userWethBefore;

        console.log("actual poolTokens sold   :", actualPoolTokensSold);
        console.log("actual weth received     :", actualWethReceived);
        console.log("expected weth            :", expectedWeth);

        assertNotEq(actualPoolTokensSold, poolTokensToSell);
        assertEq(actualWethReceived, poolTokensToSell);

        console.log("extra poolTokens taken   :", actualPoolTokensSold - poolTokensToSell);
        vm.stopPrank();
    }
}