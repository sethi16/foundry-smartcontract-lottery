// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script, console} from "forge-std/Script.sol";

contract DevOpsTools is Script {
    function getLastDeployedAddress(string memory contractName)
        public
        view
        returns (address)
    {
        string[] memory lines = vm.readFile(
            string.concat("./broadcast/", contractName, ".s.sol/", vm.toString(block.chainid), "/run-latest.json")
        ).split("\n");

        for (uint256 i = 0; i < lines.length; i++) {
            if (bytes(lines[i]).length > 0) {
                // Look for "contractAddress": "0x..."
                if (bytes(lines[i]).length > 24 && bytes(lines[i])[8] == "c") {
                    return vm.parseJsonAddress(lines[i], "$.contractAddress");
                }
            }
        }
        revert("Address not found");
    }
}
