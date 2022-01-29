// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IERC721.sol";

contract DEX_internal {
    
    enum orderType {
        AUCTION,
        FIXED
    }

    struct Order {
        orderType orderType;
        address seller;
        IERC721 token;
        uint256 tokenId;
        uint256 startPrice;
        uint256 startTime;
        uint256 endTime;
        uint256 lastBidPrice;
        address lastBidder;
        bool isSold;
    }

    mapping(IERC721 => mapping(uint256 => bytes32[])) public orderIdByToken;
    mapping(address => bytes32[]) public orderIdBySeller;
    mapping(bytes32 => Order) public orderInfo;

    address public admin;
    address public feeAddress;
    uint16 public feePercent;

    event MakeOrder(
        IERC721 indexed token,
        uint256 id,
        bytes32 indexed hash,
        address seller
    );
    event CancelOrder(
        IERC721 indexed token,
        uint256 id,
        bytes32 indexed hash,
        address seller
    );
    event Bid(
        IERC721 indexed token,
        uint256 id,
        bytes32 indexed hash,
        address bidder,
        uint256 bidPrice
    );
    event Claim(
        IERC721 indexed token,
        uint256 id,
        bytes32 indexed hash,
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

    constructor(uint16 _feePercent) {
        require(_feePercent <= 10000, "input value is more than 100%");
        admin = msg.sender;
        feeAddress = msg.sender;
        feePercent = _feePercent;
    }

    function _getCurrentPrice(bytes32 _order)
        internal
        view
        returns (uint256 price)
    {
        Order memory o = orderInfo[_order];
        if (o.orderType == orderType.FIXED) {
            return o.startPrice;
        } else if (o.orderType == orderType.AUCTION) {
            uint256 lastBidPrice = o.lastBidPrice;
            return lastBidPrice == 0 ? o.startPrice : lastBidPrice;
        }
    }

    function _makeOrder(
        orderType _orderType,
        IERC721 _token,
        uint256 _id,
        uint256 _startPrice,
        uint256 _endTime
    ) internal returns (bytes32 transactionID) {
        require(_endTime > block.timestamp, "Duration must be more than zero");

        bytes32 hash = _hash(_token, _id, msg.sender);
        orderInfo[hash] = Order(
            _orderType,
            msg.sender,
            _token,
            _id,
            _startPrice,
            block.timestamp,
            _endTime,
            0,
            address(0),
            false
        );
        orderIdByToken[_token][_id].push(hash);
        orderIdBySeller[msg.sender].push(hash);
// dla bida zmienic mechanizm 
        _token.safeTransferFrom(msg.sender, address(this), _id);

        emit MakeOrder(_token, _id, hash, msg.sender);
        return hash;
    }

    function _hash(
        IERC721 _token,
        uint256 _id,
        address _seller
    ) internal view returns (bytes32) {
        return
            keccak256(abi.encodePacked(block.timestamp, _token, _id, _seller));
    }
// poszukac interwal ///

    //Bids must be at least 5% higher than the previous bid.
    //If someone bids in the last 5 minutes of an auction, the auction will automatically extend by 5 minutes.
    function _bid(bytes32 _order) internal {
        Order storage o = orderInfo[_order];
        uint256 endTime = o.endTime;
        uint256 lastBidPrice = o.lastBidPrice;
        address lastBidder = o.lastBidder;

        require(o.orderType == orderType.AUCTION, "only for Auction");
        require(endTime != 0, "Canceled order");
        require(endTime >= block.timestamp, "It's over");
        // powinien sie usuwac
        require(o.seller != msg.sender, "Can not bid to your order");

        if (lastBidPrice != 0) {
            require(
                msg.value >= lastBidPrice + (lastBidPrice / 20),
                "low price bid"
            ); //5%
        } else {
            require(
                msg.value >= o.startPrice && msg.value > 0,
                "low price bid"
            );
        }

        if (block.timestamp > endTime - 5 minutes) {
            o.endTime += 5 minutes;
        }

        o.lastBidder = msg.sender;
        o.lastBidPrice = msg.value;

        if (lastBidPrice != 0) {
            payable(lastBidder).transfer(lastBidPrice);
        }

        emit Bid(o.token, o.tokenId, _order, msg.sender, msg.value);
    }

    function _buyItNow(bytes32 _order) internal {
        Order storage o = orderInfo[_order];
        uint256 endTime = o.endTime;
        require(endTime != 0, "Canceled order");
        require(endTime > block.timestamp, "It's over");
        require(o.orderType == orderType.AUCTION, "It's an auction");
        require(o.isSold == false, "Already sold");

        uint256 currentPrice = _getCurrentPrice(_order);
        require(msg.value >= currentPrice, "price error");

        o.isSold = true;

        uint256 fee = (currentPrice * feePercent) / 10000;
        payable(o.seller).transfer(currentPrice - fee);
        payable(feeAddress).transfer(fee);
        if (msg.value > currentPrice) {
            payable(msg.sender).transfer(msg.value - currentPrice);
        }

        o.token.safeTransferFrom(address(this), msg.sender, o.tokenId);

        emit Claim(
            o.token,
            o.tokenId,
            _order,
            o.seller,
            msg.sender,
            currentPrice
        );
    }

    function _claim(bytes32 _order) internal {
        Order storage o = orderInfo[_order];
        address seller = o.seller;
        address lastBidder = o.lastBidder;
        require(o.isSold == false, "Already sold");

        require(
            seller == msg.sender || lastBidder == msg.sender,
            "Access denied"
        );
        require(
            o.orderType == orderType.AUCTION,
            "This function is an Auction"
        );
        require(block.number > o.endTime, "Not yet");

        IERC721 token = o.token;
        uint256 tokenId = o.tokenId;
        uint256 lastBidPrice = o.lastBidPrice;

        uint256 fee = (lastBidPrice * feePercent) / 10000;

        o.isSold = true;

        payable(seller).transfer(lastBidPrice - fee);
        payable(feeAddress).transfer(fee);
        token.safeTransferFrom(address(this), lastBidder, tokenId);

        emit Claim(token, tokenId, _order, seller, lastBidder, lastBidPrice);
    }

    function _cancelOrder(bytes32 _order) internal {
        Order storage o = orderInfo[_order];
        require(o.seller == msg.sender, "Access denied");
        require(o.lastBidPrice == 0, "Bidding exist");
        require(o.isSold == false, "Already sold");

        IERC721 token = o.token;
        uint256 tokenId = o.tokenId;

        o.endTime = 0; //0 means the order was canceled.

        token.safeTransferFrom(address(this), msg.sender, tokenId);
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

    event Received(address, uint256);

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

//TODO 
    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes calldata _data
    ) external returns (bytes4) {
        emit TestEvent(_operator, _from, _tokenId, _data);
        return
            bytes4(
                keccak256("onERC721Received(address,address,uint256,bytes)")
            );
    }
}
