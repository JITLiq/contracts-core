// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IDestOpStateManager {
    function syncSourceData(address[] memory operators, uint256 totalFundsOnHold) external;
}
