// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IEntity {
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

    struct FulfillerData {
        uint256 fulfillAmount;
        address fulfiller;
    }

    struct OperatorData {
        uint256 currentStake;
        uint256 currentHolding;
        bool registered;
    }

    struct LzReceiveMessage {
        bytes32 orderId;
        FulfillerData[] fulfillerData;
    }
}
