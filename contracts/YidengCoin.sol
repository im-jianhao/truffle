// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract YidengCoin is ERC20 {
    string public constant NAME = "YidengERC20Token";
    string public constant SYMBOL = "YD";
    uint256 public constant INITAL_SUPPL = 10000;
    constructor() ERC20(NAME, SYMBOL) {
        _mint(msg.sender, INITAL_SUPPL);
    }

    function decimals() public view virtual override returns (uint8) {
        return 0;
    }
}
