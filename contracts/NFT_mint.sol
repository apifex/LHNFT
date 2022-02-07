// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./NFT_internal.sol";
import "./NFT_Royalties.sol";

// mintingu po tokenie -> token jajko pozwala wymintowac kure
// royalties -> 1eth -> 10%
// cechy unikatowosci

abstract contract NFT_Mint is NFT_internal, NFT_Royalties {
    //classic mint
    function safeMint(
        address to,
        uint256 tokenId,
        string memory uri,
        uint256 royalties
    ) external onlyAdmin {
        _mint(to, tokenId);
        _setTokenURI(tokenId, uri, true);
        _setTokenRoyalty(tokenId, to, royalties);
        require(_checkOnERC721Received(address(0), to, tokenId, ""));
    }

    function mintMultiple(
        address[] memory to,
        uint256[] memory tokenId,
        string[] memory uri,
        uint256[] memory royalties
    ) external onlyAdmin {
        for (uint256 i = 0; i < to.length; i++) {
            _mint(to[i], tokenId[i]);
            _setTokenURI(tokenId[i], uri[i], true);
            _setTokenRoyalty(tokenId[i], to[i], royalties[i]);
            require(_checkOnERC721Received(address(0), to[i], tokenId[i], ""));
        }
    }

    // external mint (with default royalties to msg.sender)
    function getMintPrice() external view returns (uint256 price) {
        return _mintPrice;
    }

    function setMintPrice(uint256 price) external onlyAdmin {
        _mintPrice = price;
    }

    function mintYourToken(string memory uri) external payable {
        require(msg.value == _mintPrice, "Not enough value for mint token.");
        uint256 tokenId = _createTokenId();
        _mint(msg.sender, tokenId);
        _setTokenURI(tokenId, uri, false);
        _setTokenRoyalty(tokenId, msg.sender, _defaultRoyalty);
    }

    // conditional mint
    function setRequiredForMintToken(IERC721 nftContract, uint256 tokenId)
        external
        onlyAdmin
    {
        requiredMintTokens[nftContract][tokenId] = true;
    }

    function _mintIfHaveToken(
        address to,
        IERC721 nftContract,
        uint256 _tokenId,
        string memory uri
    ) external payable {
        require(msg.value == _mintPrice, "Not enough value for mint token.");
        require(
            requiredMintTokens[nftContract][_tokenId],
            "This token does not allow to mint here"
        );
        require(
            nftContract.ownerOf(_tokenId) == to,
            "You have to be owner of required token"
        );
        uint256 newTokenId = _createTokenId();
        _mint(to, newTokenId);
        _setTokenURI(newTokenId, uri, false);
        _setTokenRoyalty(newTokenId, msg.sender, _defaultRoyalty);
    }

    //mint core
    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0), "mint to zero address");
        require(_owners[tokenId] == address(0), "token already minted");

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }
}
