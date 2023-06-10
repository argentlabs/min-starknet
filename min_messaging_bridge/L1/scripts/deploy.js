const fs = require("fs");
const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  console.log("Account balance:", (await deployer.getBalance()).toString());

  // deploying the token bridge contract
  const TokenBridge = await ethers.getContractFactory("ERC20Bridge");
  //Passing Starknet core contract address and Stake L2 address
  const bridge = await TokenBridge.deploy(
    "0xde29d060D45901Fb19ED6C6e959EB22d8626708e", //core contract for goerli testnet
    "0x03b716d0d4b01f1a095f443fd49f1a10c0c90c980242a41131fe9d9d47a543d1", // L2 contract address
    "0x9F7D1801163902A50C168f310691FdC97C346395" //bridge admin address
  );

  // Deploying the ERC20
  const ERC20 = await ethers.getContractFactory("MinStarknet");
  const erc20 = await ERC20.deploy(
    bridge.address //bridge contract address
  );

  // Deploying the Token Bridge contract
  console.log("Token Bridge smart contract address:", bridge.address);
  console.log("ERC20 smart contract address:", erc20.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });