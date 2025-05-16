const { expect } = require("chai");
const { ethers } = require("hardhat");
// 使用hardhat 默认自带的测试库与断言框架对MyNFT合约进行测试
describe("合约部署", function() {
    let signers = [];
    before(async function() {
        // 获取所有账户
        signers = await ethers.getSigners();
        console.log("signers:",signers.length)
        console.log("address[0]",signers[0].address)
    });
    it("测试合约部署", async function() {
        const MyNFT = await ethers.getContractFactory("MyNFT");
        const myNFT = await MyNFT.deploy();
        console.log("MyNFT deployed to:", await myNFT.getAddress());
    }); 
})

describe("合约mint", function() { 
    let signers = [];
    let myNFT;
    before(async function() { 
        signers = await ethers.getSigners();
        const nftFactory = await ethers.getContractFactory("MyNFT");
        myNFT = await nftFactory.deploy()
        console.log("MyNFT deployed to:", await myNFT.getAddress());
    });
    it("测试 mint", async function() {
        await myNFT.mint(signers[0].address,1)
        expect(await myNFT.balanceOf(signers[0].address)).to.equal(1);
        expect(await myNFT.ownerOf(1)).to.equal(signers[0].address);
    });
})

describe("合约transfer", function() { 
    let signers = [];
    let myNFT;
    before(async function() { 
        signers = await ethers.getSigners();
        const nftFactory = await ethers.getContractFactory("MyNFT");
        myNFT = await nftFactory.deploy()
        console.log("MyNFT deployed to:", await myNFT.getAddress());
    });
    it("测试 transfer", async function() {
        await myNFT.mint(signers[0].address,1);
        await myNFT.transferFrom(signers[0].address,signers[1].address,1);
        expect(await myNFT.balanceOf(signers[0].address)).to.equal(0,"invalid balance of signers[0]");
        expect(await myNFT.balanceOf(signers[1].address)).to.equal(1,"invalid balance of signers[1]");
        expect(await myNFT.ownerOf(1)).to.equal(signers[1].address,"invalid owner of token 1");
    })
})

describe("权限管理", function() {
    let signers = [];
    let myNFT;
    this.beforeEach(async function() { 
        signers = await ethers.getSigners();
        const nftFactory = await ethers.getContractFactory("MyNFT");
        myNFT = await nftFactory.deploy();
        await myNFT.mint(signers[0].address,1);
        await myNFT.mint(signers[0].address,2); 
    })  
    it("测试Token授权", async function() {
        await myNFT.connect(signers[0]).approve(signers[1].address,1);
        expect(await myNFT.getApproved(1)).to.equal(signers[1].address,"invalid approved address");
        await myNFT.connect(signers[1]).transferFrom(signers[0].address,signers[2].address,1);
        expect(await myNFT.ownerOf(1)).to.equal(signers[2].address,"invalid owner of token 1");
        expect(await myNFT.balanceOf(signers[0].address)).to.equal(1,"invalid balance of signers[0]");
        expect(await myNFT.balanceOf(signers[2].address)).to.equal(1,"invalid balance of signers[2]");
    })
    it("测试授权管理-1", async function() { 
        await myNFT.connect(signers[0]).setApprovalForAll(signers[1].address,true);
        expect(await myNFT.isApprovedForAll(signers[0].address,signers[1].address)).to.equal(true,"invalid isApprovedForAll");
        await myNFT.connect(signers[0]).setApprovalForAll(signers[1].address,false);
        expect(await myNFT.isApprovedForAll(signers[0].address,signers[1].address)).to.equal(false,"invalid isApprovedForAll");
    })

    it("测试transferFrom-允许", async function() { 
        await myNFT.connect(signers[0]).setApprovalForAll(signers[1].address,true);
        await myNFT.connect(signers[1]).transferFrom(signers[0].address,signers[2].address,1);
        expect(await myNFT.ownerOf(1)).to.equal(signers[2].address,"invalid owner of token 1");
    })

    it("测试transferFrom-没有权限", async function() { 
        // 原始的使用字符串比较的方式
        // try{
        //     await myNFT.connect(signers[1]).transferFrom(signers[0].address,signers[2].address,1);
        // } catch (e){
        //     const errMatch=e.message.includes('Not authorized')
        //     expect(errMatch).to.equal(true,"invalid error message");
        // }
        const result = myNFT.connect(signers[1]).transferFrom(signers[0].address,signers[2].address,1);
        await expect(result).to.be.revertedWith("Not authorized");
    })
})


describe("向合约转账", function() {
    let signers = [];
    let myNFT;
    this.beforeEach(async function() { 
        signers = await ethers.getSigners();
        const nftFactory = await ethers.getContractFactory("MyNFT");
        myNFT = await nftFactory.deploy();
        await myNFT.mint(signers[0].address,1);
        await myNFT.mint(signers[0].address,2); 
    })
    it("测试向普通合约转账", async function() {
        const receiverFactory = await ethers.getContractFactory("NormalReceiver");
        const receiver = await receiverFactory.deploy();
        const receiverAddress = await receiver.getAddress();
        await expect(myNFT.safeTransferFrom(signers[0].address,receiverAddress,1)).to.be.revertedWith("ERC721: transfer to non ERC721Receiver implementer");
    })
    it("测试向特殊合约转账",async function(){
        const receiverFactory = await ethers.getContractFactory("NFTReceiver");
        const receiver = await receiverFactory.deploy();
        const receiverAddress = await receiver.getAddress();
        await expect(myNFT.safeTransferFrom(signers[0].address,receiverAddress,1)).to.emit(myNFT,"Transfer").withArgs(signers[0].address,receiverAddress,1);
        expect(await myNFT.balanceOf(receiverAddress)).to.be.equal(1,'balance of receiverAddress should be 1');
        expect(await myNFT.ownerOf(1)).to.be.equal(receiverAddress,'receiverAddress should be owner of tokenId');
    })
})
// 后续优化,需要生成测试报告