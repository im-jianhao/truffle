const NezhaInterest = artifacts.require("NezhaInterest");

module.exports = function (deployer) {
  const tokenAddress = "0x1491587f2b57d5cc0fd2162ab05f943c3b98e77f"; // ERC-20 代币地址
  deployer.deploy(NezhaInterest, tokenAddress);
};
