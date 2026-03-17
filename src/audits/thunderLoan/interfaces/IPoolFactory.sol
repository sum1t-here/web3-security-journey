// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.34;

// e this is probably interface to work with poolFactory.sol from tSwap
interface IPoolFactory {
    function getPool(address tokenAddress) external view returns (address);
}

// alr
