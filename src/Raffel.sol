// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

enum RaffleState { // enum need to be outside of the contract
        OPEN, // In enum, the first value is 0, the second value is 1, and so on
        // Could be checked as " RaffleState.CALCULATING_WINNER == 1 " or "RaffleState.OPEN == 0"
        CALCULATING_WINNER
    }


import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";

   
/**
 * @title A sample contract for a lottery game
 * @author Sarthak Sethi
 * @notice Implementing a lottery game using Chainlink VRF
 * @dev This contract is a sample implementation of a lottery game using Chainlink VRF
 */
 contract Raffel is VRFConsumerBaseV2Plus {
    //Type Declarations
   
    // Errors
    error NotEnoughCryptoToParticapate();
    error TimeLimitNotReached();
    error MoneyTransferFailed();
    error RaffleNotOpen();
    error Raffle_UpkeeperNeeded(uint256, uint256, uint256);

    // State Variables
    uint256 public immutable i_timeInput;
    uint256 public min_deposit;
    address payable[] public participants;
    uint256 public lastTimeStamp;
    uint256 public lotteryCall;
    uint256 public immutable i_interval;
    bytes32 private immutable i_keyHash;
    uint256 private immutable i_subscriptionId;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private immutable i_callbackGasLimit;
    uint32 private constant NUM_WORDS = 1;
    RaffleState private s_rafflestate;
    address payable[] private s_players;

    event Winner(address indexed winner); // this is an event
    event WinnerSelected(address indexed winner); // this is an event
    event RequestRaffleWinner(uint256 indexed requestId);
// iN EVENT, more than 3 index is not possible in an single event 
    constructor(
        uint256 lotteryTime,
        uint256 entrancefee,
        address vrfCoordinator,
        bytes32 gaslane,
        uint256 subscriptionId,
        uint32 callbackGasLimit,
        uint256 interval
    ) VRFConsumerBaseV2Plus(vrfCoordinator) {
        // lotteryTime is a parameter of the constructor  // above here, VRFConsumerBaseV2Plus is a contract of Chainlink import!
        i_timeInput = entrancefee;
        lastTimeStamp = block.timestamp;
        lotteryCall = lotteryTime;
        i_keyHash = gaslane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        i_interval = interval;
        s_rafflestate = RaffleState.OPEN;
        s_players = participants;
        min_deposit=10 ether;
    }

    function CheckRaffelEntry() external payable {
        // check the ether paid
        if (msg.value <= min_deposit) {
            revert NotEnoughCryptoToParticapate();
        }
        if (s_rafflestate != RaffleState.OPEN) {
            revert RaffleNotOpen();
        }

        participants.push(payable(msg.sender)); // payable is used to send ether
        // ETH to to the winner whom is deploying in the lottery game
        emit Winner(msg.sender); // this is an event
            // emit is logging the event, the event is sending the data off-chain
            // sending data off-chain is cheaper than sending it on-chain
            // sending to the app
            // It does NOT store anything in contract storage to save gas.
            //Instead, it creates a log entry, which is stored in the transaction receipt
    }

    // when should the winner be selected?
    /**
     * @dev This is the function that the Chainlink Keeper nodes call to see if
     * the lottery is ready to have a winner selected
     * 1.  The time interval passed b.w raffle runs
     * 2. The lottery is open
     * 3. The Contract has ETH
     * 4. Implicity, your subscription is funded with LINK
     * @param - ignored
     * @return upkeepNeeded - true if the lottery is ready to have a winner selected
     * @return - ignored
     */
    function checkUpkeep(bytes memory /* checkData */ )
        public
        view
        returns (bool upkeepNeeded, bytes memory /* performData */ )
    {
        bool TimePassed = (block.timestamp - lastTimeStamp) >= i_interval;
        bool isOpen = (s_rafflestate == RaffleState.OPEN);
        bool hasBalance = address(this).balance > 0;
        bool hasplayers = s_players.length > 0;
        upkeepNeeded = TimePassed && isOpen && hasBalance && hasplayers;
        return (upkeepNeeded, "0x0");
    }

    function performUpkeep(bytes calldata /* performData */ ) external {
        //require(block.timestamp - lastTimeStamp)
        (bool upkeepNeeded,) = checkUpkeep("");
        // remember the way, were doing from another imported contract
        // function is equal to all the variable it includes!
        if (!upkeepNeeded) {
            revert Raffle_UpkeeperNeeded(address(this).balance, s_players.length, uint256(s_rafflestate));
        }

        s_rafflestate = RaffleState.CALCULATING_WINNER;
        VRFV2PlusClient.RandomWordsRequest memory request = VRFV2PlusClient.RandomWordsRequest({
            keyHash: i_keyHash, // hash value resprents maximum gas price you are willing to pay
            subId: i_subscriptionId, // subscription ID that contract uses for funding requests
            requestConfirmations: REQUEST_CONFIRMATIONS, // number of confirmations the Chainlink node should wait before responding
            // in ordere to get the random number, the longer the node waits, the more secure the random number is
            // the more secure the random number is, the more gas it will cost
            callbackGasLimit: i_callbackGasLimit, // gas limit for the callback request
            numWords: NUM_WORDS, // number of random numbers to request
            extraArgs: VRFV2PlusClient._argsToBytes(
                // Set nativePayment to true to pay for VRF requests with Sepolia ETH instead of LINK
                VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
            )
        });
        uint256 requestId = s_vrfCoordinator.requestRandomWords(request);
        emit RequestRaffleWinner(requestId);

    }

    function fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) internal virtual override {
        // CEI pattern,  Check, Effect, Interaction   // <-
        // override is used because we are using a virtual function
        //check
        // a%2==0 mod, check!

        //  Effect
        uint256 winnerindex = randomWords[0] % s_players.length;
        address payable winner = s_players[winnerindex];
        s_rafflestate = RaffleState.OPEN;
        s_players = new address payable[](0);
        lastTimeStamp = block.timestamp; // time when the winner was selected, deploed time!
        // reset the participants array
        // Interaction
        (bool success,) = winner.call{value: address(this).balance}("");
        if (!success) {
            revert MoneyTransferFailed();
        }
        emit WinnerSelected(winner); // this is an event
            // emit is logging the event, the event is sending the data off-chain
    }

    function getRaffelState() external view returns (RaffleState) {
        return s_rafflestate;
    }
    function checkparticipants(uint256 index) public view returns(address payable) {
        return participants[index];
    }
    function getLastTimeStamp() public view returns (uint256) {
        return lastTimeStamp;
    }

    function getInterval() public view returns (uint256) {
        return i_interval;
    }

    function getEntranceFee() public view returns (uint256) {
        return i_timeInput;
    }

    function getNumberOfPlayers() public view returns (uint256) {
        return s_players.length;
    }
}


// Use view / pure → In contract function declarations (in src/*.sol)

//Don't use view / pure →  In test calls, script calls, or anywhere else

