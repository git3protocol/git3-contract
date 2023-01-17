import { ethers } from "hardhat";

async function main() {
  const Git3 = await ethers.getContractFactory("Git3Hub");
  const git3 = await Git3.deploy();
  let logicReceipt = await git3.deployed()

  let factory1 = await ethers.getContractFactory("UpgradeableProxy");
  // Proxy don't need to init Git3 contract because the constructor is empty.
  let initSelector = "0x";
  let [operator,] = await ethers.getSigners();
  let proxyInstance = await factory1
    .connect(operator)
    .deploy(git3.address, operator.address, initSelector);
  let proxyReceipt = await proxyInstance.deployed()

  // console.log({logicReceipt,proxyReceipt});
  console.log("Logic Contract",git3.address);
  console.log("Proxy Contract",git3.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
