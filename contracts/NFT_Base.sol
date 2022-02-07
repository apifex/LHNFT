// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IERC721.sol";
import "./NFT_internal.sol";

abstract contract NFT_Base is IERC721, NFT_internal {
    function balanceOf(address _owner)
        external
        view
        override
        returns (uint256)
    {
        require(_owner != address(0), "Balance query for the zero address");
        return _balances[_owner];
    }

    function ownerOf(uint256 _tokenId)
        external
        view
        override
        returns (address)
    {
        address owner = _owners[_tokenId];
        require(owner != address(0), "Owner query for the zero address");
        return owner;
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory _data
    ) external override {
        require(
            _isOwnerOrApproved(msg.sender, _tokenId),
            "Transfer caller is not owner or approved"
        );
        require(
            _from == this.ownerOf(_tokenId),
            "transfer from incorrect owner"
        );
        require(_to != address(0), "transfer to zero address");
        _transfer(_from, _to, _tokenId);
        require(
            _checkOnERC721Received(_from, _to, _tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external override {
        require(
            _isOwnerOrApproved(msg.sender, _tokenId),
            "Transfer caller is not owner or approved"
        );
        require(
            _from == this.ownerOf(_tokenId),
            "transfer from incorrect owner"
        );
        require(_to != address(0), "transfer to zero address");
        _transfer(_from, _to, _tokenId);
        require(
            _checkOnERC721Received(_from, _to, _tokenId, ""),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external override {
        require(
            _isOwnerOrApproved(msg.sender, _tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
        _transfer(_from, _to, _tokenId);
    }

    function approve(address _approved, uint256 _tokenId) external override {
        address owner = _owners[_tokenId];
        require(owner != _approved, "approval to current owner");
        require(
            msg.sender == owner || this.isApprovedForAll(owner, _approved),
            "approve caller is not owner or appoved for all"
        );
        _tokenApprovals[_tokenId] = _approved;
        emit Approval(owner, _approved, _tokenId);
    }

    function setApprovalForAll(address _operator, bool _approved)
        external
        override
    {
        _setApprovalForAll(_operator, _approved);
    }

    function getApproved(uint256 _tokenId)
        external
        view
        override
        returns (address)
    {
        require(
            _owners[_tokenId] != address(0),
            "appoved query for nonexistent token"
        );
        return _tokenApprovals[_tokenId];
    }

    function isApprovedForAll(address _owner, address _operator)
        external
        view
        override
        returns (bool)
    {
        return _operatorApprovals[_owner][_operator];
    }
}
