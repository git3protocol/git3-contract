import { ethers } from "hardhat";

async function main() {
  let provider = ethers.provider;
  let [operator] = await ethers.getSigners();
  let nonce = await operator.getTransactionCount();
  console.log(operator.address, nonce, await operator.getBalance());

  let price = await provider.getFeeData();
  let net = await provider.getNetwork();
  console.log(price, net.chainId);

  const Nameservice = await ethers.getContractFactory("Git3NameService");
  const ns = await Nameservice.deploy({
    nonce: nonce,
    type: 2,
    maxFeePerGas: price.maxFeePerGas!,
    maxPriorityFeePerGas: price.maxPriorityFeePerGas!,
  });

  let receipt = await ns.deployed();
  console.log(receipt.deployTransaction.hash);
  console.log("NS Contract", ns.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
