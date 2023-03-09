// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { NFT721A } from "./NFT721A.sol";
// import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import { VRFCoordinatorV2Interface } from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import { VRFConsumerBaseV2Upgradeable } from "@chainlink/contracts/src/v0.8/dev/VRFConsumerBaseV2Upgradeable.sol";

// contract name will be changed later
contract WowTNft721A is NFT721A, VRFConsumerBaseV2Upgradeable {

    VRFCoordinatorV2Interface public coordinator;  // coordinator

    error NoTokenIdAvailable();

    // uint256 private price;  // remove global var
    address[] public buyAddresses;  // buyAddresses
    bool public whitelisted;
    bool public allowlisted;
    bool public publiclisted;
    uint256 public totalTokenSold;

    // Variable used for chainlink

    bytes32 public sKeyHash; // sKeyHash
    uint64 private sSubscriptionId; // sSubscriptionId
    uint32 public callbackGasLimit;
    uint16 public requestConfirmations;
    uint32 public numWords;
    uint256[] public requestIds;

    // struct used for chainlink

    struct RequestStatus {
    bool fulfilled;
    bool exists;
    uint256[] randomWords;
    }

    struct TokenStatus {
        address buyer;
        bool exists;
    }

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
    mapping(uint256 => uint256[]) public randomWordsToRequestId;

    // mapping for chainlink
    mapping(uint256 => address) public requestIdToAddress; // mapping requestId to buyAddress
    mapping(uint256 => TokenStatus) public tokenIdToAddress; // mapping tokenId to buyAddress
    mapping(uint256 => RequestStatus) public requestIdToRequestStatus;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    // event capture here

    // 1 - mint

    /**
     * @dev Throws if called by any account other than admins.
    */

    function initialize(
        string memory name,
        string memory symbol,
        string memory _contractUri,
        uint256 _maxSupply,
        address _feeAddress,
        uint64 _sSubscriptionId,
        address _vrfCoordinator,
        bytes32 _sKeyHash
        ) public initializerERC721A initializer {
        contractUri = _contractUri;
        maxSupply = _maxSupply;
        feeAddress = _feeAddress;
        sKeyHash = _sKeyHash;
        callbackGasLimit = 100000;
        requestConfirmations = 3;
        numWords = 1;
        pausable = true;
        sSubscriptionId = _sSubscriptionId;
        __ERC721A_init(name, symbol);
        __VRFConsumerBaseV2_init(_vrfCoordinator);
        coordinator = VRFCoordinatorV2Interface(_vrfCoordinator);
        _grantRole(ADMIN_ROLE, _msgSender());
        _grantRole(MINTER_ROLE, _msgSender());
    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
        ) internal override {
        require(
            requestIdToRequestStatus[requestId].exists,
            "request not found"
        );
        requestIdToRequestStatus[requestId].fulfilled = true;
        requestIdToRequestStatus[requestId].randomWords = randomWords;        
    }

    function requestRandomness(uint256 from, uint256 to) public adminOnly returns (uint256 requestId) {

        for(uint256 i = from; i < to; i++) {
            requestId = coordinator.requestRandomWords(
            sKeyHash,
            sSubscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
            requestIdToRequestStatus[requestId].exists = true;
            requestIds.push(requestId);
            requestIdToAddress[requestId] = buyAddresses[i];
        }

         return requestId;
    }

    function getRandomTokenId(uint256 from, uint256 to, uint256 requestId)
        private
        view
        returns (uint256 randomTokenId)
    {
        uint256 diff = to - from;
        RequestStatus memory requestStatus = getRandomnessRequestState(
            requestId
        );
        require(requestStatus.fulfilled, "Request not fulfilled");
        uint256 randomWord = requestStatus.randomWords[0];
        uint256 randomTokenIdFirst = (randomWord % diff) + from; 
        uint256 stopValue = randomTokenIdFirst;
        if (tokenIdToAddress[randomTokenIdFirst].exists) {
            while (
                tokenIdToAddress[randomTokenIdFirst].exists &&
                randomTokenIdFirst < to - 1
            ) {
                randomTokenIdFirst = (randomTokenIdFirst + 1);
            }
            if (tokenIdToAddress[randomTokenIdFirst].exists) {
                randomTokenIdFirst = 0;
                while (
                    tokenIdToAddress[randomTokenIdFirst].exists &&
                    randomTokenIdFirst < stopValue
                ) {
                    randomTokenIdFirst = (randomTokenIdFirst + 1);
                }
                if (tokenIdToAddress[randomTokenIdFirst].exists) {
                    revert NoTokenIdAvailable();
                } else if (!(tokenIdToAddress[randomTokenIdFirst].exists)) {
                    randomTokenId = randomTokenIdFirst;
                }
            } else if (!(tokenIdToAddress[randomTokenIdFirst].exists)) {
                randomTokenId = randomTokenIdFirst;
            }
        } else if (!(tokenIdToAddress[randomTokenIdFirst].exists)) {
            randomTokenId = randomTokenIdFirst;
        }
    }

    function getRandomnessRequestState(uint256 requestId) public view returns (RequestStatus memory)
    {
        return requestIdToRequestStatus[requestId];
    }

    function generateTokenIds(uint256 from, uint256 to) public adminOnly {
        
        for (uint256 i = from; i < to; i++) {
           uint256 tokenid = getRandomTokenId(from, to, requestIds[i]); 
            tokenIdToAddress[tokenid].exists = true;
            tokenIdToAddress[tokenid].buyer = buyAddresses[i];
        }
    }

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
        uint256 txAmount = whitelists.whitelistPrice * quantity;  // txAmount
        require(msg.value == txAmount, "Not enough eth sent");
        for(uint i = 0; i < quantity; i++) {
            buyAddresses.push(_msgSender());
        }
        maxWhitelistWalletMints[_msgSender()] += quantity;
        whitelists.whitelistTokenSold += quantity;
        payable(feeAddress).transfer(txAmount);
    }

    function allowlistBuyToken(uint256 quantity) private whenMintable {
        require(allowlist[_msgSender()] && allowlisted, "You are not allowlisted");
        require(maxAllowlistWalletMints[_msgSender()] < allowlists.allowlistLimit, "Maximum NFT's per wallet reached");
        require(allowlists.allowlistTokenSold < allowlists.maxAllowListSupply, "Maximum allowlist supply reached");
        uint256 txAmount = allowlists.allowlistPrice * quantity;
        require(msg.value == txAmount, "Not enough eth sent");
        for(uint i = 0; i < quantity; i++) {
            buyAddresses.push(_msgSender());
        }
        maxAllowlistWalletMints[_msgSender()] += quantity;
        allowlists.allowlistTokenSold += quantity;
        payable(feeAddress).transfer(txAmount);
    }

    function publicBuyToken(uint256 quantity) private whenMintable {
        require(totalTokenSold < maxSupply, "Maximum supply reached");
        uint256 txAmount = tokenPrice * quantity;
        require(msg.value == txAmount, "Not enough eth sent");
        for(uint i = 0; i < quantity; i++) {
            buyAddresses.push(_msgSender());
        }
        totalTokenSold += quantity;
        payable(feeAddress).transfer(txAmount);
    }

    /* function mint() public adminOnly returns (uint256 requestId) {
        requestId = coordinator.requestRandomWords(
            sKeyHash,
            sSubscriptionId,
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
    } */

    function mint(uint256 from, uint256 to) public adminOnly {
        for (uint256 i = from; i < to; i++) {
            _safeMint(tokenIdToAddress[i].buyer, 1);
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
        allowlists.maxAllowListSupply = _maxAllowListSupply + (whitelists.maxWhiteListSupply - whitelists.whitelistTokenSold);
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
        maxSupply = maxSupply - (whitelists.whitelistTokenSold + allowlists.allowlistTokenSold);
    }

    function setTokenPrice(uint256 _newPrice) public adminOnly {
        tokenPrice = _newPrice;
    }

    //  For development use

    function getRandomWords(uint256 _requestId) public view returns (uint256[] memory)  {
       return requestIdToRequestStatus[_requestId].randomWords;
    }

    function getBuyerAddress() public view returns(address[] memory) {
        return buyAddresses;
    }

    function checkTokenId(uint256 _tokenId) public view returns (address) {
          return tokenIdToAddress[_tokenId].buyer;
    }

}