//SPDX-License-Identifier: GLP-3.0
pragma solidity ^0.8.0;

// import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Create2.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "./Hubv3.sol";

contract HubFactory is Ownable {
    event CreateHub(address indexed hub, address indexed creator);

    bool public dbSelector;
    address[] public hubs;
    Hubv3 public hubImp;

    constructor(bool _dbSelector) {
        dbSelector = _dbSelector;
    }

    function newHubImp() public onlyOwner {
        hubImp = new Hubv3();
    }

    function setHubImp(address addr) public onlyOwner {
        hubImp = Hubv3(addr);
    }

    function createHub(bool isPermissionless) external{
        address instance = Clones.clone(address(hubImp));
        hubs.push(instance);
        Hubv3(instance).initialize(dbSelector, _msgSender(), isPermissionless);
        emit CreateHub(instance, _msgSender());
    }
}
