pragma solidity ^0.8.0;

// import "hardhat/console.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "./EnumerableSet.sol";
import "./Repositorylib.sol";
import "./database/database.sol";
contract Hub is AccessControlEnumerableUpgradeable{

    using EnumerableSet for EnumerableSet.AddressSet;
    using RepositoryLib for RepositoryLib.BranchInfo;

    // Hub Info
    bytes32 public constant CREATOR = bytes32(uint256(0));
    bytes32 public constant MANAGER =  bytes32(uint256(1));
    bytes32 public constant CONTRIBUTOR =  bytes32(uint256(2));
    bytes32[] public RoleList = [CREATOR,MANAGER,CONTRIBUTOR];
    bool public permissionless;

    // Repository Info
    struct RepositoryInfo{
        uint256 repoNameIndex;
        address owner;
        bool    exist;
        EnumerableSet.AddressSet repoContributors;
        RepositoryLib.BranchInfo branchs;
    }

    mapping(bytes=>RepositoryInfo) nameToRepository;
    bytes[] public repoNames;

    // DataBase Info 
    database public db;


    // ===== hub operator functions====== 
    function openPermissonlessJoin(bool open) public {
        require(hasRole(CREATOR, _msgSender()));
        permissionless = open;
    }

    function memberShip() public view returns(bool){
        if (hasRole(CREATOR, _msgSender())){
            return true;
        }else if (hasRole(MANAGER, _msgSender())){
            return true;
        }else if (hasRole(CONTRIBUTOR, _msgSender())){
            return true;
        }else{
            return false;
        }
    }

    //createRepository can be invoked by anyone within Hub 
    function createRepository(bytes memory repoName) public{
        require(memberShip());
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
        require(
            repo.exist == false ,
            "RepoName already exist"
        );
        
        repo.repoNameIndex = repoNames.length;
        repo.owner = _msgSender();
        repo.exist =  true;
        repoNames.push(repoName);
    }

    function deleteRepository(bytes memory repoName) public returns(address){
        require(hasRole(CREATOR, _msgSender()) || hasRole(MANAGER, _msgSender()));
        require(nameToRepository[repoName].exist==true,"repoName do not exist");    
        delete(nameToRepository[repoName]);
    }

    function addMember( bytes32 senderRole , bytes32 role,address member) public{
        require(hasRole(senderRole, _msgSender()));
        require(senderRole>role);
        grantRole(role, member);
    }


    function deleteMember(bytes32 senderRole  ,bytes32 role,address member) public{
        require(hasRole(senderRole, _msgSender()));
        require(senderRole>role);
        revokeRole(role, member);
    }

    // permissionlessJoin can be invoked by everyone who want to join this hub 
    function permissionlessJoin() public{
        require(permissionless,"permissionless join no open");
        grantRole(CONTRIBUTOR, _msgSender());
    }

    // ===== repository operator functions====== 

    function isRepoContributor(bytes memory repoName , address member) internal view returns(bool){
        RepositoryInfo storage repo = nameToRepository[repoName];
        if (repo.owner == member) return true;
        if (repo.repoContributors.contains(member)) {
            return true;
        }else {
            return false;
        }
    }
    
    function listRepoBranchs( bytes memory repoName)external view {
        nameToRepository[repoName].branchs.listBranchs();
    }

    function updateRepoBranch(
        bytes memory repoName,
        bytes memory branchPath,
        bytes20 refHash
    )external{
        require(isRepoContributor(repoName, _msgSender()));
        nameToRepository[repoName].branchs.updateBranch(repoName,branchPath,refHash);
    }

    function removeRepoBranch(
        bytes memory repoName,
        bytes memory branchPath
    ) external{
        require(isRepoContributor(repoName, _msgSender()));
        nameToRepository[repoName].branchs.removeBranch(repoName,branchPath);
    }

    // ===== database operator functions======    
    function newDataBase() external onlyRole(CREATOR) {
        
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
        return db.upload(repoName, path,data);
    }

}
