// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "erc721a-upgradeable/contracts/ERC721AUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

contract NFT721A is ERC721AUpgradeable, AccessControlUpgradeable {
    uint256 public tokenPrice;
    uint256 public maxSupply;
    string public contractUri;
    string public baseTokenURI;
    address public feeAddress;
    bool public pausable; // pausable

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    /**
     * @dev Throws if called by any account other than admins.
    */

    modifier adminOnly() {
        require(
            hasRole(ADMIN_ROLE, _msgSender()),
            "#adminOnly: Must have admin role"
        );
        _;
    }

    modifier whenMintable() {
        require(pausable, "Not mintable");
        _;
    }

    function setMintable(bool _mintStatus) public adminOnly {
        pausable = _mintStatus;
    }

    function setFeeAddress(address _newFeeAddress) public adminOnly {
        feeAddress = _newFeeAddress;
    }

    function setBaseURI(string memory _newBaseURI) private adminOnly {
        baseTokenURI = _newBaseURI;
    }

    function setMaxSupply(uint256 _newSupply) public adminOnly {
        maxSupply = _newSupply;
    }

    function totalMinted() public view returns (uint256) {
        return _totalMinted();
    }

    function baseURI() internal view virtual returns (string memory) {
        return baseTokenURI;
    }

    function contractURI() public view returns (string memory) {
        return contractUri;
    }

    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    function burn(uint256 tokenId, bool approvalCheck) public {
        _burn(tokenId, approvalCheck);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override (
        ERC721AUpgradeable, AccessControlUpgradeable
        ) returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }
}