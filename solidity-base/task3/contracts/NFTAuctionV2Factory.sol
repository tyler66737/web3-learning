// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./NFTAuctionV2.sol";

// 拍卖工厂合约
contract NFTAuctionV2Factory {
    // 所有创建的拍卖合约
    NFTAuctionV2[] public auctions;
    
    // NFT合约 => TokenId => 拍卖合约
    mapping(address => mapping(uint256 => address)) public getAuction;
    
    // 事件
    event AuctionCreated(
        address indexed nftContract,
        uint256 indexed tokenId,
        address auctionContract
    );

    // 创建拍卖
    function createAuction(
        address nftContract,
        uint256 tokenId,
        uint256 startTime,
        uint256 endTime,
        uint256 startPrice,
        uint256 minBidIncrement
    ) external returns (address auctionContract) {
        // 检查NFT所有权
        require(
            IERC721(nftContract).ownerOf(tokenId) == msg.sender,
            "Only owner of nft can create auction"
        );
        
        // 检查NFT是否已授权
        require(
            IERC721(nftContract).getApproved(tokenId) == address(this),
            "NFT not approved"
        );

        // 创建新的拍卖合约
        NFTAuctionV2 auction = new NFTAuctionV2();
        auctions.push(auction);
        
        // 记录拍卖合约地址
        getAuction[nftContract][tokenId] = address(auction);
        
        // 转移NFT到拍卖合约
        IERC721(nftContract).safeTransferFrom(msg.sender, address(auction), tokenId);
        
        // 初始化拍卖
        auction.initialize(
            nftContract,
            tokenId,
            startTime,
            endTime,
            startPrice,
            minBidIncrement
        );

        emit AuctionCreated(
            nftContract,
            tokenId,
            address(auction)
        );
        
        return address(auction);
    }

    // 获取所有拍卖合约数量
    function getAuctionsCount() external view returns (uint256) {
        return auctions.length;
    }

    // 获取所有拍卖合约
    function getAllAuctions() external view returns (NFTAuctionV2[] memory) {
        return auctions;
    }
} 