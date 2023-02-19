pragma solidity ^0.8.0;

// import "hardhat/console.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";
import "./Hub.sol";

contract HubFactory {
    function createHub() public returns(Hub){
        Hub hub = new Hub();
        return hub;
    }
}