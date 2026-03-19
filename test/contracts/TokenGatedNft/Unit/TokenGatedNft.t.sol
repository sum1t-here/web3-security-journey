// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {TokenGatedNft} from "src/contracts/TokenGatedNft.sol";
import {ERC20Mock} from "test/mocks/ERC20Mock.sol";

contract TokenGatedNftTest is Test {
    address public OWNER = makeAddr("owner");
    address public USER = makeAddr("user");
    address public USER2 = makeAddr("user2");

    TokenGatedNft public tokenGatedNft;
    ERC20Mock public erc20Mock;

    uint256 constant MINT_PRICE = 10e18;
    uint256 constant MAX_SUPPLY = 5;
    string constant BASE_URI = "ipfs://QmXxx.../";

    function setUp() public {
        erc20Mock = new ERC20Mock();
        tokenGatedNft = new TokenGatedNft(OWNER, address(erc20Mock), MINT_PRICE, MAX_SUPPLY, BASE_URI);

        // fund users
        erc20Mock.mint(USER, 100e18);
        erc20Mock.mint(USER2, 100e18);
    }

    // constructors

    function test_constructor_success() public {
        assertEq(tokenGatedNft.owner(), OWNER);
        assertEq(address(tokenGatedNft.paymentToken()), address(erc20Mock));
        assertEq(tokenGatedNft.mintPrice(), MINT_PRICE);
        assertEq(tokenGatedNft.maxSupply(), MAX_SUPPLY);
        assertEq(tokenGatedNft.baseNftURI(), BASE_URI);
    }

    function test_RevertIfZeroAddressPaymentToken() public {
        vm.expectRevert(TokenGatedNft.ZeroAddress.selector);
        new TokenGatedNft(OWNER, address(0), MINT_PRICE, MAX_SUPPLY, BASE_URI);
    }

    function test_RevertIfZeroAddressOwner() public {
        vm.expectRevert();
        new TokenGatedNft(address(0), address(erc20Mock), MINT_PRICE, MAX_SUPPLY, BASE_URI);
    }

    function test_RevertIfZeroMintPrice() public {
        vm.expectRevert(TokenGatedNft.MintPriceCannotBeZero.selector);
        new TokenGatedNft(OWNER, address(erc20Mock), 0, MAX_SUPPLY, BASE_URI);
    }

    function test_RevertIfZeroMaxSupply() public {
        vm.expectRevert(TokenGatedNft.MaxSupplyCannotBeZero.selector);
        new TokenGatedNft(OWNER, address(erc20Mock), MINT_PRICE, 0, BASE_URI);
    }

    // mint
    function test_MintSuccessfully() public {
        vm.startPrank(USER);
        erc20Mock.approve(address(tokenGatedNft), type(uint256).max);
        tokenGatedNft.mint();
        assertEq(tokenGatedNft.ownerOf(1), USER);
        assertEq(tokenGatedNft.balanceOf(USER), 1);
        assertEq(tokenGatedNft.totalMinted(), 1);
        assertEq(tokenGatedNft.remainingSupply(), MAX_SUPPLY - 1);
        vm.stopPrank();
    }

    function test_MintTransferBalanceToContract() public {
        uint256 balanceBeforeMint = erc20Mock.balanceOf(address(tokenGatedNft));
        uint256 balanceBeforeUser = erc20Mock.balanceOf(USER);

        vm.startPrank(USER);
        erc20Mock.approve(address(tokenGatedNft), type(uint256).max);
        tokenGatedNft.mint();
        vm.stopPrank();

        assertEq(erc20Mock.balanceOf(address(tokenGatedNft)), balanceBeforeMint + MINT_PRICE);
        assertEq(erc20Mock.balanceOf(USER), balanceBeforeUser - MINT_PRICE);
    }

    function test_MintRevertIfInsufficientBalance() public {
        address broke = makeAddr("broke");
        vm.startPrank(broke);
        vm.expectRevert(TokenGatedNft.InsufficientBalance.selector);
        tokenGatedNft.mint();
        vm.stopPrank();
    }

    function test_MultipleUsersMintSuccessfully() public {
        vm.startPrank(USER);
        erc20Mock.approve(address(tokenGatedNft), type(uint256).max);
        tokenGatedNft.mint();
        vm.stopPrank();

        vm.startPrank(USER2);
        erc20Mock.approve(address(tokenGatedNft), type(uint256).max);
        tokenGatedNft.mint();
        vm.stopPrank();

        assertEq(tokenGatedNft.ownerOf(1), USER);
        assertEq(tokenGatedNft.ownerOf(2), USER2);
        assertEq(tokenGatedNft.balanceOf(USER), 1);
        assertEq(tokenGatedNft.balanceOf(USER2), 1);
        assertEq(tokenGatedNft.totalMinted(), 2);
        assertEq(tokenGatedNft.remainingSupply(), MAX_SUPPLY - 2);
    }

    function test_MintRevertIfMaxSupplyExceeded() public {
        for (uint256 i = 0; i < MAX_SUPPLY; i++) {
            vm.startPrank(USER);
            erc20Mock.approve(address(tokenGatedNft), type(uint256).max);
            tokenGatedNft.mint();
            vm.stopPrank();
        }

        vm.startPrank(USER);
        erc20Mock.approve(address(tokenGatedNft), type(uint256).max);
        vm.expectRevert(TokenGatedNft.NftSupplyExceeded.selector);
        tokenGatedNft.mint();
        vm.stopPrank();
    }

    function test_MintFailsIfNoApprove() public {
        vm.startPrank(USER);
        vm.expectRevert();
        tokenGatedNft.mint();
        vm.stopPrank();
    }

    function test_NftIdStartsFromOne() public {
        vm.startPrank(USER);
        erc20Mock.approve(address(tokenGatedNft), type(uint256).max);
        tokenGatedNft.mint();
        vm.stopPrank();

        assertEq(tokenGatedNft.ownerOf(1), USER);
    }

    // tokenURI
    function test_TokenURI() public {
        vm.startPrank(USER);
        erc20Mock.approve(address(tokenGatedNft), type(uint256).max);
        tokenGatedNft.mint();
        vm.stopPrank();

        assertEq(tokenGatedNft.tokenURI(1), string(abi.encodePacked(BASE_URI, "1")));
    }

    // withdraw
    function test_WithdrawSuccessfully() public {
        vm.startPrank(USER);
        erc20Mock.approve(address(tokenGatedNft), type(uint256).max);
        tokenGatedNft.mint();
        vm.stopPrank();

        uint256 balanceBeforeOwner = erc20Mock.balanceOf(OWNER);
        uint256 balanceBeforeContract = erc20Mock.balanceOf(address(tokenGatedNft));

        vm.startPrank(OWNER);
        tokenGatedNft.withdraw();
        vm.stopPrank();

        assertEq(erc20Mock.balanceOf(OWNER), balanceBeforeOwner + balanceBeforeContract);
        assertEq(erc20Mock.balanceOf(address(tokenGatedNft)), 0);
    }

    function test_WithdrawRevertIfNonOwner() public {
        vm.startPrank(USER);
        vm.expectRevert();
        tokenGatedNft.withdraw();
        vm.stopPrank();
    }

    // totalMinted
    function test_TotalMinted() public {
        vm.startPrank(USER);
        erc20Mock.approve(address(tokenGatedNft), type(uint256).max);
        tokenGatedNft.mint();
        vm.stopPrank();

        assertEq(tokenGatedNft.totalMinted(), 1);
    }

    // remainingSupply
    function test_RemainingSupply() public {
        vm.startPrank(USER);
        erc20Mock.approve(address(tokenGatedNft), type(uint256).max);
        tokenGatedNft.mint();
        vm.stopPrank();

        assertEq(tokenGatedNft.remainingSupply(), MAX_SUPPLY - 1);
    }
}
