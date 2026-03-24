// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {Base_TestV1, IHorseStore} from "./Base_TestV1.t.sol";
import {HuffDeployer} from "foundry-huff/HuffDeployer.sol";

contract HorseStoreHuff is Base_TestV1 {

    string public constant HUFF_PATH = "horseStore/HorseStore";

    function setUp() public override {
        horseStore = IHorseStore(HuffDeployer.config().deploy(HUFF_PATH));
    }   
    
}