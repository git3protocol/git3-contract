pragma solidity ^0.8.0;

// import "hardhat/console.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "./Repository.sol";
contract Hub is AccessControlEnumerableUpgradeable{
    // AccessController public accessController;

    mapping(bytes=>address) public nameToRepository;
    bytes[] public repoNames;

    bytes32 public constant CREATOR = bytes32(uint256(1));
    bytes32 public constant MANAGER =  bytes32(uint256(2));
    bytes32 public constant CONTRIBUTOR =  bytes32(uint256(3));
    bytes32[] public RoleList = [CREATOR,MANAGER,CONTRIBUTOR];
    // mapping(bytes32=>address)public executors;

    bool public permissionless;

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
    function createRepository(bytes memory repoName) public returns(address){
        require(hasRole(CREATOR, _msgSender()));
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
            nameToRepository[repoName] == address(0),
            "RepoName already exist"
        );
        address repo = address(new Repository(repoName));
        nameToRepository[repoName] = repo;
        repoNames.push(repoName);
        return repo;
    }

    function deleteRepository(bytes memory repoName) public returns(address){
        require(nameToRepository[repoName]!=address(0),"repoName do not exist");
        address repoAddr = nameToRepository[repoName];
        delete(nameToRepository[repoName]);
        // todo:remove repoName from repoNames 
        return repoAddr;
    }

    function addMember( bytes32 senderRole , bytes32 role,address member) public{
        require(hasRole(senderRole, _msgSender()));
        require(senderRole>role);
        grantRole(role, member);
    }


    function deleteMember(bytes32 senderRole  ,bytes32 role,address member) public{
        require(hasRole(CREATOR, _msgSender()));
        require(hasRole(senderRole, _msgSender()));
        require(senderRole>role);
        revokeRole(role, member);
    }

    // permissionlessJoin can be invoked by everyone who want to join this hub 
    function permissionlessJoin() public{
        require(permissionless,"permissionless join no open");
        grantRole(CONTRIBUTOR, _msgSender());
    }


}
