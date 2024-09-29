// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SpacePredictionTimeCapsule {   
    struct Prediction {
        address creator;
        string content; // Prediction or message for time capsule
        uint256 lockedUntil; // Timestamp when it can be unlocked
        bool isVerified; // Whether the prediction was verified as correct
        uint256 lockedGAS; // Amount of GAS locked for this prediction
    }

    address public owner;
    mapping(bytes32 => Prediction) public predictions;
    mapping(address => uint256) public rewards; // GAS rewards for accurate predictions
    uint256 public verificationFee = 0.01 ether; // Fee for verification (in GAS)
    uint256 public predictionReward = 1 ether; // Reward for accurate predictions (in GAS)

    event PredictionCreated(address indexed creator, bytes32 indexed predictionId, uint256 lockedUntil);
    event PredictionVerified(bytes32 indexed predictionId, bool verified);
    event PredictionUnlocked(address indexed creator, bytes32 indexed predictionId, uint256 reward);
    event RewardClaimed(address indexed user, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    modifier onlyAfterUnlock(bytes32 predictionId) {
        require(block.timestamp >= predictions[predictionId].lockedUntil, "Prediction is still locked");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    // Create a new prediction or time capsule
    
    function createPrediction(string memory content, uint256 timeLockDuration) public payable {
        // require(timeLockDuration >= 1 days, "Time lock must be at least 1 day");
        // require(msg.value > 0, "Must lock some GAS");

        bytes32 predictionId = keccak256(abi.encodePacked(msg.sender, content, block.timestamp));

        predictions[predictionId] = Prediction({
            creator: msg.sender,
            content: content,
            lockedUntil: block.timestamp + timeLockDuration,
            isVerified: false,
            lockedGAS: msg.value
        });

        emit PredictionCreated(msg.sender, predictionId, block.timestamp + timeLockDuration);
    }

    // Verify a prediction (manual or oracle-based)
    function verifyPrediction(bytes32 predictionId, bool isCorrect) public payable onlyOwner {
        require(predictions[predictionId].lockedGAS > 0, "Invalid prediction");
        require(msg.value >= verificationFee, "Insufficient verification fee");

        predictions[predictionId].isVerified = isCorrect;

        if (isCorrect) {
            rewards[predictions[predictionId].creator] += predictionReward;
        }

        emit PredictionVerified(predictionId, isCorrect);
    }

    // Unlock and claim rewards after the time lock
    function unlockPrediction(bytes32 predictionId) public onlyAfterUnlock(predictionId) {
        Prediction storage pred = predictions[predictionId];
        require(pred.creator == msg.sender, "Not the creator");

        uint256 rewardAmount = pred.isVerified ? pred.lockedGAS + predictionReward : pred.lockedGAS;
        payable(msg.sender).transfer(rewardAmount);

        delete predictions[predictionId]; // Remove the prediction once unlocked

        emit PredictionUnlocked(msg.sender, predictionId, rewardAmount);
    }

    // Allow users to claim their rewards for correct predictions
    function claimReward() public {
        uint256 reward = rewards[msg.sender];
        require(reward > 0, "No rewards to claim");

        rewards[msg.sender] = 0;
        payable(msg.sender).transfer(reward);

        emit RewardClaimed(msg.sender, reward);
    }

    // Change verification fee
    function changeVerificationFee(uint256 newFee) public onlyOwner {
        verificationFee = newFee;
    }

    // Change reward for correct predictions
    function changePredictionReward(uint256 newReward) public onlyOwner {
        predictionReward = newReward;
    }

    // Fallback function to receive GAS directly
    receive() external payable {}
}
