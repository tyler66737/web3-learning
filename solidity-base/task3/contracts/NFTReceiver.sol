// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "./IERC721.sol";

// 这个合约是为了演示,接收NFT
// 这里只是实现了接收验证接口,这样子可以接收NFT
// 但是缺乏转移功能
contract NFTReceiver is IERC721Receiver {
    event Received(address, address, uint256, bytes);
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4) {
        emit Received(operator, from, tokenId, data);
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }
}