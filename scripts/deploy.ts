import { ethers } from "hardhat";

async function main() {
  let provider = ethers.provider
  let [operator,] = await ethers.getSigners();
  let nonce = await operator.getTransactionCount()


  let price = await provider.getFeeData()
  console.log(price)

  console.log(operator.address, nonce)

  const Git3 = await ethers.getContractFactory("Git3Hub");
  const git3 = await Git3.deploy({ nonce: nonce });

  let logicReceipt = await git3.deployed()
  console.log(logicReceipt.deployTransaction.hash)
  nonce++


  let factory1 = await ethers.getContractFactory("UpgradeableProxy");
  // Proxy don't need to init Git3 contract because the constructor is empty.
  let initSelector = "0x";

  let proxyInstance = await factory1
    .connect(operator)
    .deploy(git3.address, operator.address, initSelector, { nonce: nonce });
  let proxyReceipt = await proxyInstance.deployed()
  console.log(proxyReceipt.deployTransaction.hash)

  // console.log({logicReceipt,proxyReceipt});
  console.log("Logic Contract", git3.address);
  console.log("Proxy Contract", proxyInstance.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
