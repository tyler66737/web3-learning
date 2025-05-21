// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

/**
 * @title MockV3Aggregator
 * @notice 简化版 Chainlink V3 价格预言机模拟
 * @dev 仅实现必要的价格查询功能
 */
contract MockV3Aggregator is AggregatorV3Interface {
    uint8 private _decimals;
    int256 private _latestAnswer;

    /**
     * @notice 构造函数
     * @param decimals_ 价格精度
     * @param initialAnswer_ 初始价格
     */
    constructor(uint8 decimals_, int256 initialAnswer_) {
        _decimals = decimals_;
        _latestAnswer = initialAnswer_;
    }

    /**
     * @notice 获取价格精度
     */
    function decimals() external view override returns (uint8) {
        return _decimals;
    }

    /**
     * @notice 获取预言机描述
     */
    function description() external pure override returns (string memory) {
        return "Mock V3 Aggregator";
    }

    /**
     * @notice 获取预言机版本
     */
    function version() external pure override returns (uint256) {
        return 0;
    }

    /**
     * @notice 获取最新价格数据
     */
    function latestRoundData()
        external
        view
        override
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        return (0, _latestAnswer, block.timestamp, block.timestamp, 0);
    }

    /**
     * @notice 获取指定轮次的价格数据
     */
    function getRoundData(uint80)
        external
        view
        override
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        return (0, _latestAnswer, block.timestamp, block.timestamp, 0);
    }

    /**
     * @notice 更新价格（仅用于测试）
     */
    function updateAnswer(int256 newAnswer) external {
        _latestAnswer = newAnswer;
    }
} 