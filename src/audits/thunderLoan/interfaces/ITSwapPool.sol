// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.34;

// q answer: why are we only using the price of one pool token in weth?
// this is a bug
interface ITSwapPool {
    function getPriceOfOnePoolTokenInWeth() external view returns (uint256);
}
