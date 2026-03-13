// SPDX-License-Identifier: MIT
pragma solidity 0.8.34;

import { Test, console } from "forge-std/Test.sol";
import { ThunderLoan } from "../../../src/audits/thunderLoan/protocol/ThunderLoan.sol";
import { ERC20Mock } from "../mocks/ERC20Mock.sol";
import { MockTSwapPool } from "../mocks/MockTSwapPool.sol";
import { MockPoolFactory } from "../mocks/MockPoolFactory.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract BaseTest is Test {
    ThunderLoan thunderLoanImplementation;
    MockPoolFactory mockPoolFactory;
    ERC1967Proxy proxy;
    ThunderLoan thunderLoan;

    ERC20Mock weth;
    ERC20Mock tokenA;

    function setUp() public virtual {
        thunderLoanImplementation = new ThunderLoan();
        mockPoolFactory = new MockPoolFactory();

        weth = new ERC20Mock();
        tokenA = new ERC20Mock();

        mockPoolFactory.createPool(address(tokenA));

        // encode initialize call
        bytes memory initData = abi.encodeWithSelector(
            ThunderLoan.initialize.selector,
            address(mockPoolFactory)
        );

        // pass initData to proxy — calls initialize atomically
        proxy = new ERC1967Proxy(address(thunderLoanImplementation), initData);

        // cast proxy to ThunderLoan interface
        thunderLoan = ThunderLoan(address(proxy));
    }
}