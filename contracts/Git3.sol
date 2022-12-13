//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "./IFileOperator.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "git3-evm-large-storage/contracts/LargeStorageManager.sol";
// import "evm-large-storage/contracts/W3RC3.sol";

contract Git3 is LargeStorageManager {

  struct refInfo {
    bytes20 hash;
    uint96 index; 
  }

  struct refData {
    bytes20 hash;
    string name;
  }

  mapping (string => refInfo) public nameToRefInfo; // dev => {hash: 0x1234..., index: 1 }
  string[] public refs;  // [main, dev, test, staging]

  function _convertRefInfo(refInfo memory info) internal view returns(refData memory res){
    res.hash = info.hash;
    res.name = refs[info.index];
  }

  constructor() LargeStorageManager(0) {
  }

  function download(bytes memory path) external view returns (bytes memory, bool) {
    return _get(keccak256(path));
  }

  function upload(bytes memory path, bytes calldata data) external payable {
    _putChunkFromCalldata(keccak256(path), 0, data,msg.value);
  }

  function uploadChunk(bytes memory path,uint256 chunkId,  bytes calldata data) external payable {
    _putChunkFromCalldata(keccak256(path), chunkId, data,msg.value);
  }

  function remove(bytes memory path) external {
    // The actually process of remove will remove all the chunks
    _remove(keccak256(path),0);
  }

  function size(bytes memory name) external view returns (uint256,uint256){
    return _size(keccak256(name));
  }

  function countChunks(bytes memory path)external view returns (uint256){
    return _countChunks(keccak256(path));
  }

  function listRefs() public view returns (refData[] memory list) {
    list = new refData[](refs.length);
    for (uint index = 0; index < refs.length; index++) {
      list[index] = _convertRefInfo(nameToRefInfo[refs[index]]);
    }
  }

  function setRef(string memory name, bytes20 refHash) public {
     // only execute `sload` once to reduce gas consumption
    refInfo memory srs;
    srs = nameToRefInfo[name];
    uint256 refsLen = refs.length;

    if (srs.hash == bytes20(0)) {
      // store refHash for the first time
      require(refsLen <= uint256(uint96(int96(-1))),"Refs exceed valid length");

      nameToRefInfo[name].hash = refHash;
      nameToRefInfo[name].index = uint96(refsLen);

      refs.push(name);

    }else{
      // only update refHash 
      nameToRefInfo[name].hash = refHash;
    }
  }

  function delRef(string memory name) public {
    // only execute `sload` once to reduce gas consumption
    refInfo memory srs;
    srs = nameToRefInfo[name];
    uint256 refsLen = refs.length;

    require(srs.hash != bytes20(0),"The name of reference does not exist");
    require(srs.index < refsLen,"System Error: Invalid index");

    if (srs.index < refsLen-1){
      refs[srs.index] = refs[refsLen - 1];
      nameToRefInfo[refs[refsLen - 1]].index = srs.index;
    }
    refs.pop();
    delete nameToRefInfo[name];
  }
}