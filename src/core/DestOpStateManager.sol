// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IDestOpStateManager} from "src/interfaces/IDestOpStateManager.sol";
import {AddressRegistryService} from "src/core/AddressRegistryService.sol";

contract DestOpStateManager is IDestOpStateManager, AddressRegistryService {
    address internal immutable _BASE_BRIDGE_TOKEN;

    address[] public operators;
    uint256 public totalFundsOnHold;

    constructor(address _addressRegistry, address _baseBridgeToken) AddressRegistryService(_addressRegistry) {
        _BASE_BRIDGE_TOKEN = _baseBridgeToken;
    }

    function baseBridgeToken() external view returns (address) {
        return _BASE_BRIDGE_TOKEN;
    }

    function syncSourceData(address[] memory newOperators, uint256 newTotalFundsOnHold) external {
        operators = newOperators;
        totalFundsOnHold = newTotalFundsOnHold;
    }
}
