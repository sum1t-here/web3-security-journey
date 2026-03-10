// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.28;

contract Proxy {
    uint256 public num;
    address public sender;
    uint256 public value;

    function setVars(uint256 _num) public payable {
        num = _num;
        sender = msg.sender;
        value = msg.value;
    }
}

contract Logic {
    uint256 public num;
    address public sender;
    uint256 public value;

    event DelegateResponse(bool success, bytes data);

    // Logic's storage will be set. Proxy's storage is not set
    function setVarsDelegateCall(address _contract, uint256 _num) public payable {
        (bool success, bytes memory data) = _contract.delegatecall(abi.encodeWithSignature("setVars(uint256)", _num));

        emit DelegateResponse(success, data);
    }
}
