pragma solidity ^0.8.0;

contract filecoin{

    mapping(bytes32 => bytes) public pathToHash;

     function download(
        bytes memory repoName,
        bytes memory path
    ) external view returns (bytes memory, bool) {

        bytes32  fullName = keccak256(bytes.concat(repoName, "/", path));
        // call flat directory(FD)
        return (pathToHash[fullName],true);
    }

    function upload(
        bytes memory repoName,
        bytes memory path,
        bytes calldata data
    ) external payable {
        bytes32  fullName = keccak256(bytes.concat(repoName, "/", path));
        pathToHash[fullName] = data;
            
    }

}