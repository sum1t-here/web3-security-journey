// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

import {Test, console} from "forge-std/Test.sol";
import {PoolFactory} from "../../../src/audits/tSwap/PoolFactory.sol";
import {TSwapPool} from "../../../src/audits/tSwap/TSwapPool.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

contract Handler is Test {
    TSwapPool pool;
    ERC20Mock weth;
    ERC20Mock poolToken;

    int256 public expectedDeltaX;
    int256 public expectedDeltaY;
    int256 public actualDeltaX;
    int256 public actualDeltaY;
    int256 public startingX;
    int256 public startingY;

    address liquidityProvider = makeAddr("liquidityProvider");
    address swapper = makeAddr("swapper");

    constructor(TSwapPool _pool) {
        pool = _pool;
        weth = ERC20Mock(_pool.getWeth());
        poolToken = ERC20Mock(_pool.getPoolToken());
    }

    // deposit, swapExactOutput
    function deposit(uint256 wethAmount) public {
        uint256 mintWeth = pool.getMinimumWethDepositAmount();
        wethAmount = bound(wethAmount, mintWeth, type(uint64).max);

        startingX = int256(poolToken.balanceOf(address(pool)));
        startingY = int256(weth.balanceOf(address(pool)));

        expectedDeltaY = int256(wethAmount);
        expectedDeltaX = int256(pool.getPoolTokensToDepositBasedOnWeth(wethAmount));

        // deposit
        vm.startPrank(liquidityProvider);
        weth.mint(liquidityProvider, wethAmount);
        poolToken.mint(liquidityProvider, uint256(expectedDeltaX));
        weth.approve(address(pool), type(uint256).max);
        poolToken.approve(address(pool), type(uint256).max);
        pool.deposit(wethAmount, 0, uint256(expectedDeltaX), uint64(block.timestamp));
        vm.stopPrank();

        // actual
        uint256 endingX = poolToken.balanceOf(address(pool));
        uint256 endingY = weth.balanceOf(address(pool));

        actualDeltaX = int256(endingX) - int256(startingX);
        actualDeltaY = int256(endingY) - int256(startingY);

        assertEq(actualDeltaX, expectedDeltaX);
        assertEq(actualDeltaY, expectedDeltaY);
    }

    function swapPoolTokenForWethBasedOnOutputWeth(uint256 outputWeth) public {
        uint256 mintWeth = pool.getMinimumWethDepositAmount();
        outputWeth = bound(outputWeth, mintWeth, weth.balanceOf(address(pool)));
        if (outputWeth >= weth.balanceOf(address(pool))) {
            return;
        }

        // delta x
        uint256 poolTokenAmount = pool.getInputAmountBasedOnOutput(
            outputWeth, poolToken.balanceOf(address(pool)), weth.balanceOf(address(pool))
        );

        if (poolTokenAmount > type(uint64).max) {
            return;
        }

        startingY = int256(weth.balanceOf(address(pool)));
        startingX = int256(poolToken.balanceOf(address(pool)));

        expectedDeltaY = int256(-1) * int256(outputWeth);
        expectedDeltaX = int256(poolTokenAmount);

        if (poolToken.balanceOf(swapper) < poolTokenAmount) {
            poolToken.mint(swapper, poolTokenAmount - poolToken.balanceOf(swapper) + 1);
        }

        vm.startPrank(swapper);
        poolToken.approve(address(pool), type(uint256).max);
        pool.swapExactOutput(poolToken, weth, outputWeth, uint64(block.timestamp));
        vm.stopPrank();

        // actual
        uint256 endingY = weth.balanceOf(address(pool));
        uint256 endingX = poolToken.balanceOf(address(pool));

        actualDeltaY = int256(endingY) - int256(startingY);
        actualDeltaX = int256(endingX) - int256(startingX);
    }
}
