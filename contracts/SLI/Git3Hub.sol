//SPDX-License-Identifier: GLP-3.0
pragma solidity ^0.8.0;

// import "hardhat/console.sol";
import "./Git3HubStorage.sol";

contract Git3Hub_SLI is Git3HubStorage_SLI {
    event RepoCreated(bytes repoName, address owner);
    event RepoOwnerTransfer(bytes repoName, address oldOwner, address newOwner);
    event PushRef(bytes repoName, bytes ref);

    constructor() Git3HubStorage_SLI() {}

    modifier onlyOwner(bytes memory repoName) {
        require(repoNameToOwner[repoName] == msg.sender, "only owner");
        _;
    }

    function createRepo(bytes memory repoName) external {
        require(
            repoName.length > 0 && repoName.length <= 100,
            "RepoName length must be 1-100"
        );
        for (uint i; i < repoName.length; i++) {
            bytes1 char = repoName[i];
            require(
                (char >= 0x61 && char <= 0x7A) || //a-z
                    (char >= 0x41 && char <= 0x5A) || //A-Z
                    (char >= 0x30 && char <= 0x39) || //0-9
                    (char == 0x2D || char == 0x2E || char == 0x5F), //-._
                "RepoName must be alphanumeric or -._"
            );
        }

        require(
            repoNameToOwner[repoName] == address(0),
            "RepoName already exist"
        );
        repoNameToOwner[repoName] = msg.sender;
        emit RepoCreated(repoName, msg.sender);
    }

    function transferOwnership(
        bytes memory repoName,
        address newOwner
    ) external onlyOwner(repoName) {
        require(newOwner != address(0), "newOwner must not be zero address");
        repoNameToOwner[repoName] = newOwner;
        emit RepoOwnerTransfer(repoName, msg.sender, newOwner);
    }

    function download(
        bytes memory repoName,
        bytes memory path
    ) external view returns (bytes memory) {
        return pathToHash[keccak256(bytes.concat(repoName, "/", path))];
    }

    function upload(
        bytes memory repoName,
        bytes memory path,
        bytes calldata data
    ) external payable onlyOwner(repoName) {
        pathToHash[keccak256(bytes.concat(repoName, "/", path))] = data;
    }

    function batchUpload(
        bytes memory repoName,
        bytes[] memory path,
        bytes[] calldata data
    ) external payable onlyOwner(repoName) {
        require(path.length == data.length, "path and data length mismatch");
        for (uint i = 0; i < path.length; i++) {
            pathToHash[keccak256(bytes.concat(repoName, "/", path[i]))] = data[
                i
            ];
        }
    }

    function remove(
        bytes memory repoName,
        bytes memory path
    ) external onlyOwner(repoName) {
        // The actually process of remove will remove all the chunks
        pathToHash[keccak256(bytes.concat(repoName, "/", path))] = "";
    }

    function listRefs(
        bytes memory repoName
    ) external view returns (refData[] memory list) {
        list = new refData[](repoNameToRefs[repoName].length);
        for (uint index = 0; index < repoNameToRefs[repoName].length; index++) {
            list[index] = _convertRefInfo(
                repoName,
                nameToRefInfo[repoNameToRefs[repoName][index]]
            );
        }
    }

    function setRef(
        bytes memory repoName,
        bytes memory ref,
        bytes20 refHash
    ) external onlyOwner(repoName) {
        bytes memory fullName = bytes.concat(repoName, "/", ref);
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
        emit PushRef(repoName, ref);
    }

    function delRef(
        bytes memory repoName,
        bytes memory ref
    ) external onlyOwner(repoName) {
        bytes memory fullName = bytes.concat(repoName, "/", ref);
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
            repoNameToRefs[repoName][srs.index] = repoNameToRefs[repoName][
                refsLen - 1
            ];
            nameToRefInfo[repoNameToRefs[repoName][refsLen - 1]].index = srs
                .index;
        }
        repoNameToRefs[repoName].pop();
        delete nameToRefInfo[fullName];
    }

    function _convertRefInfo(
        bytes memory repoName,
        refInfo memory info
    ) internal view returns (refData memory res) {
        res.hash = info.hash;
        res.name = repoNameToRefs[repoName][info.index];
    }
}
