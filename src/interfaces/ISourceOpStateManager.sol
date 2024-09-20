// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface ISourceOpStateManager {
    struct FulfillerData {
        uint256 fulfillAmount;
        address fulfiller;
    }

    struct OperatorData {
        uint256 currentStake;
        uint256 currentHolding;
        bool registered;
    }

    struct OrderData {
        bool fulfilled;
        uint32 expiry;
        uint256 orderAmount;
        address destAddress;
        address operator;
        FeesData fees;
    }

    struct FeesData {
        uint256 operationFee;
        uint256 bridgeFee;
    }

    /// -- public --
    function baseBridgeToken() external view returns (address);

    function registerOperator(uint256 stakeAmount) external;

    function increaseStake(uint256 stakeAmount) external;

    function withdrawStake(uint256 withdrawAmount) external;

    /// -- governance --
    function syncOperator(address operator, OperatorData memory newOperatorData, bool deleteOperator) external;

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
