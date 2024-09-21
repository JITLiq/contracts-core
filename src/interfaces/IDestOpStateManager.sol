// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IDestOpStateManager {
    function baseBridgeToken() external view returns (address);

    function getOperators() external view returns (address[] memory);

    function syncSourceData(address[] memory operators, uint256 totalStakedFunds) external;

    function deductStakedFunds(uint256 updatedFundsOnHold) external;
}
