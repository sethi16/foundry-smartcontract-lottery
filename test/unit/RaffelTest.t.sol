// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Raffel, RaffleState} from "../../src/Raffel.sol";
import {DeployRaffel} from "Script/DeployRaffel.s.sol";
import {HelperConfig} from "../../Script/HelperConfig.s.sol";
import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {Vm} from "forge-std/Vm.sol";
// This import is different, this is capital.

contract RaffelTest is Test {
    Raffel public raffel;
    HelperConfig public helperConfig;
    uint256 public interval = 300; // this is the interval for the raffel to be open and work

    address public user;
    address public player;
    uint256 public constant transferFund = 500 ether;
     event Winner(address indexed winner); // this is an event
    event WinnerSelected(address indexed winner); // this is an event
    // We need to paste the same event as it is in the Raffel contract, so that we can test it
    // we cant import it!

    function setUp() external {
        user = makeAddr("user");
        player = makeAddr("player");
        vm.deal(player, transferFund);
        vm.deal(user, transferFund);

        helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        raffel = new Raffel(
            config.lotteryTime,
            config.entrancefee,
            config.vrfCoordinator,
            config.gaslane,
            uint64(config.subscriptionId),
            config.callbackGasLimit,
            config.interval
        );
    }

    function testRaffelOpenStat() public view{ // added view to the function because the function, I am testing is a view function!
    // Code will run, but without view result in warning
    // Added view means give return but in testin gno need it is for the function which is a view function
        assertEq(uint256(raffel.getRaffelState()), uint256(RaffleState.OPEN));
    }

    function testRaffleRevertsWhenYouNotPayEnough() public {
        // Arrange
        vm.prank(user);
        // Act / Assert
        vm.expectRevert(Raffel.NotEnoughCryptoToParticapate.selector);
        raffel.CheckRaffelEntry{value: 19 ether}(); // this should revert if msg.value < entrance fee
    }
    function testparticipationinraffel() public {
        // Arrange
        vm.prank(user);
        // Act
        raffel.CheckRaffelEntry{value: 20 ether}();
        address participants = raffel.checkparticipants(0);
        assertEq(participants, user);
//---------------
     
    }
    function testparticipationinraffelEmit() public {
        vm.prank(user);
        raffel.CheckRaffelEntry{value: 15 ether}();
        vm.expectEmit(true,false,false,false, address(raffel)); // index value meas true
        // this accept four boolean value, if it is one
        // first is true, others are false, means we are not checking for indexed value
        // at last we need to give the address of the contract which is emitting the event
        // expectEmit is a test which checks if the emit is calling the right event for that both needs to be same 
        // vm.expectEmit(true, false, false, false, address(raffel)) ==  emit Winner(user); of same event!
        emit Winner(user);

    }
    function testdontallowPlayerToEnterWhenItisCalculatinng() public {
        vm.deal(user, 200 ether); // giving 20 ether to user
        vm.prank(user);
        raffel.CheckRaffelEntry{value: 20 ether}();
        vm.warp(block.timestamp + interval + 1); // this will increase the block timestamp by interval + 1
        // vm.warp is used to increase the block timestamp
        vm.roll(block.number+1); // this will increase the block number by 1
        assert(raffel.getRaffelState() == RaffleState.OPEN); // this will check if the raffel is open or not
       // vm.expectRevert();
        raffel.performUpkeep(""); // used ("") because not want to give input to the function!
         assert(raffel.getRaffelState() == RaffleState.CALCULATING_WINNER);
        // -----------------
        vm.prank(user);
        vm.expectRevert(Raffel.RaffleNotOpen.selector);
        raffel.CheckRaffelEntry{value: 20 ether}();
// when my raffel is calculating the winner, it should not allow any player to enter the raffle

    }
    function testCheckUpKeep() public{
        vm.prank(user);
        vm.wrap(block.timestamp + interval + 1); // this will increase the block timestamp by interval + 1
        vm.roll(block.number + 1); // this will increase the block number by 1
        (bool upkeepNeeded,)=checkUpkeep("");
        assert(!upkeepNeeded);
        // Here, I am checking if checkUpkeep is returning false when the raffel is not open
        // I dont need the vm.expectRevert to expect an error, upper code could be used to determine is it not running!

    }
    function testCheckUpKeepagain() public{
        vm.prank(user);

         vm.wrap(block.timestamp + interval + 1); 
        vm.roll(block.number + 1); 
         raffel.CheckRaffelEntry{value: 20 ether}();
           raffel.performUpkeep(""); 

           vm.prank(user);
        (bool upkeepNeeded,) = raffel.checkUpkeep("");
        assert(!upkeepNeeded); // or you can write assert(upkeepNeeded == false);
        // For true, assert(upkeepNeeded) or assert(upkeepNeeded == true);
        // Here, I am checking if checkUpkeep is returning false when the raffel is not open
        // Above, I gave all the required details but called the function " performUpkeep " which closed my raffel after entering the raffel!

}

    function testCheckUpkeepReturnsFalseIfRaffleIsntOpen() public {
        // Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: 23 ether}();
        vm.warp(block.timestamp + automationUpdateInterval + 1);
        vm.roll(block.number + 1);
        raffle.performUpkeep("");
        Raffle.RaffleState raffleState = raffle.getRaffleState();
        // Act
        (bool upkeepNeeded,) = raffle.checkUpkeep("");
        // Assert
        assert(raffleState == Raffle.RaffleState.CALCULATING);
        assert(upkeepNeeded == false);
    }

    // Challenge 1. testCheckUpkeepReturnsFalseIfEnoughTimeHasntPassed
    function testCheckUpkeepReturnsFalseIfEnoughTimeHasntPassed() public {
        // Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: 25 ether}();

        // Act
        (bool upkeepNeeded,) = raffle.checkUpkeep("");

        // Assert
        assert(!upkeepNeeded);
    }
     function testCheckUpkeepReturnsTrueWhenParametersGood() public {
        // Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: 20 ether}();
        vm.warp(block.timestamp + automationUpdateInterval + 1);
        vm.roll(block.number + 1);

        // Act
        (bool upkeepNeeded,) = raffle.checkUpkeep("");

        // Assert
        assert(upkeepNeeded);
    }
    function testPerformUpkeepRevertsIfCheckUpkeepIsFalse() public{
        vm.prank(user);
        uint256 AccountBalance=0;
        uint256 players = 0;
        uint256 checker = raffel.getRaffelState();

        vm.expectRevert(abi.encodeWithSelector()(Raffel.Raffle_UpkeeperNeeded.Selector,AccountBalance,players,checker));
        // In order to give the error & the inputs to the error, we need to use abi.encodeWithSelector
        // Inside it first we need to give the error selector, then the inputs to the error
        raffel.performUpkeep("");
        // When we call a function, but not wanted to give the input, we can use "" as input
    }
    modifier RaffelContract() {
            vm.prank(user);
          raffle.enterRaffle{value: 25 ether}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        _;
    }

    modifier skipFork() {
        if(block.chainid != 31337){
            return;
            // simple, ' return ' means exit the function or modifier, means skip the rest of the code
            // If this present in a function, the whole function will be skipped!
        }
        _;
    }
    function testPerformUpkeepUpdatesRaffelStateAndEmitsEequestId() public RaffelContract{
        
        // Act
        vm.recordLogs();
        raffel.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs(); // entries hold all emits of this function!
        // struct Vm.Log , Here Vm is a library from forge-std, which includes the Log struct mentioned below with three types:
        // address emitter;   -> who emitted the event (contract address)
       //bytes32[] topics;   // contains event signature + indexed params
       //bytes data;         // contains non-indexed params


         bytes32 requestNumber = entries[0].topics[1]; // Here, it means first emit & it's first indexed parameter
        // Assert
       
        Raffle.RaffleState raffleState = raffle.getRaffleState();
        assert(uint256(requestNumber)>0); 
        // Checked the requestId by converting it to uint256 from bytes32 and checking if it is greater than 0
        assert(uint256(raffelState) == 1); // Or assert(raffelState == Raffle.RaffleState.CALCULATING_Winner);
    }

}

This part of the command tells Foundry to run test coverage analysis.
 It runs your tests and checks how much of your Solidity code is being exercised by them.
  It helps identify untested parts of your contracts in the coverage.txt file.
```bash
forge coverage --report debug > coverage.txt
```
