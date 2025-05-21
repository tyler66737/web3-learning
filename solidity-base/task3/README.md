## 项目简介
**V1版本**
    简单实现了拍卖功能,只支持ETH出价

**V2版本**
    添加了工厂模式和语言机功能,支持ETH,和其它ERC20代币支付,并且支持管理预言机地址


**代办清单**

* 集成可升级
* 跨链拍卖
* sepolia测试


## 快速开始

```
# 本地开发时使用node v20版本,其它版本是否兼容可以测试
nvm use v20
npm install # 未测试
```

**参考命令**

```shell
npx hardhat help
npx hardhat test
REPORT_GAS=true npx hardhat test
npx hardhat node
npx hardhat ignition deploy ./ignition/modules/Lock.js
npx hardhat ignition deploy ./ignition/modules/Lock.js --network sepolia
# 默认情况下部署过一次后,会缓存,下次部署时,会跳过
# 需要明确指明重置,才会重新发布
npx hardhat ignition deploy ./ignition/modules/Lock.js --network sepolia --reset

# 生成覆盖率报告
npx hardhat coverage
```

## 测试报告

```bash
npx hardhat test
# NFTAuctionV1
#     ✔ 应该能够成功创建拍卖
#     ✔ 应该能够成功出价
#     ✔ 应该能够成功结束拍卖
#     ✔ 未被出价的拍卖在到期后可以结束
#     ✔ 卖家应该能够取消没有出价的拍卖
#     ✔ 非卖家不能取消拍卖
#     ✔ 有出价的拍卖不能取消
#     ✔ 应该能够提取被超过的出价
#     ✔ 没有待返还金额时不能提取

#   NFTAuctionV2
#     价格源管理
#       ✔ 只有管理员可以设置价格源
#       ✔ 可以设置有效的价格源
#       ✔ 不能设置零地址作为价格源
#       ✔ 不能设置零地址作为代币地址
#     ETH拍卖
#       ✔ 应该正确初始化拍卖
#       ✔ 应该允许出价
#       ✔ 应该正确结束拍卖
#     ERC20代币拍卖
#       ✔ 应该允许使用ERC20代币出价
#       ✔ 应该正确结束拍卖并转移代币
#       ✔ 不能使用未设置价格源的代币出价
#     错误处理
#       ✔ 非工厂合约不能初始化
#       ✔ 拍卖结束后不能出价
#       ✔ 不能使用错误的代币类型出价
#     取消拍卖
#       ✔ 卖家可以取消没有出价的拍卖
#       ✔ 非卖家不能取消拍卖
#       ✔ 有出价的拍卖不能取消
#       ✔ 已结束的拍卖不能取消

#   NFTAuctionV2Factory
#     创建拍卖
#       ✔ 应该成功创建拍卖
#       ✔ 非NFT所有者不能创建拍卖
#       ✔ 未授权的NFT不能创建拍卖
#     查询功能
#       ✔ 应该正确返回拍卖合约数量
#       ✔ 应该正确返回所有拍卖合约
```
```
 
```

覆盖率:
```bash
npx hardhat coverage
# --------------------------|----------|----------|----------|----------|----------------|
# File                      |  % Stmts | % Branch |  % Funcs |  % Lines |Uncovered Lines |
# --------------------------|----------|----------|----------|----------|----------------|
#  contracts/               |    95.27 |    66.03 |    90.24 |    95.21 |                |
#   IERC721.sol             |      100 |      100 |      100 |      100 |                |
#   MyNFT.sol               |    90.63 |    67.86 |    81.25 |    90.24 |  67,97,116,121 |
#   NFTAuctionV1.sol        |      100 |       62 |      100 |      100 |                |
#   NFTAuctionV2.sol        |    93.65 |    66.22 |      100 |    95.12 |  70,83,153,242 |
#   NFTAuctionV2Factory.sol |      100 |      100 |      100 |      100 |                |
#   NFTReceiver.sol         |      100 |      100 |      100 |      100 |                |
#   NormalReceiver.sol      |      100 |      100 |        0 |        0 |              8 |
#   TestToken.sol           |      100 |      100 |      100 |      100 |                |
#  contracts/mocks/         |       40 |      100 |    42.86 |       50 |                |
#   MockV3Aggregator.sol    |       40 |      100 |    42.86 |       50 |    36,43,79,86 |
# --------------------------|----------|----------|----------|----------|----------------|
```






