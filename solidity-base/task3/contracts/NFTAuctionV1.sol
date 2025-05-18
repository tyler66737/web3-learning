// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";



// 拍卖合约
// 仅支持以太坊出价
// 不支持预言机,不支持可升级
contract NFTAuctionV1 is ReentrancyGuard,Ownable { 


    struct Auction {
        address nftContract;
        uint256 tokenId; 
        address payable seller; // 卖家

        uint256 startTime;
        uint256 endTime;
        uint256 startPrice;
        uint256 minBidIncrement;
        address highestBidder; // 最高出价者
        uint256 highestBid;    // 最高出价(以太坊)
        bool ended; // 是否结束
    }
    uint256 private _actionCounter;
    mapping(uint256 => Auction) private auctions;
    mapping(uint256 => mapping(address => uint256)) pendingReturns;

    event AuctionCreated(uint256 indexed auctionId,address indexed seller,address nftContract,uint256 indexed tokenId,uint256 startTime, uint256 endTime, uint256 startPrice, uint256 minBidIncrement);
    event BidPlaced(uint256 indexed auctionId,address indexed bidder,uint256 amount);
    event AuctionEnded(uint256 indexed auctionId,address indexed winner,uint256 amount);    
    event AuctionCanceled(uint256 indexed auctionId);
    event WithdrawPendingReturns(uint256 indexed auctionId,address indexed bidder,uint256 amount);


    constructor() Ownable(msg.sender) {
    }

    function createAction(address nftContract,uint256 tokenId, uint256 startTime, uint256 endTime, uint256 startPrice, uint256 minBidIncrement) public { 
        require(startTime > block.timestamp, "startTime must be greater than current time");
        require(endTime > startTime, "endTime must be greater than startTime");
        require(startPrice > 0, "startPrice must be greater than 0");
        require(minBidIncrement > 0, "minBidIncrement must be greater than 0");
        require(IERC721(nftContract).ownerOf(tokenId)== msg.sender, "Only owner of nft can create auction");

        require(IERC721(nftContract).getApproved(tokenId)==address(this), "NFT not approved");   

        _actionCounter++; 
        uint256 auctionId = _actionCounter;

        auctions[auctionId] = Auction({
            nftContract: nftContract,
            tokenId: tokenId,
            seller: payable(msg.sender),
            startPrice: startPrice,
            startTime: startTime,
            endTime: endTime,
            minBidIncrement: minBidIncrement,
            highestBid: 0,
            highestBidder: address(0),
            ended: false
        });
        // IERC721(nftContract).approve(address(this), tokenId);   
        IERC721(nftContract).safeTransferFrom(msg.sender, address(this), tokenId);
        emit AuctionCreated(auctionId,msg.sender, nftContract, tokenId, startTime,endTime,startPrice, minBidIncrement);
    }


    function placeBid(uint256 auctionId) public payable nonReentrant {  
        Auction storage auction = auctions[auctionId];
        require(auction.startTime <= block.timestamp, "Auction not started");   
        require(auction.endTime >= block.timestamp, "Auction ended");
        require(auction.highestBidder != msg.sender, "You are already the highest bidder");
        // 检查价格是否有效
        uint256 leastAmount ;
        if(auction.highestBid == 0){
            leastAmount = auction.startPrice;
        }else{
            leastAmount = auction.highestBid + auction.minBidIncrement;
            
        }
        require(msg.value >= leastAmount, "Bid is not high enough");

        if(auction.highestBid != 0){
            // 保留之前的投标数据到待返回
            pendingReturns[auctionId][auction.highestBidder] += auction.highestBid;
        }

        auction.highestBidder = msg.sender;
        auction.highestBid = msg.value;

        emit BidPlaced(auctionId, msg.sender, msg.value);
    }

    function endAuction(uint256 auctionId) public nonReentrant { 
        Auction storage auction = auctions[auctionId];
        require(block.timestamp >= auction.endTime, "Auction not ended");
        require(!auction.ended, "Auction already ended");

        require(msg.sender == auction.seller || msg.sender == owner(), "Not authorized");

        auction.ended = true;

        if (auction.highestBidder != address(0)) {
            // Transfer the token to the highest bidder
            IERC721(auction.nftContract).safeTransferFrom(address(this), auction.highestBidder, auction.tokenId);
            // Transfer the bid amount to the seller
            payable(auction.seller).transfer(auction.highestBid);
        } else {
            // If no bids were placed, transfer the token back to the seller
            IERC721(auction.nftContract).safeTransferFrom(address(this), auction.seller, auction.tokenId);
        }
        emit AuctionEnded(auctionId, auction.highestBidder,auction.highestBid);
    }

    // 取消拍卖,仅限卖家,并且没有出价
    function cancelAuction(uint256 auctionId) external nonReentrant{
        Auction storage auction = auctions[auctionId];
        require(auction.seller == msg.sender, "Only the seller can cancel the auction");
        require(!auction.ended, "The auction has already ended");
        require(auction.highestBidder == address(0), "There are bids on this auction"); 

        auction.ended = true;
        IERC721(auction.nftContract).safeTransferFrom(address(this), auction.seller, auction.tokenId);

        emit AuctionCanceled(auctionId);
    }


    function getAuction(uint256 auctionId) external view returns (Auction memory) {
        return auctions[auctionId];
    }

    function getPendingReturns(uint256 auctionId, address bidder) external view returns (uint256) {
        return pendingReturns[auctionId][bidder];
    }

    function withdrawPendingReturns(uint256 auctionId) external nonReentrant { 
        uint256 amount = pendingReturns[auctionId][msg.sender];
        require(amount > 0, "You have no pending returns");
        pendingReturns[auctionId][msg.sender] = 0;
        payable(msg.sender).transfer(amount);
        emit WithdrawPendingReturns(auctionId, msg.sender, amount);
    }

    // 接收ERC721代币,需要定义该方法
    function onERC721Received(address , address , uint256 , bytes calldata ) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

}