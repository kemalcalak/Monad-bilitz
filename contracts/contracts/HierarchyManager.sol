// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title HierarchyManager
 * @dev Manages hierarchical groups and user assignments for the authority system
 */
contract HierarchyManager {
    struct Group {
        string groupId;
        string name;
        uint256 level;
        uint256 authorityScore;
        bool exists;
        uint256 createdAt;
    }

    // Mappings
    mapping(string => Group) public groups;
    mapping(address => string) public userGroups;
    mapping(string => address[]) public groupMembers;
    
    // Owner
    address public owner;
    
    // Events
    event GroupCreated(
        string indexed groupId,
        string name,
        uint256 level,
        uint256 authorityScore,
        uint256 timestamp
    );
    
    event GroupUpdated(
        string indexed groupId,
        uint256 newAuthorityScore,
        uint256 timestamp
    );
    
    event UserAssigned(
        address indexed user,
        string indexed groupId,
        uint256 timestamp
    );
    
    event UserRemoved(
        address indexed user,
        string indexed groupId,
        uint256 timestamp
    );

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier groupExists(string memory groupId) {
        require(groups[groupId].exists, "Group does not exist");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    /**
     * @dev Create a new hierarchical group
     * @param groupId Unique identifier for the group
     * @param name Display name of the group
     * @param level Hierarchy level (1 = highest)
     * @param authorityScore Authority score for this group
     */
    function createGroup(
        string memory groupId,
        string memory name,
        uint256 level,
        uint256 authorityScore
    ) external onlyOwner {
        require(!groups[groupId].exists, "Group already exists");
        require(bytes(groupId).length > 0, "Group ID cannot be empty");
        require(level > 0, "Level must be greater than 0");

        groups[groupId] = Group({
            groupId: groupId,
            name: name,
            level: level,
            authorityScore: authorityScore,
            exists: true,
            createdAt: block.timestamp
        });

        emit GroupCreated(groupId, name, level, authorityScore, block.timestamp);
    }

    /**
     * @dev Update authority score of a group
     * @param groupId Group to update
     * @param newAuthorityScore New authority score
     */
    function updateGroupScore(
        string memory groupId,
        uint256 newAuthorityScore
    ) external onlyOwner groupExists(groupId) {
        groups[groupId].authorityScore = newAuthorityScore;
        emit GroupUpdated(groupId, newAuthorityScore, block.timestamp);
    }

    /**
     * @dev Assign a user to a group
     * @param user User address
     * @param groupId Group to assign to
     */
    function assignUser(
        address user,
        string memory groupId
    ) external onlyOwner groupExists(groupId) {
        require(user != address(0), "Invalid user address");
        
        // Remove from previous group if exists
        string memory previousGroup = userGroups[user];
        if (bytes(previousGroup).length > 0) {
            _removeUserFromGroup(user, previousGroup);
        }

        userGroups[user] = groupId;
        groupMembers[groupId].push(user);

        emit UserAssigned(user, groupId, block.timestamp);
    }

    /**
     * @dev Remove a user from their group
     * @param user User address
     */
    function removeUser(address user) external onlyOwner {
        string memory groupId = userGroups[user];
        require(bytes(groupId).length > 0, "User not assigned to any group");

        _removeUserFromGroup(user, groupId);
        delete userGroups[user];

        emit UserRemoved(user, groupId, block.timestamp);
    }

    /**
     * @dev Get group information
     * @param groupId Group identifier
     */
    function getGroup(string memory groupId) 
        external 
        view 
        groupExists(groupId) 
        returns (Group memory) 
    {
        return groups[groupId];
    }

    /**
     * @dev Get user's group ID
     * @param user User address
     */
    function getUserGroup(address user) external view returns (string memory) {
        return userGroups[user];
    }

    /**
     * @dev Get user's authority score
     * @param user User address
     */
    function getUserAuthorityScore(address user) external view returns (uint256) {
        string memory groupId = userGroups[user];
        if (bytes(groupId).length == 0) {
            return 0;
        }
        return groups[groupId].authorityScore;
    }

    /**
     * @dev Get all members of a group
     * @param groupId Group identifier
     */
    function getGroupMembers(string memory groupId) 
        external 
        view 
        groupExists(groupId) 
        returns (address[] memory) 
    {
        return groupMembers[groupId];
    }

    /**
     * @dev Internal function to remove user from group members array
     */
    function _removeUserFromGroup(address user, string memory groupId) private {
        address[] storage members = groupMembers[groupId];
        for (uint256 i = 0; i < members.length; i++) {
            if (members[i] == user) {
                members[i] = members[members.length - 1];
                members.pop();
                break;
            }
        }
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
