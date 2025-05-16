

const { expect} = require("chai");

// mocha与chai的基本用法
// 运行: npx hardhat test test/Example.js
describe("断言", function () {
    beforeEach(async function () {
        console.log("boforeEach");
    }) 
    it("断言1", async function () {
        expect(1).to.equal(1);
    });
    it("断言2", async function () {
        expect(2).to.equal(2);
    });

});