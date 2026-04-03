// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {BaseTest} from "../BaseTest.t.sol";
import {GasBadNftMarketplace} from "src/audits/gasBadNft/GasBadNftMarketplace.sol";

contract GasBadNftMarketplaceTest is BaseTest {
    function setUp() public override {
        super.setUp();
        nftMarketplace = new GasBadNftMarketplace();
    }
}
