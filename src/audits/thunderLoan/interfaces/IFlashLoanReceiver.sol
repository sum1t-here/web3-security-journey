// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.34;

// @audit-info unused import
import {IThunderLoan} from "./IThunderLoan.sol";

/**
 * @dev Inspired by Aave:
 * https://github.com/aave/aave-v3-core/blob/master/contracts/flashloan/interfaces/IFlashLoanReceiver.sol
 */
interface IFlashLoanReceiver {
    // @audit-info where is the natspec ??
    // q token is the borrowed token ??
    // q amount is the amount of token borrowed ??
    function executeOperation(address token, uint256 amount, uint256 fee, address initiator, bytes calldata params)
        external
        returns (bool);
}
