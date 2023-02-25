//SPDX-License-Identifier: GLP-3.0
pragma solidity ^0.8.0;

library Repolib {
    struct refInfo {
        bytes20 hash;
        uint96 index;
    }

    struct refData {
        bytes20 hash;
        bytes name;
    }

    struct BranchInfo {
        mapping(bytes => refInfo) branchToRefInfo; // dev => {hash: 0x1234..., index: 1 }
        bytes[] branchs; //
    }

    function branchNum(
        BranchInfo storage info
    ) internal view returns (uint256) {
        return info.branchs.length;
    }

    function listBranchs(
        BranchInfo storage info
    ) internal view returns (refData[] memory list) {
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
    ) internal {
        bytes memory fullname = bytes.concat(repositoryName, "/", branch);
        require(refHash != bytes20(0), "reference hash don't allow to set 0x0");
        if (info.branchToRefInfo[fullname].hash == bytes20(0)) {
            info.branchToRefInfo[fullname].hash = refHash;
            info.branchToRefInfo[fullname].index = uint96(info.branchs.length);
            info.branchs.push(fullname);
        } else {
            info.branchToRefInfo[fullname].hash = refHash;
        }
    }

    function getBranch(
        BranchInfo storage info,
        bytes memory repositoryName,
        bytes memory branch
    ) internal view returns (bytes20) {
        bytes memory fullname = bytes.concat(repositoryName, "/", branch);
        return info.branchToRefInfo[fullname].hash;
    }

    function removeBranch(
        BranchInfo storage info,
        bytes memory repositoryName,
        bytes memory branch
    ) internal {
        bytes memory fullname = bytes.concat(repositoryName, "/", branch);
        refInfo memory refI = info.branchToRefInfo[fullname];
        require(
            refI.hash != bytes20(0),
            "Reference of this name does not exist"
        );
        uint256 lastIndex = info.branchs.length - 1;
        if (refI.index < lastIndex) {
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
