// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title SignatureAuthority
 * @dev Manages contracts and multi-signature approvals based on authority scores
 */
contract SignatureAuthority {
    struct Contract {
        string contractId;
        address creator;
        uint256 requiredScore;
        uint256 currentScore;
        bool finalized;
        uint256 createdAt;
        uint256 finalizedAt;
    }

    struct Signature {
        address signer;
        uint256 score;
        uint256 timestamp;
    }

    // Mappings
    mapping(string => Contract) public contracts;
    mapping(string => Signature[]) public contractSignatures;
    mapping(string => mapping(address => bool)) public hasSigned;
    
    // Reference to HierarchyManager
    address public hierarchyManager;
    address public owner;

    // Events
    event ContractCreated(
        string indexed contractId,
        address indexed creator,
        uint256 requiredScore,
        uint256 timestamp
    );

    event SignatureAdded(
        string indexed contractId,
        address indexed signer,
        uint256 score,
        uint256 currentScore,
        uint256 timestamp
    );

    event ContractFinalized(
        string indexed contractId,
        uint256 finalScore,
        uint256 timestamp
    );

    event ContractRejected(
        string indexed contractId,
        address indexed rejector,
        uint256 timestamp
    );

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier contractExists(string memory contractId) {
        require(bytes(contracts[contractId].contractId).length > 0, "Contract does not exist");
        _;
    }

    modifier contractNotFinalized(string memory contractId) {
        require(!contracts[contractId].finalized, "Contract already finalized");
        _;
    }

    constructor(address _hierarchyManager) {
        require(_hierarchyManager != address(0), "Invalid hierarchy manager address");
        hierarchyManager = _hierarchyManager;
        owner = msg.sender;
    }

    /**
     * @dev Create a new contract requiring signatures
     * @param contractId Unique identifier for the contract
     * @param requiredScore Minimum authority score needed to finalize
     */
    function createContract(
        string memory contractId,
        uint256 requiredScore
    ) external {
        require(bytes(contractId).length > 0, "Contract ID cannot be empty");
        require(bytes(contracts[contractId].contractId).length == 0, "Contract already exists");
        require(requiredScore > 0, "Required score must be greater than 0");

        contracts[contractId] = Contract({
            contractId: contractId,
            creator: msg.sender,
            requiredScore: requiredScore,
            currentScore: 0,
            finalized: false,
            createdAt: block.timestamp,
            finalizedAt: 0
        });

        emit ContractCreated(contractId, msg.sender, requiredScore, block.timestamp);
    }

    /**
     * @dev Add signature to a contract
     * @param contractId Contract to sign
     * @param signerScore Authority score of the signer (from backend verification)
     */
    function addSignature(
        string memory contractId,
        uint256 signerScore
    ) external contractExists(contractId) contractNotFinalized(contractId) {
        require(!hasSigned[contractId][msg.sender], "Already signed this contract");
        require(signerScore > 0, "Signer must have authority score");

        // Add signature
        contractSignatures[contractId].push(Signature({
            signer: msg.sender,
            score: signerScore,
            timestamp: block.timestamp
        }));

        hasSigned[contractId][msg.sender] = true;
        contracts[contractId].currentScore += signerScore;

        emit SignatureAdded(
            contractId,
            msg.sender,
            signerScore,
            contracts[contractId].currentScore,
            block.timestamp
        );

        // Auto-finalize if score threshold met
        if (contracts[contractId].currentScore >= contracts[contractId].requiredScore) {
            _finalizeContract(contractId);
        }
    }

    /**
     * @dev Internal function to finalize a contract
     */
    function _finalizeContract(string memory contractId) private {
        contracts[contractId].finalized = true;
        contracts[contractId].finalizedAt = block.timestamp;

        emit ContractFinalized(
            contractId,
            contracts[contractId].currentScore,
            block.timestamp
        );
    }

    /**
     * @dev Manually finalize a contract (owner only, for emergency)
     * @param contractId Contract to finalize
     */
    function manuallyFinalizeContract(
        string memory contractId
    ) external onlyOwner contractExists(contractId) contractNotFinalized(contractId) {
        _finalizeContract(contractId);
    }

    /**
     * @dev Reject a contract (creator or owner only)
     * @param contractId Contract to reject
     */
    function rejectContract(
        string memory contractId
    ) external contractExists(contractId) contractNotFinalized(contractId) {
        require(
            msg.sender == contracts[contractId].creator || msg.sender == owner,
            "Only creator or owner can reject"
        );

        contracts[contractId].finalized = true; // Mark as finalized to prevent further signatures
        contracts[contractId].finalizedAt = block.timestamp;

        emit ContractRejected(contractId, msg.sender, block.timestamp);
    }

    /**
     * @dev Get contract details
     * @param contractId Contract identifier
     */
    function getContract(string memory contractId) 
        external 
        view 
        contractExists(contractId) 
        returns (Contract memory) 
    {
        return contracts[contractId];
    }

    /**
     * @dev Get all signatures for a contract
     * @param contractId Contract identifier
     */
    function getContractSignatures(string memory contractId) 
        external 
        view 
        contractExists(contractId) 
        returns (Signature[] memory) 
    {
        return contractSignatures[contractId];
    }

    /**
     * @dev Check if user has signed a contract
     * @param contractId Contract identifier
     * @param signer Signer address
     */
    function hasUserSigned(string memory contractId, address signer) 
        external 
        view 
        returns (bool) 
    {
        return hasSigned[contractId][signer];
    }

    /**
     * @dev Get contract status
     * @param contractId Contract identifier
     */
    function getContractStatus(string memory contractId) 
        external 
        view 
        contractExists(contractId) 
        returns (
            uint256 currentScore,
            uint256 requiredScore,
            bool finalized,
            uint256 signatureCount
        ) 
    {
        Contract memory c = contracts[contractId];
        return (
            c.currentScore,
            c.requiredScore,
            c.finalized,
            contractSignatures[contractId].length
        );
    }

    /**
     * @dev Update hierarchy manager address
     * @param newHierarchyManager New hierarchy manager address
     */
    function updateHierarchyManager(address newHierarchyManager) external onlyOwner {
        require(newHierarchyManager != address(0), "Invalid address");
        hierarchyManager = newHierarchyManager;
    }

    /**
     * @dev Transfer ownership
     * @param newOwner New owner address
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid new owner address");
        owner = newOwner;
    }
}
