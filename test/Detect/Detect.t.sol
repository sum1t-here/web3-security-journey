// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

import "forge-std/Test.sol";
import {MsgSender, CodeLength} from "src/rareskill/detect/Detect.sol";

contract DetectTest is Test {
    MsgSender public msgSender;
    CodeLength public codeLength;

    address public eoa = makeAddr("eoa");

    function setUp() public {
        msgSender = new MsgSender();
        codeLength = new CodeLength();
    }

    function test_detect_eoa() public {
        // msg.sender, tx.origin
        vm.startPrank(eoa, eoa);
        assertEq(msgSender.detect(), true);
        assertEq(codeLength.detect(), false);
        vm.stopPrank();
    }

    function test_smart_contract() public {
        SmartContractAccount smartContractAccount = new SmartContractAccount(address(msgSender), address(codeLength));
    }
}

contract SmartContractAccount {
    address public msg_sender;
    address public tx_origin;

    constructor(address _msg_sender, address _codeLength) {
        // MsgSender check:
        // msg.sender = this contract ✅
        // tx.origin  = test contract ✅
        // NOT equal → false
        bool result1 = MsgSender(_msg_sender).detect();
        require(result1 == false, "MsgSender: should be false for contract");

        // CodeLength check:
        // Called FROM constructor!
        // code.length == 0 during construction → BYPASS! ❌
        // returns false even though caller IS a contract!
        bool result2 = CodeLength(_codeLength).detect();
        require(result2 == false, "CodeLength: bypassed in constructor!");
    }
}
