// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IERC721.sol";
import "../interfaces/IERC721Receiver.sol";

abstract contract NFT_internal is IERC721 {
    
    address payable internal _admin;

    mapping(uint256 => address) internal _owners;

    mapping(address => uint256) internal _balances;

    mapping(uint256 => address) internal _tokenApprovals;

    mapping(address => mapping(address => bool)) internal _operatorApprovals;

    mapping(uint256 => string) internal _tokenURI;

    string internal _baseURI;

    modifier onlyAdmin() {
        require(msg.sender == _admin, "only admin can do this");
        _;
    }

    function _approve(address _approved, uint256 _tokenId) internal {
        address owner = _owners[_tokenId];
        require(owner != _approved, "approval to current owner");
        require(
            // podzielic na dwa
            msg.sender == owner || this.isApprovedForAll(owner, _approved),
            "approve caller is not owner or appoved for all"
        );
        _tokenApprovals[_tokenId] = _approved;
        emit Approval(owner, _approved, _tokenId);
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
            returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
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

    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0), "mint to zero address");
        require(_owners[tokenId] == address(0), "token already minted");

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    function _getBaseURI() internal view returns (string memory) {
        return _baseURI;
    }

    function _setTokenURI(uint256 tokenId, string memory uri) internal {
        _tokenURI[tokenId] = uri;
    }

    function _getTokenURI(uint256 tokenId)
        internal
        view
        returns (string memory)
    {
        return string(abi.encodePacked(_getBaseURI(), _tokenURI[tokenId]));
    }

    function _burn(uint256 tokenId) internal {
        address owner = this.ownerOf(tokenId);
        this.approve(address(0), tokenId);
        _balances[owner] -= 1;
        delete _owners[tokenId];
    }
}
