// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./NFT_Base.sol";
import "./NFT_mint.sol";

contract NFT is NFT_Base, NFT_Mint {
    constructor(address payable admin, uint256 mintPrice, uint256 defaultRoyalty) {
        _admin = admin;
        _mintPrice = mintPrice;
        _defaultRoyalty = defaultRoyalty;
    }

    function setBaseURI(string memory baseUri) external onlyAdmin {
        _baseURI = baseUri;
    }

    function tokenUri(uint256 _tokenId) external view returns (string memory) {
        return _getTokenURI(_tokenId);
    }

    function setDefaultRoyalty(uint256 value) external onlyAdmin {
        require(value < 10000, "The royalty can't be 100% or more");
        _defaultRoyalty = value;
    }

    function getDefaultRoyalty() external view returns (uint256 defaultRoyalty) {
        return _defaultRoyalty;
    }

     function changeTokenRoyaly(
        uint256 tokenId,
        address receiver,
        uint256 value
    ) external onlyAdmin {
        _setTokenRoyalty(tokenId, receiver, value);
    }

    function burn(uint256 tokenId) external {
        _burn(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        external
        pure
        override
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC2981).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }
}
