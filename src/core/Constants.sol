// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

abstract contract Constants {
    /// -- TOKENS --
    bytes32 internal constant _BASE_BRIDGE_TOKEN_HASH = bytes32(uint256(keccak256("jitliq.core.baseBridgeToken")) - 1);

    /// -- CORE CONTRACRS --
    bytes32 internal constant _SOURCE_OP_SM_HASH = bytes32(uint256(keccak256("jitliq.core.sourceOpSM")) - 1);
    bytes32 internal constant _DEST_OP_SM_HASH = bytes32(uint256(keccak256("jitliq.core.destOpSM")) - 1);
    bytes32 internal constant _SOURCE_ENTRYPOINT_HASH = bytes32(uint256(keccak256("jitliq.core.sourceEntrypoint")) - 1);
    bytes32 internal constant _DEST_ENTRYPOINT_HASH = bytes32(uint256(keccak256("jitliq.core.destEntrypoint")) - 1);

    /// -- ADAPTERS --
    bytes32 internal constant _BASE_WITHDRAWAL_ADAPTER_HASH =
        bytes32(uint256(keccak256("jitliq.core.baseWithdrawalAdapter")) - 1);
}
