// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8;


contract P1ERC20 {
    uint private _totalSupply;
    mapping(address => uint) private _balances;
    mapping(address => mapping(address => uint)) private _allowances;
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    address private _owner;
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

    modifier onlyOwner {
        require(msg.sender == _owner, "ERC20: only owner can call this function");
        _;
    }

    constructor(string memory name_, string memory symbol_, uint8 decimals_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        _owner = msg.sender;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view returns (uint256){
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256){
        return _balances[account];
    }

    function transfer(address to, uint256 amount) public returns (bool){ 
        require(to != address(0), "ERC20: transfer to the zero address");
        return _transfer(msg.sender, to, amount);
    }

    function _transfer(address from, address to, uint256 amount) internal returns (bool){
        require(to != address(0), "ERC20: transfer to the zero address");
        require(_balances[from] >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] -= amount;
            _balances[to] += amount;
        }
        emit Transfer(from, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public returns (bool){
        // 是否允许重复approve?
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256){
        return _allowances[owner][spender];
    }

    function transferFrom(address from, address to, uint256 amount) public returns (bool){
        require(_allowances[from][msg.sender] >= amount, "ERC20: transfer amount exceeds allowance");
        require(_balances[from] >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _allowances[from][msg.sender] -= amount;
            _balances[from] -= amount;
            _balances[to] += amount;
        }
        emit Transfer(from, to, amount);
        return true;
    }

    function mint(address to, uint256 amount) public onlyOwner returns (bool){
        require(msg.sender == _owner, "ERC20: only owner can mint");
        require(to != address(0), "ERC20: mint to the zero address");
        _totalSupply += amount;
        _balances[to] += amount;
        emit Transfer(address(0), to, amount);
        return true;
    }

}