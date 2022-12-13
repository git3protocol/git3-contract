//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "./IFileOperator.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "evm-large-storage/contracts/examples/FlatDirectory.sol";

// import "evm-large-storage/contracts/W3RC3.sol";

contract Git3 {
    IFileOperator public immutable storageManager;
    struct refInfo {
        bytes20 hash;
        uint96 index;
    }

    struct refData {
        bytes20 hash;
        string name;
    }

    mapping(bytes => address) public repoNameToOwner;
    mapping(string => refInfo) public nameToRefInfo; // dev => {hash: 0x1234..., index: 1 }
    string[] public refs; // [main, dev, test, staging]

    function _convertRefInfo(
        refInfo memory info
    ) internal view returns (refData memory res) {
        res.hash = info.hash;
        res.name = refs[info.index];
    }

    constructor() {
        storageManager = IFileOperator(address(new FlatDirectory(220)));
    }

    modifier onlyOwner(bytes memory repoName, address memory user) {
        require(repoNameToOwner[repoName] == user || repoNameToOwner[repoName] == address(0));
        _;
    }

    function download(
        bytes memory repoName,
        bytes memory path
    ) external view returns (bytes memory, bool) {
        // call flat directory(FD)
        return storageManager.read(bytes.concat(repoName, '/', path));
    }

    function upload(bytes memory repoName, bytes memory path, bytes memory data)
        external payable onlyOwner(repoName, msg.sender)
    {
        storageManager.writeChunk{value: msg.value}(bytes.concat(repoName, '/', path), 0, data);
    }

    function uploadChunk(
        bytes memory repoName,
        bytes memory path,
        uint256 chunkId,
        bytes memory data
    ) external payable onlyOwner(repoName, msg.sender) {
        storageManager.writeChunk{value: msg.value}(bytes.concat(repoName, '/', path), chunkId, data);
    }

    function remove(bytes memory repoName, bytes memory path) external onlyOwner(repoName, msg.sender) {

        // The actually process of remove will remove all the chunks
        storageManager.remove(bytes.concat(repoName, '/', path));
    }

    function size(bytes memory name) external view returns (uint256, uint256) {
        return storageManager.size(name);
    }

    function countChunks(bytes memory name) external view returns (uint256) {
        return storageManager.countChunks(name);
    }

    function listRefs() public view returns (refData[] memory list) {
        list = new refData[](refs.length);
        for (uint index = 0; index < refs.length; index++) {
            list[index] = _convertRefInfo(nameToRefInfo[refs[index]]);
        }
    }

    function setRef(bytes memory repoName, bytes memory name, bytes20 refHash) public onlyOwner(repoName, msg.sender) {
        // only execute `sload` once to reduce gas consumption
        refInfo memory srs;
        srs = nameToRefInfo[name];
        uint256 refsLen = refs.length;

        if (srs.hash == bytes20(0)) {
            // store refHash for the first time
            require(
                refsLen <= uint256(uint96(int96(-1))),
                "Refs exceed valid length"
            );

            repoToOwner
            nameToRefInfo[name].hash = refHash;
            nameToRefInfo[name].index = uint96(refsLen);

            refs.push(name);
        } else {
            // only update refHash
            nameToRefInfo[name].hash = refHash;
        }
    }

    function delRef(bytes memory repoName, bytes memory name) public onlyOwner(repoName, msg.sender) {
        // only execute `sload` once to reduce gas consumption
        refInfo memory srs;
        srs = nameToRefInfo[name];
        uint256 refsLen = refs.length;

        require(
            srs.hash != bytes20(0),
            "Reference of this name does not exist"
        );
        require(srs.index < refsLen, "System Error: Invalid index");

        if (srs.index < refsLen - 1) {
            refs[srs.index] = refs[refsLen - 1];
            nameToRefInfo[refs[refsLen - 1]].index = srs.index;
        }
        refs.pop();
        delete nameToRefInfo[name];
    }
}
