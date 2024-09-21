// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "src/core/AddressRegistry.sol";
import "src/core/Constants.sol";
import "src/core/DestEntrypoint.sol";
import "src/core/DestOpStateManager.sol";

import "forge-std/Script.sol";

contract DeployDest is Script, Constants {
    function run() public {
        vm.startBroadcast();
        AddressRegistry ar = new AddressRegistry(
            0xE177DdEa55d5A724515AF1D909a36543cBC4d93E
        );
        ar.setAddress(_BASE_BRIDGE_TOKEN_HASH, 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913);
        // AddressRegistry ar = AddressRegistry(
        //     0x1a9d99B3e5Df870f823d00bCA728a466deC089b6
        // );

        DestOpStateManager dosm = new DestOpStateManager(address(ar));
        // SourceOpStateManager sosm = SourceOpStateManager(
        //     0x2bCFbC4Dd2Af9Af0458c9aD179A7A5791b0A9502
        // );
        ar.setAddress(_DEST_OP_SM_HASH, address(dosm));

        DestEntrypoint de = new DestEntrypoint(
            address(ar),
            0x1a44076050125825900e736c501f859c50fE728c, //base & arb endpoint
            30110 /// arb eid
        );
        ar.setAddress(_DEST_ENTRYPOINT_HASH, address(de));
        vm.stopBroadcast();
    }
}
