// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IDestOpStateManager} from "src/interfaces/IDestOpStateManager.sol";
import {AddressRegistryService} from "src/core/AddressRegistryService.sol";

contract DestOpStateManager is IDestOpStateManager, AddressRegistryService {
    address[] operators;
    uint256 totalFundsOnHold;

    constructor(address _addressRegistry) AddressRegistryService(_addressRegistry) {}

    function syncSourceData(address[] memory newOperators, uint256 newTotalFundsOnHold) external {
        operators = newOperators;
        totalFundsOnHold = newTotalFundsOnHold;
    }
}
