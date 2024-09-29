// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract NeoxNFT is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    mapping(string => bool) private _linkMinted;

    constructor(address initialOwner) 
        ERC721("NeoxNFT", "NNFT") 
        Ownable(initialOwner)
    {}

    function mintNFT(address recipient, string memory link) public onlyOwner returns (uint256) {
        require(!_linkMinted[link], "NFT already minted for this link");

        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _safeMint(recipient, newItemId);
        _linkMinted[link] = true;

        return newItemId;
    }

    function isLinkMinted(string memory link) public view returns (bool) {
        return _linkMinted[link];
    }
}