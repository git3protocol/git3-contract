import hre from "hardhat";
const { ethers } = hre;
import fs from "fs";

async function main() {
  const accounts = await ethers.getSigners();
  console.log(accounts[0].address);

  const Git3 = await hre.ethers.getContractAt(
    "Git3Hub",
    "0x608860940b8f3D3247E1B301Cf2fA5690e6504DD"
  );

  let file = fs.readFileSync("scripts/git3.png");
  let rept
  let buffer = Array.from(file).slice(0, 24 * 1024 - 300);
  let fileSize = buffer.length;
  console.log("buffer", buffer.length);

  let cost = 0;
  // if (fileSize > 24 * 1024 - 326) {
  //   cost = Math.floor((fileSize + 326) / 1024 / 24);
  // }
  let repoName = Buffer.from("test123")
  // rept = await"test123" Git3.createRepo(repoName)

  let key = ethers.utils.toUtf8Bytes("aaa");
  // rept = await Git3.upload(repoName, key, buffer, {
  //   value: ethers.utils.parseEther(cost.toString()),
  //   gasLimit: 6000000
  // });

  rept = await Git3.transferOwnership(repoName, "0x1eD9c2F6814eA5225Bb78f2F2CA802Ded120077A")
  console.log(await Git3.download(repoName, key));

  // rept = await Git3.remove(repoName, key)

  console.log("rept", "https://explorer.galileo.web3q.io/tx/" + rept.hash);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
