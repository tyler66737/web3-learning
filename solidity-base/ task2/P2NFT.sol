// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

/*
图片上传
    注册pinata账号,并在后台上传
    ## 资源地址
    wow.png:  https://ipfs.io/ipfs/bafkreigzby2f7f2odswr4rk7wjdypb2fzohoqwtlrhkymhvxh74p3wxmt4
    wow.json: https://ipfs.io/ipfs/bafkreif5wirsgvslqy42qy4v4blm5tshzap73yaqft4nrohnnmsygq5rnu

合约地址:
    0x8b411D3B2B9Ccf7f492Ee3bb50323788B500bC7E

创建
    0x6884142ed9f45F63b6bD1c89850d88e97b54916A,1,ipfs://bafkreif5wirsgvslqy42qy4v4blm5tshzap73yaqft4nrohnnmsygq5rnu
    0x6884142ed9f45F63b6bD1c89850d88e97b54916A,10,ipfs://bafkreify76irikxb25q7xemyqndqs3rljndle7yd4eixf7pccva2bo5434

opensea 测试网查看:
    https://testnets.opensea.io/zh-CN/assets/sepolia/0x8b411d3b2b9ccf7f492ee3bb50323788b500bc7e/1
    https://testnets.opensea.io/zh-CN/assets/sepolia/0x8b411d3b2b9ccf7f492ee3bb50323788b500bc7e/10
*/
contract P2NFT is ERC721 { 
    mapping(uint256 => string) private _tokenURIs;
    constructor() ERC721("My NFT", "MNFT") {}

    function mintNFT(address recipent,uint256 tokenID,string memory _tokenURI) public {
        require(bytes(_tokenURI).length > 0, "Token URI cannot be empty");
        require(recipent !=address(0), "invalid address");
        // 需要自己记住自己拥有的tokenID
        // uint256 tokenId = uint256(keccak256(abi.encodePacked(_tokenURI)));
        _tokenURIs[tokenID] = _tokenURI;
        _safeMint(recipent, tokenID);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return _tokenURIs[tokenId];
    } 
}
