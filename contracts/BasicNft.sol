// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract BasicNft is ERC721 {
    error Unauthorized();

    string public _tokenURI;
    uint256 private s_tokenCounter;
    address sharedEconomy;

    constructor(address _sharedEconomy) ERC721("Notebook Dell XYZ", "NOTEDELLXYZ") {
        s_tokenCounter = 0;
        sharedEconomy = sharedEconomy;
    }

    function mintMultiple(address receiver, uint256 amount) external{
        if(msg.sender != sharedEconomy){
            revert Unauthorized();
        }
        for(uint256 i = 0; i < amount; i++){
            mintNft(receiver);
        }
    }

    function mintNft(address to) internal {
        s_tokenCounter = s_tokenCounter + 1;
        _safeMint(to, s_tokenCounter);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        // require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return _tokenURI;
    }

    function setTokenURI(string memory uri) public {
        _tokenURI = uri;
    }

    function getTokenCounter() public view returns (uint256) {
        return s_tokenCounter;
    }
}
