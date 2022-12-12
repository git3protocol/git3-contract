//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "./IFileOperator.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "evm-large-storage/contracts/examples/FlatDirectory.sol";
// import "evm-large-storage/contracts/W3RC3.sol";

contract Git3 {
  uint256 constant REF_HASH_LEN = 40;
  IFileOperator public immutable storageManager;

  constructor() {
    storageManager = IFileOperator(address(new FlatDirectory(220)));
  }

  // download(path: string): Promise<[Status, Buffer]> // objects/3e/3432eac32.../
  function download(bytes memory path) external view returns (bytes memory, bool) {
    // call flat directory(FD)
    return storageManager.read(path);
  }

  // upload(path: string, file: Buffer): Promise<Status>
  function upload(bytes memory path, bytes memory data) external payable {
    storageManager.writeChunk(path, 0, data);
  }

  function uploadChunk(bytes memory path,uint256 chunkId,  bytes memory data) external payable {
    storageManager.writeChunk(path, chunkId, data);
  }

  // delete(path: string): Promise<Status>
  function remove(bytes memory path) external {
    // The actually process of remove will remove all the chunks
    storageManager.remove(path);
  }

  function size(bytes memory name) external view returns (uint256,uint256){
    return storageManager.size(name);
  }

  function countChunks(bytes memory name)external view returns (uint256){
    return storageManager.countChunks(name);
  }


  /*
  The Storage Layout as below:
    slot n   = [hash1]
    slot n+1 = [hash2,index]
  **/
  struct refInfo {
    bytes32 hash1;
    bytes8 hash2;
    uint192 index; // 8 * 24 = 192
  }

  struct refData {
    bytes hash;
    string name;
  }

  mapping (string => refInfo) public nameToRefInfo; // dev => {hash: 0x1234..., index: 1 }
  string[] public refs;  // [main, dev, test, staging]

  function _setRefInfo(refInfo storage ref, bytes memory hash,uint192 index) internal{
    require(hash.length == REF_HASH_LEN,"Incorrect RefHash Length");
    bytes32 hash1;
    bytes32 hash2;

    assembly{
      hash1 := mload(add(hash,0x20))
      // sstore(ref.slot,hash1)
      hash2 := mload(add(hash,0x40))
      // sstore(add(ref.slot,0x20),add(hash2,index))
    }

    ref.hash1 = hash1;
    ref.hash2 = bytes8(hash2);
    ref.index = index;
  }

  // listRefs(): Promise<Ref[]>
  function _convertRefInfo(refInfo storage info) internal view returns(refData memory res){
    // res .hash = 
    bytes memory hash = new bytes(REF_HASH_LEN);

    // sload hash1 and hash2 
    bytes32 hash1 = info.hash1;
    bytes8 hash2 = info.hash2;
    assembly {
      mstore(add(hash,0x20),hash1)
      mstore(add(hash,0x40),hash2)
    }
    res.hash = hash;
    res.name = refs[info.index];
  }

  function listRefs() public view returns (refData[] memory list) {
    list = new refData[](refs.length);
    for (uint index = 0; index < refs.length; index++) {
      list[index] = _convertRefInfo(nameToRefInfo[refs[index]]);
    }
  }

  // setRef(path: string, sha: string): Promise<Status>
  function setRef(string memory name, bytes memory refHash) public {

    refInfo memory srs;
    srs = nameToRefInfo[name];

    if (srs.hash1 == bytes32(0) && srs.hash2 == bytes8(0)) {
      // store refHash for the first time
      require(refs.length <= uint256(uint192(int192(-1))),"refs exceed valid length");

      _setRefInfo(nameToRefInfo[name],refHash,uint192(refs.length));
      refs.push(name);
    }else{
      // only update refHash 
      _setRefInfo(nameToRefInfo[name],refHash,srs.index);
    }
  }

  // delRef(path: string): Promise<Status>
  function delRef(string memory name) public {
    // only execute `sload` once to reduce gas consumption
    refInfo memory srs;
    srs = nameToRefInfo[name];
    uint256 refsLen = refs.length;

    require(srs.hash1 != bytes32(0) || srs.hash2 != bytes8(0),"Reference of this name does not exist");

    require(srs.index < refsLen,"System Error: Invalid index");
    if (srs.index < refsLen-1){
      refs[srs.index] = refs[refsLen - 1];
      nameToRefInfo[refs[refsLen - 1]].index = srs.index;
    }
    refs.pop();
    delete nameToRefInfo[name];
  }
}