// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {HorseStore} from "src/horseStore/HorseStore.sol";
import {Test, console} from "forge-std/Test.sol";
import {IHorseStore} from "src/horseStore/IHorseStore.sol";

abstract contract Base_TestV1 is Test {
    IHorseStore public horseStore;

    function setUp() public virtual {
        horseStore = IHorseStore(address(new HorseStore()));
    }

    function testReadValue() public {
        uint256 initialValue = horseStore.readNumberOfHorses();
        assertEq(initialValue, 0);
    }

    function testWriteValue() public {
        uint256 value = 10;
        horseStore.updateHorseNumber(value);
        uint256 readValue = horseStore.readNumberOfHorses();
        assertEq(readValue, value);
    }
}
