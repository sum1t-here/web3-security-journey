// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.34;

import { ITSwapPool } from "../interfaces/ITSwapPool.sol";
import { IPoolFactory } from "../interfaces/IPoolFactory.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract OracleUpgradeable is Initializable {
    address private s_poolFactory;

    // @aderyn lack 0 address check
    function __Oracle_init(address poolFactoryAddress) internal onlyInitializing {
        __Oracle_init_unchained(poolFactoryAddress);
    }

    function __Oracle_init_unchained(address poolFactoryAddress) internal onlyInitializing {
        s_poolFactory = poolFactoryAddress;
    }

    // e we are calling external contracts
    // what if I can manipulate the price of the token?
    // reentrancy ?
    // @audit-info use fork tests for this
    function getPriceInWeth(address token) public view returns (uint256) {
        address swapPoolOfToken = IPoolFactory(s_poolFactory).getPool(token);
        return ITSwapPool(swapPoolOfToken).getPriceOfOnePoolTokenInWeth();
    }

    // redundant
    function getPrice(address token) external view returns (uint256) {
        return getPriceInWeth(token);
    }

    function getPoolFactoryAddress() external view returns (address) {
        return s_poolFactory;
    }
}