//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "./IFileOperator.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "evm-large-storage/contracts/LargeStorageManager.sol";

// import "evm-large-storage/contracts/W3RC3.sol";

contract Git3 is LargeStorageManager {
    struct refInfo {
        bytes20 hash;
        uint96 index;
    }

    struct refData {
        bytes20 hash;
        bytes name;
    }

    mapping(bytes => address) public repoNameToOwner;
    mapping(bytes => refInfo) public nameToRefInfo; // dev => {hash: 0x1234..., index: 1 }
    mapping(bytes => bytes[]) public repoNameToRefs; // [main, dev, test, staging]

    function _convertRefInfo(
        bytes memory repoName,
        refInfo memory info
    ) internal view returns (refData memory res) {
        res.hash = info.hash;
        res.name = repoNameToRefs[repoName][info.index];
    }

    constructor() LargeStorageManager(0) {}

    modifier onlyOwner(bytes memory repoName) {
        require(repoNameToOwner[repoName] == msg.sender, "only owner");
        _;
    }

    function download(
        bytes memory repoName,
        bytes memory path
    ) external view returns (bytes memory, bool) {
        // call flat directory(FD)
        return _get(keccak256(bytes.concat(repoName, "/", path)));
    }

    function createRepo(bytes memory repoName) external{
        require(repoNameToOwner[repoName] == address(0),"RepoName already exist");
        repoNameToOwner[repoName] = msg.sender;
    }

    function upload(
        bytes memory repoName,
        bytes memory path,
        bytes calldata data
    ) external payable onlyOwner(repoName){
        _putChunkFromCalldata(
            keccak256(bytes.concat(repoName, "/", path)),
            0,
            data,
            msg.value
        );
    }

    function uploadChunk(
        bytes memory repoName,
        bytes memory path,
        uint256 chunkId,
        bytes calldata data
    ) external payable onlyOwner(repoName){
        _putChunkFromCalldata(
            keccak256(bytes.concat(repoName, "/", path)),
            chunkId,
            data,
            msg.value
        );
    }

    function remove(
        bytes memory repoName,
        bytes memory path
    ) external onlyOwner(repoName) {
        // The actually process of remove will remove all the chunks
        _remove(keccak256(bytes.concat(repoName, "/", path)), 0);
    }

    function size(
        bytes memory repoName,
        bytes memory name
    ) external view returns (uint256, uint256) {
        return _size(keccak256(bytes.concat(repoName, "/", name)));
    }

    function countChunks(
        bytes memory repoName,
        bytes memory name
    ) external view returns (uint256) {
        return _countChunks(keccak256(bytes.concat(repoName, "/", name)));
    }

    function listRefs(bytes memory repoName) public view returns (refData[] memory list) {
        list = new refData[](repoNameToRefs[repoName].length);
        for (uint index = 0; index < repoNameToRefs[repoName].length; index++) {
            list[index] = _convertRefInfo(repoName,nameToRefInfo[repoNameToRefs[repoName][index]]);
        }
    }

    function setRef(
        bytes memory repoName,
        bytes memory name,
        bytes20 refHash
    ) public onlyOwner(repoName){
        bytes memory fullName = bytes.concat(repoName, "/", name);
        // only execute `sload` once to reduce gas consumption
        refInfo memory srs;
        srs = nameToRefInfo[fullName];
        uint256 refsLen = repoNameToRefs[repoName].length;

        if (srs.hash == bytes20(0)) {
            // store refHash for the first time
            require(
                refsLen <= uint256(uint96(int96(-1))),
                "Refs exceed valid length"
            );

            nameToRefInfo[fullName].hash = refHash;
            nameToRefInfo[fullName].index = uint96(refsLen);

            repoNameToRefs[repoName].push(fullName);
        } else {
            // only update refHash
            nameToRefInfo[fullName].hash = refHash;
        }
    }

    function delRef(
        bytes memory repoName,
        bytes memory name
    ) public onlyOwner(repoName) {
        bytes memory fullName = bytes.concat(repoName, "/", name);
        // only execute `sload` once to reduce gas consumption
        refInfo memory srs;
        srs = nameToRefInfo[fullName];
        uint256 refsLen = repoNameToRefs[repoName].length;

        require(
            srs.hash != bytes20(0),
            "Reference of this name does not exist"
        );
        require(srs.index < refsLen, "System Error: Invalid index");

        if (srs.index < refsLen - 1) {
            repoNameToRefs[repoName][srs.index] = repoNameToRefs[repoName][refsLen - 1];
            nameToRefInfo[repoNameToRefs[repoName][refsLen - 1]].index = srs.index;
        }
        repoNameToRefs[repoName].pop();
        delete nameToRefInfo[fullName];
    }
}
