// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "src/core/SourceOpStateManager.sol";

interface ISourceEntrypoint {
    function initBridge(
        bytes32 orderId,
        uint256 amount,
        address destAddress,
        address operator,
        uint256 operationFee,
        uint256 bridgeFee
    ) external;

    function fulfillBridge(bytes32 orderId, SourceOpStateManager.FulfillerData[] memory fulfillerData) external;
}
