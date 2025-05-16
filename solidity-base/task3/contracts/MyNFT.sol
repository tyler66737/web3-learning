// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import './IERC721.sol';

contract MyNFT is IERC721 {
    string private _name = "Dogie";
    string private _symbol = "DOG";

    uint256 private _totalSupply = 0;
    mapping(uint256 => address) private _owners;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    mapping(address => uint256) private _balances;

    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        return _owners[tokenId];
    }

    // 授予某个账户权限后,如何撤回?
    function approve(address to, uint256 tokenId) public {
        require(msg.sender == _owners[tokenId], "Invalid owner");
        _tokenApprovals[tokenId] = to;
        emit Approval(msg.sender, to, tokenId);
    }

    function getApproved(uint256 tokenId) public view returns (address) {
        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public {
        require(msg.sender != operator, "Invalid operator");
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);    
    }

    function isApprovedForAll(address owner, address operator) public view returns (bool) {
         return _operatorApprovals[owner][operator];
    }

    function transferFrom(address from, address to, uint256 tokenId) public {
        _transfer(from, to, tokenId);
    }   

    function _transfer(address from, address to, uint256 tokenId) internal { 
        require(from !=address(0) && to != address(0), "Invalid address");
        require(from == _owners[tokenId], "Invalid owner");
        require(_isApprovedOrOwner(msg.sender,tokenId), "Not authorized");
        _tokenApprovals[tokenId] = address(0);
        _owners[tokenId] = to;
        _balances[from] -= 1;
        _balances[to] += 1;
        emit Transfer(from, to, tokenId);
    }   

    function _isApprovedOrOwner(address spender, uint256 tokenId) public view returns (bool) {
        require(_owners[tokenId] != address(0), "Invalid token");
        address owner = _owners[tokenId];
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }   

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) public{
        _safeTransferFrom(from, to, tokenId, data);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        _safeTransferFrom(from, to, tokenId, "");
    }

    function _safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) internal{
       require(_isApprovedOrOwner(msg.sender,tokenId), "Not authorized");
       _transfer(from, to, tokenId);
       // safe需要执行合约检查
       // 假如接收方是合约,需要做 onERC721Received检查
       // 一般的合约如果没有实现该函数,转移不会成功.
       // 这样做主要主要是为确保合约能够处理NFT,避免资产丢失
       require(_checkOnERC721Received(from, to, tokenId, data), "Transfer to non ERC721Receiver implementer");
    }
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory data) private returns (bool) {
        if(to.code.length == 0){
            return true;
        }
        // gpt帮忙生成的代码,用于检查目标地址是否实现了ERC721Receiver
        // IERC721Receiver.onERC721Received.selector
        // 等价于 bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))
        // 获取函数选择器
        try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) returns (bytes4 retval) {
            return retval == IERC721Receiver.onERC721Received.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                revert("ERC721: transfer to non ERC721Receiver implementer");
            } else {
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
    }

    // 创建NFT
    // 非标准接口内容,自定义铸造函数
    function mint(address to, uint256 tokenId) public {
        require(to != address(0), "Invalid address");
        require(_owners[tokenId] == address(0), "Token already minted");
        _owners[tokenId] = to;
        _balances[to] += 1;
        emit Transfer(address(0), to, tokenId);
    }

    // name 是否是标准接口?
    function name() public view returns (string memory) {
        return _name;
    }

    // symbol 是否是标准接口?
    function symbol() public view returns (string memory) {
        return _symbol;
    }
}
