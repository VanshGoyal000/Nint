// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MyToken is ERC20, Ownable {
    // Mapping to track how many tokens a user has minted
    mapping(address => uint256) public userMintedAmount;

    // Maximum tokens a user can mint in one transaction
    uint256 public constant MAX_MINT_AMOUNT = 1000 * 10 ** 18; // Adjust as needed

    // Lock duration for newly minted tokens (in seconds)
    uint256 public lockDuration = 1 days;
    
    // Event for token locking
    event TokensLocked(address indexed account, uint256 amount, uint256 unlockTime);
    
    // Struct to hold locked token details
    struct LockedToken {
        uint256 amount;
        uint256 unlockTime;
    }

    // Mapping to track locked tokens for each user
    mapping(address => LockedToken) public lockedTokens;

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    // Mint tokens, with a limit per user
    function mint(address to, uint256 amount) external onlyOwner {
        require(userMintedAmount[to] + amount <= MAX_MINT_AMOUNT, "Minting limit exceeded");
        _mint(to, amount);
        userMintedAmount[to] += amount;

        // Lock the tokens
        lockedTokens[to] = LockedToken({
            amount: amount,
            unlockTime: block.timestamp + lockDuration
        });
        emit TokensLocked(to, amount, lockedTokens[to].unlockTime);
    }

    // Function to unlock tokens after the lock period
    function unlockTokens() external {
        LockedToken storage locked = lockedTokens[msg.sender];
        require(block.timestamp >= locked.unlockTime, "Tokens are still locked");
        require(locked.amount > 0, "No tokens to unlock");

        // Transfer the unlocked tokens to the user
        _transfer(address(this), msg.sender, locked.amount);
        delete lockedTokens[msg.sender]; // Reset locked tokens
    }

    // Burn function to allow users to destroy their tokens
    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
        userMintedAmount[msg.sender] -= amount; // Update minted amount
    }

    // Function for batch minting tokens
    function mintBatch(address[] calldata to, uint256[] calldata amounts) external onlyOwner {
        require(to.length == amounts.length, "Array length mismatch");
        for (uint256 i = 0; i < to.length; i++) {
            mint(to[i], amounts[i]);
        }
    }
}
