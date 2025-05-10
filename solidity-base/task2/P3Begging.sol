// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

// 测试网合约地址: 0xAE753C889f9AF5fa21d078DaB445C15EF59E0126
contract P3Begging {
    mapping(address => uint) private _donates;
    address payable private  _owner;
    address[3] private _top3;
    uint256 private _totalDonates;
    uint256 private _deadline;


    event Donate(address indexed from, uint256 amount);
    event Withdraw(address indexed to, uint256 amount);

    modifier onlyOwner(){
        require(msg.sender == _owner, "only owner can call this function");
        _;
    }

    constructor(uint256 deadline_){
        _deadline = deadline_;
        _owner = payable(msg.sender);
    }

    function donate()public payable {
        require(msg.value > 0, "donate value must > 0");
        require(block.timestamp < _deadline, "deadline passed");
        _donates[msg.sender] += msg.value;
        _totalDonates += msg.value;

        // 实时更新top3
        uint minIndex=0;
        bool isInTop3=false;
        for(uint i=1;i<3;i++){
            if(_donates[_top3[i]] < _donates[_top3[minIndex]]){
                minIndex=i;
            }
            if(_top3[i]==msg.sender){
                isInTop3=true;
                break;
            }
        }
        if(!isInTop3 && _donates[_top3[minIndex]] < _donates[msg.sender]){
            _top3[minIndex] = msg.sender;
        }

        emit Donate(msg.sender, msg.value);
    }

    function withdraw()public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "balance must > 0");
        _owner.transfer(balance);
        emit Withdraw(msg.sender, balance);
    }

    function getDonation(address addr)public view returns(uint256){
        return _donates[addr];
    }

    function deadline()public view returns(uint256){
        return _deadline;
    }


    function top3()public view returns(address[3] memory){
        // 客户端需要自行判断空地址,这里不处理
        return _top3;
    }
}