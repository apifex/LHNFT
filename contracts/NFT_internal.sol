// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IERC721.sol";
import "../interfaces/IERC721Receiver.sol";

abstract contract NFT_internal is IERC721{
    
    address payable internal _admin;

    mapping(uint256 => address) internal _owners;

    mapping(address => uint256) internal _balances;

    mapping(uint256 => address) internal _tokenApprovals;

    mapping(address => mapping(address => bool)) internal _operatorApprovals;

    struct TokenUri {
        string uri;
        bool useBase;
    }

    mapping(uint256 => TokenUri) internal _tokenURI;

    mapping(IERC721 => mapping(uint=> bool)) internal requiredMintTokens; 

    string internal _baseURI;

    uint256 internal actualTokenId;

    uint256 internal _mintPrice;

    uint256 internal _defaultRoyalty;

    

    modifier onlyAdmin() {
        require(msg.sender == _admin, "only admin can do this");
        _;
    }


    function _setApprovalForAll(address _operator, bool _approved) internal {
        address owner = msg.sender;
        require(owner != _operator, "approve to caller");
        _operatorApprovals[owner][_operator] = _approved;
        emit ApprovalForAll(owner, _operator, _approved);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal {
        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function _isOwnerOrApproved(address spender, uint256 tokenId)
        internal
        view
        returns (bool)
    {
        address owner = this.ownerOf(tokenId);
        return (spender == owner ||
            spender == this.getApproved(tokenId) ||
            this.isApprovedForAll(owner, spender));
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal returns (bool) {
        if (to.code.length > 0) {
            try
                IERC721Receiver(to).onERC721Received(
                    msg.sender,
                    from,
                    tokenId,
                    _data
                )
            returns (bytes4 response) {
                return response == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert(
                        "ERC721: transfer to non ERC721Receiver implementer"
                    );
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    function _checkIfExists(uint256 tokenId) internal view returns(bool) {
        return _owners[tokenId] != address(0);
    }

    function _createTokenId() internal returns (uint256 tokenId) {
        while (_checkIfExists(actualTokenId)) {
            actualTokenId++;    
        }
        return actualTokenId;
    }

    function _getBaseURI() internal view returns (string memory) {
        return _baseURI;
    }

    function _setTokenURI(uint256 tokenId, string memory uri, bool useBase) internal {
        _tokenURI[tokenId] = TokenUri(uri, useBase);
    }

    function _getTokenURI(uint256 tokenId)
        internal
        view
        returns (string memory)
    {
        TokenUri memory tokenUri = _tokenURI[tokenId];
        if (tokenUri.useBase) {
            return string(abi.encodePacked(_getBaseURI(), tokenUri.uri));
        } else {
            return tokenUri.uri;
        }
        
    }

    function _burn(uint256 tokenId) internal {
        address owner = this.ownerOf(tokenId);
        require(msg.sender == owner, "Only owner can burn token");
        this.approve(address(0), tokenId);
        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }
}
