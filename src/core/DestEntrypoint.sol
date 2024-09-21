// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IDestEntrypoint} from "src/interfaces/IDestEntrypoint.sol";
import {AddressRegistryService} from "src/core/AddressRegistryService.sol";

import {OAppSender, MessagingFee} from "layerzero-v2/oapp/contracts/oapp/OAppSender.sol";
import {OAppCore} from "layerzero-v2/oapp/contracts/oapp/OAppCore.sol";
import {OptionsBuilder} from "layerzero-v2/oapp/contracts/oapp/libs/OptionsBuilder.sol";

import {Ownable} from "openzeppelin-contracts/access/Ownable.sol";

import {SafeTransferLib} from "solady/utils/SafeTransferLib.sol";

contract DestEntrypoint is IDestEntrypoint, AddressRegistryService, OAppSender {
    using SafeTransferLib for address;
    using OptionsBuilder for bytes;

    event FulfilledOrder(bytes32 indexed orderId);

    uint32 public immutable SOURCE_CHAIN_EID;

    bytes _lzOptions = OptionsBuilder.newOptions().addExecutorLzReceiveOption(50000, 0);

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
    ) external {
        address _baseBridgeToken = _getAddress(_BASE_BRIDGE_TOKEN_HASH);
        /// todo: validate sigs & stake
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
}
