// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// NFT拍卖合约V2
contract NFTAuctionV2 is ERC721Holder, ReentrancyGuard, Ownable {
    // 拍卖信息
    address public nftContract;      // NFT合约地址
    uint256 public tokenId;          // NFT的TokenId
    address public seller;           // 卖家地址
    uint256 public startTime;        // 开始时间
    uint256 public endTime;          // 结束时间
    uint256 public startPrice;       // 起拍价
    uint256 public minBidIncrement;  // 最小加价幅度
    address public highestBidder;    // 最高出价者
    uint256 public highestBid;       // 最高出价
    bool public ended;               // 是否已结束

    // 工厂合约地址
    address public factory;

    // 待退还金额
    mapping(address => uint256) public pendingReturns;

    // 事件
    event AuctionInitialized(
        address indexed nftContract,
        uint256 indexed tokenId,
        address seller,
        uint256 startTime,
        uint256 endTime,
        uint256 startPrice,
        uint256 minBidIncrement
    );
    event BidPlaced(uint256 indexed auctionId, address indexed bidder, uint256 amount);
    event AuctionEnded(address indexed winner, uint256 amount);
    event AuctionCancelled();
    event WithdrawPendingReturns(address indexed bidder, uint256 amount);

    // 构造函数
    constructor() Ownable(msg.sender) {
        factory = msg.sender;
    }

    // 初始化拍卖
    function initialize(
        address nftContract_,
        uint256 tokenId_,
        uint256 startTime_,
        uint256 endTime_,
        uint256 startPrice_,
        uint256 minBidIncrement_
    ) external {
        require(msg.sender == factory, "Only factory can initialize");
        require(startTime_ > block.timestamp, "startTime must be greater than current time");
        require(endTime_ > startTime_, "endTime must be greater than startTime");
        require(startPrice_ > 0, "startPrice must be greater than 0");
        require(minBidIncrement_ > 0, "minBidIncrement must be greater than 0");

        nftContract = nftContract_;
        tokenId = tokenId_;
        seller = tx.origin;
        startTime = startTime_;
        endTime = endTime_;
        startPrice = startPrice_;
        minBidIncrement = minBidIncrement_;
        highestBidder = address(0);
        highestBid = 0;
        ended = false;

        emit AuctionInitialized(
            nftContract_,
            tokenId_,
            tx.origin,
            startTime_,
            endTime_,
            startPrice_,
            minBidIncrement_
        );
    }

    // 出价
    function placeBid() external payable nonReentrant {
        require(block.timestamp >= startTime, "Auction not started");
        require(block.timestamp <= endTime, "Auction ended");
        require(!ended, "Auction already ended");
        require(highestBidder != msg.sender, "You are already the highest bidder");
        require(msg.value > 0, "Bid must be greater than 0");

        if (highestBid == 0) {
            require(msg.value >= startPrice, "Bid must be greater than startPrice");
        } else {
            require(
                msg.value >= highestBid + minBidIncrement,
                "Bid must be greater than highestBid + minBidIncrement"
            );
        }

        // 记录之前的最高出价者待退还金额
        if (highestBidder != address(0)) {
            pendingReturns[highestBidder] += highestBid;
        }

        // 更新最高出价
        highestBidder = msg.sender;
        highestBid = msg.value;

        emit BidPlaced(tokenId, msg.sender, msg.value);
    }

    // 结束拍卖
    function endAuction() external nonReentrant {
        require(block.timestamp > endTime, "Auction not ended");
        require(!ended, "Auction already ended");

        ended = true;

        if (highestBidder != address(0)) {
            // 转移NFT给最高出价者
            IERC721(nftContract).safeTransferFrom(
                address(this),
                highestBidder,
                tokenId
            );

            // 转移ETH给卖家
            payable(seller).transfer(highestBid);

            emit AuctionEnded(highestBidder, highestBid);
        } else {
            // 如果没有出价，将NFT退还给卖家
            IERC721(nftContract).safeTransferFrom(
                address(this),
                seller,
                tokenId
            );

            emit AuctionCancelled();
        }
    }

    // 取消拍卖
    function cancelAuction() external nonReentrant {
        require(msg.sender == seller, "Only seller can cancel");
        require(!ended, "Auction already ended");
        require(highestBidder == address(0), "Cannot cancel auction with bids");

        ended = true;

        // 退还NFT给卖家
        IERC721(nftContract).safeTransferFrom(
            address(this),
            seller,
            tokenId
        );

        emit AuctionCancelled();
    }

    // 提取待退还的ETH
    function withdrawPendingReturns() external nonReentrant {
        uint256 amount = pendingReturns[msg.sender];
        require(amount > 0, "No pending returns");

        pendingReturns[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
        emit WithdrawPendingReturns(msg.sender, amount);
    }
} 