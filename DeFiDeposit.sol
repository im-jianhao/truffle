// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title DeFiDeposit
 * @dev 带利息计算的去中心化存款合约
 * @notice 这个合约实现了存款、计息和提款功能，并有防护机制防止恶意提款
 * @author Your Name
 */
contract DeFiDeposit {
  // 状态变量

  /**
     * @dev 用户存款信息结构体
     * @notice 记录用户的存款金额和存款时间
     */
  struct DepositInfo {
    uint256 amount;      // 存款金额
    uint256 timestamp;   // 存款时间
    uint256 lastInterestCalculation; // 上次计算利息的时间
  }

  /**
     * @dev 存储每个地址的存款信息
     */
  mapping(address => DepositInfo) public deposits;

  /**
     * @dev 年化利率(基点：1% = 100)
     * 例如：500 表示 5% 年化利率
     */
  uint256 public constant ANNUAL_INTEREST_RATE = 500; // 5% 年化

  /**
     * @dev 最大提款限额(占总存款的百分比)
     */
  uint256 public constant MAX_WITHDRAWAL_PERCENTAGE = 50; // 50%

  /**
     * @dev 一年的秒数，用于利息计算
     */
  uint256 public constant SECONDS_PER_YEAR = 31536000; // 365 days

  // 事件定义
  event Deposit(address indexed user, uint256 amount);
  event Withdrawal(address indexed user, uint256 amount, uint256 interest);
  event InterestCalculated(address indexed user, uint256 interest);

  /**
     * @dev 存入ETH并开始计算利息
     */
  function deposit() public payable {
    require(msg.value > 0, "Deposit amount must be greater than 0");

    DepositInfo storage userDeposit = deposits[msg.sender];

    // 如果用户已有存款，先计算并添加之前的利息
    if (userDeposit.amount > 0) {
      uint256 interest = calculateInterest(msg.sender);
      userDeposit.amount += interest;
      emit InterestCalculated(msg.sender, interest);
    }

    // 更新存款信息
    userDeposit.amount += msg.value;
    userDeposit.timestamp = block.timestamp;
    userDeposit.lastInterestCalculation = block.timestamp;

    emit Deposit(msg.sender, msg.value);
  }

  /**
     * @dev 计算用户应得的利息
     * @param user 用户地址
     * @return 应得的利息金额
     */
  function calculateInterest(address user) public view returns (uint256) {
    DepositInfo storage userDeposit = deposits[user];

    if (userDeposit.amount == 0) {
      return 0;
    }

    uint256 timeElapsed = block.timestamp - userDeposit.lastInterestCalculation;

    // 使用基点计算利息：本金 * 年化利率 * 时间占比
    uint256 interest = (userDeposit.amount * ANNUAL_INTEREST_RATE * timeElapsed) 
    / (SECONDS_PER_YEAR * 10000);

    return interest;
  }

  /**
     * @dev 提取指定数量的ETH和对应的利息
     * @param amount 要提取的金额
     */
  function withdraw(uint256 amount) public {
    DepositInfo storage userDeposit = deposits[msg.sender];

    require(userDeposit.amount >= amount, "Insufficient balance");
    require(amount > 0, "Withdrawal amount must be greater than 0");

    // 计算当前利息
    uint256 interest = calculateInterest(msg.sender);
    uint256 totalBalance = userDeposit.amount + interest;

    // 检查提款限额
    uint256 maxWithdrawal = (totalBalance * MAX_WITHDRAWAL_PERCENTAGE) / 100;
        require(amount <= maxWithdrawal, "Exceeds maximum withdrawal limit");
        
        // 更新存款信息
        userDeposit.amount = totalBalance - amount;
        userDeposit.lastInterestCalculation = block.timestamp;
        
        // 发送ETH
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Transfer failed");
        
        emit Withdrawal(msg.sender, amount, interest);
    }

    /**
     * @dev 提取所有存款和利息
     * @notice 为防止挤兑，该功能已禁用
     */
    function withdrawAll() public {
        revert("Function disabled to prevent bank run");
    }

    /**
     * @dev 查询用户的总余额（包含利息）
     * @param user 要查询的用户地址
     * @return 用户的总余额(包含利息)
     */
    function getTotalBalance(address user) public view returns (uint256) {
        return deposits[user].amount + calculateInterest(user);
    }

    /**
     * @dev 查询合约的总余额
     */
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    receive() external payable {
        revert("Use deposit() to deposit ETH");
    }

    fallback() external payable {
        revert("Function does not exist");
    }
}