pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract RepositoryAccess{
    using EnumerableSet for EnumerableSet.AddressSet;
    mapping(bytes => EnumerableSet.AddressSet) BranchOperators;

    modifier onlyBranchOperator(bytes memory branch) {
        require(BranchOperators[branch].contains(msg.sender),"only branch Operator");
        _;
    }

    function _getBranchOwner(bytes memory branch) internal view returns(address){
        return BranchOperators[branch].at(0) ;
    }
    
    function addBranchOperator(bytes memory branch, address member) external virtual{
        require(_getBranchOwner(branch) == msg.sender,"only branch owner");
        BranchOperators[branch].add(member);
    }

    function removeBranchOperator(bytes memory branch , address member) external virtual{
        require(_getBranchOwner(branch) == msg.sender,"only branch owner");
        BranchOperators[branch].remove(member);
    }

}
