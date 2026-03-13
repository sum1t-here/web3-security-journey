// SPDX-License-Identifier: MIT
pragma solidity 0.8.34;

interface IThunderLoan {
    function repay(address token, uint256 amount) external;
}