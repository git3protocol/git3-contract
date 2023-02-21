pragma solidity ^0.8.0;

library RepositoryLib {

    struct refInfo {
        bytes20 hash;
        uint96 index;
    }

    struct refData {
        bytes20 hash;
        bytes name;
    }

    struct BranchInfo{
        mapping(bytes => refInfo) branchToRefInfo; // dev => {hash: 0x1234..., index: 1 }
        bytes[] branchs; // 有几条branch,就有几个reference
    } 


    function listBranchs(BranchInfo storage info) external view returns (refData[] memory list) {
        list = new refData[](info.branchs.length);
        for (uint index = 0; index < info.branchs.length; index++) {
            list[index] = _convertToRefData(
                info,
                info.branchToRefInfo[info.branchs[index]]
            );
        }
    }

    function updateBranch(
        BranchInfo storage info,
        bytes memory repositoryName,
        bytes memory branch,
        bytes20 refHash
    ) external {
        bytes memory fullname = bytes.concat(repositoryName,"/",branch);
        require(refHash!=bytes20(0),"reference hash don't allow to set 0x0" );
        if (info.branchToRefInfo[fullname].hash==bytes20(0)) {
            info.branchToRefInfo[fullname].hash = refHash;
            info.branchToRefInfo[fullname].index = uint96(info.branchs.length);
            info.branchs.push(fullname);
        }else {
            info.branchToRefInfo[fullname].hash = refHash;
        }
    
    }

    function removeBranch(
        BranchInfo storage info,
        bytes memory repositoryName,
        bytes memory branch
    ) external {
        bytes memory fullname = bytes.concat(repositoryName,"/",branch);
        refInfo memory refI =  info.branchToRefInfo[fullname];
        require(
            refI.hash != bytes20(0),
            "Reference of this name does not exist"
        );
        uint256 lastIndex = info.branchs.length -1 ;
        if (refI.index < lastIndex){
            info.branchToRefInfo[info.branchs[lastIndex]].index = refI.index;
            info.branchs[refI.index] = info.branchs[lastIndex];
        }
        info.branchs.pop();
        delete info.branchToRefInfo[fullname];
    }

    function _convertToRefData(
        BranchInfo storage info,
        refInfo memory rInfo
    ) internal view returns (refData memory res) {
        res.hash = rInfo.hash;
        res.name = info.branchs[rInfo.index];
    }

}