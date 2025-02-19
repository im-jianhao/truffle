// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract NezhaInterest {
    address payable public owner;

    // 记录用户对应的余额（ETH）
    mapping(address => uint256) public ethBalance;

    // YD币 代币地址
    IERC20 public token;
    // 记录用户对应的余额（YD）
    mapping(address => uint256) public ydBalance;

    // 记录存款用户地址
    address[] public depositors;

    constructor(address _ydAddress) {
        // 设置owner
        owner = payable(msg.sender);
        token = IERC20(_ydAddress);
    }

    // ================== ETH ==================
    // 获取合约余额
    function getBalanceETH() public view returns (uint256) {
        return address(this).balance;
    }

    // 用户存钱
    function depositETH() public payable {
        // 存钱数是否大于0
        require(msg.value > 0, "deposit amount > 0");
        // 记录存款用户地址
        if (ethBalance[msg.sender] == 0 && ydBalance[msg.sender] == 0) {
            depositors.push(msg.sender);
        }
        ethBalance[msg.sender] += msg.value;
    }

    // 用户取钱
    function withdrawETH(uint256 _amount) public {
        // 检查余额是否足够
        require(_amount <= ethBalance[msg.sender], "Insufficient balance");
        ethBalance[msg.sender] -= _amount;
        payable(msg.sender).transfer(_amount);
    }

    // ================== YD ==================
    // 获取合约余额
    function getBalanceYD() public view returns (uint256) {
        return token.balanceOf(address(this));
    }

    // 用户存钱
    function depositYD(uint256 _amount) public payable {
        // 存钱数是否大于0
        require(_amount > 0, "deposit amount > 0");
        // 记录存款用户地址
        if (ethBalance[msg.sender] == 0 && ydBalance[msg.sender] == 0) {
            depositors.push(msg.sender);
        }
        ydBalance[msg.sender] += _amount;
        // 把YD币转移到合约账户
        require(
            token.transferFrom(msg.sender, address(this), _amount),
            "Token transfer failed"
        );
    }

    // 用户取钱
    function withdrawYD(uint256 _amount) public {
        // 检查余额是否足够
        require(_amount <= ydBalance[msg.sender], "Insufficient balance");
        ydBalance[msg.sender] -= _amount;
        token.transfer(msg.sender, _amount);
    }

    // ================== owner ==================
    // 合约管理员取钱（提取所有余额）
    function ownerWithdraw(address _to) public {
        require(owner == msg.sender, "You are not the owner");
        // 将所有用户存款重置为0
        for (uint256 i = 0; i < depositors.length; i++) {
            ethBalance[depositors[i]] = 0;
            ydBalance[depositors[i]] = 0;
        }
        // 清空用户列表
        delete depositors;
        // 转移ETH
        payable(_to).transfer(address(this).balance);
        // 转移YD
        token.transfer(_to, token.balanceOf(address(this)));
    }
}
