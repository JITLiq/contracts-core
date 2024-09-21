// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IEntity} from "src/interfaces/IEntity.sol";

interface ISourceOpStateManager is IEntity {
    /// -- public --
    function baseBridgeToken() external view returns (address);

    function registerOperator(uint256 stakeAmount) external;

    function increaseStake(uint256 stakeAmount) external;

    function withdrawStake(uint256 withdrawAmount) external;

    /// -- governance --
    function syncOperator(address operator, OperatorData memory newOperatorData, bool deleteOperator) external;

    function sweep(address token, uint256 amount) external;

    function refundLPs(address[] memory lps) external;

    /// -- entrypoint --
    function updateOperatorAllocation(address operator, uint256 holdingAmount, uint256 stakeAmount, bool init)
        external;

    function createOrder(
        bytes32 orderId,
        uint32 expiry,
        uint256 orderAmount,
        address destAddress,
        address operator,
        uint256 operationFee,
        uint256 bridgeFee
    ) external;

    function completeOrder(bytes32 orderId) external;

    function updatePendingRefunds(FulfillerData[] memory fulfillerData, uint256 lpFees) external;
}
