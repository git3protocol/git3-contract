//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract Git3NameService {
    mapping(string => address) public nameHub;
    mapping(string => address) public nameOwner;
    string[] public nameList;

    mapping(address => mapping(string => string)) public HubRecords;

    constructor() {}

    modifier onlyHubOwner(string memory name) {
        require(nameOwner[name] == msg.sender, "Only name owner can do this");
        _;
    }

    function registerHub(string memory name, address hub) public {
        require(nameHub[name] == address(0), "Name already registered");
        nameHub[name] = hub;
        nameOwner[name] = msg.sender;
        nameList.push(name);
    }

    function nameListLength() public view returns (uint256) {
        return nameList.length;
    }

    function rebindHubAddress(
        string memory name,
        address hub
    ) public onlyHubOwner(name) {
        nameHub[name] = hub;
    }

    function transferNameOwner(
        string memory name,
        address newOwner
    ) public onlyHubOwner(name) {
        nameOwner[name] = newOwner;
    }
}
