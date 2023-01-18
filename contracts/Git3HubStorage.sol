//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Git3HubStorage {
    struct refInfo {
        bytes20 hash;
        uint96 index;
    }

    struct refData {
        bytes20 hash;
        bytes name;
    }
    // LargeStorageManagerV2 Storage Layout
    mapping(bytes32 => mapping(uint256 => bytes32)) internal keyToMetadata;
    mapping(bytes32 => mapping(uint256 => mapping(uint256 => bytes32)))
        internal keyToSlots;  

    // Git3Hub Storage Layout
    mapping(bytes => address) public repoNameToOwner;
    mapping(bytes => refInfo) public nameToRefInfo; // dev => {hash: 0x1234..., index: 1 }
    mapping(bytes => bytes[]) public repoNameToRefs; // [main, dev, test, staging]
}