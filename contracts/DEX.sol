// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './DEX_internal.sol';

contract DEX is DEX_internal {

  constructor(uint16 _feePercent) DEX_internal(_feePercent) {
  }

  function getCurrentPrice(bytes32 _order) public view returns (uint256 price) {
    return _getCurrentPrice(_order);
  }

  function tokenOrderLength(IERC721 _token, uint256 _id) external view returns (uint256) {
    return orderIdByToken[_token][_id].length;
  }

  function sellerOrderLength(address _seller) external view returns (uint256) {
    return orderIdBySeller[_seller].length;
  }

  function makeAuctionOrder(IERC721 _token, uint256 _id, uint256 _startPrice, uint256 duration) external returns(bytes32 transactionId){
    uint256 _endTime = block.timestamp + duration;
    return _makeOrder(orderType.AUCTION, _token, _id, _startPrice, _endTime);
  } 

  function makeFixedPricOrder(IERC721 _token, uint256 _id, uint256 _price, uint256 duration) external returns(bytes32 transactionId){
    uint256 _endTime = block.timestamp + duration;
    return _makeOrder(orderType.FIXED, _token, _id, _price, _endTime);
  } 

  function bid(bytes32 _order) payable external {
    _bid(_order);
  }

  function buyItNow(bytes32 _order) payable external {
    _buyItNow(_order);
  }

  function claim(bytes32 _order) external {
    _claim(_order);
  }

  function cancelOrder(bytes32 _order) external {
    _cancelOrder(_order);
  }
}