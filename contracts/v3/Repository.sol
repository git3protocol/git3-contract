pragma solidity ^0.8.0;

import "./storage/IStorageLayer.sol";
import "./RepositoryAccess.sol";

contract Repository is RepositoryAccess{

    struct refInfo {
        bytes20 hash;
        uint96 index;
    }

    struct refData {
        bytes20 hash;
        bytes name;
    }

    bytes repositoryName;
    address creator;
    address[] public contributorList;
    
    mapping(bytes => refInfo) public branchToRefInfo; // dev => {hash: 0x1234..., index: 1 }
    bytes[] public branchs; // 有几条branch,就有几个reference

    IStorageLayer public storageManager;
    bytes32 constant public ETHSTORAGEID_LAYER = bytes32(keccak256("ETHSTORAGE"));
    bytes32 constant public NFTSTORAGE_LAYER = bytes32(keccak256("NFTSTORAGE"));
    constructor(bytes memory repoName){
        creator = msg.sender;
        repositoryName = repoName;
    }

    modifier onlyCreator() {
        require(address(storageManager) == msg.sender, "only creator");
        _;
    }

    function listBranchs() external view returns (refData[] memory list) {
        list = new refData[](branchs.length);
        for (uint index = 0; index < branchs.length; index++) {
            list[index] = _convertToRefData(
                branchToRefInfo[branchs[index]]
            );
        }
    }

    function createBranch(bytes memory branch,bytes20 refHash) public onlyCreator {
        bytes memory fullname = bytes.concat(repositoryName,"/",branch);
        require(refHash!=bytes20(0),"reference hash don't allow to set 0x0" );
        require(branchToRefInfo[fullname].hash == bytes20(0),"branch already exists");
        branchToRefInfo[fullname].hash = refHash;
        branchToRefInfo[fullname].index = uint96(branchs.length);
        branchs.push(fullname);

        // add branch owner 
        this.addBranchOperator(fullname,msg.sender);
    }


    function updateBranch(
        bytes memory branch,
        bytes20 refHash
    )external onlyBranchOperator(branch){
        bytes memory fullname = bytes.concat(repositoryName,"/",branch);
        require(refHash!=bytes20(0),"reference hash don't allow to set 0x0" );
        require(branchToRefInfo[fullname].hash != bytes20(0),"branch do not exist");
        branchToRefInfo[fullname].hash = refHash;
    }

    function removeBranch(
        bytes memory branch
    ) external {
        bytes memory fullname = bytes.concat(repositoryName,"/",branch);
        refInfo memory refI =  branchToRefInfo[fullname];
        require(
            refI.hash != bytes20(0),
            "Reference of this name does not exist"
        );
        uint256 lastIndex = branchs.length -1 ;
        if (refI.index < lastIndex){
            branchToRefInfo[branchs[lastIndex]].index = refI.index;
            branchs[refI.index] = branchs[lastIndex];
        }
        branchs.pop();
        delete branchToRefInfo[fullname];
    }

    function _convertToRefData(
        refInfo memory info
    ) internal view returns (refData memory res) {
        res.hash = info.hash;
        res.name = branchs[info.index];
    }

    // data storage module

    function setStorageLayer(IStorageLayer addr) external onlyCreator {
        storageManager = addr;
    }

    function upload(
        bytes20 refHash,
        bytes calldata data
    ) external payable {
        storageManager.upload(refHash, data);
    }

    function download(bytes20 refHash) external view returns(bytes32 storageLayerId , bytes memory data){
        return storageManager.download(refHash);
    }
}