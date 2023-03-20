// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { NFT721A } from "./NFT721A.sol";
import { VRFCoordinatorV2Interface } from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import { VRFConsumerBaseV2Upgradeable } from "@chainlink/contracts/src/v0.8/dev/VRFConsumerBaseV2Upgradeable.sol";
import { StringsUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

// contract name will be changed later
contract WowTNft721A is NFT721A, VRFConsumerBaseV2Upgradeable {

    VRFCoordinatorV2Interface public coordinator;
    using StringsUpgradeable for uint256;

    enum SaleStatus {
      PAUSED,
      WHITELIST,
      ALLOWLIST,
      PUBLIC
    }

    // Set Sale as PAUSED on DEPLOY
    SaleStatus public saleStatus;

    // struct used for whitelist
    struct Whitelists {
        uint256 whitelistPrice;
        uint256 whitelistLimit;
        uint256 whitelistAddressCount;
        uint256 maxWhiteListSupply;
        uint256 whitelistTokenSold;
    }

    // struct used for allowlist
    struct AllowLists {
        uint256 allowlistPrice;
        uint256 allowlistLimit;
        uint256 allowlistAddressCount;
        uint256 maxAllowListSupply;
        uint256 allowlistTokenSold;
    }

    Whitelists public whitelists;
    AllowLists public allowlists;

    // Reveal
    string public preRevealURI;
    string public postRevealURI;
    bool public revealed;
    uint256 public tokenOffset;

    // Variable used for chainlink

    bytes32 public sKeyHash;
    uint64 private sSubscriptionId;
    uint32 public callbackGasLimit;
    uint16 public requestConfirmations;
    uint32 public numWords;

    // Set about the Whitelist Person
    mapping(address => bool) private whitelist;
    mapping(address => uint) public maxWhitelistWalletMints;

    // Set about the Allowlist Person
    mapping(address => bool) private allowlist;
    mapping(address => uint) public maxAllowlistWalletMints;

    event TokensSold(address market, uint256[] tokenIds, uint256 price, address buyer);
    event RevealStarted(address market, string newUri);

    modifier mintStatus {
        require(
            saleStatus != SaleStatus.PAUSED,
            "token is paused"
        );
        _;
    }

    function initialize(
        string memory name,
        string memory symbol,
        string memory _contractUri,
        string memory _preRevealURI,
        uint256 _tokenPrice,
        uint256 _maxSupply,
        address _feeAddress,
        uint64 _sSubscriptionId,
        address _vrfCoordinator,
        bytes32 _sKeyHash
    ) external initializerERC721A initializer {
        contractUri = _contractUri;
        preRevealURI = _preRevealURI;
        tokenPrice = _tokenPrice;
        maxSupply = _maxSupply;
        feeAddress = _feeAddress;
        sKeyHash = _sKeyHash;
        callbackGasLimit = 100000;
        requestConfirmations = 3;
        numWords = 1;
        sSubscriptionId = _sSubscriptionId;
        saleStatus = SaleStatus.PUBLIC;
        __ERC721A_init(name, symbol);
        __Ownable_init();
        __VRFConsumerBaseV2_init(_vrfCoordinator);
        coordinator = VRFCoordinatorV2Interface(_vrfCoordinator);
    }

    function buyToken(uint256 quantity) external payable mintStatus {
        if(saleStatus == SaleStatus.WHITELIST) {
            whitelistBuyToken(quantity);
        }
        else if(saleStatus == SaleStatus.ALLOWLIST) {
            allowlistBuyToken(quantity);
        }
        else if(saleStatus == SaleStatus.PUBLIC) {
            publicBuyToken(quantity);
        }
    }

    function whitelistBuyToken(uint256 quantity) internal {
        require(saleStatus == SaleStatus.WHITELIST, "Whitelist SALE NOT ACTIVE");
        require(whitelist[_msgSender()], "You are not whitelisted");
        require(
            maxWhitelistWalletMints[_msgSender()] + quantity <= whitelists.whitelistLimit,
            "Maximum NFT's per wallet reached"
        );
        require(
            whitelists.whitelistTokenSold + quantity <= whitelists.maxWhiteListSupply,
            "Maximum whitelist supply reached"
        );
        uint256 txAmount = whitelists.whitelistPrice * quantity;  // txAmount
        require(msg.value == txAmount, "Not enough eth sent");
        uint256[] memory tokenIds = new uint256[](quantity);
        for (uint256 i = 0; i < quantity; i++) {
            tokenIds[i] = totalMinted() + i + 1;
        }
        maxWhitelistWalletMints[_msgSender()] += quantity;
        whitelists.whitelistTokenSold += quantity;
        payable(feeAddress).transfer(txAmount);
        _safeMint(_msgSender(), quantity);
        emit TokensSold(address(this), tokenIds, whitelists.whitelistPrice, _msgSender());
    }

    function allowlistBuyToken(uint256 quantity) internal {
        require(saleStatus == SaleStatus.ALLOWLIST, "Allowlist SALE NOT ACTIVE");
        require(allowlist[_msgSender()], "You are not allowlisted");
        require(
            maxAllowlistWalletMints[_msgSender()] + quantity <= allowlists.allowlistLimit,
            "Maximum NFT's per wallet reached"
        );
        require(
            allowlists.allowlistTokenSold + quantity <= allowlists.maxAllowListSupply,
            "Maximum allowlist supply reached"
        );
        uint256 txAmount = allowlists.allowlistPrice * quantity;
        require(msg.value == txAmount, "Not enough eth sent");
        uint256[] memory tokenIds = new uint256[](quantity);
        for (uint256 i = 0; i < quantity; i++) {
            tokenIds[i] = totalMinted() + i + 1;
        }
        maxAllowlistWalletMints[_msgSender()] += quantity;
        allowlists.allowlistTokenSold += quantity;
        payable(feeAddress).transfer(txAmount);
        _safeMint(_msgSender(), quantity);
        emit TokensSold(address(this), tokenIds, allowlists.allowlistPrice, _msgSender());
    }

    function publicBuyToken(uint256 quantity) internal {
        require(saleStatus == SaleStatus.PUBLIC, "PUBLIC SALE NOT LIVE");
        require(totalMinted() + quantity <= maxSupply, "Maximum supply reached");
        uint256 txAmount = tokenPrice * quantity;
        require(msg.value == txAmount, "Not enough eth sent");
        uint256[] memory tokenIds = new uint256[](quantity);
        for (uint256 i = 0; i < quantity; i++) {
            tokenIds[i] = totalMinted() + i + 1;
        }
        payable(feeAddress).transfer(txAmount);
        _safeMint(_msgSender(), quantity);
        emit TokensSold(address(this), tokenIds, tokenPrice, _msgSender());
    }

    /********    For whitelist     **********/
    function setWhitelistAddress(
        address[] calldata whitelistaddresses,
        uint256 _whitelistLimit,
        uint256 _whitelistPrice,
        uint256 _maxwhiteListSupply
        ) external onlyOwner
    {
        for (uint16 i = 0; i < whitelistaddresses.length; i++) {
            whitelist[whitelistaddresses[i]] = true;
        }
        whitelists.whitelistLimit = _whitelistLimit;
        whitelists.whitelistPrice = _whitelistPrice;
        whitelists.maxWhiteListSupply = _maxwhiteListSupply;
        saleStatus = SaleStatus.WHITELIST;
        whitelists.whitelistAddressCount += whitelistaddresses.length;
    }

    function setWhitelistPrice(uint256 _whitelistPrice) external onlyOwner {
        whitelists.whitelistPrice = _whitelistPrice;
    }

    function setMaxWhitelistSupply(uint256 _newMaxWhiteListSupply) external onlyOwner {
        whitelists.maxWhiteListSupply = _newMaxWhiteListSupply;
    }

    function findAddressInWhitelist(address user) external view returns (bool) {
        return whitelist[user];
    }

    /**********    For allowlist      *********/
    function setAllowlistAddress(
        address[] calldata allowlistaddresses,
        uint256 _allowlistLimit,
        uint256 _allowlistPrice,
        uint256 _maxAllowListSupply
        ) external onlyOwner
    {
        for (uint16 i = 0; i < allowlistaddresses.length; i++) {
            allowlist[allowlistaddresses[i]] = true;
        }
        allowlists.allowlistLimit = _allowlistLimit;
        allowlists.allowlistPrice = _allowlistPrice;
        allowlists.maxAllowListSupply = _maxAllowListSupply + (
          whitelists.maxWhiteListSupply - whitelists.whitelistTokenSold
        );
        saleStatus = SaleStatus.ALLOWLIST;
        allowlists.allowlistAddressCount += allowlistaddresses.length;
    }

    function setAllowlistPrice(uint256 _allowlistPrice) external onlyOwner {
        allowlists.allowlistPrice = _allowlistPrice;
    }

    function setMaxAllowlistSupply(uint256 _newMaxAllowListSupply) external onlyOwner {
        allowlists.maxAllowListSupply = _newMaxAllowListSupply;
    }

    function findAddressInAllowlist(address user) external view returns (bool) {
        return allowlist[user];
    }

    // Request Token Offset
    // NOTE: contract must be approved for and own LINK before calling this function
    function startReveal(string memory _newURI) external onlyOwner returns (uint256 requestId) {
        require(!revealed, "ALREADY REVEALED");
        postRevealURI = _newURI;
        requestId = coordinator.requestRandomWords(
              sKeyHash,
              sSubscriptionId,
              requestConfirmations,
              callbackGasLimit,
              numWords
        );
        emit RevealStarted(address(this), _newURI);
        return requestId;
    }

    // CHAINLINK CALLBACK FOR TOKEN OFFSET

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
        ) internal override {
        require(!revealed, "ALREADY REVEALED");
        tokenOffset = (randomWords[0] % totalSupply()) + 1;
        revealed = true;
    }

    // Token URI
    // Before reveal, return same pre-reveal URI
    // After reveal, return post-reveal URI with random token offset from Chainlink
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        if (!revealed) return preRevealURI;
        uint256 shiftedTokenId = (_tokenId + tokenOffset) % totalSupply();
        return string(abi.encodePacked(postRevealURI, shiftedTokenId.toString()));
    }

    // Sale State Function
    function setSaleStatus(SaleStatus _status) external onlyOwner {
        saleStatus = _status;
    }

    // Sale State Function
    function setPreRevealURI(string memory _newPreRevealURI) external onlyOwner {
        preRevealURI = _newPreRevealURI;
    }
}