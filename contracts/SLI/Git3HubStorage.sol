//SPDX-License-Identifier: GLP-3.0
pragma solidity ^0.8.0;

contract Git3HubStorage_SLI {
    struct refInfo {
        bytes20 hash;
        uint96 index;
    }

    struct refData {
        bytes20 hash;
        bytes name;
    }
    // FileStorage Storage Layout
    mapping(bytes32 => bytes) public pathToHash;
    

    // Git3Hub Storage Layout
    mapping(bytes => address) public repoNameToOwner;
    mapping(bytes => refInfo) public nameToRefInfo; // dev => {hash: 0x1234..., index: 1 }
    mapping(bytes => bytes[]) public repoNameToRefs; // [main, dev, test, staging]
}
