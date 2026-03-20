// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SubscriptionStorageLayout.sol";

// This contract inherits the storage layout defined in SubscriptionStorageLayout.
// The proxy contract handling 'delegatecall'
// It can be used as the storage layer for a proxy pattern, allowing the logic contract to be upgraded without changing the storage layout.

contract SubscriptionStorage is day-17/SubscriptionStorageLayout {
    constructor(address _logicContract) {
        owner = msg.sender;
        require(_logicContract != address(0), "Invalid logic address.");
        require(_logicContract.code.length > 0, "Logic must be a contract.");
    }

    function upgradeTo(address _newLogic) external {
        require(msg.sender == owner, "You are not the owner.");
        require(_newLogic != address(0), "Invalid logic address.");
        require(_newLogic.code.length > 0, "Logic must be a contract.");
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