// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

// 这个合约用于演示普通合约无法接受通过safeTransferFrom接收NFT
contract NormalReceiver { 
    uint public balance;
    function receiveEther() public payable {
        balance += msg.value;
    }
}
