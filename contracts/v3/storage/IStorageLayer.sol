pragma solidity ^0.8.0;


interface IStorageLayer{

    function upload(
        bytes20 refHash,
        bytes calldata data
    ) external payable ;

    function download(bytes20 refHash) external view returns(bytes32 storageLayerId,bytes memory data);
}