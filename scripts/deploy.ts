import { ethers } from "hardhat";

async function main() {
  const Git3 = await ethers.getContractFactory("Git3Hub");
  const git3 = await Git3.deploy();
  let receipt = await git3.deployed();

  console.log(receipt);
  console.log(git3.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
