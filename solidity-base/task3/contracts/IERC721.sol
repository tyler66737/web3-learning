// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

interface IERC721 {
    // 事件: 当NFT从一个地址转移到另一个地址时触发
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    
    // 事件: 当NFT的所有者批准某个地址操作特定tokenId时触发
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    
    // 事件: 当NFT的所有者批准或取消某个操作者管理其所有NFT时触发
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    // 查询指定地址拥有的NFT数量
    // 返回: 地址持有的NFT数量
    // 备注: 无需权限, 公开查询
    function balanceOf(address owner) external view returns (uint256 balance);

    // 查询特定tokenId的拥有者地址
    // 返回: tokenId的当前拥有者地址
    // 备注: 无需权限, 公开查询, tokenId必须存在
    function ownerOf(uint256 tokenId) external view returns (address owner);

    // 安全转移NFT到指定地址, 包含额外数据
    // 参数: from(原拥有者), to(接收者), tokenId(NFT ID), data(附加数据)
    // 备注: 调用者需是tokenId的所有者或被授权者; 接收者需是有效地址; 若to是合约, 需实现IERC721Receiver
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    // 安全转移NFT到指定地址, 无附加数据
    // 参数: from(原拥有者), to(接收者), tokenId(NFT ID)
    // 备注: 调用者需是tokenId的所有者或被授权者; 接收者需是有效地址; 若to是合约, 需实现IERC721Receiver
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    // 转移NFT到指定地址(非安全版本)
    // 参数: from(原拥有者), to(接收者), tokenId(NFT ID)
    // 备注: 调用者需是tokenId的所有者或被授权者; 不检查接收者是否能接收NFT
    function transferFrom(address from, address to, uint256 tokenId) external;

    // 批准某个地址操作特定的NFT
    // 参数: to(被授权地址), tokenId(NFT ID)
    // 备注: 调用者需是tokenId的所有者或被授权的操作者; 授权后to可转移该NFT
    function approve(address to, uint256 tokenId) external;

    // 设置或取消某个地址对调用者所有NFT的操作权限
    // 参数: operator(操作者地址), approved(是否授权)
    // 备注: 调用者需是NFT所有者; 设置approved为true授权, false取消授权
    function setApprovalForAll(address operator, bool approved) external;

    // 查询特定NFT的被授权地址
    // 返回: 被授权操作tokenId的地址
    // 备注: 无需权限, 公开查询, tokenId必须存在
    function getApproved(uint256 tokenId) external view returns (address operator);

    // 查询某操作者是否被授权管理某地址的全部NFT
    // 返回: 是否被授权
    // 备注: 无需权限, 公开查询
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}


interface IERC721Receiver {
    // 接收NFT的回调函数
    // 参数: operator(操作者地址), from(原拥有者), tokenId(NFT ID), data(附加数据)
    // 返回: 是否接收成功
    // 描述: 接收者需实现此函数, 并返回true表示接收成功
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}