// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract HorseStoreYul {
    uint256 numberOfHorses; // 0th storage slot

    function updateHorseNumber(uint256 newNumber) public {
        // numberOfHorses = newNumber;
        assembly {
            sstore(numberOfHorses.slot, newNumber)
        }
    }

    function readNumberOfHorses() external view returns (uint256) {
        // return numberOfHorses;
        assembly {
            let num := sload(numberOfHorses.slot)
            mstore(0, num)
            return(0, 0x20)
        }
    }
}
