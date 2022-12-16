import hre from "hardhat";
const { ethers } = hre;
import fs from "fs";

async function main() {
    const accounts = await ethers.getSigners();
    console.log(accounts[0].address);

    const Git3 = await hre.ethers.getContractAt(
        "Git3Hub",
        "0x0068bD3ec8D16402690C1Eddff06ACb913A209ef"
    );
    let rept
    let owner = await Git3.repoNameToOwner(Buffer.from("helloworld1"))
    console.log(owner)
    // return
    rept = await Git3.createRepo(Buffer.from("helloworld1"))
    console.log("rept", "https://explorer.galileo.web3q.io/tx/" + rept.hash);

    // rept = await Git3.transferOwnership(Buffer.from("helloworld"), "0x1eD9c2F6814eA5225Bb78f2F2CA802Ded120077A")
    // console.log("rept", "https://explorer.galileo.web3q.io/tx/" + rept.hash)
}

main().catch((error) => {
    console.error(error);
    process.exit(1);
});
