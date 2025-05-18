const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("NFTAuctionV2Factory", function () {
    let factory;
    let nft;
    let owner;
    let seller;
    let bidder1;
    let bidder2;
    let currentBlock;

    beforeEach(async function () {
        // 获取当前区块信息
        currentBlock = await ethers.provider.getBlock("latest");
        // 部署合约
        const NFTAuctionFactory = await ethers.getContractFactory("NFTAuctionV2Factory");
        const MyNFT = await ethers.getContractFactory("MyNFT");
        [owner, seller, bidder1, bidder2] = await ethers.getSigners();
        factory = await NFTAuctionFactory.deploy();
        nft = await MyNFT.deploy();
        
        // 铸造NFT给卖家
        await nft.connect(seller).mint(seller.address, 1);
    });

    describe("创建拍卖", function () {
        it("应该成功创建拍卖", async function () {
            // 授权工厂合约
            await nft.connect(seller).approve(await factory.getAddress(), 1);

            // 创建拍卖
            const startTime = currentBlock.timestamp + 100;
            const endTime = startTime + 3600;
            const startPrice = ethers.parseEther("1.0");
            const minBidIncrement = ethers.parseEther("0.1");

            const tx = await factory.connect(seller).createAuction(
                await nft.getAddress(),
                1,
                startTime,
                endTime,
                startPrice,
                minBidIncrement
            );

            const receipt = await tx.wait();
            const event = receipt.logs.find(log => log.fragment && log.fragment.name === 'AuctionCreated');
            const auctionAddress = event.args[2];

            // 验证NFT所有权已转移到拍卖合约
            expect(await nft.ownerOf(1)).to.equal(auctionAddress);
            expect(await factory.getAuction(await nft.getAddress(), 1)).to.equal(auctionAddress);
        });

        it("非NFT所有者不能创建拍卖", async function () {
            await nft.connect(seller).approve(await factory.getAddress(), 1);

            const startTime = currentBlock.timestamp + 100;
            const endTime = startTime + 3600;
            const startPrice = ethers.parseEther("1.0");
            const minBidIncrement = ethers.parseEther("0.1");

            await expect(
                factory.connect(bidder1).createAuction(
                    await nft.getAddress(),
                    1,
                    startTime,
                    endTime,
                    startPrice,
                    minBidIncrement
                )
            ).to.be.revertedWith("Only owner of nft can create auction");
        });

        it("未授权的NFT不能创建拍卖", async function () {
            const startTime = currentBlock.timestamp + 100;
            const endTime = startTime + 3600;
            const startPrice = ethers.parseEther("1.0");
            const minBidIncrement = ethers.parseEther("0.1");

            await expect(
                factory.connect(seller).createAuction(
                    await nft.getAddress(),
                    1,
                    startTime,
                    endTime,
                    startPrice,
                    minBidIncrement
                )
            ).to.be.revertedWith("NFT not approved");
        });
    });

    describe("查询功能", function () {
        it("应该正确返回拍卖合约数量", async function () {
            expect(await factory.getAuctionsCount()).to.equal(0);

            // 创建拍卖
            await nft.connect(seller).approve(await factory.getAddress(), 1);
            const startTime = currentBlock.timestamp + 100;
            const endTime = startTime + 3600;
            const startPrice = ethers.parseEther("1.0");
            const minBidIncrement = ethers.parseEther("0.1");

            await factory.connect(seller).createAuction(
                await nft.getAddress(),
                1,
                startTime,
                endTime,
                startPrice,
                minBidIncrement
            );

            expect(await factory.getAuctionsCount()).to.equal(1);
        });

        it("应该正确返回所有拍卖合约", async function () {
            // 创建拍卖
            await nft.connect(seller).approve(await factory.getAddress(), 1);
            const startTime = currentBlock.timestamp + 100;
            const endTime = startTime + 3600;
            const startPrice = ethers.parseEther("1.0");
            const minBidIncrement = ethers.parseEther("0.1");

            const tx = await factory.connect(seller).createAuction(
                await nft.getAddress(),
                1,
                startTime,
                endTime,
                startPrice,
                minBidIncrement
            );

            const receipt = await tx.wait();
            const event = receipt.logs.find(log => log.fragment && log.fragment.name === 'AuctionCreated');
            const auctionAddress = event.args[2];

            const auctions = await factory.getAllAuctions();
            expect(auctions.length).to.equal(1);
            expect(auctions[0]).to.equal(auctionAddress);
            expect(await factory.getAuction(await nft.getAddress(), 1)).to.equal(auctionAddress);
        });
    });
}); 