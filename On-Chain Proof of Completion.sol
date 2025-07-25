// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title On-Chain Proof of Completion
 * @dev A smart contract for creating, submitting, and verifying completion proofs
 * @author Blockchain Developer
 */
contract OnChainProofOfCompletion {
    
    // Struct to represent a task
    struct Task {
        uint256 taskId;
        address creator;
        string title;
        string description;
        uint256 deadline;
        bool isActive;
        uint256 createdAt;
        string completionCriteria;
    }
    
    // Struct to represent a completion proof
    struct CompletionProof {
        uint256 proofId;
        uint256 taskId;
        address submitter;
        string proofData;
        string evidenceHash;
        uint256 submittedAt;
        bool isVerified;
        address verifiedBy;
        uint256 verifiedAt;
        string remarks;
    }
    
    // State variables
    uint256 private taskCounter;
    uint256 private proofCounter;
    
    // Mappings
    mapping(uint256 => Task) public tasks;
    mapping(uint256 => CompletionProof) public proofs;
    mapping(uint256 => uint256[]) public taskProofs; // taskId => proofIds[]
    mapping(address => uint256[]) public userTasks; // user => taskIds[]
    mapping(address => uint256[]) public userProofs; // user => proofIds[]
    mapping(address => uint256) public userCompletionCount;
    
    // Events
    event TaskCreated(
        uint256 indexed taskId,
        address indexed creator,
        string title,
        uint256 deadline
    );
    
    event ProofSubmitted(
        uint256 indexed proofId,
        uint256 indexed taskId,
        address indexed submitter,
        string evidenceHash
    );
    
    event ProofVerified(
        uint256 indexed proofId,
        uint256 indexed taskId,
        address indexed verifier,
        bool isApproved
    );
    
    // Modifiers
    modifier onlyTaskCreator(uint256 _taskId) {
        require(tasks[_taskId].creator == msg.sender, "Only task creator can perform this action");
        _;
    }
    
    modifier taskExists(uint256 _taskId) {
        require(_taskId <= taskCounter && _taskId > 0, "Task does not exist");
        _;
    }
    
    modifier proofExists(uint256 _proofId) {
        require(_proofId <= proofCounter && _proofId > 0, "Proof does not exist");
        _;
    }
    
    modifier taskActive(uint256 _taskId) {
        require(tasks[_taskId].isActive, "Task is not active");
        require(block.timestamp <= tasks[_taskId].deadline, "Task deadline has passed");
        _;
    }
    
    /**
     * @dev Core Function 1: Create a new task with completion criteria
     * @param _title Title of the task
     * @param _description Detailed description of the task
     * @param _deadline Unix timestamp for task deadline
     * @param _completionCriteria Specific criteria for task completion
     */
    function createTask(
        string memory _title,
        string memory _description,
        uint256 _deadline,
        string memory _completionCriteria
    ) external returns (uint256) {
        require(bytes(_title).length > 0, "Task title cannot be empty");
        require(_deadline > block.timestamp, "Deadline must be in the future");
        
        taskCounter++;
        
        tasks[taskCounter] = Task({
            taskId: taskCounter,
            creator: msg.sender,
            title: _title,
            description: _description,
            deadline: _deadline,
            isActive: true,
            createdAt: block.timestamp,
            completionCriteria: _completionCriteria
        });
        
        userTasks[msg.sender].push(taskCounter);
        
        emit TaskCreated(taskCounter, msg.sender, _title, _deadline);
        
        return taskCounter;
    }
    
    /**
     * @dev Core Function 2: Submit proof of task completion
     * @param _taskId ID of the task being completed
     * @param _proofData Description or details of the completion proof
     * @param _evidenceHash Hash of evidence files or data supporting completion
     */
    function submitProof(
        uint256 _taskId,
        string memory _proofData,
        string memory _evidenceHash
    ) external taskExists(_taskId) taskActive(_taskId) returns (uint256) {
        require(bytes(_proofData).length > 0, "Proof data cannot be empty");
        require(bytes(_evidenceHash).length > 0, "Evidence hash cannot be empty");
        
        proofCounter++;
        
        proofs[proofCounter] = CompletionProof({
            proofId: proofCounter,
            taskId: _taskId,
            submitter: msg.sender,
            proofData: _proofData,
            evidenceHash: _evidenceHash,
            submittedAt: block.timestamp,
            isVerified: false,
            verifiedBy: address(0),
            verifiedAt: 0,
            remarks: ""
        });
        
        taskProofs[_taskId].push(proofCounter);
        userProofs[msg.sender].push(proofCounter);
        
        emit ProofSubmitted(proofCounter, _taskId, msg.sender, _evidenceHash);
        
        return proofCounter;
    }
    
    /**
     * @dev Core Function 3: Verify a submitted completion proof
     * @param _proofId ID of the proof to verify
     * @param _isApproved Whether the proof is approved or rejected
     * @param _remarks Optional remarks from the verifier
     */
    function verifyCompletion(
        uint256 _proofId,
        bool _isApproved,
        string memory _remarks
    ) external proofExists(_proofId) {
        CompletionProof storage proof = proofs[_proofId];
        uint256 taskId = proof.taskId;
        
        // Only task creator can verify completions
        require(tasks[taskId].creator == msg.sender, "Only task creator can verify completions");
        require(!proof.isVerified, "Proof already verified");
        
        proof.isVerified = true;
        proof.verifiedBy = msg.sender;
        proof.verifiedAt = block.timestamp;
        proof.remarks = _remarks;
        
        // If approved, increment user's completion count
        if (_isApproved) {
            userCompletionCount[proof.submitter]++;
        }
        
        emit ProofVerified(_proofId, taskId, msg.sender, _isApproved);
    }
    
    // View functions
    
    /**
     * @dev Get task details by ID
     */
    function getTask(uint256 _taskId) external view taskExists(_taskId) returns (Task memory) {
        return tasks[_taskId];
    }
    
    /**
     * @dev Get proof details by ID
     */
    function getProof(uint256 _proofId) external view proofExists(_proofId) returns (CompletionProof memory) {
        return proofs[_proofId];
    }
    
    /**
     * @dev Get all proof IDs for a specific task
     */
    function getTaskProofs(uint256 _taskId) external view taskExists(_taskId) returns (uint256[] memory) {
        return taskProofs[_taskId];
    }
    
    /**
     * @dev Get all task IDs created by a user
     */
    function getUserTasks(address _user) external view returns (uint256[] memory) {
        return userTasks[_user];
    }
    
    /**
     * @dev Get all proof IDs submitted by a user
     */
    function getUserProofs(address _user) external view returns (uint256[] memory) {
        return userProofs[_user];
    }
    
    /**
     * @dev Get user's total verified completion count
     */
    function getUserCompletionCount(address _user) external view returns (uint256) {
        return userCompletionCount[_user];
    }
    
    /**
     * @dev Get current task and proof counters
     */
    function getCounters() external view returns (uint256 totalTasks, uint256 totalProofs) {
        return (taskCounter, proofCounter);
    }
    
    /**
     * @dev Check if a task is still active and within deadline
     */
    function isTaskActive(uint256 _taskId) external view taskExists(_taskId) returns (bool) {
        Task memory task = tasks[_taskId];
        return task.isActive && block.timestamp <= task.deadline;
    }
    
    /**
     * @dev Deactivate a task (only by creator)
     */
    function deactivateTask(uint256 _taskId) external taskExists(_taskId) onlyTaskCreator(_taskId) {
        tasks[_taskId].isActive = false;
    }
}
