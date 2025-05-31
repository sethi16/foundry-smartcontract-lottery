//SPDX-LICENSE-IDENTIFIER: MIT
// Interaction script for creating a subscription, funding it, and adding a consumer to the subscription
// Interaction file is made for every project to work on mainnet, in order to actually check other than testing
pragma solidity ^0.8.19;

import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {HelperConfig, codeConstants} from "Script/HelperConfig.s.sol";
import {Script, console} from "forge-std/Script.sol";
import {DevOpsTools} from "../script/DevOpsTools.sol";
import {LinkToken} from "test/mocks/LinkTokens.sol"; // Importing LinkToken for testing purposes
contract CreateSubsciption is Script{

    function CreateSubsciptionUsingConfig() public returns (uint256, address) {
        HelperConfig helperConfig = new HelperConfig();
        address VrfCoordinator = helperConfig.getConfig().vrfCoordinator;
       (uint256 subId,)= createSubscription(VrfCoordinator);
        return (subId, VrfCoordinator);
    }
    function createSubscription(address VrfCoordinator) public  returns(uint256,address){
        vm.startBroadcast();
        uint256 subId = VRFCoordinatorV2Mock(VrfCoordinator).createSubscription();
        vm.stopBroadcast();
        return (subId, VrfCoordinator);
    }
    function run() external returns (uint256, address) {
        return CreateSubsciptionUsingConfig();
    }
}
contract FundSubscription is  codeConstants,  Script { 
    // codeConstants is an abstract contarct from helperConfig.s.sol file
    uint256 public constant Fund_Value = 3 ether; // 3 link tokens, this is the value to fund the subscription
    function fundSubscripition(address VrfCoordinator, uint256 subId, address link) public {
        console.log("Funding subscription with ID:", subId);
        console.log("Using VRF Coordinator:", VrfCoordinator);
        console.log("Using LINK token:", link);
        console.log("Current chain ID:", block.chainid);

        // Example: assuming Local_chain_id is defined elsewhere and chainId is block.chainid
        if (block.chainid == Local_chain_id) {
            vm.startBroadcast();
            VRFCoordinatorV2Mock(VrfCoordinator).fundSubscription(subId, Fund_Value); // Funding the subscription with LINK
            vm.stopBroadcast();
        } else {
            vm.startBroadcast();
            LinkToken(link).transferAndCall(
                VrfCoordinator,
                Fund_Value,
                abi.encode(subId)
            ); // Funding the subscription with LINK
            vm.stopBroadcast();
            console.log("Subscription funded successfully!");
        }
    }
    function fundSubscriptionUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        address VrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        uint256 subId = helperConfig.getConfig().subscriptionId;
        address link =helperConfig.getConfig().Link;

        if(subId == 0){
            CreateSubsciption createSubsciption = new CreateSubsciption();
            (uint256 subId,address VrfCoordinator ) = createSubsciption.run();
            console.log("Created new subscription with ID:", subId, " on VRF Coordinator:", VrfCoordinator);
        }
        fundSubscripition(VrfCoordinator, subId, link);
    }

    function run() external {
        fundSubscriptionUsingConfig();
    }

}

contract AddConsumer is Script{
    function AddConsumer(address mostRecentlyDeployed,address VrfCoordinator,uint256 subId,uint256 account) public {
        console.log(mostRecentlyDeployed);
        console.log(VrfCoordinator);
        console.log(subId);
        console.log(account);
        console.log(block.chainid);
        vm.startBroadcast();
        VRFCoordinatorV2Mock(VrfCoordinator).addConsumer(subId, mostRecentlyDeployed);
        // VRFCoordinatorV2Mock, In this case, I inserted the address of the network in this contract as " VrfCoordinator ",
        // & called the addConsumer function of the VRFCoordinatorV2Mock contract with values inserted in the function
        vm.stopBroadcast();
    }


    function AddConsumerUsingConfig(address mostRecentlyDeployed) public {
        HelperConfig helperConfig = new HelperConfig();
        address VrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        uint256 subId = helperConfig.getConfig().subscriptionId;
        uint256 account = helperConfig.getConfig().account();
        addConsumer(mostRecentlyDeplyed,VrfCoordinator, subId, account);
    }
    function run() external {
        address mostRecentlyDeplyed = DevOpsTools.get_most_recent_deployment("Raffel",block.chainid);
        AddConsumerUsingConfig(mostRecentlyDeplyed);
    }
    
}

