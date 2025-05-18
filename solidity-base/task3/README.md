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
