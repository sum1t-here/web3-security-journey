// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.28;

import {console} from "forge-std/console.sol";

contract Fallback {
    fallback() external payable {
        console.log("Fallback called");
    }
}
