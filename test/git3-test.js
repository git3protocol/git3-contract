const { web3 } = require("hardhat");
const { expect } = require("chai");
const { ethers } = require("hardhat");
const { defaultAbiCoder } = require("ethers/lib/utils");

var ToBig = (x) => ethers.BigNumber.from(x);

describe("Git3 Test", function () {
  it("upload/download/remove", async function () {
    const Git3 = await ethers.getContractFactory("Git3");
    const git3 = await Git3.deploy();
    await git3.deployed();

    let singer;
    [singer] = await ethers.getSigners();
    console.log("singer", singer.address);

    await git3.upload("0x616263", "0x112233");
    expect(await git3.download("0x616263")).to.eql(["0x112233", true]);

    let data = Array.from({ length: 40 }, () => Math.floor(Math.random() * 256));

    await git3.upload("0x616263", data);
    expect(await git3.download("0x616263")).to.eql([ethers.utils.hexlify(data), true]);

    expect(await git3.size("0x616263")).to.eql([ToBig(40), ToBig(1)]);

    await git3.remove("0x616263");
    expect(await git3.size("0x616263")).to.eql([ToBig(0), ToBig(0)]);
  });

  it("upload/download/remove chunks", async function () {
    const Git3 = await ethers.getContractFactory("Git3");
    const git3 = await Git3.deploy();
    await git3.deployed();

    expect(await git3.countChunks("0x616263")).to.eql(ToBig(0));

    let data0 = Array.from({ length: 10 }, () => Math.floor(Math.random() * 256));
    await git3.uploadChunk("0x616263", 0, data0);
    expect(await git3.download("0x616263")).to.eql([ethers.utils.hexlify(data0), true]);

    let data1 = Array.from({ length: 20 }, () => Math.floor(Math.random() * 256));
    await git3.uploadChunk("0x616263", 1, data1);
    expect(await git3.download("0x616263")).to.eql([ethers.utils.hexlify(data0.concat(data1)), true]);

    await git3.remove("0x616263"); // should succeed
    expect(await git3.size("0x616263")).to.eql([ToBig(0), ToBig(0)]);
    expect(await git3.download("0x616263")).to.eql(["0x", false]);
    expect(await git3.countChunks("0x616263")).to.eql(ToBig(0));
  });

  it("set/update/list/remove Reference", async function () {
    const Git3 = await ethers.getContractFactory("Git3");
    const git3 = await Git3.deploy();
    await git3.deployed();

    let key0 = "0x616263";
    let data0 = "0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa";
    await git3.setRef(key0, data0);

    let key1 = "0x717273";
    let data1 = "0xbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb";
    await git3.setRef(key1, data1);

    let key2 = "0x818283";
    let data2 = "0xcccccccccccccccccccccccccccccccccccccccc";
    await git3.setRef(key2, data2);

    let refs = await git3.listRefs();
    expect(refs[0]).to.eql([data0, key0]);
    expect(refs[1]).to.eql([data1, key1]);
    expect(refs[2]).to.eql([data2, key2]);
    expect(refs.length).to.eql(3);

    // check delRef
    await git3.delRef(key0);
    refs = await git3.listRefs();
    expect(refs[0]).to.eql([data2, key2]);
    expect(refs[1]).to.eql([data1, key1]);
    expect(refs.length).to.eql(2);

    await git3.delRef(key1);
    refs = await git3.listRefs();
    expect(refs[0]).to.eql([data2, key2]);
    expect(refs.length).to.eql(1);

    // check update
    let data3 = "0xdddddddddddddddddddddddddddddddddddddddd";
    await git3.setRef(key2, data3);
    refs = await git3.listRefs();
    expect(refs[0]).to.eql([data3, key2]);
  });
});
