import hre from "hardhat";
const { ethers } = hre;
import fs from "fs";

async function main() {
  const accounts = await ethers.getSigners();
  console.log(accounts[0].address);

  const Git3 = await hre.ethers.getContractAt(
    "Git3",
    "0xa709975Bc01e745432f8898499E7b9a60f420117"
  );

  let file = fs.readFileSync("test/git3.png");

  let buffer = Array.from(file).slice(0, 24576);
  let fileSize = buffer.length;
  console.log("buffer", buffer.length);

  let cost = 0;
  if (fileSize > 24 * 1024 - 326) {
    cost = Math.floor((fileSize + 326) / 1024 / 24);
  }
  let key = ethers.utils.toUtf8Bytes("aaa");
  let rept = await Git3.upload(key, buffer, {
    value: ethers.utils.parseEther(cost.toString()),
  });
  console.log("rept", "https://explorer.galileo.web3q.io/tx/" + rept.hash);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
