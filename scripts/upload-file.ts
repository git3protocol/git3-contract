import hre from "hardhat";
const { ethers } = hre;
import fs from "fs";

async function main() {
  const accounts = await ethers.getSigners();
  console.log(accounts[0].address);

  const Git3 = await hre.ethers.getContractAt(
    "Git3Hub",
    "0xcE386Fe1d237e42dd01c130DA19d32B2c3794C06"
  );

  let file = fs.readFileSync("scripts/git3.png");
  let rept
  let buffer = Array.from(file).slice(0, 24 * 1024 * 5);
  let fileSize = buffer.length;
  console.log("buffer", buffer.length);

  let cost = 0;
  if (fileSize > 24 * 1024 - 326) {
    cost = Math.floor((fileSize + 326) / 1024 / 24);
  }
  let repoName = Buffer.from("helloworld")
  // rept = await Git3.createRepo(repoName)

  let key = ethers.utils.toUtf8Bytes("aaa");
  // rept = await Git3.upload(repoName, key, buffer, {
  //   value: ethers.utils.parseEther(cost.toString()),
  // });
  console.log(await Git3.download(repoName, key));

  rept = await Git3.remove(repoName, key)

  console.log("rept", "https://explorer.galileo.web3q.io/tx/" + rept.hash);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
