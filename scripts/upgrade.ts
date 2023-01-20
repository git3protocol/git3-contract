import { ethers } from "hardhat";

async function main(proxyAddr:string) {

  const Git3 = await ethers.getContractFactory("Git3Hub");
  const git3 = await Git3.deploy();
  let logicReceipt = await git3.deployed()

  let proxyInstance = await ethers.getContractAt("UpgradeableProxy",proxyAddr);
  // Proxy don't need to init Git3 contract because the constructor is empty.
  let initSelector = "0x";
  let [operator,] = await ethers.getSigners();
  let receipt = await proxyInstance
    .connect(operator)
    .upgradeToAndCall(git3.address, initSelector);
  await receipt.wait();

  console.log("upgradeTxHash:",receipt.hash);
}

main(process.argv0).catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
