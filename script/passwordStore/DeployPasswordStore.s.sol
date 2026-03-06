// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {Script, console2} from "forge-std/Script.sol";
import {PasswordStore} from "../../src/audits/passwordStore/PasswordStore.sol";

contract DeployPasswordStore is Script {
    function run() public returns (PasswordStore) {
        vm.startBroadcast();
        PasswordStore passwordStore = new PasswordStore();
        passwordStore.setPassword("myPassword");
        vm.stopBroadcast();
        return passwordStore;
    }
}
