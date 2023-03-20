// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { ERC721AUpgradeable, IERC721AUpgradeable } from "erc721a-upgradeable/contracts/ERC721AUpgradeable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract NFT721A is ERC721AUpgradeable, OwnableUpgradeable {
    uint256 public tokenPrice;
    uint256 public maxSupply;
    string public contractUri;
    string public baseTokenURI;
    address public feeAddress;

    function setFeeAddress(address _newFeeAddress) external onlyOwner {
        feeAddress = _newFeeAddress;
    }

    function setContractUri(string memory _newContractUri) external onlyOwner {
        contractUri = _newContractUri;
    }

    function setMaxSupply(uint256 _newSupply) external onlyOwner {
        maxSupply = _newSupply;
    }

    function setTokenPrice(uint256 _newPrice) external onlyOwner {
        tokenPrice = _newPrice;
    }

    /// Default functions
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function totalMinted() public view returns (uint256) {
        return _totalMinted();
    }

    // function _baseURI() internal view virtual override returns (string memory) {
    //     return baseTokenURI;
    // }

    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    function burn(uint256 tokenId, bool approvalCheck) public {
        _burn(tokenId, approvalCheck);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override (
        ERC721AUpgradeable
        ) returns (bool) {
        return interfaceId == type(IERC721AUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }
}