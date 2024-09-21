// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IDestEntrypoint} from "src/interfaces/IDestEntrypoint.sol";
import {AddressRegistryService} from "src/core/AddressRegistryService.sol";
import {DestOpStateManager} from "src/core/DestOpStateManager.sol";

import {OAppSender, MessagingFee} from "layerzero-v2/oapp/contracts/oapp/OAppSender.sol";
import {OAppCore} from "layerzero-v2/oapp/contracts/oapp/OAppCore.sol";
import {OptionsBuilder} from "layerzero-v2/oapp/contracts/oapp/libs/OptionsBuilder.sol";

import {Ownable} from "openzeppelin-contracts/access/Ownable.sol";

import {SafeTransferLib} from "solady/utils/SafeTransferLib.sol";
import {ECDSA} from "solady/utils/ECDSA.sol";

contract DestEntrypoint is IDestEntrypoint, AddressRegistryService, OAppSender {
    using SafeTransferLib for address;
    using OptionsBuilder for bytes;
    using ECDSA for bytes32;

    error InvalidSignatures();
    error TransferFailed();

    event FulfilledOrder(bytes32 indexed orderId);

    uint32 public immutable SOURCE_CHAIN_EID;

    bytes internal _lzOptions = OptionsBuilder.newOptions().addExecutorLzReceiveOption(3000000, 0);

    constructor(address _addressRegistry, address _lzEndpoint, uint32 _sourceChainEid)
        AddressRegistryService(_addressRegistry)
        OAppCore(_lzEndpoint, msg.sender)
        Ownable(msg.sender)
    {
        SOURCE_CHAIN_EID = _sourceChainEid;
    }

    function fulfillOrder(
        bytes32 orderId,
        OrderData memory orderData,
        FulfillerData[] memory fulfillerData,
        bytes[] memory operatorSignatures
    ) external payable {
        (DestOpStateManager _destOpSM, address _baseBridgeToken) = _getStateManager();

        uint256 operatorsLength = operatorSignatures.length;
        address[] memory operators = _destOpSM.getOperators();

        while (operatorsLength != 0) {
            uint256 idx = operatorsLength - 1;
            address recoveredSigner = orderId.recover(operatorSignatures[idx]);

            if (recoveredSigner != operators[idx]) revert InvalidSignatures();

            unchecked {
                operatorsLength--;
            }
        }

        uint256 fulfillersLength = fulfillerData.length;
        while (fulfillersLength != 0) {
            FulfillerData memory _fulfillerData = fulfillerData[fulfillersLength - 1];
            _baseBridgeToken.safeTransferFrom(
                _fulfillerData.fulfiller, orderData.destAddress, _fulfillerData.fulfillAmount
            );

            unchecked {
                fulfillersLength--;
            }
        }

        _destOpSM.deductStakedFunds(orderData.orderAmount);

        LzReceiveMessage memory _lzMessage = LzReceiveMessage({orderId: orderId, fulfillerData: fulfillerData});
        bytes memory _payload = abi.encode(_lzMessage);

        MessagingFee memory _fee = lzQuote(SOURCE_CHAIN_EID, _payload, false);
        _lzSend(SOURCE_CHAIN_EID, _payload, _lzOptions, _fee, addressRegistry.owner());

        emit FulfilledOrder(orderId);
    }

    function lzQuote(uint32 dstEid, bytes memory payload, bool payInLzToken)
        public
        view
        returns (MessagingFee memory fee)
    {
        fee = _quote(dstEid, payload, _lzOptions, payInLzToken);
    }

    function _getStateManager() internal view returns (DestOpStateManager, address) {
        DestOpStateManager destOpSM = DestOpStateManager(_getAddress(_DEST_OP_SM_HASH));
        return (destOpSM, destOpSM.baseBridgeToken());
    }

    function sweep(address token, uint256 amount) external {
        _onlyGov(msg.sender);

        if (token == address(0)) {
            (bool succ,) = msg.sender.call{value: amount}("");
            if (!succ) revert TransferFailed();

            return;
        }

        token.safeTransfer(msg.sender, amount);
    }

    receive() external payable {}
}
