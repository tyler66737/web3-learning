const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("NFTAuctionV2", function () {
    let nftContract;
    let auctionFactory;
    let auction;
    let owner;
    let seller;
    let bidder1;
    let bidder2;
    let tokenId;
    let startTime;
    let endTime;
    let startPrice;
    let minBidIncrement;
    let testToken;
    let mockPriceFeed;

    beforeEach(async function () {
        [owner, seller, bidder1, bidder2] = await ethers.getSigners();

        // 部署NFT合约
        const MyNFT = await ethers.getContractFactory("MyNFT");
        nftContract = await MyNFT.connect(owner).deploy();

        // 部署测试代币
        const TestToken = await ethers.getContractFactory("TestToken");
        testToken = await TestToken.connect(owner).deploy();

        // 部署预言机模拟合约
        const MockPriceFeed = await ethers.getContractFactory("MockV3Aggregator");
        mockPriceFeed = await MockPriceFeed.connect(owner).deploy(8, ethers.parseUnits("0.0005", 8)); // 2000 代币 = 1 ETH,汇率保留8位小数

        // 部署工厂合约
        const NFTAuctionV2Factory = await ethers.getContractFactory("NFTAuctionV2Factory");
        auctionFactory = await NFTAuctionV2Factory.connect(owner).deploy();

        // 铸造NFT
        tokenId = 1;
        await nftContract.mint(seller.address, tokenId);

        // 设置拍卖参数
        const currentBlock = await ethers.provider.getBlock("latest");
        startTime = currentBlock.timestamp + 100;
        endTime = startTime + 3600;
        startPrice = ethers.parseEther("1.0");
        minBidIncrement = ethers.parseEther("0.1");

        // 授权NFT给工厂合约
        await nftContract.connect(seller).approve(await auctionFactory.getAddress(), tokenId);

        // 给测试账户转一些测试代币
        await testToken.transfer(bidder1.address, ethers.parseEther("3000"));
        await testToken.transfer(bidder2.address, ethers.parseEther("3000"));
    });

    describe("价格源管理", function () {
        beforeEach(async function () {
            // 创建拍卖
            const tx = await auctionFactory.connect(seller).createAuction(
                await nftContract.getAddress(),
                tokenId,
                startTime,
                endTime,
                startPrice,
                minBidIncrement
            );

            const receipt = await tx.wait();
            const event = receipt.logs.find(log => log.fragment && log.fragment.name === 'AuctionCreated');
            auction = await ethers.getContractAt("NFTAuctionV2", event.args[2]);
        });

        it("只有管理员可以设置价格源", async function () {
            await expect(
                auction.connect(bidder1).setPriceFeed(await testToken.getAddress(), await mockPriceFeed.getAddress())
            ).to.be.revertedWith("Not authorized");
        });

        it("可以设置有效的价格源", async function () {
            await expect(auction.connect(seller).setPriceFeed(await testToken.getAddress(), await mockPriceFeed.getAddress()))
                .to.emit(auction, "PriceFeedUpdated")
                .withArgs(await testToken.getAddress(), await mockPriceFeed.getAddress());
        });

        it("不能设置零地址作为价格源", async function () {
            await expect(
                auction.connect(seller).setPriceFeed(await testToken.getAddress(), ethers.ZeroAddress)
            ).to.be.revertedWith("Invalid price feed address");
        });

        it("不能设置零地址作为代币地址", async function () {
            await expect(
                auction.connect(seller).setPriceFeed(ethers.ZeroAddress, await mockPriceFeed.getAddress())
            ).to.be.revertedWith("Invalid token address");
        });
    });

    describe("ETH拍卖", function () {
        beforeEach(async function () {
            // 创建拍卖
            const tx = await auctionFactory.connect(seller).createAuction(
                await nftContract.getAddress(),
                tokenId,
                startTime,
                endTime,
                startPrice,
                minBidIncrement
            );

            const receipt = await tx.wait();
            const event = receipt.logs.find(log => log.fragment && log.fragment.name === 'AuctionCreated');
            auction = await ethers.getContractAt("NFTAuctionV2", event.args[2]);
        });

        it("应该正确初始化拍卖", async function () {
            expect(await auction.nftContract()).to.equal(await nftContract.getAddress());
            expect(await auction.tokenId()).to.equal(tokenId);
            expect(await auction.seller()).to.equal(seller.address);
            expect(await auction.startTime()).to.equal(startTime);
            expect(await auction.endTime()).to.equal(endTime);
            expect(await auction.startPrice()).to.equal(startPrice);
            expect(await auction.minBidIncrement()).to.equal(minBidIncrement);
        });

        it("应该允许出价", async function () {
            // 增加时间到拍卖开始
            await ethers.provider.send("evm_increaseTime", [100]);
            await ethers.provider.send("evm_mine");

            const bidAmount = ethers.parseEther("1.5");
            await expect(auction.connect(bidder1).placeBid(ethers.ZeroAddress, bidAmount, { value: bidAmount }))
                .to.emit(auction, "BidPlaced")
                .withArgs(bidder1.address, bidAmount, ethers.ZeroAddress, bidAmount);

            expect(await auction.highestBidder()).to.equal(bidder1.address);
            expect(await auction.highestBid()).to.equal(bidAmount);
        });

        it("应该正确结束拍卖", async function () {
            // 增加时间到拍卖开始
            await ethers.provider.send("evm_increaseTime", [100]);
            await ethers.provider.send("evm_mine");

            // 出价
            const bidAmount = ethers.parseEther("1.5");
            await auction.connect(bidder1).placeBid(ethers.ZeroAddress, bidAmount, { value: bidAmount });

            // 增加时间到拍卖结束
            await ethers.provider.send("evm_increaseTime", [3600]);
            await ethers.provider.send("evm_mine");

            // 结束拍卖
            await expect(auction.endAuction())
                .to.emit(auction, "AuctionEnded")
                .withArgs(bidder1.address, bidAmount);

            expect(await nftContract.ownerOf(tokenId)).to.equal(bidder1.address);
        });
    });

    describe("ERC20代币拍卖", function () {
        beforeEach(async function () {
            // 创建拍卖
            const tx = await auctionFactory.connect(seller).createAuction(
                await nftContract.getAddress(),
                tokenId,
                startTime,
                endTime,
                startPrice,
                minBidIncrement
            );

            const receipt = await tx.wait();
            const event = receipt.logs.find(log => log.fragment && log.fragment.name === 'AuctionCreated');
            auction = await ethers.getContractAt("NFTAuctionV2", event.args[2]);
            // 设置价格源
            await auction.connect(seller).setPriceFeed(await testToken.getAddress(), await mockPriceFeed.getAddress());
        });

        it("应该允许使用ERC20代币出价", async function () {
            // 增加时间到拍卖开始
            await ethers.provider.send("evm_increaseTime", [100]);
            await ethers.provider.send("evm_mine");

            // 授权代币
            // 由于预言机价格是 1 ETH = 2000 USD，我们需要确保出价超过起拍价
            // 起拍价是 1 ETH，所以我们需要至少 2000 TEST 代币
            // 使用 2100 TEST 代币，这样转换为 ETH 后约为 1.05 ETH
            const bidAmount = ethers.parseUnits("2100", 18); // 2100 TEST
            await testToken.connect(bidder1).approve(await auction.getAddress(), bidAmount);

            // 出价
            const tx = await auction.connect(bidder1).placeBid(await testToken.getAddress(), bidAmount);
            const receipt = await tx.wait();
            const event = receipt.logs.find(log => log.fragment && log.fragment.name === 'BidPlaced');
            
            expect(event.args[0]).to.equal(bidder1.address);
            expect(event.args[1]).to.equal(bidAmount);
            expect(event.args[2]).to.equal(await testToken.getAddress());
            // 2100 TEST * 2000 (price) / 1e18 = 1.05 ETH
            expect(event.args[3]).to.equal(ethers.parseEther("1.05"));

            expect(await auction.highestBidder()).to.equal(bidder1.address);
            expect(await auction.highestBid()).to.equal(bidAmount);
        });

        it("应该正确结束拍卖并转移代币", async function () {
            // 增加时间到拍卖开始
            await ethers.provider.send("evm_increaseTime", [100]);
            await ethers.provider.send("evm_mine");

            // 授权代币
            const bidAmount = ethers.parseUnits("2100", 18); // 2100 TEST
            await testToken.connect(bidder1).approve(await auction.getAddress(), bidAmount);

            // 出价
            await auction.connect(bidder1).placeBid(await testToken.getAddress(), bidAmount);

            // 增加时间到拍卖结束
            await ethers.provider.send("evm_increaseTime", [3600]);
            await ethers.provider.send("evm_mine");

            // 记录卖家初始余额
            const sellerInitialBalance = await testToken.balanceOf(seller.address);

            // 结束拍卖
            const tx = await auction.connect(seller).endAuction();
            const receipt = await tx.wait();
            const event = receipt.logs.find(log => log.fragment && log.fragment.name === 'AuctionEnded');
            
            expect(event.args[0]).to.equal(bidder1.address);
            expect(event.args[1]).to.equal(bidAmount);

            // 检查NFT所有权
            expect(await nftContract.ownerOf(tokenId)).to.equal(bidder1.address);

            // 检查卖家收到的代币
            const sellerFinalBalance = await testToken.balanceOf(seller.address);
            expect(sellerFinalBalance - sellerInitialBalance).to.equal(bidAmount);
        });

        it("不能使用未设置价格源的代币出价", async function () {
            // 增加时间到拍卖开始
            await ethers.provider.send("evm_increaseTime", [100]);
            await ethers.provider.send("evm_mine");

            // 部署新的测试代币
            const TestToken = await ethers.getContractFactory("TestToken");
            const newTestToken = await TestToken.connect(owner).deploy();

            // 授权代币
            const bidAmount = ethers.parseUnits("2100", 18);
            await newTestToken.connect(bidder1).approve(await auction.getAddress(), bidAmount);

            // 尝试出价
            await expect(
                auction.connect(bidder1).placeBid(await newTestToken.getAddress(), bidAmount)
            ).to.be.revertedWith("Price feed not set");
        });
    });

    describe("错误处理", function () {
        it("非工厂合约不能初始化", async function () {
            // todo
        });

        it("拍卖结束后不能出价", async function () {
            // 创建拍卖
            const tx = await auctionFactory.connect(seller).createAuction(
                await nftContract.getAddress(),
                tokenId,
                startTime,
                endTime,
                startPrice,
                minBidIncrement
            );

            const receipt = await tx.wait();
            const event = receipt.logs.find(log => log.fragment && log.fragment.name === 'AuctionCreated');
            auction = await ethers.getContractAt("NFTAuctionV2", event.args[2]);

            // 增加时间到拍卖结束
            await ethers.provider.send("evm_increaseTime", [3700]);
            await ethers.provider.send("evm_mine");

            // 尝试出价
            const bidAmount = ethers.parseEther("1.5");
            await expect(
                auction.connect(bidder1).placeBid(ethers.ZeroAddress, bidAmount, { value: bidAmount })
            ).to.be.revertedWith("Auction ended");
        });

        it("不能使用错误的代币类型出价", async function () {
            // 创建拍卖
            const tx = await auctionFactory.connect(seller).createAuction(
                await nftContract.getAddress(),
                tokenId,
                startTime,
                endTime,
                startPrice,
                minBidIncrement
            );

            const receipt = await tx.wait();
            const event = receipt.logs.find(log => log.fragment && log.fragment.name === 'AuctionCreated');
            auction = await ethers.getContractAt("NFTAuctionV2", event.args[2]);

            // 增加时间到拍卖开始
            await ethers.provider.send("evm_increaseTime", [100]);
            await ethers.provider.send("evm_mine");

            // 尝试使用ERC20代币出价
            const bidAmount = ethers.parseEther("2000");
            await testToken.connect(bidder1).approve(await auction.getAddress(), bidAmount);
            await expect(
                auction.connect(bidder1).placeBid(await testToken.getAddress(), bidAmount)
            ).to.be.revertedWith("Price feed not set");
        });
    });

    describe("取消拍卖", function () {
        beforeEach(async function () {
            // 创建拍卖
            const tx = await auctionFactory.connect(seller).createAuction(
                await nftContract.getAddress(),
                tokenId,
                startTime,
                endTime,
                startPrice,
                minBidIncrement
            );

            const receipt = await tx.wait();
            const event = receipt.logs.find(log => log.fragment && log.fragment.name === 'AuctionCreated');
            auction = await ethers.getContractAt("NFTAuctionV2", event.args[2]);
        });

        it("卖家可以取消没有出价的拍卖", async function () {
            // 取消拍卖
            const tx = await auction.connect(seller).cancelAuction();
            const receipt = await tx.wait();
            const event = receipt.logs.find(log => log.fragment && log.fragment.name === 'AuctionCancelled');
            
            expect(event).to.not.be.undefined;
            expect(await nftContract.ownerOf(tokenId)).to.equal(seller.address);
            expect(await auction.ended()).to.be.true;
        });

        it("非卖家不能取消拍卖", async function () {
            await expect(
                auction.connect(bidder1).cancelAuction()
            ).to.be.revertedWith("Only seller can cancel");
        });

        it("有出价的拍卖不能取消", async function () {
            // 增加时间到拍卖开始
            await ethers.provider.send("evm_increaseTime", [100]);
            await ethers.provider.send("evm_mine");

            // 出价
            const bidAmount = ethers.parseEther("1.5");
            await auction.connect(bidder1).placeBid(ethers.ZeroAddress, bidAmount, { value: bidAmount });

            // 尝试取消拍卖
            await expect(
                auction.connect(seller).cancelAuction()
            ).to.be.revertedWith("Cannot cancel auction with bids");
        });

        it("已结束的拍卖不能取消", async function () {
            // 增加时间到拍卖结束
            await ethers.provider.send("evm_increaseTime", [3700]);
            await ethers.provider.send("evm_mine");

            // 结束拍卖
            await auction.connect(seller).endAuction();

            // 尝试取消拍卖
            await expect(
                auction.connect(seller).cancelAuction()
            ).to.be.revertedWith("Auction already ended");
        });
    });
}); 