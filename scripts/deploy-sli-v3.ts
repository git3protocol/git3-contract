import { ethers } from "hardhat";

async function main() {
  let provider = ethers.provider;
  let [operator] = await ethers.getSigners();
  let nonce = await operator.getTransactionCount();

  let price = await provider.getFeeData();
  console.log(price);

  console.log(operator.address, nonce);

  const Git3Fac = await ethers.getContractFactory("HubFactory");
  const hubFac = await Git3Fac.deploy(false, { nonce: nonce });

  let logicReceipt = await hubFac.deployed();
  console.log(logicReceipt.deployTransaction.hash);
  nonce++;

  let newHubReceipt = await hubFac.newHubImp({ nonce: nonce });
  nonce++;

  // let createHubReceipt = await hubFac.createHub(false, { nonce: nonce });
  // nonce++;

  // let hubAddr = await hubFac.hubs(0);
  // let git3 = await ethers.getContractAt("Hubv3", hubAddr);

  // console.log({logicReceipt,proxyReceipt});
  console.log("HubFactory Contract", hubFac.address);
  // console.log("Hub Contract", git3.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
