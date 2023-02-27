const { web3 } = require("hardhat");
const { expect } = require("chai");
const { ethers } = require("hardhat");
const { defaultAbiCoder } = require("ethers/lib/utils");
const { isConstructorDeclaration } = require("typescript");

var ToBig = (x) => ethers.BigNumber.from(x);
let ETH = ethers.BigNumber.from(10).pow(18);

describe("Hub V3 Test", function () {


    it("Hub Access Control", async function () {
      const hubfacFac = await ethers.getContractFactory("HubFactory");
      const hubFac = await hubfacFac.deploy(false);
      await hubFac.deployed();
  
      await hubFac.newHubImp();
  
      expect(await hubFac.createHub(true)).to.emit(hubFac,"CreateHub");
      let hub = await hubFac.hubs(0);
      console.log(hub);
      let git3 = await ethers.getContractAt("Hubv3",hub)
        let [singer,manager1,manager2,con1,con2,repoCon1,repoCon2] = await ethers.getSigners();
      

        let [IsAdmin,IsManager,IsContributor] = await git3.memberRole(singer.address);
        expect(IsAdmin).to.equal(true);
        expect(IsManager).to.equal(true);
        expect(IsContributor).to.equal(false);

        let ADMIN_ROLE = await git3.DEFAULT_ADMIN_ROLE();
        let addrs = await git3.roleToMembers(ADMIN_ROLE);
        expect(addrs[0]).to.equal(singer.address);

        await git3.addManager(manager1.address)
        await git3.addManager(manager2.address)
        let roles = await git3.memberRole(manager1.address)
        expect(roles[0]).to.equal(false);
        expect(roles[1]).to.equal(true);
        expect(roles[2]).to.equal(false);

        let MANAGER_ROLE = await git3.MANAGER();
        let m_addrs = await git3.roleToMembers(MANAGER_ROLE);
        expect(m_addrs[0]).to.equal(singer.address);
        expect(m_addrs[1]).to.equal(manager1.address);
        expect(m_addrs[2]).to.equal(manager2.address);


        roles = await git3.memberRole(manager2.address)
        expect(roles[0]).to.equal(false);
        expect(roles[1]).to.equal(true);
        expect(roles[2]).to.equal(false);

        await git3.removeManager(manager2.address)
        roles = await git3.memberRole(manager2.address)
        expect(roles[0]).to.equal(false);
        expect(roles[1]).to.equal(false);
        expect(roles[2]).to.equal(false);
        m_addrs = await git3.roleToMembers(MANAGER_ROLE);
        expect(m_addrs.length).to.equal(2);
        expect(m_addrs[0]).to.equal(singer.address);
        expect(m_addrs[1]).to.equal(manager1.address);

        // power no enough
        await expect(
            git3.connect(manager2).addContributor(con1.address)
            ).to.be.reverted


        await git3.connect(manager1).addContributor(con1.address)
        await git3.connect(manager1).addContributor(con2.address)

        roles = await git3.memberRole(con1.address)
        expect(roles[0]).to.equal(false);
        expect(roles[1]).to.equal(false);
        expect(roles[2]).to.equal(true);

        roles = await git3.memberRole(con2.address)
        expect(roles[0]).to.equal(false);
        expect(roles[1]).to.equal(false);
        expect(roles[2]).to.equal(true);
        
        await git3.connect(manager1).removeContributor(con2.address)
        roles = await git3.memberRole(con2.address)
        expect(roles[0]).to.equal(false);
        expect(roles[1]).to.equal(false);
        expect(roles[2]).to.equal(false);
        
        const repoName = "0x616263"
        await git3.connect(con1).createRepo(repoName)
        let repoOwner = await git3.connect(con1).repoOwner(repoName)
        expect(repoOwner).to.equal(con1.address)
        
        await git3.connect(con1).addRepoContributor(repoName,repoCon1.address)
        await git3.connect(con1).addRepoContributor(repoName,repoCon2.address)
        let cons = await git3.connect(con1).repoContributors(repoName)
        expect(cons[0]).to.equal(repoCon1.address)
        expect(cons[1]).to.equal(repoCon2.address)

        const branchPath = "0x2244"
        const branchRefHash = "0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
        const branchRefHash1 = "0x111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
        const branchRefHash2 = "0x222aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
        const emptyRefHash = "0x0000000000000000000000000000000000000000"

        const anotherBranchPath = "0x6644"
        const anotherBranchRefHash = "0xffffaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
        await expect(
            git3.connect(singer).setRepoRef(repoName,branchPath,branchRefHash)
        ).to.be.reverted

        await git3.connect(repoCon1).setRepoRef(repoName,branchPath,branchRefHash)
        expect(await git3.getRepoRef(repoName,branchPath)).to.eq(branchRefHash)

        await git3.connect(repoCon1).setRepoRef(repoName,branchPath,branchRefHash1)
        expect(await git3.getRepoRef(repoName,branchPath)).to.eq(branchRefHash1)

        await git3.connect(repoCon2).setRepoRef(repoName,branchPath,branchRefHash2)
        expect(await git3.getRepoRef(repoName,branchPath)).to.eq(branchRefHash2)
        
        await git3.connect(repoCon1).delRepoRef(repoName,branchPath)
        expect(await git3.getRepoRef(repoName,branchPath)).to.eq(emptyRefHash)

        await git3.connect(con1).setRepoRef(repoName,anotherBranchPath,anotherBranchRefHash)
        expect(await git3.getRepoRef(repoName,anotherBranchPath)).to.eq(anotherBranchRefHash)
        
        let refs = await git3.listRepoRefs(repoName);
        console.log(refs);

    })


  it("upload/download/remove", async function () {
    const hubfacFac = await ethers.getContractFactory("HubFactory");
    const hubFac = await hubfacFac.deploy(true);
    await hubFac.deployed();

    await hubFac.newHubImp();

    expect(await hubFac.createHub(true)).to.emit(hubFac,"CreateHub");
    let hub = await hubFac.hubs(0);
    console.log(hub);
    let git3 = await ethers.getContractAt("Hubv3",hub)

    let singer;
    [singer] = await ethers.getSigners();
    const repoName = Buffer.from("test");

    await git3.createRepo(repoName);

    await git3.upload(repoName, "0x616263", "0x112233");
    expect(await git3.download(repoName, "0x616263")).to.eql([
      "0x112233",
      true,
    ]);

    let data = Array.from({ length: 40 }, () =>
      Math.floor(Math.random() * 256)
    );

    await git3.upload(repoName, "0x616263", data);
    expect(await git3.download(repoName, "0x616263")).to.eql([
      ethers.utils.hexlify(data),
      true,
    ]);

    // expect(await git3.size(repoName, "0x616263")).to.eql([ToBig(40), ToBig(1)]);

    // await git3.remove(repoName, "0x616263");
    // expect(await git3.size(repoName, "0x616263")).to.eql([ToBig(0), ToBig(0)]);
  });

  it("set/update/list/remove Branch", async function () {
    const hubfacFac = await ethers.getContractFactory("HubFactory");
    const hubFac = await hubfacFac.deploy(true);
    await hubFac.deployed();

    await hubFac.newHubImp();

    expect(await hubFac.createHub(true)).to.emit(hubFac,"CreateHub");
    let hub = await hubFac.hubs(0);
    console.log(hub);
    let git3 = await ethers.getContractAt("Hubv3",hub)

    let repoName = Buffer.from("test");
    await git3.createRepo(repoName);

    function concatHexStr(s1, s2) {
      return "0x" + Buffer.concat([s1, Buffer.from("/"), s2]).toString("hex");
    }

    let key0 = Buffer.from("refs/heads/master");
    let data0 = "0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa";
    await git3.setRepoRef(repoName, key0, data0);

    let key1 = Buffer.from("refs/heads/dev");
    let data1 = "0xbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb";
    await git3.setRepoRef(repoName, key1, data1);

    let key2 = Buffer.from("refs/heads/main");
    let data2 = "0xcccccccccccccccccccccccccccccccccccccccc";
    await git3.setRepoRef(repoName, key2, data2);

    let refs = await git3.listRepoRefs(repoName);
    expect(refs[0]).to.eql([data0, concatHexStr(repoName, key0)]);
    expect(refs[1]).to.eql([data1, concatHexStr(repoName, key1)]);
    expect(refs[2]).to.eql([data2, concatHexStr(repoName, key2)]);
    expect(refs.length).to.eql(3);

    // check delRef
    await git3.delRepoRef(repoName, key0);
    refs = await git3.listRepoRefs(repoName);
    expect(refs[0]).to.eql([data2, concatHexStr(repoName, key2)]);
    expect(refs[1]).to.eql([data1, concatHexStr(repoName, key1)]);
    expect(refs.length).to.eql(2);

    await git3.delRepoRef(repoName, key1);
    refs = await git3.listRepoRefs(repoName);
    expect(refs[0]).to.eql([data2, concatHexStr(repoName, key2)]);
    expect(refs.length).to.eql(1);

    // check update
    let data3 = "0xdddddddddddddddddddddddddddddddddddddddd";
    await git3.setRepoRef(repoName, key2, data3);
    refs = await git3.listRepoRefs(repoName);
    expect(refs[0]).to.eql([data3, concatHexStr(repoName, key2)]);
  });

  it("upload chunks", async function () {
    const hubfacFac = await ethers.getContractFactory("HubFactory");
    const hubFac = await hubfacFac.deploy(true);
    await hubFac.deployed();

    await hubFac.newHubImp();

    expect(await hubFac.createHub(true)).to.emit(hubFac,"CreateHub");
    let hub = await hubFac.hubs(0);
    console.log(hub);
    let git3 = await ethers.getContractAt("Hubv3",hub)

    let chunk = Buffer.alloc(10 * 1024, Math.random(1024).toString());
    console.log(chunk);
    let chunk_1 = Buffer.alloc(5*1024)
    let chunk_2 = Buffer.alloc(2*1024)
    chunk.copy(chunk_1,0,0,5*1024)
    chunk.copy(chunk_2,0,5*1024,7*1024)
    expect(chunk.compare(chunk_1,0,5*1024,0,5*1024)).to.eq(0);
    expect(chunk.compare(chunk_2,0,2*1024,5*1024,7*1024)).to.eq(0);
    expect(chunk.length).to.eq(10 * 1024);



    let tx = await git3.uploadChunk(Buffer.from("git3"),Buffer.from("git3/test") ,0,"0x"+chunk.toString("hex"),{value:ethers.utils.parseEther("1")})
    let rec = await tx.wait();
    console.log("Receipt:",rec)
    let context = await git3.download(Buffer.from("git3"),Buffer.from("git3/test"))
    expect(context[0]).to.equal("0x"+chunk.toString("hex"));
  })

  it("HubFactory", async function () {

    const hubfacFac = await ethers.getContractFactory("HubFactory");
    const hubFac = await hubfacFac.deploy(true);
    await hubFac.deployed();

    await hubFac.newHubImp();

    expect(await hubFac.createHub(true)).to.emit(hubFac,"CreateHub");
    let hub = await hubFac.hubs(0);
    console.log(hub);
    let git3 = await ethers.getContractAt("Hubv3",hub)
  })

  

});
