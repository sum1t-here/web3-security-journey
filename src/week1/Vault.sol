// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.28;

contract Vault {
    // State variables

    // private variables
    mapping(address => uint256) private _balances;

    // Functions

    /**
     * @dev Deposit Ether into the vault
     * @notice This function allows users to deposit Ether into the vault
     * @dev The deposited Ether will be stored in the vault
     * @dev The sender's balance will be increased by the deposited amount
     */
    function deposit() public payable {
        _balances[msg.sender] += msg.value;
    }

    /**
     * @dev Withdraw Ether from the vault
     * @notice This function allows users to withdraw Ether from the vault
     * @dev The withdrawn Ether will be sent to the sender
     * @dev The sender's balance will be decreased by the withdrawn amount
     */
    function withdraw(uint256 amount) public {
        // CEI Pattern
        // 1. Check
        require(amount > 0, "Amount must be greater than 0");
        require(_balances[msg.sender] >= amount, "Insufficient balance");

        // 2. Effect
        _balances[msg.sender] -= amount;

        // 3. Interaction
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Withdrawal failed");
    }

    // Getter functions

    /**
     * @dev Returns the balance of the specified address
     * @param owner The address to check the balance of
     * @return The balance of the specified address
     */
    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }
}