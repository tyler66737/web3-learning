const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("NFTAuctionV2", function () {
    let nft;
    let auction;
    let factory;
    let seller;
    let bidder1;
    let bidder2;
    let currentBlock;
    let user1;
    let user2;

    beforeEach(async function () {
        // 部署NFT合约
        const MyNFT = await ethers.getContractFactory("MyNFT");
        nft = await MyNFT.deploy();

        // 部署工厂合约
        const NFTAuctionV2Factory = await ethers.getContractFactory("NFTAuctionV2Factory");
        factory = await NFTAuctionV2Factory.deploy();

        // 获取测试账户
        [seller, bidder1, bidder2,user1,user2] = await ethers.getSigners();

        // 铸造NFT
        await nft.mint(seller.address, 1);

        // 获取当前区块时间
        currentBlock = await ethers.provider.getBlock("latest");

        // 创建拍卖
        await nft.connect(seller).approve(factory.target, 1);
        await factory.connect(seller).createAuction(
            nft.target,
            1,
            currentBlock.timestamp + 100,
            currentBlock.timestamp + 3600,
            ethers.parseEther("1.0"),
            ethers.parseEther("0.1")
        );

        // 获取拍卖合约地址
        const auctionAddress = await factory.getAuction(nft.target, 1);
        auction = await ethers.getContractAt("NFTAuctionV2", auctionAddress);
    });

    describe("初始化", function () {
        it("应该正确初始化拍卖参数", async function () {
            expect(await auction.nftContract()).to.equal(nft.target);
            expect(await auction.tokenId()).to.equal(1);
            expect(await auction.seller()).to.equal(seller.address);
            expect(await auction.startTime()).to.equal(currentBlock.timestamp + 100);
            expect(await auction.endTime()).to.equal(currentBlock.timestamp + 3600);
            expect(await auction.startPrice()).to.equal(ethers.parseEther("1.0"));
            expect(await auction.minBidIncrement()).to.equal(ethers.parseEther("0.1"));
            expect(await auction.highestBidder()).to.equal(ethers.ZeroAddress);
            expect(await auction.highestBid()).to.equal(0);
            expect(await auction.ended()).to.equal(false);
        });

        it("非创建者不能初始化", async function () {
            // 部署一个新的拍卖合约
            const NFTAuctionV2Factory = await ethers.getContractFactory("NFTAuctionV2");
            const newAuction = await NFTAuctionV2Factory.connect(user1).deploy();

            // 尝试初始化，应该失败
            await expect(
                newAuction.connect(user2).initialize(
                    nft.target,
                    1,
                    currentBlock.timestamp + 100,
                    currentBlock.timestamp + 3600,
                    ethers.parseEther("1.0"),
                    ethers.parseEther("0.1")
                )
            ).to.be.revertedWith("Only factory can initialize");
        });
    });

    describe("出价功能", function () {
        it("应该成功出价并记录待退还金额", async function () {
            // 等待拍卖开始
            await ethers.provider.send("evm_increaseTime", [100]);
            await ethers.provider.send("evm_mine");

            // 第一次出价
            const bidAmount1 = ethers.parseEther("1.5");
            await auction.connect(bidder1).placeBid({ value: bidAmount1 });

            // 第二次出价
            const bidAmount2 = ethers.parseEther("2.0");
            await auction.connect(bidder2).placeBid({ value: bidAmount2 });

            // 验证待退还金额
            expect(await auction.pendingReturns(bidder1.address)).to.equal(bidAmount1);

            // 提取待退还金额
            const initialBalance = await ethers.provider.getBalance(bidder1.address);
            await auction.connect(bidder1).withdrawPendingReturns();
            const finalBalance = await ethers.provider.getBalance(bidder1.address);

            // 验证余额变化（考虑gas费用）
            expect(finalBalance - initialBalance).to.be.closeTo(bidAmount1, ethers.parseEther("0.1"));
        });

        it("拍卖未开始时不能出价", async function () {
            await expect(
                auction.connect(bidder1).placeBid({ value: ethers.parseEther("1.5") })
            ).to.be.revertedWith("Auction not started");
        });

        it("拍卖结束后不能出价", async function () {
            await ethers.provider.send("evm_increaseTime", [3700]);
            await ethers.provider.send("evm_mine");

            await expect(
                auction.connect(bidder1).placeBid({ value: ethers.parseEther("1.5") })
            ).to.be.revertedWith("Auction ended");
        });

        it("出价必须大于起拍价", async function () {
            await ethers.provider.send("evm_increaseTime", [100]);
            await ethers.provider.send("evm_mine");

            await expect(
                auction.connect(bidder1).placeBid({ value: ethers.parseEther("0.5") })
            ).to.be.revertedWith("Bid must be greater than startPrice");
        });

        it("出价必须大于当前最高价加最小加价幅度", async function () {
            await ethers.provider.send("evm_increaseTime", [100]);
            await ethers.provider.send("evm_mine");

            await auction.connect(bidder1).placeBid({ value: ethers.parseEther("1.5") });

            await expect(
                auction.connect(bidder2).placeBid({ value: ethers.parseEther("1.5") })
            ).to.be.revertedWith("Bid must be greater than highestBid + minBidIncrement");
        });
    });

    describe("结束拍卖", function () {
        it("应该成功结束拍卖并转移NFT和ETH", async function () {
            // 等待拍卖开始
            await ethers.provider.send("evm_increaseTime", [100]);
            await ethers.provider.send("evm_mine");

            // 出价
            const bidAmount = ethers.parseEther("1.5");
            await auction.connect(bidder1).placeBid({ value: bidAmount });

            // 等待拍卖结束
            await ethers.provider.send("evm_increaseTime", [3600]);
            await ethers.provider.send("evm_mine");

            // 结束拍卖
            const tx = await auction.endAuction();
            await tx.wait();

            // 验证NFT所有权
            expect(await nft.ownerOf(1)).to.equal(bidder1.address);

            // 验证卖家余额
            const sellerBalance = await ethers.provider.getBalance(seller.address);
            expect(sellerBalance).to.be.gt(0);
        });

        it("拍卖未结束时不能结束", async function () {
            await expect(auction.endAuction()).to.be.revertedWith("Auction not ended");
        });

        it("已结束的拍卖不能再次结束", async function () {
            await ethers.provider.send("evm_increaseTime", [3700]);
            await ethers.provider.send("evm_mine");

            await auction.endAuction();

            await expect(auction.endAuction()).to.be.revertedWith("Auction already ended");
        });
    });

    describe("取消拍卖", function () {
        it("卖家可以在没有出价时取消拍卖", async function () {
            await expect(auction.connect(seller).cancelAuction())
                .to.emit(auction, "AuctionCancelled");

            // 验证NFT所有权
            expect(await nft.ownerOf(1)).to.equal(seller.address);
        });

        it("有出价的拍卖不能取消", async function () {
            // 等待拍卖开始
            await ethers.provider.send("evm_increaseTime", [100]);
            await ethers.provider.send("evm_mine");

            // 出价
            const bidAmount = ethers.parseEther("1.5");
            await auction.connect(bidder1).placeBid({ value: bidAmount });

            // 尝试取消拍卖
            await expect(
                auction.connect(seller).cancelAuction()
            ).to.be.revertedWith("Cannot cancel auction with bids");
        });

        it("非卖家不能取消拍卖", async function () {
            await expect(
                auction.connect(bidder1).cancelAuction()
            ).to.be.revertedWith("Only seller can cancel");
        });

        it("已结束的拍卖不能取消", async function () {
            // 等待拍卖结束
            await ethers.provider.send("evm_increaseTime", [3700]);
            await ethers.provider.send("evm_mine");

            await auction.endAuction();

            await expect(
                auction.connect(seller).cancelAuction()
            ).to.be.revertedWith("Auction already ended");
        });
    });
}); 