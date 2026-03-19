// A classic NFT that can only be minted by paying with a particular ERC20 token.

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract TokenGatedNft is ERC721, Ownable {
    using SafeERC20 for IERC20;

    IERC20 public immutable paymentToken;
    uint256 public immutable mintPrice;
    uint256 public immutable maxSupply;
    string public baseNftURI;
    uint256 private nftIdCounter;

    error NftSupplyExceeded();
    error InsufficientBalance();
    error ZeroAddress();
    error MintPriceCannotBeZero();
    error MaxSupplyCannotBeZero();

    constructor(
        address initialOwner,
        address _paymentToken,
        uint256 _mintPrice,
        uint256 _maxSupply,
        string memory _baseNftURI
    ) Ownable(initialOwner) ERC721("TokenGatedNft", "TGN") {
        if (_paymentToken == address(0)) {
            revert ZeroAddress();
        }

        if (initialOwner == address(0)) {
            revert ZeroAddress();
        }

        if (_mintPrice == 0) {
            revert MintPriceCannotBeZero();
        }

        if (_maxSupply == 0) {
            revert MaxSupplyCannotBeZero();
        }

        paymentToken = IERC20(_paymentToken);
        mintPrice = _mintPrice;
        maxSupply = _maxSupply;
        baseNftURI = _baseNftURI;
    }

    /// @dev Returns the base URI for token metadata.
    function _baseURI() internal view override returns (string memory) {
        return baseNftURI;
    }

    /// @notice Mints a new NFT to the caller in exchange for the required ERC20 payment.
    /// @dev Caller must approve this contract to spend `mintPrice` of `paymentToken` before calling.
    /// @dev Reverts if max supply is reached or caller has insufficient token balance.
    /// @dev Follows CEI — token transfer occurs before `_safeMint` to prevent reentrancy.
    function mint() external {
        if (nftIdCounter >= maxSupply) {
            revert NftSupplyExceeded();
        }

        if (paymentToken.balanceOf(msg.sender) < mintPrice) {
            revert InsufficientBalance();
        }

        paymentToken.safeTransferFrom(msg.sender, address(this), mintPrice);
        nftIdCounter++;
        _safeMint(msg.sender, nftIdCounter);
    }

    /// @notice Withdraws all collected payment tokens to the owner.
    function withdraw() external onlyOwner {
        paymentToken.safeTransfer(owner(), paymentToken.balanceOf(address(this)));
    }

    /// @notice Returns the total number of NFTs minted.
    function totalMinted() external view returns (uint256) {
        return nftIdCounter;
    }

    /// @notice Returns the remaining supply of NFTs.
    function remainingSupply() external view returns (uint256) {
        return maxSupply - nftIdCounter;
    }
}

