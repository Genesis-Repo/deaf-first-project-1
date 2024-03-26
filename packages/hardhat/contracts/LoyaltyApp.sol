// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract LoyaltyApp is ERC721, Ownable {
    using SafeMath for uint256;

    // Token ID counter
    uint256 private tokenIdCounter;

    // Mapping to keep track of token burn status
    mapping(uint256 => bool) private isTokenBurnt;

    // Flag to determine if token is transferable
    bool private isTokenTransferable;

    // Mapping to store token vesting schedules
    mapping(uint256 => uint256) private tokenVestingSchedule;

    // Event emitted when a new token is minted
    event TokenMinted(address indexed user, uint256 indexed tokenId);

    // Event emitted when a token is burned
    event TokenBurned(address indexed user, uint256 indexed tokenId);

    // Event emitted when a token is vested
    event TokenVested(address indexed user, uint256 indexed tokenId, uint256 amount);

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
     * @dev Set the vesting schedule for a token.
     * Only the contract owner can call this function.
     * @param tokenId The ID of the token.
     * @param duration The duration of the vesting schedule in seconds.
     */
    function setTokenVestingSchedule(uint256 tokenId, uint256 duration) external onlyOwner {
        tokenVestingSchedule[tokenId] = block.timestamp.add(duration);
    }

    /**
     * @dev Release vested tokens to the user.
     * The caller must be the owner of the token or the contract owner.
     * @param tokenId The ID of the token.
     */
    function releaseVestedTokens(uint256 tokenId) external {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Caller is not the owner nor approved");
        require(tokenVestingSchedule[tokenId] != 0, "Vesting schedule not set");
        require(block.timestamp >= tokenVestingSchedule[tokenId], "Vesting period not completed");

        // Release tokens to the user
        ERC20 _loyaltyToken = ERC20(address(this)); // Assuming loyalty tokens are ERC20 tokens
        uint256 amount = _loyaltyToken.balanceOf(address(this));
        _loyaltyToken.transfer(_msgSender(), amount);

        emit TokenVested(_msgSender(), tokenId, amount);
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

    /**
     * @dev Get the vesting schedule for a token.
     */
    function getTokenVestingSchedule(uint256 tokenId) external view returns (uint256) {
        return tokenVestingSchedule[tokenId];
    }
}