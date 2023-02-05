import hre from "hardhat";
const { ethers } = hre;
import fs from "fs";

async function main() {
  const accounts = await ethers.getSigners();
  console.log(accounts[0].address);

  const Git3 = await hre.ethers.getContractAt(
    "Git3Hub_SLI",
    "0xF56A1dd941667911896B9B872AC79E56cfc6a3dB"
  );

  let res = await Git3.download(
    Buffer.from("h1"),
    Buffer.from("objects/9f/2781f252bddce27d26a4e9ae4acf965f09ba9f")
  );
  console.log(res);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
