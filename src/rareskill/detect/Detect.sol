// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

contract MsgSender {
    // checking an address if it is smart contract using msg.sender==tx.origin

    // if _addr is smart contract then it will return false
    // if _addr is EOA then it will return true
    // https://ethereum.stackexchange.com/questions/5828/what-is-an-eoa-account

    // if wallet 1 calls a contract A
    // then in contract A, msg.sender will be wallet 1 and tx.origin will be wallet 1

    // if wallet 1 creates a contract A and sends a transaction to contract B
    // then in contract B, msg.sender will be contract A and tx.origin will be wallet 1

    // tx.origin is always the original creator of the transaction
    // msg.sender is the immediate caller of the transaction

    function detect() public view returns (bool) {
        if (msg.sender == tx.origin) {
            return true;
        } else {
            return false;
        }
    }

    // require(msg.sender == tx.origin) is an antipattern

    // Using a smart contract as a wallet is becoming increasingly popular with the adoption of account abstraction, such as ERC-4337 and using smart contracts for multisignature wallets (like Gnosis Safe).

    // Adding require(msg.sender == tx.origin) to a smart contract means that account abstraction wallets and multisignature wallets cannot interact with the smart contract.

    // This technique can only test if msg.sender is a contract or not.
}

contract CodeLength {
    // checking an address if it is smart contract using code.length

    // if code.length > 0 then it is smart contract
    // if code.length == 0 then it is EOA

    function detect() public view returns (bool) {
        if (msg.sender.code.length > 0) {
            return true;
        } else {
            return false;
        }
    }

    // Using msg.sender.code.length == 0 is not a reliable way to detect if an incoming call is from a smart contract.
    // If a smart contract makes a call from the constructor then it has not deployed its bytecode yet and msg.sender.code.length will be 0.
    // While the constructor is executing, the bytecode of the smart contract has not yet been deployed. Therefore, code.length will be zero.
    // On EVM chains that support selfdestruct, there might have been a smart contract at target in the past, but the smart contract self destructed.
}

contract CodeHash {
    // If the address has no Ethereum balance and no bytecode, there is nothing to hash and returns bytes32(0).
    // If the address has an Ethereum balance but no bytecode, it returns the keccak256 of empty data keccak256("") which equals 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470.
    // If the address has bytecode (regardless of balance) it returns the keccak256 of the bytecode of the contract.
    // just adds more complexity better use code.length

    }
