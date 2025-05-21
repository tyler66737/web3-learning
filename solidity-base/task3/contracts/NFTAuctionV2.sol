// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
// 安装的1.4.0版本,发现接口目录变更
// import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol"; 

// NFT Auction Contract V2
contract NFTAuctionV2 is ERC721Holder, ReentrancyGuard, Ownable {
    // Auction Info
    address public nftContract;          // NFT合约地址
    uint256 public tokenId;              // NFT的TokenId
    address public seller;               // 卖家地址
    uint256 public startTime;            // 开始时间
    uint256 public endTime;              // 结束时间
    uint256 public startPrice;           // 起拍价（以ETH为单位）
    uint256 public minBidIncrement;      // 最小加价幅度（以ETH为单位）
    address public highestBidder;        // 最高出价者
    uint256 public highestBid;           // 最高出价（以支付代币为单位）
    uint256 public highestBidInEth;      // 最高出价（以ETH为单位）
    address public highestTokenAddress;  // 支付代币地址（address(0)表示ETH）
    bool public ended;                   // 是否已结束
    address public factory;              // 工厂合约地址
    // 价格源地址(合约地址->价格源地址)
    mapping(address => AggregatorV3Interface) public priceFeeds; 
    // 添加价格源管理员角色
    address public priceFeedAdmin;

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

    event BidPlaced(address indexed bidder, uint256 amount,address tokenAddress,uint256 bidInEth);
    event AuctionEnded(address indexed winner, uint256 amount);
    event AuctionCancelled();
    event PriceFeedUpdated(address indexed token, address indexed priceFeed);
    event PriceFeedRemoved(address indexed token);

    // 构造函数
    constructor() Ownable(tx.origin) {
        // 设置价格源管理员
        factory = msg.sender;
    }

    // 修改价格源设置函数
    function setPriceFeed(address tokenAddress, address priceFeedAddress) external {
        require(msg.sender == owner(), "Not authorized");
        require(tokenAddress != address(0), "Invalid token address");
        require(priceFeedAddress != address(0), "Invalid price feed address");
        
        // 验证价格源合约
        AggregatorV3Interface priceFeed = AggregatorV3Interface(priceFeedAddress);
        
        // 验证价格源合约是否实现了正确的接口
        try priceFeed.decimals() returns (uint8 decimals) {
            require(decimals > 0, "Invalid decimals");
        } catch {
            revert("Invalid price feed contract: decimals check failed");
        }

        // 验证价格源是否返回有效数据
        try priceFeed.latestRoundData() returns (
            uint80 ,
            int256 price,
            uint256,
            uint256 ,
            uint80
        ) {
            require(price > 0, "Invalid price feed: price must be positive");
        } catch {
            revert("Invalid price feed contract: latestRoundData check failed");
        }
        priceFeeds[tokenAddress] = priceFeed;
        emit PriceFeedUpdated(tokenAddress, priceFeedAddress);
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
    // 如果转入的代币地址为0,则认为是ETH出价
    // 如果转入的代币地址不为0,则认为是ERC20出价,并且会通过预言机获取对应的ETH价格
    // 最高价以转入时为准,不会因为市场行情波动而重新计算
    function placeBid(address tokenAddress,uint256 amount) external payable nonReentrant {
        require(block.timestamp >= startTime, "Auction not started");
        require(block.timestamp <= endTime, "Auction ended");
        require(!ended, "Auction already ended");
        require(highestBidder != msg.sender, "You are already the highest bidder");
        require(amount > 0, "Bid must be greater than 0");

        uint256 bidInEth;
        if (tokenAddress == address(0)) {
            require(msg.value == amount, "Incorrect ETH amount");
            bidInEth = amount;
        } else {
            // 检查价格源地址是否存在
            require(priceFeeds[tokenAddress] != AggregatorV3Interface(address(0)), "Price feed not set");
            require(msg.value == 0, "ETH not accepted");
            // 转换ERC20金额为ETH等值
            bidInEth = convertToEth(tokenAddress,amount);
        }

        if (highestBid == 0) {
            require(bidInEth >= startPrice, "Bid must be greater than startPrice");
        } else {
            require(
                bidInEth >= highestBid + minBidIncrement,
                "Bid must be greater than highestBid + minBidIncrement"
            );
        }
        if(tokenAddress != address(0)){
            // 检查权限
            require(IERC20(tokenAddress).allowance(msg.sender, address(this)) >= amount, "Insufficient allowance");
            // 转移ERC20代币
            IERC20(tokenAddress).transferFrom(msg.sender, address(this), amount);
        }

        // 退还之前金额
        backToken(highestTokenAddress,highestBid);

        // 更新最高出价
        highestBidder = msg.sender;
        highestBid = amount;
        highestTokenAddress = tokenAddress;

        emit BidPlaced(msg.sender, amount,tokenAddress,bidInEth);
    }


    // 结束拍卖
    function endAuction() external nonReentrant {
        require(block.timestamp > endTime, "Auction not ended");
        require(!ended, "Auction already ended");

        ended = true;

        if (highestBidder != address(0)) {
            // 转移NFT给最高出价者
            transferNFT(highestBidder);
            // 转移代币给卖家
            backToken(highestTokenAddress,highestBid);
            emit AuctionEnded(highestBidder, highestBid);
        } else {
            // 如果没有出价，将NFT退还给卖家
            transferNFT(seller);
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
        transferNFT(seller);
        emit AuctionCancelled();
    }

    function transferNFT(address to) internal {
        IERC721(nftContract).safeTransferFrom(
            address(this),
            to,
            tokenId
        );
    }


    // 退还ERC20代币
    function backToken(address tokenAddress,uint256 amount) internal {
        if(amount == 0){
            return;
        }
        if(tokenAddress == address(0)){
            payable(msg.sender).transfer(amount);
        }else{
            IERC20(tokenAddress).transfer(msg.sender, amount);
        }
    }

   // 获取当前价格（以ETH为单位）
    function getCurrentPrice(address tokenAddress) public view returns (uint256,uint8) {
        AggregatorV3Interface priceFeedContract = AggregatorV3Interface(priceFeeds[tokenAddress]);
        (, int256 price,,,) = priceFeedContract.latestRoundData();
        // 检查价格>0
        require(price > 0, "Price is not greater than 0");
        uint8 decimals = priceFeedContract.decimals();
        return (uint256(price),decimals);
    }

    // 将代币金额转换为ETH等值
    function convertToEth(address tokenAddress,uint256 tokenAmount) public view returns (uint256) {
        if (tokenAddress == address(0)) {
            return tokenAmount;
        }
        (uint256 price,uint8 decimals) = getCurrentPrice(tokenAddress);
        // 将代币金额转换为ETH等值
        return (tokenAmount * price) / 10 ** decimals;
    }

} 