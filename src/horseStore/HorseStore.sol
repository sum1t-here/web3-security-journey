// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract HorseStore {
    uint256 numberOfHorses; // 0th storage slot

    function updateHorseNumber(uint256 newNumber) public {
        numberOfHorses = newNumber;
    }

    function readNumberOfHorses() external view returns (uint256) {
        return numberOfHorses;
    }
}
