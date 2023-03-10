//SPDX-License-Identifier: GLP-3.0
pragma solidity ^0.8.0;

import "./database.sol";

contract filecoin is database {
    mapping(bytes32 => bytes) public pathToHash;

    function download(
        bytes memory repoName,
        bytes memory path
    ) external view override returns (bytes memory, bool) {
        bytes32 fullName = keccak256(bytes.concat(repoName, "/", path));
        // call flat directory(FD)
        return (pathToHash[fullName], true);
    }

    function upload(
        bytes memory repoName,
        bytes memory path,
        bytes calldata data
    ) external payable override {
        bytes32 fullName = keccak256(bytes.concat(repoName, "/", path));
        pathToHash[fullName] = data;
    }

    function uploadChunk(
        bytes memory repoName,
        bytes memory path,
        uint256 chunkId,
        bytes calldata data
    ) external payable override {
        repoName;
        path;
        chunkId;
        data;
        revert("unsupport uploadChunk");
    }
}
