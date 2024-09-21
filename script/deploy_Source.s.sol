// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "src/core/AddressRegistry.sol";
import "src/core/Constants.sol";
import "src/core/SourceEntrypoint.sol";
import "src/core/SourceOpStateManager.sol";

import "forge-std/Script.sol";

contract DeploySource is Script, Constants {
    function run() public {
        vm.startBroadcast();
        AddressRegistry ar = new AddressRegistry(
            0xE177DdEa55d5A724515AF1D909a36543cBC4d93E
        );
        ar.setAddress(_BASE_BRIDGE_TOKEN_HASH, 0xaf88d065e77c8cC2239327C5EDb3A432268e5831);
        ar.setAddress(_MULTICALLER_HASH, 0x0000000000002Bdbf1Bf3279983603Ec279CC6dF);
        // AddressRegistry ar = AddressRegistry(
        //     0x1a9d99B3e5Df870f823d00bCA728a466deC089b6
        // );

        SourceOpStateManager sosm = new SourceOpStateManager(
            address(ar),
            6, // base cctp domain
            0x19330d10D9Cc8751218eaf51E8885D058642E08A // arb token messenger
        );
        // SourceOpStateManager sosm = SourceOpStateManager(
        //     0x2bCFbC4Dd2Af9Af0458c9aD179A7A5791b0A9502
        // );
        ar.setAddress(_SOURCE_OP_SM_HASH, address(sosm));

        SourceEntrypoint se = new SourceEntrypoint(
            address(ar),
            100,
            0x1a44076050125825900e736c501f859c50fE728c, // base & arb endpoint
            30184 /// base eid
        );
        ar.setAddress(_SOURCE_ENTRYPOINT_HASH, address(se));
        vm.stopBroadcast();
    }
}
