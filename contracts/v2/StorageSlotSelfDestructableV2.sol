// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract StorageSlotSelfDestructableV2 {
    address immutable owner;
    address immutable userToRefund;

    constructor(address user) payable {
        owner = msg.sender;
        userToRefund = user;
    }

    function destruct() public {
        require(msg.sender == owner, "NFO");
        selfdestruct(payable(userToRefund));
    }
}

contract StorageSlotSelfDestructableV2_DEBUG {
    address public immutable owner;
    address public immutable userToRefund;

    constructor(address user) payable {
        owner = msg.sender;
        userToRefund = user;
    }

    function destruct() public {
        require(msg.sender == owner, "NFO");
        selfdestruct(payable(userToRefund));
    }
}
