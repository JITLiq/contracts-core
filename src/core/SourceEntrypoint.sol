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

    SourceOpStateManager internal immutable _SOURCE_OP_SM;
    address internal immutable _BASE_BRIDGE_TOKEN;
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
        _SOURCE_OP_SM = SourceOpStateManager(_getAddress(_SOURCE_OP_SM_HASH));
        _BASE_BRIDGE_TOKEN = _SOURCE_OP_SM.baseBridgeToken();

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
        (uint256 opCurrentStake, uint256 opCurrentHoldings, bool registered) = _SOURCE_OP_SM.operatorData(operator);
        if (!registered) revert NotRegistered();
        if ((opCurrentStake - opCurrentHoldings) < amount) {
            revert InsufficientFunds();
        }

        address _user = msg.sender;
        // change to use adapter
        uint256 _amountToPull = amount + operationFee + bridgeFee;
        _BASE_BRIDGE_TOKEN.safeTransferFrom(_user, address(_SOURCE_OP_SM), _amountToPull);

        _SOURCE_OP_SM.updateOperatorAllocation(operator, amount, 0, true);
        _SOURCE_OP_SM.createOrder(
            orderId, uint32(block.number) + _ORDER_TTL, amount, destAddress, operator, operationFee, bridgeFee
        );
    }

    function fulfillBridge(bytes32 orderId, SourceOpStateManager.FulfillerData[] memory fulfillerData) public {
        _SOURCE_OP_SM.completeOrder(orderId);

        (,, uint256 orderAmount,, address operator, SourceOpStateManager.FeesData memory fees) =
            _SOURCE_OP_SM.orderData(orderId);
        uint256 operatorFees = (fees.operationFee * _SOURCE_OP_SM.OPERATOR_FEE()) / _SOURCE_OP_SM.MAX_BPS();
        uint256 lpFees = (fees.operationFee * _SOURCE_OP_SM.LP_FEE()) / _SOURCE_OP_SM.MAX_BPS();

        _SOURCE_OP_SM.updateOperatorAllocation(operator, orderAmount, operatorFees, false);

        uint256 lpFeesPerFulfiller = lpFees / fulfillerData.length;
        _SOURCE_OP_SM.updatePendingRefunds(fulfillerData, lpFeesPerFulfiller);
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
}
