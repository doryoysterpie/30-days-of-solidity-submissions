// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SubscriptionStorageLayout.sol";

// This contract inherits the storage layout defined in SubscriptionStorageLayout.
// The proxy contract handling 'delegatecall'
// It can be used as the storage layer for a proxy pattern, allowing the logic contract to be upgraded without changing the storage layout.

contract SubscriptionStorage is day-17/SubscriptionStorageLayout {
    constructor(address _logicContract) {
        owner = msg.sender;
        logicContract = _logicContract;
    }

    function upgradeTo(address _newLogic) external {
        require(msg.sender == owner, "You are not the owner.");
        logicContract = _newLogic;
    }

    fallback() external payable {
        address impl = logicContract;
        require(impl != address(0), "Logic contract not set.");

        assembly {
            calldatacopy(ptr, 0, calldatasize())
            let result := delegatecall(gas(), impl, ptr, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    receive() external payable {}
}