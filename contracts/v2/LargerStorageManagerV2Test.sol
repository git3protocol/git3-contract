// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./LargeStorageManagerV2.sol";

contract LargeStorageManagerV2Test is LargeStorageManagerV2 {
    constructor(uint8 slotLimit) LargeStorageManagerV2(slotLimit) {}

    function get(bytes32 key) public view returns (bytes memory, bool) {
        (bytes memory data, bool found) = _get(key);
        return (data, found);
    }

    function getChunk(
        bytes32 key,
        uint256 chunkId
    ) public view returns (bytes memory, bool) {
        (bytes memory data, bool found) = _getChunk(key, chunkId);
        return (data, found);
    }

    function putChunk(
        bytes32 key,
        uint256 chunkId,
        bytes memory data
    ) public payable {
        _putChunk(key, chunkId, data, msg.value);
    }

    function putChunkFromCalldata(
        bytes32 key,
        uint256 chunkId,
        bytes calldata data
    ) public payable {
        _putChunkFromCalldata(key, chunkId, data, msg.value);
    }

    function size(bytes32 key) public view returns (uint256, uint256) {
        return _size(key);
    }

    function chunkSize(
        bytes32 key,
        uint256 chunkId
    ) public view returns (uint256, bool) {
        return _chunkSize(key, chunkId);
    }

    function countChunks(bytes32 key) public view returns (uint256) {
        return _countChunks(key);
    }

    function remove(bytes32 key) public {
        _remove(key, 0);
    }

    function removeChunk(bytes32 key, uint256 chunkId) public {
        _removeChunk(key, chunkId);
    }

    function getBalance() public view returns (uint256 balance) {
        return address(this).balance;
    }

    function stakeTokens(
        bytes32 key,
        uint256 chunkId
    ) public view returns (uint256) {
        return _stakeTokens(key, chunkId);
    }

    function chunkStakeTokens(
        bytes32 key,
        uint256 chunkId
    ) public view returns (uint256, bool) {
        return _chunkStakeTokens(key, chunkId);
    }

    function getChunkAddr(
        bytes32 key,
        uint256 chunkId
    ) public view returns (address) {
        return _getChunkAddr(key, chunkId);
    }
}
