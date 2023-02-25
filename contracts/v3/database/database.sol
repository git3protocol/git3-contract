//SPDX-License-Identifier: GLP-3.0
pragma solidity ^0.8.0;

interface database {
    function download(
        bytes memory repoName,
        bytes memory path
    ) external view returns (bytes memory, bool);

    function upload(
        bytes memory repoName,
        bytes memory path,
        bytes calldata data
    ) external payable;
}
