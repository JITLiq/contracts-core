// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface ISourceEntrypoint {
    struct FulfillerData {
        uint256 fulfillAmount;
        address fulfiller;
    }

    function initBridge(bytes32 orderId, uint256 amount, address operator) external;

    function fulfillBridge(
        bytes32 orderId,
        address destinationAddress,
        bytes memory signature,
        FulfillerData[] memory fulfillerData
    ) external;
}
