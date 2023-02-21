pragma solidity ^0.8.0;
import "./EthStorage/LargeStorageManagerV2.sol";
import "./database.sol";

contract ethstorage is LargeStorageManagerV2, database {
    function stakeTokens(
        bytes memory repoName,
        bytes memory path
    ) external view returns (uint256) {
        bytes memory fullPath = bytes.concat(repoName, "/", path);
        return _stakeTokens(keccak256(fullPath), 0);
    }

    function chunkStakeTokens(
        bytes memory repoName,
        bytes memory path,
        uint256 chunkId
    ) external view returns (uint256) {
        bytes memory fullPath = bytes.concat(repoName, "/", path);
        (uint256 sTokens, ) = _chunkStakeTokens(keccak256(fullPath), chunkId);
        return sTokens;
    }

    function getChunkAddr(
        bytes memory repoName,
        bytes memory path,
        uint256 chunkId
    ) external view returns (address) {
        bytes memory fullPath = bytes.concat(repoName, "/", path);
        return _getChunkAddr(keccak256(fullPath), chunkId);
    }

    function download(
        bytes memory repoName,
        bytes memory path
    ) external view override returns (bytes memory, bool) {
        // call flat directory(FD)
        return _get(keccak256(bytes.concat(repoName, "/", path)));
    }

    function upload(
        bytes memory repoName,
        bytes memory path,
        bytes calldata data
    ) external payable override {
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
    ) external payable {
        _putChunkFromCalldata(
            keccak256(bytes.concat(repoName, "/", path)),
            chunkId,
            data,
            msg.value
        );
    }

    function remove(bytes memory repoName, bytes memory path) external {
        // The actually process of remove will remove all the chunks
        _remove(keccak256(bytes.concat(repoName, "/", path)), 0);
    }

    function removeChunk(
        bytes memory repoName,
        bytes memory path,
        uint256 chunkId
    ) external {
        _removeChunk(keccak256(bytes.concat(repoName, "/", path)), chunkId);
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
}
