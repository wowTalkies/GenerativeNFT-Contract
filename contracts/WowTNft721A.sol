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
    uint256 public tokenPrice;

    enum SaleStatus {
      Paused,
      Whitelist,
      Allowlist,
      Public
    }

    // Set Sale as PAUSED on DEPLOY
    SaleStatus public saleStatus;

    // struct used for whitelist
    struct Whitelists {
        uint256 whitelistLimit;
        uint256 whitelistAddressCount;
        uint256 maxWhiteListSupply;
        uint256 whitelistTokenSold;
    }

    // struct used for allowlist
    struct AllowLists {
        uint256 allowlistLimit;
        uint256 allowlistAddressCount;
        uint256 maxAllowListSupply;
        uint256 allowlistTokenSold;
    }

    // struct used for public
    struct PublicSales {
        uint256 publicWalletLimit;
        uint256 maxPublicSaleSupply;
        uint256 publicTokenSold;
    }

    Whitelists public whitelists;
    AllowLists public allowlists;
    PublicSales public publicSales;

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

    // set about the public person
    mapping(address => uint) public maxPublicWalletMints;

    event TokensSold(address market, uint256[] tokenIds, uint256 price, address buyer);
    event RevealStarted(address market, string newUri);

    modifier mintStatus {
        require(
            saleStatus != SaleStatus.Paused,
            "token is paused"
        );
        _;
    }

    function initialize(
        string memory name,
        string memory symbol,
        string memory _contractUri,
        string memory _preRevealURI,
        uint256 _maxSupply,
        address _feeAddress,
        uint64 _sSubscriptionId,
        address _vrfCoordinator,
        bytes32 _sKeyHash
    ) external initializerERC721A initializer {
        contractUri = _contractUri;
        preRevealURI = _preRevealURI;
        maxSupply = _maxSupply;
        feeAddress = _feeAddress;
        sKeyHash = _sKeyHash;
        callbackGasLimit = 100000;
        requestConfirmations = 3;
        numWords = 1;
        sSubscriptionId = _sSubscriptionId;
        saleStatus = SaleStatus.Paused;
        __ERC721A_init(name, symbol);
        __Ownable_init();
        __VRFConsumerBaseV2_init(_vrfCoordinator);
        coordinator = VRFCoordinatorV2Interface(_vrfCoordinator);
    }

    function buyToken(uint256 quantity) external payable mintStatus {
        if(saleStatus == SaleStatus.Whitelist) {
            whitelistBuyToken(quantity);
        }
        else if(saleStatus == SaleStatus.Allowlist) {
            allowlistBuyToken(quantity);
        }
        else if(saleStatus == SaleStatus.Public) {
            publicBuyToken(quantity);
        }
    }

    function whitelistBuyToken(uint256 quantity) internal {
        require(saleStatus == SaleStatus.Whitelist, "Whitelist sale not live");
        require(whitelist[_msgSender()], "You are not whitelisted");
        require(
            maxWhitelistWalletMints[_msgSender()] + quantity <= whitelists.whitelistLimit,
            "Maximum NFT's per wallet reached"
        );
        require(
            whitelists.whitelistTokenSold + quantity <= whitelists.maxWhiteListSupply,
            "Maximum whitelist supply reached"
        );
        uint256 txAmount = tokenPrice * quantity;  // txAmount
        require(msg.value == txAmount, "Not enough eth sent");
        uint256[] memory tokenIds = new uint256[](quantity);
        for (uint256 i = 0; i < quantity; i++) {
            tokenIds[i] = totalMinted() + i;
        }
        maxWhitelistWalletMints[_msgSender()] += quantity;
        whitelists.whitelistTokenSold += quantity;
        payable(feeAddress).transfer(txAmount);
        _safeMint(_msgSender(), quantity);
        emit TokensSold(address(this), tokenIds, tokenPrice, _msgSender());
    }

    function allowlistBuyToken(uint256 quantity) internal {
        require(saleStatus == SaleStatus.Allowlist, "Allowlist sale not live");
        require(allowlist[_msgSender()], "You are not allowlisted");
        require(
            maxAllowlistWalletMints[_msgSender()] + quantity <= allowlists.allowlistLimit,
            "Maximum NFT's per wallet reached"
        );
        require(
            allowlists.allowlistTokenSold + quantity <= allowlists.maxAllowListSupply,
            "Maximum allowlist supply reached"
        );
        uint256 txAmount = tokenPrice * quantity;
        require(msg.value == txAmount, "Not enough eth sent");
        uint256[] memory tokenIds = new uint256[](quantity);
        for (uint256 i = 0; i < quantity; i++) {
            tokenIds[i] = totalMinted() + i;
        }
        maxAllowlistWalletMints[_msgSender()] += quantity;
        allowlists.allowlistTokenSold += quantity;
        payable(feeAddress).transfer(txAmount);
        _safeMint(_msgSender(), quantity);
        emit TokensSold(address(this), tokenIds, tokenPrice, _msgSender());
    }

    function publicBuyToken(uint256 quantity) internal {
        require(saleStatus == SaleStatus.Public, "Public sale not live");
        require(totalMinted() + quantity <= publicSales.maxPublicSaleSupply, "Maximum supply reached");
        require(
            maxPublicWalletMints[_msgSender()] + quantity <= publicSales.publicWalletLimit,
            "Maximum NFT's per wallet reached"
        );
        uint256 txAmount = tokenPrice * quantity;
        require(msg.value == txAmount, "Not enough eth sent");
        uint256[] memory tokenIds = new uint256[](quantity);
        for (uint256 i = 0; i < quantity; i++) {
            tokenIds[i] = totalMinted() + i;
        }
        maxPublicWalletMints[_msgSender()] += quantity;
        publicSales.publicTokenSold += quantity;
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
        tokenPrice = _whitelistPrice;
        whitelists.maxWhiteListSupply = _maxwhiteListSupply;
        saleStatus = SaleStatus.Whitelist;
        whitelists.whitelistAddressCount += whitelistaddresses.length;
    }

    function setWhitelistPrice(uint256 _whitelistPrice) external onlyOwner {
        tokenPrice = _whitelistPrice;
    }

    function setMaxWhitelistSupply(uint256 _newMaxWhiteListSupply) external onlyOwner {
        whitelists.maxWhiteListSupply = _newMaxWhiteListSupply;
    }

    function findAddressInWhitelist(address user) external view returns (string memory) {
        if(whitelist[user]) {
            return "You are whitelisted";
        }
        else {
            return "You are not whitelisted";
        }
    }

    function findBalancedWhitelistMint(address user) external view returns (uint) {
        return (whitelists.whitelistLimit - maxWhitelistWalletMints[user]);
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
        tokenPrice = _allowlistPrice;
        allowlists.maxAllowListSupply = _maxAllowListSupply;
        saleStatus = SaleStatus.Allowlist;
        allowlists.allowlistAddressCount += allowlistaddresses.length;
    }

    function setAllowlistPrice(uint256 _allowlistPrice) external onlyOwner {
        tokenPrice = _allowlistPrice;
    }

    function setMaxAllowlistSupply(uint256 _newMaxAllowListSupply) external onlyOwner {
        allowlists.maxAllowListSupply = _newMaxAllowListSupply;
    }

    function findAddressInAllowlist(address user) external view returns (string memory) {
        if(allowlist[user]) {
            return "You are allowlisted";
        }
        else {
            return "You are not allowlisted";
        }
    }

    function findBalancedAllowlistMint(address user) external view returns (uint) {
        return (allowlists.allowlistLimit - maxAllowlistWalletMints[user]);
    }

    /*********** For public ********/

    function setPublicSale(uint256 _tokenPrice, uint256 _publicWalletLimit) external onlyOwner {
        tokenPrice = _tokenPrice;
        publicSales.publicWalletLimit = _publicWalletLimit;
        saleStatus = SaleStatus.Public;
        publicSales.maxPublicSaleSupply = maxSupply - (allowlists.allowlistTokenSold + whitelists.whitelistTokenSold);
    }

    function setPublicTokenPrice(uint256 _newPrice) external onlyOwner {
        tokenPrice = _newPrice;
    }

    function findBalancedPublicMint(address user) external view returns (uint) {
        return (publicSales.publicWalletLimit - maxPublicWalletMints[user]);
    }

    // Request Token Offset
    // NOTE: contract must be approved for and own LINK before calling this function
    function startReveal(string memory _newURI) external onlyOwner returns (uint256 requestId) {
        require(!revealed, "Already revealed");
        postRevealURI = _newURI;
        requestId = coordinator.requestRandomWords(
              sKeyHash,
              sSubscriptionId,
              requestConfirmations,
              callbackGasLimit,
              numWords
        );
        saleStatus = SaleStatus.Paused;
        emit RevealStarted(address(this), _newURI);
        return requestId;
    }

    // Chainlink callback for token offset

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
        ) internal override {
        require(!revealed, "Already revealed");
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
    // function setSaleStatus(SaleStatus _status) external onlyOwner {
    //     saleStatus = _status;
    // }

    // Sale State Function
    function setPreRevealURI(string memory _newPreRevealURI) external onlyOwner {
        preRevealURI = _newPreRevealURI;
    }
}