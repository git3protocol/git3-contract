//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

// import "hardhat/console.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";
import "./v2/LargeStorageManagerV2.sol";

contract Git3Hub is LargeStorageManagerV2 {
    struct refInfo {
        bytes20 hash;
        uint96 index;
    }

    struct refData {
        bytes20 hash;
        bytes name;
    }

    event RepoCreated(bytes indexed repoName, address owner);
    event RepoOwnerTransfer(
        bytes indexed repoName,
        address oldOwner,
        address newOwner
    );
    event PushRef(bytes indexed repoName, bytes ref);

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

    constructor() LargeStorageManagerV2(0) {}

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
    ) external view returns (bytes memory, bool) {
        // call flat directory(FD)
        return _get(keccak256(bytes.concat(repoName, "/", path)));
    }

    function upload(
        bytes memory repoName,
        bytes memory path,
        bytes calldata data
    ) external payable onlyOwner(repoName) {
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
    ) external payable onlyOwner(repoName) {
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

    function removeChunk(
        bytes memory repoName,
        bytes memory path,
        uint256 chunkId
    ) external onlyOwner(repoName) {
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
}
