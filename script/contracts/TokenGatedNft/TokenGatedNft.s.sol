// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script, console} from "lib/forge-std/src/Script.sol";
import {TokenGatedNft} from "src/contracts/TokenGatedNft.sol";

contract TokenGatedNftScript is Script {
    // TODO: use real payment token
    address constant PAYMENT_TOKEN = address(0);
    uint256 constant MINT_PRICE = 10e18;
    uint256 constant MAX_SUPPLY = 1000;
    // TODO: use real base uri
    string constant BASE_URI = "ipfs://QmXxx.../";

    function run() external returns (TokenGatedNft) {
        console.log("Deploying TokenGatedNft...");
        console.log("Deployer     :", msg.sender);
        console.log("Payment token:", PAYMENT_TOKEN);
        console.log("Mint price   :", MINT_PRICE);
        console.log("Max supply   :", MAX_SUPPLY);
        console.log("Base URI     :", BASE_URI);

        vm.startBroadcast();
        TokenGatedNft tokenGatedNft = new TokenGatedNft(msg.sender, PAYMENT_TOKEN, MINT_PRICE, MAX_SUPPLY, BASE_URI);
        vm.stopBroadcast();

        console.log("TokenGatedNft deployed at:", address(tokenGatedNft));
        return tokenGatedNft;
    }
}
