// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IERC721.sol";
import "../interfaces/IERC2981.sol";

contract DEX_internal {
    
    enum OrderType {
        AUCTION,
        FIXED,
        MIXED
    }

    enum OrderStatus {
        ACTIVE,
        SOLD,
        CANCELED,
        OVER
    }

    struct Order {
        OrderType orderType;
        OrderStatus status;
        address seller;
        IERC721 tokenContract;
        uint256 tokenId;
        uint256 startPrice;
        uint256 fixedPrice;
        uint256 startTime;
        uint256 endTime;
        uint256 lastBidPrice;
        address lastBidder;
    }

    struct RoyaltyInfo {
        address receiver;
        uint256 amount;
    }
 
    mapping(IERC721 => mapping(uint256 => bytes32)) public orderIdByToken;
    mapping(address => bytes32[]) public orderIdBySeller;
    mapping(bytes32 => Order) public orderInfo;

    address public admin;
    address public feeAddress;
    uint16 public feePercent;
    uint16 public royaltyFeePercent;

    event MakeOrder(
        IERC721 indexed tokenContract,
        uint256 tokenId,
        bytes32 indexed orderId,
        address seller
    );
    event CancelOrder(
        IERC721 indexed tokenContract,
        uint256 tokenId,
        bytes32 indexed orderId,
        address seller
    );
    event Bid(
        IERC721 indexed tokenContract,
        uint256 tokenId,
        bytes32 indexed orderId,
        address bidder,
        uint256 bidPrice
    );
    event Claim(
        IERC721 indexed tokenContract,
        uint256 tokenId,
        bytes32 indexed orderId,
        address seller,
        address taker,
        uint256 price
    );

    event TestEvent(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes _data
    );

    constructor(uint16 _feePercent, uint16 _royaltyFeePercent) {
        require(_feePercent <= 10000, "input value is more than 100%");
        admin = msg.sender;
        feeAddress = msg.sender;
        feePercent = _feePercent;
        royaltyFeePercent = _royaltyFeePercent;
    }

    function _getCurrentPrice(bytes32 _order)
        internal
        view
        returns (uint256 price)
    {
        require(_checkOrderStatus(_order) == OrderStatus.ACTIVE, "This order is over or canceled");
        Order memory order = orderInfo[_order];
        uint256 lastBidPrice = order.lastBidPrice;
        if (order.orderType == OrderType.FIXED) {
            return order.fixedPrice;
        } else if (order.orderType == OrderType.AUCTION) {
            return lastBidPrice == 0 ? order.startPrice : lastBidPrice;
        } else if (order.orderType == OrderType.MIXED) {
            return lastBidPrice == 0 ? order.startPrice : lastBidPrice;
        }
    }

    function _makeOrder(
        OrderType _orderType,
        IERC721 _tokenContract,
        uint256 _tokenId,
        uint256 _startPrice,
        uint256 _fixedPrice,
        uint256 _endTime
    ) internal returns (bytes32 orderID) {
        require(_endTime > block.timestamp, "Duration must be more than zero");
        require(_tokenContract.getApproved(_tokenId) == address(this) || 
                 _tokenContract.isApprovedForAll(_tokenContract.ownerOf(_tokenId), address(this)) == true, 
                 "DEX Contract must be approved to make transaction with this token ID");
        require(orderIdByToken[_tokenContract][_tokenId] == 0, "There is already an order for this token ID");
        orderID = _makeOrderID(_tokenContract, _tokenId, msg.sender);

        orderInfo[orderID] = Order(
            _orderType,
            OrderStatus.ACTIVE,
            msg.sender,
            _tokenContract,
            _tokenId,
            _startPrice,
            _fixedPrice,
            block.timestamp,
            _endTime,
            0,
            address(0)
        );
        
        orderIdByToken[_tokenContract][_tokenId] = orderID;
        orderIdBySeller[msg.sender].push(orderID);
        
        emit MakeOrder(_tokenContract, _tokenId, orderID, msg.sender);
        return orderID;
    }

    function _makeOrderID(
        IERC721 _tokenContract,
        uint256 _tokenId,
        address _seller
    ) internal view returns (bytes32) {
        return
            keccak256(abi.encodePacked(block.timestamp, _tokenContract, _tokenId, _seller));
    }

    function _checkOrderStatus(bytes32 _order) internal view returns(OrderStatus) {
        require(orderInfo[_order].seller != address(0), "This order does not existe");
        Order memory order = orderInfo[_order];
        if (order.endTime < block.timestamp) {
            order.status = OrderStatus.OVER;
            }
        return order.status;
    }

    //Bids must be at least 5% higher than the previous bid.
    //If someone bids in the last 5 minutes of an auction, the auction will automatically extend by 5 minutes.
    function _bid(bytes32 _order) internal {
        Order memory order = orderInfo[_order];
        uint256 endTime = order.endTime;
        uint256 lastBidPrice = order.lastBidPrice;
        address lastBidder = order.lastBidder;

        require(_checkOrderStatus(_order) == OrderStatus.ACTIVE, "This order is over or canceled");
        require(order.orderType != OrderType.FIXED, "Can not bid to this 'fixed price' order");
        require(order.seller != msg.sender, "Can not bid to your order");
        if (lastBidPrice != 0) {
            require(
                msg.value >= lastBidPrice + (lastBidPrice / 20),
                "Price is too low (min +5% required)"
            );
        } else {
            require(
                msg.value >= order.startPrice && msg.value > 0,
                "Price can't be less than 'start price'"
            );
        }

        if (block.timestamp > endTime - 5 minutes) {
            order.endTime += 5 minutes;
        }

        if (lastBidPrice != 0) {
            payable(lastBidder).transfer(lastBidPrice);
        }

        order.lastBidder = msg.sender;
        order.lastBidPrice = msg.value;

        emit Bid(order.tokenContract, order.tokenId, _order, msg.sender, msg.value);
    }

    function _buyItNow(bytes32 _order) internal {
        Order storage order = orderInfo[_order];
        require(_checkOrderStatus(_order) == OrderStatus.ACTIVE, "This order is over or canceled");
        require(order.orderType != OrderType.AUCTION, "It's an auction, you can't 'buy it now'");

        require(msg.value == order.fixedPrice, "Wrong price for 'Buy it now!'");

        order.status = OrderStatus.SOLD;
        
        RoyaltyInfo memory royalty = _checkRoyalties(address(order.tokenContract), order.tokenId, order.fixedPrice);
        
        uint256 fee = (order.fixedPrice * feePercent) / 10000;
        uint256 royaltyFee = (royalty.amount * royaltyFeePercent) / 10000;
        payable(order.seller).transfer(order.fixedPrice - fee - royalty.amount - royaltyFee);
        payable(feeAddress).transfer(fee + royaltyFee);
        payable(royalty.receiver).transfer(royalty.amount);
       
        order.tokenContract.safeTransferFrom(order.seller, msg.sender, order.tokenId);

        emit Claim(
            order.tokenContract,
            order.tokenId,
            _order,
            order.seller,
            msg.sender,
            order.fixedPrice
        );
    }

    function _claim(bytes32 _order) internal {
        Order storage order = orderInfo[_order];
        require(_checkOrderStatus(_order) == OrderStatus.OVER, "This order is not finish yet");
        require(order.orderType != OrderType.FIXED, "This order is not an auction");
        
        address seller = order.seller;
        address lastBidder = order.lastBidder;
        require(seller == msg.sender || lastBidder == msg.sender, "Access denied");
        

        order.status = OrderStatus.SOLD;

        IERC721 token = order.tokenContract;
        uint256 tokenId = order.tokenId;
        uint256 lastBidPrice = order.lastBidPrice;
        uint256 fee = (lastBidPrice * feePercent) / 10000;
        RoyaltyInfo memory royalty = _checkRoyalties(address(token), tokenId, lastBidPrice);
        uint256 royaltyFee = (royalty.amount * royaltyFeePercent) / 10000;

        payable(seller).transfer(lastBidPrice - fee - royalty.amount - royaltyFee);
        payable(feeAddress).transfer(fee + royaltyFee);
        payable(royalty.receiver).transfer(royalty.amount);

        token.safeTransferFrom(order.seller, lastBidder, tokenId);

        emit Claim(token, tokenId, _order, seller, lastBidder, lastBidPrice);
    }

  function _cancelOrder(bytes32 _order) internal {
        Order storage order = orderInfo[_order];
        require(_checkOrderStatus(_order) == OrderStatus.ACTIVE, "This order is not active");
        require(order.seller == msg.sender, "Access denied");
        require(order.lastBidPrice == 0, "Bidding exist");
        
        IERC721 token = order.tokenContract;
        uint256 tokenId = order.tokenId;

        order.status = OrderStatus.CANCELED;

        emit CancelOrder(token, tokenId, _order, msg.sender);
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can do this");
        _;
    }

    function changeAdmin(address _newAdmin) external onlyAdmin {
        admin = _newAdmin;
    }

    function setFeeAddress(address _feeAddress) external onlyAdmin {
        feeAddress = _feeAddress;
    }

    function updateFeePercent(uint16 _percent) external onlyAdmin {
        require(_percent <= 10000, "input value is more than 100%");
        feePercent = _percent;
    }

    function _checkRoyalties(address tokenContract, uint256 tokenId, uint256 transactionAmount) internal view returns(RoyaltyInfo memory royalty){
        (address receiver, uint256 amount) = IERC2981(tokenContract).royaltyInfo(tokenId, transactionAmount);
        royalty.receiver = receiver;
        royalty.amount = amount;
        return royalty;
    }

    event Received(address sender, uint256 value);

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}
