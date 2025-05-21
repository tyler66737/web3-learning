## 项目简介


## 快速开始

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



## 基本环境与环境初始化

```
# 本地开发时使用node v20版本
nvm use v20
```



# todo
npx remixd
app.uniswap.org 代币兑换
chain link官网,兑换,以及测试网地址
