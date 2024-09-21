// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IDestOpStateManager} from "src/interfaces/IDestOpStateManager.sol";
import {AddressRegistryService} from "src/core/AddressRegistryService.sol";

contract DestOpStateManager is IDestOpStateManager, AddressRegistryService {
    address[] public operators;
    uint256 public totalFundsOnHold;

    constructor(address _addressRegistry) AddressRegistryService(_addressRegistry) {}

    function baseBridgeToken() external view returns (address) {
        return _getAddress(_BASE_BRIDGE_TOKEN);
    }

    function syncSourceData(address[] memory newOperators, uint256 newTotalFundsOnHold) external {
        operators = newOperators;
        totalFundsOnHold = newTotalFundsOnHold;
    }
}
