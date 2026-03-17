// SPDX-License-Identifier: MIT
pragma solidity 0.8.34;

contract MockTSwapPool {
    function getPriceOfOnePoolTokenInWeth() external pure returns (uint256) {
        return 1e18;
    }
}
