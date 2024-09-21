// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IDestOpStateManager} from "src/interfaces/IDestOpStateManager.sol";
import {AddressRegistryService} from "src/core/AddressRegistryService.sol";

contract DestOpStateManager is IDestOpStateManager, AddressRegistryService {
    error OnlyEntrypoint();

    address[] public operators;
    uint256 public totalStakedFunds;

    constructor(address _addressRegistry) AddressRegistryService(_addressRegistry) {}

    function baseBridgeToken() external view returns (address) {
        return _getAddress(_BASE_BRIDGE_TOKEN_HASH);
    }

    function getOperators() external view returns (address[] memory) {
        return operators;
    }

    function syncSourceData(address[] memory newOperators, uint256 newTotalStakedFunds) external {
        _onlyGov(msg.sender);

        operators = newOperators;
        totalStakedFunds = newTotalStakedFunds;
    }

    function deductStakedFunds(uint256 amountDeduct) external {
        _onlyEntrypoint(msg.sender);

        totalStakedFunds -= amountDeduct;
    }

    function _onlyEntrypoint(address _addr) internal view {
        if (_addr != _getAddress(_DEST_ENTRYPOINT_HASH)) {
            revert OnlyEntrypoint();
        }
    }
}
