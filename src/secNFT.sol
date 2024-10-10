pragma solidity ^0.8.0;

import {ERC721} from "solmate/tokens/ERC721.sol";
import {ERC2981} from "solmate/tokens/ERC2981.sol";
import "@chainlink/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/v0.8/VRFConsumerBaseV2.sol";

contract SecureNFT is ERC721, ERC2981, Ownable {
    mapping(uint256 => string) private _tokenURIs;
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    constructor(uint64 subscriptionId, address vrfCoordinatorV2Address) VRFConsumerBaseV2(vrfCoordinatorV2Address) {
        _subscriptionId = subscriptionId;
        CoordinatorInterface = VRFCoordinatorV2Interface(vrfCoordinatorV2Address);
    }

    function useChainlinkVRF() public returns (uint256 requestId) {
        requestId = CoordinatorInterface.requestRandomWords(
            KEY_HASH,
            _subscriptionId,
            BLOCK_CONFIRMATIONS,
            CALLBACK_GAS_LIMIT,
            NUM_WORDS
        );
        return requestId;
    }

    uint256 public number;
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        uint256 number = (randomWords[0] % 100) + 1;
    }

    uint256 private nonce;
    function mint() public {
        uint256 tokenId = uint256(keccak256(abi.encodePacked(
            blockhash(number),
            msg.sender,
            nonce
        )));
        nonce++;
        _mint(msg.sender, tokenId);
        _setTokenURI(tokenId, _tokenURI);
    }

    mapping(address => uint256) private balances;
    function sellNFT(address nftContract, uint256 tokenId, uint256 price) external {
        IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);
        balances[msg.sender] += price;
    }

    function withdraw() external {
        uint256 amount = balances[msg.sender];
        balances[msg.sender] = 0;
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
    }

    constructor(string memory name, string memory symbol, address royaltyRecipient, uint96 royaltyPercentage) 
        ERC721(name, symbol) 
    {
        _setDefaultRoyalty(royaltyRecipient, royaltyPercentage);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    mapping(address => bool) public holders;
    uint256 public nextTokenId;
    function addHolder(address holder) public onlyOwner {
        holders[holder] = true;
    }

    function claim() public {
        require(holders[msg.sender], "Not eligible for airdrop");
        require(!_exists(nextTokenId), "All tokens minted");
        _mint(msg.sender, nextTokenId);
        nextTokenId++;
    }
}
