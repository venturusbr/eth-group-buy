// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract BasicNftChild is ERC721 {
    string public constant TOKEN_URI =
        "ipfs://bafybeig37ioir76s7mg5oobetncojcm3c3hxasyd4rvid4jqhy4gkaheg4/?filename=0-PUG.json";
    uint256 private s_tokenCounter;
    IERC721 private original = IERC721(0xbA5e088A8AB053F4933317Eb2F9903f16eb80051);
    //address private marketingTeam = 0x0; // funds go to marketing.

    constructor() ERC721("DogieChild", "DOGCHILD") {
        s_tokenCounter = 0;
    }

    // Mint for free if you own the rugged token.
    function mintNft(uint tokenId) public {
        require(original.ownerOf(tokenId) == msg.sender, "Caller must own the original token.");
        s_tokenCounter = s_tokenCounter + 1;
        _safeMint(msg.sender, tokenId);
    }

    // Mint at a premium if you don't own it.
    function mintNftWithFee(uint tokenId) public payable{
        require(tokenId <= 10000, "Maximum tokenId must be 10000.");
        require(msg.value == 50000000000000000, "You must pay 0.05 ETH to mint.");
        s_tokenCounter = s_tokenCounter + 1;
        _safeMint(msg.sender, tokenId);
    }

    function withdraw() external{
        //require(msg.sender == marketingTeam);
        (bool sent,) = payable(msg.sender).call{value: address(this).balance}("");
        require(sent);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        // require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return TOKEN_URI;
    }

    function getTokenCounter() public view returns (uint256) {
        return s_tokenCounter;
    }
}
