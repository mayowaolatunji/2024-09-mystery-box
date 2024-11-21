// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MysteryBox {

    address public owner;
    uint256 public boxPrice;

    mapping(address => uint256) public boxesOwned;
    mapping(address => Reward[]) public rewardsOwned;

    Reward[] public rewardPool;

    uint256 public constant SEEDVALUE = 0.1 ether;

    struct Reward {
        string name;
        uint256 value;
    }

    constructor() payable {
        owner = msg.sender;
        boxPrice = 0.1 ether;
        require(msg.value >= SEEDVALUE, "Incorrect ETH sent");
      
        // Initialize with some default rewards
        rewardPool.push(Reward("Gold Coin", 0.5 ether));
        rewardPool.push(Reward("Silver Coin", 0.25 ether));
        rewardPool.push(Reward("Bronze Coin", 0.1 ether));
        rewardPool.push(Reward("Coal", 0 ether));
    }

//this looks good for now. but why make it public when only owner action is required.
    function setBoxPrice(uint256 _price) public {
        require(msg.sender == owner, "Only owner can set price");
        // what if box prize was set to cause underflows??
        boxPrice = _price;
    }

//
    function addReward(string memory _name, uint256 _value) public {
        require(msg.sender == owner, "Only owner can add rewards");
        rewardPool.push(Reward(_name, _value));
    }

// function does not take input from users but automatically deducit fee..to where?
    function buyBox() public payable {
        require(msg.value == boxPrice, "Incorrect ETH sent");
        // does not update the balance of the owner address
        boxesOwned[msg.sender] += 1;
    }

    function openBox() public {
        require(boxesOwned[msg.sender] > 0, "No boxes to open");
        //@audit prone to insecure randomness.--Using blocktimestanmp for random number is unsafe. correct
        // Generate a random number between 0 and 99
        uint256 randomValue = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender))) % 100; //@audit check for arithemetic error.??? 

        // Determine the reward based on probability
        if (randomValue < 75) {
            // 75% chance to get Coal (0-74)
            rewardsOwned[msg.sender].push(Reward("Coal", 0 ether));
        } else if (randomValue < 95) {
            // 20% chance to get Bronze Coin (75-94)
            rewardsOwned[msg.sender].push(Reward("Bronze Coin", 0.1 ether));
        } else if (randomValue < 99) {
            // 4% chance to get Silver Coin (95-98)
            rewardsOwned[msg.sender].push(Reward("Silver Coin", 0.5 ether)); // not consitent with what we have in the constructor
        } else {
            // 1% chance to get Gold Coin (99)
            rewardsOwned[msg.sender].push(Reward("Gold Coin", 1 ether)); // not consitent with what we have in the constructor
        }

        boxesOwned[msg.sender] -= 1;

        // THis does not completely follow CEI but it also does not make any external call. correct
    }

    function withdrawFunds() public {
        require(msg.sender == owner, "Only owner can withdraw");
        (bool success,) = payable(owner).call{value: address(this).balance}(""); 
        // does not deduct the balance from the contract...yes. balance not updated here again.
        require(success, "Transfer failed");

        // this function missed the E in CEI.
    }

    function transferReward(address _to, uint256 _index) public {
        require(_index < rewardsOwned[msg.sender].length, "Invalid index");
        rewardsOwned[_to].push(rewardsOwned[msg.sender][_index]); // i don't understand this but i will check.
        delete rewardsOwned[msg.sender][_index]; // this method is suspecious.
    }

//@audits Mystery:ClaimAllRewards is prone to Reentrancy attack
    function claimAllRewards() public {
        uint256 totalValue = 0;
        for (uint256 i = 0; i < rewardsOwned[msg.sender].length; i++) {
            totalValue += rewardsOwned[msg.sender][i].value;
        }
        require(totalValue > 0, "No rewards to claim"); //checks

        (bool success,) = payable(msg.sender).call{value: totalValue}(""); // interaction
        require(success, "Transfer failed");

        delete rewardsOwned[msg.sender]; // effect
        // this delete method is suspecious.
    }


//@audits Mystery:ClaimSingleRewards is prone to Reentrancy attack
    function claimSingleReward(uint256 _index) public {
        require(_index <= rewardsOwned[msg.sender].length, "Invalid index");
        uint256 value = rewardsOwned[msg.sender][_index].value;
        require(value > 0, "No reward to claim"); //Checks

        (bool success,) = payable(msg.sender).call{value: value}("");
        require(success, "Transfer failed"); //Interaction.

        delete rewardsOwned[msg.sender][_index]; //Effect
    }

    function getRewards() public view returns (Reward[] memory) {
        return rewardsOwned[msg.sender];
    }

    function getRewardPool() public view returns (Reward[] memory) {
        return rewardPool;
    }
//@audit MysteryBox::changeOwner lackes access control.
    function changeOwner(address _newOwner) public {
        owner = _newOwner;
    }

}
