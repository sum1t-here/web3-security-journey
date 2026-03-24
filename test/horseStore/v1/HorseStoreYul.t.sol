// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {Base_TestV1, IHorseStore} from "./Base_TestV1.t.sol";
import {HorseStoreYul} from "src/horseStore/HorseStoreYul.sol";

contract HorseStoreYulTest is Base_TestV1 {
    function setUp() public override {
        horseStore = IHorseStore(address(new HorseStoreYul()));
    }
}