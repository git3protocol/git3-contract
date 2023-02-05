import hre from "hardhat";
const { ethers } = hre;
import fs from "fs";

async function main() {
  const accounts = await ethers.getSigners();
  console.log(accounts[0].address);
  let provider = ethers.provider;
  let price = await provider.getFeeData();

  const Git3 = await hre.ethers.getContractAt(
    "Git3Hub_SLI",
    "0xF56A1dd941667911896B9B872AC79E56cfc6a3dB"
  );
  let rept;
  let repoName = Buffer.from("h2");
  let owner = await Git3.repoNameToOwner(repoName);
  console.log(owner);

  rept = await Git3.createRepo(repoName, {
    type: 2,
    maxFeePerGas: price.maxFeePerGas!,
    maxPriorityFeePerGas: price.maxPriorityFeePerGas!,
  });
  console.log("rept", "https://explorer.galileo.web3q.io/tx/" + rept.hash);

  rept = await Git3.transferOwnership(
    repoName,
    "0x1eD9c2F6814eA5225Bb78f2F2CA802Ded120077A",
    {
      type: 2,
      maxFeePerGas: price.maxFeePerGas!,
      maxPriorityFeePerGas: price.maxPriorityFeePerGas!,
    }
  );
  console.log("rept", "https://explorer.galileo.web3q.io/tx/" + rept.hash);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
