// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Constants} from "src/core/Constants.sol";

import {Ownable} from "openzeppelin-contracts/access/Ownable.sol";

contract AddressRegistry is Constants, Ownable {
    error NullAddress();

    event AddressInitialised(address indexed authorizedAddress, bytes32 indexed key);

    mapping(bytes32 => address) internal addresses;

    constructor(address _governance) Ownable(_governance) {}

    function setAddress(bytes32 _key, address _address) external onlyOwner {
        _notNull(_address);

        addresses[_key] = _address;
        emit AddressInitialised(_address, _key);
    }

    function getAddress(bytes32 _key) external view returns (address) {
        return addresses[_key];
    }

    function _notNull(address addr) internal pure {
        if (addr == address(0)) revert NullAddress();
    }
}
