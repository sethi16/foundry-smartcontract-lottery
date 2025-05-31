//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {Raffel} from "../src/Raffel.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {LinkToken} from "test/mocks/LinkTokens.sol";

abstract contract codeConstants {
    /* VRF Mock Values */
    uint96 public MOCK_BASE_FEE = 0.25 ether;
    uint96 public MOCK_GAS_PRICE_LINK = 1e9; // 0.000000001 LINK per gas
    int96 public MOCK_WEI_PER_UINT_LINK = 1e9; // 0.000000001 LINK per gas
    uint256 public constant BLOCK_CONFIRMATIONS = 6;
    uint256 public constant SEPOLIA_BLOCK_CONFIRMATIONS = 1;
    uint256 public constant sepolia_network = 11155111;
    uint256 public constant Local_chain_id = 31337;
}

contract HelperConfig is codeConstants, Script { // contract get info from abstract contract
    struct NetworkConfig {
        uint256 lotteryTime;
        uint256 entrancefee;
        address vrfCoordinator;
        bytes32 gaslane;
        uint256 subscriptionId;
        uint32 callbackGasLimit;
        uint256 interval;
        address Link; // Link token address
    }

    error HelperConfig_InvalidChainId();
    error localNetworkConfig_InvalidChainId();

    NetworkConfig public LocalNetworkConfig;
    mapping(uint256 chainID => NetworkConfig) public networkConfigs; // mapping to store network configurations

    constructor() {
        networkConfigs[sepolia_network] = getSepoliaConfig();
        // this value is stored for further use
    }

    function getConfigChainId(uint256 chainId) public returns (NetworkConfig memory) {
        if (networkConfigs[chainId].vrfCoordinator != address(0)) {
            return networkConfigs[chainId];
        } else if (chainId == Local_chain_id) {
            return getAnvilConfig();
        } else {
            revert HelperConfig_InvalidChainId();
        }
    }

    function getConfig() public returns (NetworkConfig memory) {
        return getConfigChainId(block.chainid);
    }

    function getSepoliaConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({
            lotteryTime: 60,
            entrancefee: 0.01 ether,
            vrfCoordinator: 0x3C0Ca683b403E37668AE3DC4FB62F4B29B6f7a3e,
            gaslane: 0x9e9e46732b32662b9adc6f3abdf6c5e926a666d174a4d6b8e39c4cca76a38897,
           callbackGasLimit: 500000,
           subscriptionId: 0,
           interval: 30,
           Link: 0x6641415a61bCe80D97a715054d1334360Ab833Eb
           // address got from Sepolia Chainlink Faucet
           // Link is the address of the LINK token on Sepolia 
           // Link token is used to pay for the gas fees of the Chainlink VRF, keepers, pricefeed
        });
    }

    function getAnvilConfig() public returns (NetworkConfig memory) {
        if (LocalNetworkConfig.vrfCoordinator != address(0)) {
            return LocalNetworkConfig;
        }
        vm.startBroadcast();
        VRFCoordinatorV2Mock vrfCoordinator = new VRFCoordinatorV2Mock(MOCK_BASE_FEE, MOCK_GAS_PRICE_LINK);
        LinkToken link = new LinkToken();
        // Needed to deploy the Link token contract for local testing
        // The same way I did for the VRFCoordinatorV2Mock contract
        vm.stopBroadcast();

        LocalNetworkConfig = NetworkConfig({
            lotteryTime: 60,
            entrancefee: 0.01 ether,
            vrfCoordinator: address(vrfCoordinator), // gives the network address on which it require to work!
            gaslane: 0x9e9e46732b32662b9adc6f3abdf6c5e926a666d174a4d6b8e39c4cca76a38897,
            callbackGasLimit: 500000,
            subscriptionId: 0,
            interval: 30,
            Link : address(link) // Link token address for local network
        });
        return LocalNetworkConfig;
    }
}
