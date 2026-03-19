// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {TokenGatedNft} from "src/contracts/TokenGatedNft.sol";
import {ERC20Mock} from "test/mocks/ERC20Mock.sol";
import {Handler} from "test/contracts/TokenGatedNft/Handler/Handler.sol";

contract TokenGatedNftInvariant is StdInvariant, Test {
    TokenGatedNft tokenGatedNft;
    ERC20Mock erc20;
    Handler handler;
    address owner = makeAddr("owner");

    function setUp() public {
        erc20 = new ERC20Mock();
        tokenGatedNft = new TokenGatedNft(owner, address(erc20), 10e18, 5, "ipfs://QmXxx.../");
        handler = new Handler(tokenGatedNft, erc20, owner);
        targetContract(address(handler));
    }

    /// @dev totalMinted can never exceed maxSupply
    function invariant_supplyNeverExceeded() public view {
        assertLe(tokenGatedNft.totalMinted(), tokenGatedNft.maxSupply());
    }

    /// @dev totalWithdrawn can never exceed totalMinted * mintPrice
    function invariant_totalWithdrawn() public view {
        assertLe(handler.totalWithdrawn(), tokenGatedNft.totalMinted() * tokenGatedNft.mintPrice());
    }
}
