// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IEntity} from "src/interfaces/IEntity.sol";

interface IDestEntrypoint is IEntity {
    function fulfillOrder(
        bytes32 orderId,
        OrderData memory orderData,
        FulfillerData[] memory fulfillerData,
        bytes[] memory operatorSignatures
    ) external payable;

    function sweep(address token, uint256 amount) external;
}
