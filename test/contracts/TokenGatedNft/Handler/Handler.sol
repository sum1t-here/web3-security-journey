// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {TokenGatedNft} from "src/contracts/TokenGatedNft.sol";
import {ERC20Mock} from "test/mocks/ERC20Mock.sol";

contract Handler is Test {
    TokenGatedNft public tokenGatedNft;
    ERC20Mock erc20;
    address owner;
    address[] public users;

    uint256 public totalWithdrawn;

    constructor(TokenGatedNft _tokenGatedNft, ERC20Mock _erc20, address _owner) {
        tokenGatedNft = _tokenGatedNft;
        erc20 = _erc20;
        owner = _owner;

        // make user
        for (uint256 i = 0; i < 5; i++) {
            users.push(makeAddr(string(abi.encodePacked("user", i))));
        }
    }

    function mint(uint256 userSeed) public {
        address user = users[userSeed % users.length];

        // fund user
        erc20.mint(user, tokenGatedNft.mintPrice());

        vm.startPrank(user);
        erc20.approve(address(tokenGatedNft), tokenGatedNft.mintPrice());

        if (tokenGatedNft.remainingSupply() > 0) {
            tokenGatedNft.mint();
        }
        vm.stopPrank();
    }

    function withdraw() public {
        uint256 balance = tokenGatedNft.balanceOf(address(tokenGatedNft));
        vm.prank(owner);
        tokenGatedNft.withdraw();
        totalWithdrawn += balance;
    }
}
