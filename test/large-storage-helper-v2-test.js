const { web3 } = require("hardhat");
const { expect } = require("chai");
const { ethers } = require("hardhat");
const { defaultAbiCoder } = require("ethers/lib/utils");

var ToBig = (x) => ethers.BigNumber.from(x);
const contractName = "LargeStorageManagerV2Test";
let key = Buffer.from("a".repeat(32));
let ETH = ethers.BigNumber.from("10").pow("18");
describe("FlatDirectory Test", function () {
  it("read/write", async function () {
    const FlatDirectory = await ethers.getContractFactory(contractName);
    const fd = await FlatDirectory.deploy(0);
    await fd.deployed();

    await fd.putChunk(key, 0, "0x112233");
    expect(await fd.get(key)).to.eql(["0x112233", true]);

    let data = Array.from({ length: 40 }, () =>
      Math.floor(Math.random() * 256)
    );
    await fd.putChunk(key, 0, data);
    expect(await fd.get(key)).to.eql([ethers.utils.hexlify(data), true]);
    expect(await fd.size(key)).to.eql([ToBig(40), ToBig(1)]);
  });

  it("read/write chunks", async function () {
    const FlatDirectory = await ethers.getContractFactory(contractName);
    const fd = await FlatDirectory.deploy(0);
    await fd.deployed();

    let data0 = Array.from({ length: 1024 }, () =>
      Math.floor(Math.random() * 256)
    );
    await fd.putChunk(key, 0, data0);
    expect(await fd.get(key)).to.eql([ethers.utils.hexlify(data0), true]);

    let data1 = Array.from({ length: 512 }, () =>
      Math.floor(Math.random() * 256)
    );
    await fd.putChunk(key, 1, data1);
    expect(await fd.getChunk(key, 1)).to.eql([
      ethers.utils.hexlify(data1),
      true,
    ]);

    let data = data0.concat(data1);
    expect(await fd.get(key)).to.eql([ethers.utils.hexlify(data), true]);
    expect(await fd.size(key)).to.eql([ToBig(1536), ToBig(2)]);
  });

  it("write/remove chunks", async function () {
    const FlatDirectory = await ethers.getContractFactory(contractName);
    const fd = await FlatDirectory.deploy(0);
    await fd.deployed();

    expect(await fd.countChunks(key)).to.eql(ToBig(0));

    let data0 = Array.from({ length: 10 }, () =>
      Math.floor(Math.random() * 256)
    );
    await fd.putChunk(key, 0, data0);
    expect(await fd.get(key)).to.eql([ethers.utils.hexlify(data0), true]);

    let data1 = Array.from({ length: 20 }, () =>
      Math.floor(Math.random() * 256)
    );
    await fd.putChunk(key, 1, data1);
    expect(await fd.getChunk(key, 1)).to.eql([
      ethers.utils.hexlify(data1),
      true,
    ]);

    await fd.removeChunk(key, 0); // should do nothing
    expect(await fd.size(key)).to.eql([ToBig(30), ToBig(2)]);
    expect(await fd.countChunks(key)).to.eql(ToBig(2));
    expect(await fd.getChunk(key, 0)).to.eql([
      ethers.utils.hexlify(data0),
      true,
    ]);

    await fd.removeChunk(key, 1); // should succeed
    expect(await fd.size(key)).to.eql([ToBig(10), ToBig(1)]);
    expect(await fd.get(key)).to.eql([ethers.utils.hexlify(data0), true]);
    expect(await fd.getChunk(key, 1)).to.eql(["0x", false]);
    expect(await fd.countChunks(key)).to.eql(ToBig(1));
  });

  it("remove chunks and refund to user", async function () {
    const FlatDirectory = await ethers.getContractFactory(contractName);
    const fd = await FlatDirectory.deploy(0);
    await fd.deployed();

    let stakeTokenNum = ETH;
    let signer;
    [signer] = await ethers.getSigners();

    let data0 = Array.from({ length: 10 }, () =>
      Math.floor(Math.random() * 256)
    );
    await fd.putChunk(key, 0, data0, { value: stakeTokenNum });
    expect(await fd.get(key)).to.eql([ethers.utils.hexlify(data0), true]);

    let data1 = Array.from({ length: 20 }, () =>
      Math.floor(Math.random() * 256)
    );
    await fd.putChunkFromCalldata(key, 1, data1, { value: stakeTokenNum });
    expect(await fd.getChunk(key, 1)).to.eql([
      ethers.utils.hexlify(data1),
      true,
    ]);

    // get stake tokens from files
    let amount = await fd.stakeTokens(key, 0);
    expect(amount).to.equal(stakeTokenNum.mul(2));

    let amount1 = await fd.stakeTokens(key, 1);
    expect(amount1).to.equal(stakeTokenNum);

    let chunk0Addr = await fd.getChunkAddr(key, 0);
    let chunk0Balance = await ethers.provider.getBalance(chunk0Addr);
    expect(chunk0Balance).to.equal(stakeTokenNum);

    // check the balance of user after removing chunk
    // The tokens pledged by the chunk should all be returned to the user
    let balBefore = await signer.getBalance();
    let tx1 = await fd.remove(key); // should succeed
    let rec1 = await tx1.wait();
    amount1 = await fd.stakeTokens(key, 1);
    expect(amount1).to.equal(ethers.BigNumber.from("0"));
    let removeTxCost = rec1.gasUsed.mul(rec1.effectiveGasPrice);
    let balAfter = await signer.getBalance();
    // check balance after refunding
    expect(
      balBefore.add(stakeTokenNum).add(stakeTokenNum).sub(removeTxCost)
    ).to.eq(balAfter);
  });
});
