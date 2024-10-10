pragma solidity ^0.8.0;

import {ERC721} from "solmate/tokens/ERC721.sol";

contract VulnerableNFT is ERC721 {
    function mint() public {
        uint256 tokenId = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender)));
        _mint(msg.sender, tokenId);
    }

    mapping(uint256 => string) private _tokenURIs;
    function setTokenURI(uint256 tokenId, string memory _tokenURI) public { 
        _tokenURIs[tokenId] = _tokenURI; 
    } 

    mapping(address => uint256) private balances;
    function sellNFT(address nftContract, uint256 tokenId, uint256 price) external {
        IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);
        balances[msg.sender] += price;
    }

    function withdraw() external {
        uint256 amount = balances[msg.sender];
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
        balances[msg.sender] = 0;
    }

    address[] public holders;
    function airdrop() public {
        for (uint i = 0; i < holders.length; i++) {
            _mint(holders[i], holders.length + i);
        }
    }
}
