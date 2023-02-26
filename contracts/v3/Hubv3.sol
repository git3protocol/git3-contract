//SPDX-License-Identifier: GLP-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./EnumerableSet.sol";
import "./Repolib.sol";
import "./database/database.sol";
import "./database/ethstorage.sol";
import "./database/filecoin.sol";

contract Hubv3 is AccessControl, Initializable {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Repolib for Repolib.BranchInfo;

    // Hub Info
    // bytes32 public constant CREATOR = bytes32(uint256(1));
    bytes32 public constant MANAGER = bytes32(uint256(1));
    bytes32 public constant CONTRIBUTOR = bytes32(uint256(2));
    bytes32 public constant NOTFOUND = bytes32(uint256(10000));
    bytes32[] public RoleList = [DEFAULT_ADMIN_ROLE, MANAGER, CONTRIBUTOR];
    bool public permissionless;

    // Repository Info
    struct RepositoryInfo {
        uint256 repoNameIndex;
        address owner;
        bool exist;
        EnumerableSet.AddressSet repoContributors;
        Repolib.BranchInfo branchs;
    }

    mapping(bytes => RepositoryInfo) nameToRepository;
    bytes[] public repoNames;

    // DataBase Info
    database public db;

    constructor() {
        _setupRole(AccessControl.DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MANAGER, _msgSender());
        _setRoleAdmin(CONTRIBUTOR, MANAGER);
    }

    function initialize(
        bool dbSelector,
        address user,
        bool isPermissionless
    ) public initializer {
        _setupRole(AccessControl.DEFAULT_ADMIN_ROLE, user);
        _setupRole(MANAGER, user);
        _setRoleAdmin(CONTRIBUTOR, MANAGER);
        _newDataBase(dbSelector);
        permissionless = isPermissionless;
    }

    // ===== hub operator functions======
    function openPermissonlessJoin(bool open) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()));
        permissionless = open;
    }

    function memberRole(
        address member
    ) public view returns (bool IsAdmin, bool IsManager, bool IsContributor) {
        if (hasRole(DEFAULT_ADMIN_ROLE, member)) {
            IsAdmin = true;
        }
        if (hasRole(MANAGER, member)) {
            IsManager = true;
        }
        if (hasRole(CONTRIBUTOR, member)) {
            IsContributor = true;
        }

        return (IsAdmin, IsManager, IsContributor);
    }

    function membership(address member) public view returns (bool) {
        if (hasRole(DEFAULT_ADMIN_ROLE, member)) {
            return true;
        }
        if (hasRole(MANAGER, member)) {
            return true;
        }
        if (hasRole(CONTRIBUTOR, member)) {
            return true;
        }
        return false;
    }

    function addManager(address member) public {
        grantRole(MANAGER, member);
    }

    function addContributor(address member) public {
        grantRole(CONTRIBUTOR, member);
    }

    function removeManager(address member) public {
        revokeRole(MANAGER, member);
    }

    function removeContributor(address member) public {
        revokeRole(CONTRIBUTOR, member);
    }

    // permissionlessJoin can be invoked by everyone who want to join this hub
    function permissionlessJoin() public {
        require(permissionless, "permissionless join no open");
        _setupRole(CONTRIBUTOR, _msgSender());
    }

    // ===== repository operator functions======
    //createRepository can be invoked by anyone within Hub
    function createRepo(bytes memory repoName) public {
        require(membership(_msgSender()));
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

        RepositoryInfo storage repo = nameToRepository[repoName];
        require(repo.exist == false, "RepoName already exist");

        repo.repoNameIndex = repoNames.length;
        repo.owner = _msgSender();
        repo.exist = true;
        repoNames.push(repoName);
    }

    function deleteRepo(bytes memory repoName) public {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()) ||
                hasRole(MANAGER, _msgSender())
        );
        require(
            nameToRepository[repoName].exist == true,
            "repoName do not exist"
        );
        delete (nameToRepository[repoName]);
    }

    function repoOwner(bytes memory repoName) public view returns (address) {
        RepositoryInfo storage repo = nameToRepository[repoName];
        return repo.owner;
    }

    function repoContributors(
        bytes memory repoName
    ) public view returns (address[] memory) {
        RepositoryInfo storage repo = nameToRepository[repoName];
        return repo.repoContributors.values();
    }

    function isRepoMembership(
        bytes memory repoName,
        address member
    ) internal view returns (bool) {
        RepositoryInfo storage repo = nameToRepository[repoName];
        if (repo.owner == member) return true;
        if (repo.repoContributors.contains(member)) {
            return true;
        } else {
            return false;
        }
    }

    function addRepoContributor(
        bytes memory repoName,
        address con
    ) public returns (bool) {
        RepositoryInfo storage repo = nameToRepository[repoName];
        require(_msgSender() == repo.owner, "only repo owner");
        return nameToRepository[repoName].repoContributors.add(con);
    }

    function removeRepoContributor(
        bytes memory repoName,
        address con
    ) public returns (bool) {
        RepositoryInfo storage repo = nameToRepository[repoName];
        require(_msgSender() == repo.owner, "only repo owner");
        return nameToRepository[repoName].repoContributors.remove(con);
    }

    // listRef
    function listRepoRefs(
        bytes memory repoName
    ) external view returns (Repolib.refData[] memory list) {
        return nameToRepository[repoName].branchs.listBranchs();
    }

    // setRef
    function setRepoRef(
        bytes memory repoName,
        bytes memory branchPath,
        bytes20 refHash
    ) external {
        require(isRepoMembership(repoName, _msgSender()));
        nameToRepository[repoName].branchs.updateBranch(
            repoName,
            branchPath,
            refHash
        );
    }

    function getRepoRef(
        bytes memory repoName,
        bytes memory branchPath
    ) external view returns (bytes20) {
        return
            nameToRepository[repoName].branchs.getBranch(repoName, branchPath);
    }

    function delRepoRef(
        bytes memory repoName,
        bytes memory branchPath
    ) external {
        require(isRepoMembership(repoName, _msgSender()));
        nameToRepository[repoName].branchs.removeBranch(repoName, branchPath);
    }

    // ===== database operator functions======
    // function newDataBase(bool flag) public onlyRole(DEFAULT_ADMIN_ROLE) {
    //     _newDataBase(flag);
    // }

    function _newDataBase(bool flag) internal {
        if (flag) {
            db = new ethstorage();
        } else {
            db = new filecoin();
        }
    }

    function download(
        bytes memory repoName,
        bytes memory path
    ) external view returns (bytes memory, bool) {
        // call flat directory(FD)
        return db.download(repoName, path);
    }

    function upload(
        bytes memory repoName,
        bytes memory path,
        bytes calldata data
    ) external payable {
        return db.upload(repoName, path, data);
    }

    function batchUpload(
        bytes memory repoName,
        bytes[] memory path,
        bytes[] calldata data
    ) external payable {
        require(path.length == data.length, "path and data length mismatch");
        for (uint i = 0; i < path.length; i++) {
            db.upload(repoName, path[i], data[i]);
        }
    }
}
