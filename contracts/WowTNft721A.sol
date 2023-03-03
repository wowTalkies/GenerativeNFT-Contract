// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./NFT721A.sol";
// import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/dev/VRFConsumerBaseV2Upgradeable.sol";

contract WowTNft721A is NFT721A, VRFConsumerBaseV2Upgradeable {

    VRFCoordinatorV2Interface private COORDINATOR;

    uint256 private price;
    address[] private buyAddresses;  // buyAddresses
    bool public whitelisted;
    bool public allowlisted;
    uint256 public totalTokenSold;

    // Variable used for chainlink

    bytes32 private s_keyHash;
    uint64 private s_subscriptionId;
    uint32 private callbackGasLimit;
    uint16 private requestConfirmations;
    uint32 private numWords;

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

    // Set about the Whitelist Person
    mapping(address => bool) public whitelist;
    mapping(address => uint) public maxWhitelistWalletMints;

    // Set about the Allowlist Person
    mapping(address => bool) public allowlist;
    mapping(address => uint) public maxAllowlistWalletMints;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /**
     * @dev Throws if called by any account other than admins.
    */

    function initialize(
        string memory name,
        string memory symbol,
        string memory _contractUri,
        uint256 _maxSupply,
        address _feeAddress,
        uint64 _s_subscriptionId,
        address _vrfCoordinator,
        bytes32 _s_keyHash
        ) public initializerERC721A initializer {
        contractUri = _contractUri;
        maxSupply = _maxSupply;
        feeAddress = _feeAddress;
        s_keyHash = _s_keyHash;
        callbackGasLimit = 100000;
        requestConfirmations = 3;
        numWords = 1;
        pausable = true;
        s_subscriptionId = _s_subscriptionId;
        __ERC721A_init(name, symbol);
        __VRFConsumerBaseV2_init(_vrfCoordinator);
        COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
        _grantRole(ADMIN_ROLE, _msgSender());
        _grantRole(MINTER_ROLE, _msgSender());
    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {}

    /********** Buy token and mint functions     *******/

    function buyToken(uint256 quantity) public payable {
        if(whitelist[_msgSender()] && whitelisted) {
            whitelistBuyToken(quantity);
        }
        else if(allowlist[_msgSender()] && allowlisted) {
            allowlistBuyToken(quantity);
        }
        else {
            publicBuyToken(quantity);
        }
    }

    function whitelistBuyToken(uint256 quantity) private whenMintable {
        require(whitelist[_msgSender()] && whitelisted, "You are not whitelisted");
        require(maxWhitelistWalletMints[_msgSender()] < whitelists.whitelistLimit, "Maximum NFT's per wallet reached");
        require(whitelists.whitelistTokenSold < whitelists.maxWhiteListSupply, "Maximum whitelist supply reached");
        price = whitelists.whitelistPrice * quantity;
        require(msg.value == price, "Not enough eth sent");
        for(uint i = 0; i < quantity; i++) {
            buyAddresses.push(_msgSender());
        }
        maxWhitelistWalletMints[_msgSender()] += quantity;
        whitelists.whitelistTokenSold += quantity;
        payable(feeAddress).transfer(price);
    }

    function allowlistBuyToken(uint256 quantity) private whenMintable {
        require(allowlist[_msgSender()] && allowlisted, "You are not allowlisted");
        require(maxAllowlistWalletMints[_msgSender()] < allowlists.allowlistLimit, "Maximum NFT's per wallet reached");
        require(allowlists.allowlistTokenSold < allowlists.maxAllowListSupply, "Maximum allowlist supply reached");
        price = allowlists.allowlistPrice * quantity;
        require(msg.value == price, "Not enough eth sent");
        for(uint i = 0; i < quantity; i++) {
            buyAddresses.push(_msgSender());
        }
        maxAllowlistWalletMints[_msgSender()] += quantity;
        allowlists.allowlistTokenSold += quantity;
        payable(feeAddress).transfer(price);
    }

    function publicBuyToken(uint256 quantity) private whenMintable {
        require(totalTokenSold < maxSupply, "Maximum supply reached");
        price = tokenPrice * quantity;
        require(msg.value == price, "Not enough eth sent");
        for(uint i = 0; i < quantity; i++) {
            buyAddresses.push(_msgSender());
        }
        totalTokenSold += quantity;
        payable(feeAddress).transfer(price);
    }

    function mint() public adminOnly returns (uint256 requestId) {
        requestId = COORDINATOR.requestRandomWords(
            s_keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
        uint256 mintLength = buyAddresses.length;
        require(mintLength > 0, "No address need to mint");
        for (uint i = 0; i < mintLength; i++) {
            uint256 randomIndex = requestId % (buyAddresses.length);
            address resultNumber = buyAddresses[randomIndex];
            buyAddresses[randomIndex] = buyAddresses[buyAddresses.length - 1];
            buyAddresses.pop();
            _safeMint(resultNumber, 1);
        }
    }

    /********    For whitelist     **********/

    function setWhitelistAddress(
        address[] calldata whitelistaddresses,
        uint256 _whitelistLimit,
        uint256 _whitelistPrice,
        uint256 _maxwhiteListSupply
        ) public adminOnly
    {
        for (uint16 i = 0; i < whitelistaddresses.length; i++) {
            whitelist[whitelistaddresses[i]] = true;
            whitelists.whitelistLimit = _whitelistLimit;
        }
        whitelists.whitelistPrice = _whitelistPrice;
        whitelists.maxWhiteListSupply = _maxwhiteListSupply;
        whitelisted = true;
        whitelists.whitelistAddressCount += whitelistaddresses.length;
    }

    function setWhitelistPrice(uint256 _whitelistPrice) public adminOnly {
        whitelists.whitelistPrice = _whitelistPrice;
    }

    function setMaxWhitelistSupply(uint256 _newMaxWhiteListSupply) public adminOnly {
        whitelists.maxWhiteListSupply = _newMaxWhiteListSupply;
    }

    function findAddressInWhitelist(address user) public view returns (bool) {
        return whitelist[user];
    }

    function totalWhitelistTokenSold() public view returns (uint) {
        return whitelists.whitelistTokenSold;
    }

    /**********    For allowlist      *********/

    function setAllowlistAddress(
        address[] calldata allowlistaddresses,
        uint256 _allowlistLimit,
        uint256 _allowlistPrice,
        uint256 _maxAllowListSupply
        ) public adminOnly
    {
        for (uint16 i = 0; i < allowlistaddresses.length; i++) {
            allowlist[allowlistaddresses[i]] = true;
            allowlists.allowlistLimit = _allowlistLimit;
        }
        allowlists.allowlistPrice = _allowlistPrice;
        allowlists.maxAllowListSupply = _maxAllowListSupply;
        whitelisted = false;
        allowlisted = true;
        allowlists.allowlistAddressCount += allowlistaddresses.length;
    }

    function setAllowlistPrice(uint256 _allowlistPrice) public adminOnly {
        allowlists.allowlistPrice = _allowlistPrice;
    }

    function setMaxAllowlistSupply(uint256 _newMaxAllowListSupply) public adminOnly {
        allowlists.maxAllowListSupply = _newMaxAllowListSupply;
    }

    function findAddressInAllowlist(address user) public view returns (bool) {
        return allowlist[user];
    }

    function totalAllowlistTokenSold() public view returns (uint) {
        return allowlists.allowlistTokenSold;
    }

    /*********    For public mint    *********/

    function setPublicMint(uint256 _tokenPrice) public adminOnly {
        tokenPrice = _tokenPrice;
        allowlisted = false;
    }

    function setTokenPrice(uint256 _newPrice) public adminOnly {
        tokenPrice = _newPrice;
    }

}