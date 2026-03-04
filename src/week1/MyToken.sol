// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.28;

contract MyToken {
    // State variables

    // public variables
    string public name = "MyToken";
    string public symbol = "MTK";
    uint8 public decimals = 18;

    // private variables
    mapping(address => uint256) private _balances;
    uint256 private _totalSupply = 1000000 * 10 ** 18;
    mapping(address => mapping(address => uint256)) private _allowances;

    // Events
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor() {
        _balances[msg.sender] = _totalSupply;
    }

    // Functions

    /**
     * @dev Transfers tokens from the caller to the specified address.
     * @param to The address to transfer tokens to.
     * @param value The amount of tokens to transfer.
     * @return True if the transfer was successful.
     */
    function transfer(address to, uint256 value) public returns (bool) {
        require(to != address(0), "Invalid address");
        require(_balances[msg.sender] >= value, "Insufficient balance");

        _balances[msg.sender] -= value;
        _balances[to] += value;

        emit Transfer(msg.sender, to, value);
        return true;
    }

    /**
     * @dev Approves the specified address to spend the specified amount of tokens on behalf of the caller.
     * @param spender The address to approve.
     * @param value The amount of tokens to approve.
     * @return True if the approval was successful.
     */
    function approve(address spender, uint256 value) public returns (bool) {
        require(spender != address(0), "Invalid address");

        _allowances[msg.sender][spender] = value;

        emit Approval(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev Transfers tokens from the specified address to the specified address.
     * @param from The address to transfer tokens from.
     * @param to The address to transfer tokens to.
     * @param value The amount of tokens to transfer.
     * @return True if the transfer was successful.
     */
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(to != address(0), "Invalid address");
        require(_balances[from] >= value, "Insufficient balance");
        require(_allowances[from][msg.sender] >= value, "Insufficient allowance");

        _balances[from] -= value;
        _balances[to] += value;
        _allowances[from][msg.sender] -= value;

        emit Transfer(from, to, value);
        return true;
    }

    // Getter functions

    /**
     * @dev Returns the balance of the specified address.
     * @param owner The address to check the balance of.
     * @return The balance of the specified address.
     */
    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

    /**
     * @dev Returns the allowance of the specified address to spend the specified amount of tokens on behalf of the caller.
     * @param owner The address to check the allowance of.
     * @param spender The address to check the allowance of.
     * @return The allowance of the specified address to spend the specified amount of tokens on behalf of the caller.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev Returns the total supply of tokens.
     * @return The total supply of tokens.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
}
