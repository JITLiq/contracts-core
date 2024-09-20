// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {AddressRegistry} from "src/core/AddressRegistry.sol";
import {Constants} from "src/core/Constants.sol";

abstract contract AddressRegistryService is Constants {
    error InvalidAddressRegistry();
    error NotGovernance(address);
    error InvalidAddress();

    // solhint-disable-next-line immutable-vars-naming
    AddressRegistry public immutable addressRegistry;

    constructor(address _addressRegistry) {
        if (_addressRegistry == address(0)) revert InvalidAddressRegistry();
        addressRegistry = AddressRegistry(_addressRegistry);
    }

    function _getAddress(bytes32 _key) internal view returns (address authorizedAddress) {
        authorizedAddress = addressRegistry.getAddress(_key);
        _notNull(authorizedAddress);
    }

    function _notNull(address _addr) internal pure {
        if (_addr == address(0)) revert InvalidAddress();
    }

    function _onlyGov(address _addr) internal view {
        if (_addr != addressRegistry.owner()) revert NotGovernance(_addr);
    }
}
