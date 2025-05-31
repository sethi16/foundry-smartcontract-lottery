// SPDX-LICENSE-IDENTIFIER: MIT

pragma solidity ^0.8.19;

import{Script} from "forge-std/Script.sol";
import {Raffel} from "../src/Raffel.sol";
import {HelperConfig} from "Script/HelperConfig.s.sol";
import "Script/Interaction.s.sol"; // Importing the createSubscription script to create a subscription if needed

contract DeployRaffel is Script {
    function run() public returns (Raffel, HelperConfig) {
        return setUp();
    }

    function setUp() internal returns (Raffel, HelperConfig) {
        HelperConfig config = new HelperConfig();
        HelperConfig.NetworkConfig memory Networkconfig = config.getConfig();
        AddConsumer addconsumer = new AddConsumer();
        FundSubscription fundSubscription = new FundSubscription();
        fundSubscription.fundSubscription(Networkconfig.vrfCoordinator, Networkconfig.subscriptionId, Networkconfig.Link);

         
         if(Networkconfig.subscriptionId == 0){
            CreateSubsciption createSubscription = new CreateSubsciption();
           (Networkconfig.subscriptionId, Networkconfig.vrfCoordinator) = createSubscription.createSubscription(Networkconfig.vrfCoordinator);
           // addconsumer
           addconsumer.addconsumer(address(Raffel), Networkconfig.vrfCoordinator, Networkconfig.subscriptionId, Networkconfig.account);


            // if subscriptionId is 0, then we need to create a subscription
            // this is done in the CreateSubscription script
            // we can call the CreateSubscription script here
            // but it is better to call it in the CreateSubscription script
            // so that we can use the same subscriptionId in the Raffel contract
        // block.chainId is used to get the current chain id,
        // given automatically by forge on whih blockchain we are working
        //  config.NetworkConfig, this variable is used to get the network configuration
        vm.startBroadcast();
        Raffel raffel = new Raffel(
            Networkconfig.lotteryTime,
            Networkconfig.entrancefee,
            Networkconfig.vrfCoordinator,
            Networkconfig.gaslane,
            Networkconfig.subscriptionId,
            Networkconfig.callbackGasLimit,
            Networkconfig.interval
        );
        vm.startBroadcast();

        return(raffel, config);
    }
}
}