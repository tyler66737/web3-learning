const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("NFTAuctionV1", function() {
    let nftContract;
    let auctionContract;
    let seller;
    let bidders;
    let startPrice;
    let minBidIncrement;
    let auctionId;
    let currentBlock;
    let startTime;
    let endTime;

    // 辅助函数：创建拍卖
    async function createAuction() {
        await nftContract.connect(seller).approve(await auctionContract.getAddress(), 1);
        const tx = await auctionContract.connect(seller).createAction(
            await nftContract.getAddress(),
            1,
            startTime,
            endTime,
            startPrice,
            minBidIncrement
        );
        auctionId = 1;
        return tx;
    }

    // 辅助函数：等待拍卖开始
    async function waitForAuctionStart() {
        await ethers.provider.send("evm_increaseTime", [61]);
        await ethers.provider.send("evm_mine");
    }

    // 辅助函数：等待拍卖结束
    async function waitForAuctionEnd() {
        await ethers.provider.send("evm_increaseTime", [3661]);
        await ethers.provider.send("evm_mine");
    }

    beforeEach(async function() {
        [seller, ...bidders] = await ethers.getSigners();
        
        const MyNFT = await ethers.getContractFactory("MyNFT");
        nftContract = await MyNFT.deploy();
        
        const NFTAuctionV1 = await ethers.getContractFactory("NFTAuctionV1");
        auctionContract = await NFTAuctionV1.deploy();
        
        startPrice = ethers.parseEther("1.0");
        minBidIncrement = ethers.parseEther("0.1");
        
        await nftContract.mint(seller.address, 1);
        
        expect(await nftContract.getAddress()).to.be.properAddress;
        expect(await auctionContract.getAddress()).to.be.properAddress;

        // 设置拍卖时间
        currentBlock = await ethers.provider.getBlock("latest");
        startTime = currentBlock.timestamp + 60;
        endTime = startTime + 3600;
    });

    // 创建拍卖相关测试
    it("应该能够成功创建拍卖", async function() {
        const tx = await createAuction();
        await expect(tx)
        .to.emit(auctionContract, "AuctionCreated")
        .withArgs(1, seller.address, await nftContract.getAddress(), 1, startTime, endTime, startPrice, minBidIncrement);
        
        expect(await nftContract.ownerOf(1)).to.equal(await auctionContract.getAddress());

        // 查看合约详情
        const auction = await auctionContract.getAuction(auctionId);
        expect(auction.seller).to.equal(seller.address);
        expect(auction.nftContract).to.equal(await nftContract.getAddress());
        expect(auction.tokenId).to.equal(1);
        expect(auction.startTime).to.equal(startTime);
        expect(auction.endTime).to.equal(endTime);
        expect(auction.startPrice).to.equal(startPrice);
        expect(auction.minBidIncrement).to.equal(minBidIncrement);
        expect(auction.highestBidder).to.equal(ethers.ZeroAddress);
        expect(auction.highestBid).to.equal(0);
        expect(auction.ended).to.equal(false);
    });

    // 出价相关测试
    it("应该能够成功出价", async function() {
        await createAuction();
        await waitForAuctionStart();

        await expect(auctionContract.connect(bidders[0]).placeBid(auctionId, {
            value: startPrice
        }))
        .to.emit(auctionContract, "BidPlaced")
        .withArgs(auctionId, bidders[0].address, startPrice);
    });

    // 结束拍卖相关测试
    it("应该能够成功结束拍卖", async function() {
        await createAuction();
        await waitForAuctionStart();

        await auctionContract.connect(bidders[0]).placeBid(auctionId, {
            value: startPrice
        });

        await waitForAuctionEnd();

        await expect(auctionContract.connect(seller).endAuction(auctionId))
        .to.emit(auctionContract, "AuctionEnded")
        .withArgs(auctionId, bidders[0].address, startPrice);

        expect(await nftContract.ownerOf(1)).to.equal(bidders[0].address);
    });

    it("未被出价的拍卖在到期后可以结束", async function() {
        await createAuction();
        await waitForAuctionEnd();

        // 验证NFT在结束前属于拍卖合约
        expect(await nftContract.ownerOf(1)).to.equal(await auctionContract.getAddress());

        await expect(auctionContract.connect(seller).endAuction(auctionId))
        .to.emit(auctionContract, "AuctionEnded")
        .withArgs(auctionId, ethers.ZeroAddress, 0);

        expect(await nftContract.ownerOf(1)).to.equal(seller.address);
    });


    // 取消拍卖相关测试
    it("卖家应该能够取消没有出价的拍卖", async function() {
        await createAuction();
        // 验证NFT在结束前属于拍卖合约
        expect(await nftContract.ownerOf(1)).to.equal(await auctionContract.getAddress());
        await expect(auctionContract.connect(seller).cancelAuction(auctionId))
        .to.emit(auctionContract, "AuctionCanceled")
        .withArgs(auctionId);

        expect(await nftContract.ownerOf(1)).to.equal(seller.address);
    });

    it("非卖家不能取消拍卖", async function() {
        await createAuction();

        await expect(auctionContract.connect(bidders[0]).cancelAuction(auctionId))
        .to.be.revertedWith("Only the seller can cancel the auction");
    });

    it("有出价的拍卖不能取消", async function() {
        await createAuction();
        await waitForAuctionStart();

        await auctionContract.connect(bidders[0]).placeBid(auctionId, {
            value: startPrice
        });

        await expect(auctionContract.connect(seller).cancelAuction(auctionId))
        .to.be.revertedWith("There are bids on this auction");
    });

    // 提取待返还金额相关测试
    it("应该能够提取被超过的出价", async function() {
        await createAuction();
        await waitForAuctionStart();

        await auctionContract.connect(bidders[0]).placeBid(auctionId, {
            value: startPrice
        });

        await auctionContract.connect(bidders[1]).placeBid(auctionId, {
            value: startPrice + minBidIncrement
        });

        const pendingReturns = await auctionContract.getPendingReturns(auctionId, bidders[0].address);
        expect(pendingReturns).to.equal(startPrice);

        await expect(auctionContract.connect(bidders[0]).withdrawPendingReturns(auctionId))
        .to.emit(auctionContract, "WithdrawPendingReturns")
        .withArgs(auctionId, bidders[0].address, startPrice);
    });

    it("没有待返还金额时不能提取", async function() {
        await createAuction();

        await expect(auctionContract.connect(bidders[0]).withdrawPendingReturns(auctionId))
        .to.be.revertedWith("You have no pending returns");
    });
});
