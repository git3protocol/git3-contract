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
    const repoName = Buffer.from("test");

    await git3.createRepo(repoName);

    await git3.upload(repoName, "0x616263", "0x112233");
    expect(await git3.download(repoName, "0x616263")).to.eql(["0x112233", true]);

    let data = Array.from({ length: 40 }, () =>
      Math.floor(Math.random() * 256)
    );

    await git3.upload(repoName, "0x616263", data);
    expect(await git3.download(repoName, "0x616263")).to.eql([
      ethers.utils.hexlify(data),
      true,
    ]);

    expect(await git3.size(repoName, "0x616263")).to.eql([ToBig(40), ToBig(1)]);

    await git3.remove(repoName, "0x616263");
    expect(await git3.size(repoName, "0x616263")).to.eql([ToBig(0), ToBig(0)]);
  });

  it("upload/download/remove chunks", async function () {
    const Git3 = await ethers.getContractFactory("Git3");
    const git3 = await Git3.deploy();
    await git3.deployed();

    const repoName = Buffer.from("test");
    await git3.createRepo(repoName);

    expect(await git3.countChunks(repoName, "0x616263")).to.eql(ToBig(0));

    let data0 = Array.from({ length: 10 }, () =>
      Math.floor(Math.random() * 256)
    );
    await git3.uploadChunk(repoName, "0x616263", 0, data0);
    expect(await git3.download(repoName, "0x616263")).to.eql([
      ethers.utils.hexlify(data0),
      true,
    ]);

    let data1 = Array.from({ length: 20 }, () =>
      Math.floor(Math.random() * 256)
    );
    await git3.uploadChunk(repoName, "0x616263", 1, data1);
    expect(await git3.download(repoName, "0x616263")).to.eql([
      ethers.utils.hexlify(data0.concat(data1)),
      true,
    ]);

    await git3.remove(repoName, "0x616263"); // should succeed
    expect(await git3.size(repoName, "0x616263")).to.eql([ToBig(0), ToBig(0)]);
    expect(await git3.download(repoName, "0x616263")).to.eql(["0x", false]);
    expect(await git3.countChunks(repoName, "0x616263")).to.eql(ToBig(0));
  });

  it("set/update/list/remove Reference", async function () {
    const Git3 = await ethers.getContractFactory("Git3");
    const git3 = await Git3.deploy();
    await git3.deployed();

    let repoName = Buffer.from("test");
    await git3.createRepo(repoName);

    function concatHexStr(s1, s2) {
      return "0x" + Buffer.concat([s1, Buffer.from("/"), s2]).toString("hex");
    }

    let key0 = Buffer.from("refs/heads/master");
    let data0 = "0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa";
    await git3.setRef(repoName, key0, data0);

    let key1 = Buffer.from("refs/heads/dev");
    let data1 = "0xbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb";
    await git3.setRef(repoName, key1, data1);

    let key2 = Buffer.from("refs/heads/main");
    let data2 = "0xcccccccccccccccccccccccccccccccccccccccc";
    await git3.setRef(repoName, key2, data2);

    let refs = await git3.listRefs(repoName);
    expect(refs[0]).to.eql([data0, concatHexStr(repoName, key0)]);
    expect(refs[1]).to.eql([data1, concatHexStr(repoName, key1)]);
    expect(refs[2]).to.eql([data2, concatHexStr(repoName, key2)]);
    expect(refs.length).to.eql(3);

    // check delRef
    await git3.delRef(repoName, key0);
    refs = await git3.listRefs(repoName);
    expect(refs[0]).to.eql([data2, concatHexStr(repoName, key2)]);
    expect(refs[1]).to.eql([data1, concatHexStr(repoName, key1)]);
    expect(refs.length).to.eql(2);

    await git3.delRef(repoName, key1);
    refs = await git3.listRefs(repoName);
    expect(refs[0]).to.eql([data2, concatHexStr(repoName, key2)]);
    expect(refs.length).to.eql(1);

    // check update
    let data3 = "0xdddddddddddddddddddddddddddddddddddddddd";
    await git3.setRef(repoName, key2, data3);
    refs = await git3.listRefs(repoName);
    expect(refs[0]).to.eql([data3, concatHexStr(repoName, key2)]);
  });

  it("Access Control", async function () {
    const Git3 = await ethers.getContractFactory("Git3");
    const git3 = await Git3.deploy();
    await git3.deployed();

    let singer;
    let user1;
    [singer, user1,] = await ethers.getSigners();
    const repoName = Buffer.from("test")

    await git3.connect(singer).createRepo(repoName);

    await expect(git3.connect(user1).upload(repoName, "0x616263", "0x112233")).to.be.revertedWith("only owner");
    await expect(git3.connect(user1).uploadChunk(repoName, "0x616263", 0, "0x112233")).to.be.revertedWith("only owner");
    await expect(git3.connect(user1).setRef(repoName, "0x616263", "0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa")).to.be.revertedWith("only owner");

    await git3.connect(singer).upload(repoName, "0x616263", "0x112233")
    expect(await git3.download(repoName, "0x616263")).to.eql(["0x112233", true]);
    await git3.connect(singer).setRef(repoName, "0x616263", "0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa")

    await expect(git3.connect(user1).remove(repoName, "0x616263")).to.be.revertedWith("only owner");
    await expect(git3.connect(user1).delRef(repoName, "0x616263")).to.be.revertedWith("only owner");

  });

  it("RepoName Check", async function () {
    const Git3 = await ethers.getContractFactory("Git3");
    const git3 = await Git3.deploy();
    await git3.deployed();

    let repoName = Buffer.from("abcdefghijklmnopqrstuvwxyz0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ.-_");
    await git3.createRepo(repoName);
    await expect(git3.createRepo(repoName)).to.be.revertedWith("RepoName already exist");
    await expect(git3.createRepo(Buffer.from("a/b"))).to.be.revertedWith("RepoName must be alphanumeric or -._");
    await expect(git3.createRepo(Buffer.from("a".repeat(101)))).to.be.revertedWith("RepoName length must be 1-100");

  })
});
