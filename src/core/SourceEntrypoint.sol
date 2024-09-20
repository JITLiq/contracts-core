// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ISourceEntrypoint} from "src/interfaces/ISourceEntrypoint.sol";
import {AddressRegistryService} from "src/core/AddressRegistryService.sol";
import {SourceOpStateManager} from "src/core/SourceOpStateManager.sol";

import {SafeTransferLib} from "solady/utils/SafeTransferLib.sol";

import {OAppReceiver, Origin} from "layerzero-v2/oapp/contracts/oapp/OAppReceiver.sol";
import {OAppCore} from "layerzero-v2/oapp/contracts/oapp/OAppCore.sol";

import {Ownable} from "openzeppelin-contracts/access/Ownable.sol";

contract SourceEntrypoint is ISourceEntrypoint, AddressRegistryService, OAppReceiver {
    using SafeTransferLib for address;

    error NotRegistered();
    error InsufficientFunds();
    error AlreadyExists();
    error UnexpectedPeer();

    uint32 internal immutable _ORDER_TTL;

    struct LzReceiveMessage {
        bytes32 orderId;
        SourceOpStateManager.FulfillerData[] fulfillerData;
    }

    constructor(address _addressRegistry, uint32 _orderTTL, address _lzEndpoint)
        AddressRegistryService(_addressRegistry)
        OAppCore(_lzEndpoint, msg.sender)
        Ownable(msg.sender)
    {
        _ORDER_TTL = _orderTTL;
    }

    function initBridge(
        bytes32 orderId,
        uint256 amount,
        address destAddress,
        address operator,
        uint256 operationFee,
        uint256 bridgeFee
    ) external {
        (SourceOpStateManager sourceOpSM, address baseBridgeToken) = _getStateManager();
        (uint256 opCurrentStake, uint256 opCurrentHoldings, bool registered) = sourceOpSM.operatorData(operator);
        if (!registered) revert NotRegistered();
        if ((opCurrentStake - opCurrentHoldings) < amount) {
            revert InsufficientFunds();
        }

        address _user = msg.sender;
        // change to use adapter
        uint256 _amountToPull = amount + operationFee + bridgeFee;
        baseBridgeToken.safeTransferFrom(_user, address(sourceOpSM), _amountToPull);

        sourceOpSM.updateOperatorAllocation(operator, amount, 0, true);
        sourceOpSM.createOrder(
            orderId, uint32(block.number) + _ORDER_TTL, amount, destAddress, operator, operationFee, bridgeFee
        );
    }

    function fulfillBridge(bytes32 orderId, SourceOpStateManager.FulfillerData[] memory fulfillerData) public {
        (SourceOpStateManager sourceOpSM,) = _getStateManager();
        sourceOpSM.completeOrder(orderId);

        (,, uint256 orderAmount,, address operator, SourceOpStateManager.FeesData memory fees) =
            sourceOpSM.orderData(orderId);
        uint256 operatorFees = (fees.operationFee * sourceOpSM.OPERATOR_FEE()) / sourceOpSM.MAX_BPS();
        uint256 lpFees = (fees.operationFee * sourceOpSM.LP_FEE()) / sourceOpSM.MAX_BPS();

        sourceOpSM.updateOperatorAllocation(operator, orderAmount, operatorFees, false);

        uint256 lpFeesPerFulfiller = lpFees / fulfillerData.length;
        sourceOpSM.updatePendingRefunds(fulfillerData, lpFeesPerFulfiller);
    }

    function _lzReceive(Origin calldata _origin, bytes32, bytes calldata message, address, bytes calldata)
        internal
        override
    {
        address destEntrypoint = _getAddress(_DEST_ENTRYPOINT_HASH);
        if (address(bytes20(_origin.sender)) != destEntrypoint) {
            revert UnexpectedPeer();
        }

        LzReceiveMessage memory lzReceiveMessage = abi.decode(message, (LzReceiveMessage));

        fulfillBridge(lzReceiveMessage.orderId, lzReceiveMessage.fulfillerData);
    }

    function _getStateManager() internal view returns (SourceOpStateManager, address) {
        SourceOpStateManager sourceOpSM = SourceOpStateManager(_getAddress(_SOURCE_OP_SM_HASH));
        return (sourceOpSM, sourceOpSM.baseBridgeToken());
    }
}
