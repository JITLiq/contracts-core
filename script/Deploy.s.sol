// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "src/core/AddressRegistry.sol";
import "src/core/Constants.sol";
import "src/core/SourceEntrypoint.sol";
import "src/core/SourceOpStateManager.sol";

import "forge-std/Script.sol";

contract Deploy is Script, Constants {
    function run() public {
        vm.startBroadcast();
        AddressRegistry ar = new AddressRegistry(
            0xE177DdEa55d5A724515AF1D909a36543cBC4d93E
        );
        // AddressRegistry ar = AddressRegistry(
        //     0x1a9d99B3e5Df870f823d00bCA728a466deC089b6
        // );

        SourceOpStateManager sosm = new SourceOpStateManager(
            address(ar),
            0xaf88d065e77c8cC2239327C5EDb3A432268e5831
        );
        // SourceOpStateManager sosm = SourceOpStateManager(
        //     0x2bCFbC4Dd2Af9Af0458c9aD179A7A5791b0A9502
        // );
        ar.setAddress(_SOURCE_OP_SM_HASH, address(sosm));

        SourceEntrypoint se = new SourceEntrypoint(
            address(ar),
            100,
            0x1a44076050125825900e736c501f859c50fE728c
        );
        ar.setAddress(_SOURCE_ENTRYPOINT_HASH, address(se));
        vm.stopBroadcast();
    }
}
