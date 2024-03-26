// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract LoyaltyApp is ERC721, Ownable {
    // Token ID counter
    uint256 private tokenIdCounter;

    // Mapping to keep track of token burn status
    mapping(uint256 => bool) private isTokenBurnt;

    // Flag to determine if token is transferable
    bool private isTokenTransferable;

    // Event emitted when a new token is minted
    event TokenMinted(address indexed user, uint256 indexed tokenId);

    // Event emitted when a token is burned
    event TokenBurned(address indexed user, uint256 indexed tokenId);

    // Modifier to check if token is transferable
    modifier onlyTransferable() {
        require(isTokenTransferable, "Token is not transferable");
        _;
    }

    constructor() ERC721("Loyalty Token", "LOYALTY") {
        tokenIdCounter = 1;
        isTokenBurnt[0] = true; // Reserve token ID 0 to represent a burnt token
        isTokenTransferable = false; // Token is not transferable by default
    }

    /**
     * @dev Mint a new token for the user.
     * Only the contract owner can call this function.
     */
    function mintToken(address user) external onlyOwner returns (uint256) {
        require(user != address(0), "Invalid user address");

        uint256 newTokenId = tokenIdCounter;
        tokenIdCounter++;

        // Mint new token
        _safeMint(user, newTokenId);

        emit TokenMinted(user, newTokenId);

        return newTokenId;
    }

    /**
     * @dev Burn a token.
     * The caller must be the owner of the token or the contract owner.
     */
    function burnToken(uint256 tokenId) external {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Caller is not the owner nor approved");
        require(!isTokenBurnt[tokenId], "Token is already burnt");

        isTokenBurnt[tokenId] = true;
        _burn(tokenId);

        emit TokenBurned(_msgSender(), tokenId);
    }

    /**
     * @dev Set whether the token is transferable or not.
     * Only the contract owner can call this function.
     */
    function setTokenTransferability(bool transferable) external onlyOwner {
        isTokenTransferable = transferable;
    }

    /**
     * @dev Check if a token is burnt.
     */
    function isTokenBurned(uint256 tokenId) external view returns (bool) {
        return isTokenBurnt[tokenId];
    }

    /**
     * @dev Check if the token is transferable.
     */
    function getTransferability() external view returns (bool) {
        return isTokenTransferable;
    }
}