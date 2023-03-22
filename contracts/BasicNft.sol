// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract BasicNftFactory{
    event NewNft(address nft);
    address[] public nfts;
    function newNft(address _groupBy, string memory _name, string memory _symbol) public returns (address){
        BasicNft b = new BasicNft(_groupBy, _name, _symbol, msg.sender);
        nfts.push(address(b));
        emit NewNft(address(b));
        return address(b);
    }
}

contract BasicNft is ERC721 {
    error Unauthorized();

    string public _tokenURI;
    uint256 private s_tokenCounter;
    address groupBuy;
    address owner;

    constructor(address _groupBuy, string memory _name, string memory _symbol, address _owner)
        ERC721(_name, _symbol)
    {
        s_tokenCounter = 0;
        groupBuy = _groupBuy;
        owner = _owner;
    }

    function mintMultiple(address receiver, uint256 amount) external {
        if (msg.sender != groupBuy) {
            revert Unauthorized();
        }
        for (uint256 i = 0; i < amount; i++) {
            mintNft(receiver);
        }
    }

    function mintNft(address to) internal {
        s_tokenCounter = s_tokenCounter + 1;
        _safeMint(to, s_tokenCounter);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        // require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return _tokenURI;
    }

    function setTokenURI(string memory uri) public {
        _tokenURI = uri;
    }

    function getTokenCounter() public view returns (uint256) {
        return s_tokenCounter;
    }

    function getOwner() external view returns (address) {
        return owner;
    }
}
