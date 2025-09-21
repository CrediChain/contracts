// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {ByteHasher} from "./helpers/ByteHasher.sol";
import {IWorldID} from "./interfaces/IWorldID.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

/**
 * @title IdentityManagerV2
 * @author CrediChain V2
 * @notice Enhanced contract for identity verification using World ID on #Superchain.
 * Includes batch operations, verification levels, expiration support, and comprehensive admin controls.
 * @dev This contract manages identity verification with enhanced security and administrative features.
 */
contract IdentityManagerV2 is AccessControl, ReentrancyGuard, Pausable {
    using ByteHasher for bytes;

    ///////////////////////////////////////////////////////////////////////////////
    ///                                  ROLES                                 ///
    ///////////////////////////////////////////////////////////////////////////////
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant VERIFIER_ROLE = keccak256("VERIFIER_ROLE");
    bytes32 public constant EMERGENCY_ROLE = keccak256("EMERGENCY_ROLE");

    ///////////////////////////////////////////////////////////////////////////////
    ///                                  ENUMS                                 ///
    ///////////////////////////////////////////////////////////////////////////////

    enum VerificationLevel {
        NONE,
        DEVICE,
        ORB
    }
    enum UserType {
        STUDENT,
        INSTITUTION,
        VERIFIER,
        ADMIN
    }

    ///////////////////////////////////////////////////////////////////////////////
    ///                                STRUCTS                                 ///
    ///////////////////////////////////////////////////////////////////////////////

    struct UserVerification {
        bool isVerified;
        VerificationLevel level;
        UserType userType;
        uint256 verificationTimestamp;
        uint256 expirationTimestamp; // 0 for no expiration
        uint256 nullifierHash;
        string metadata; // Additional user metadata (IPFS hash)
    }

    struct VerificationStats {
        uint256 totalVerifications;
        uint256 deviceVerifications;
        uint256 orbVerifications;
        uint256 activeVerifications;
        uint256 expiredVerifications;
    }

    ///////////////////////////////////////////////////////////////////////////////
    ///                                  ERRORS                                ///
    ///////////////////////////////////////////////////////////////////////////////
    error DuplicateNullifier(uint256 nullifierHash);
    error UserAlreadyVerified(address user);
    error UserNotVerified(address user);
    error VerificationExpired(address user);
    error InvalidUserType();
    error InvalidExpirationTime();
    error BatchSizeLimitExceeded();
    error ArrayLengthMismatch();
    error ZeroAddress();
    error InvalidSignal();

    ///////////////////////////////////////////////////////////////////////////////
    ///                             STATE VARIABLES                            ///
    ///////////////////////////////////////////////////////////////////////////////

    /// @dev The World ID instance that will be used for verifying proofs
    IWorldID internal immutable worldId;

    /// @dev The contract's external nullifier hash
    uint256 internal immutable externalNullifier;

    /// @dev The World ID group ID (always 1 for orb verification, can be different for device)
    uint256 internal immutable groupId;

    /// @dev Maximum batch size for operations
    uint256 public constant MAX_BATCH_SIZE = 100;

    /// @dev Default verification expiration time (1 year in seconds)
    uint256 public constant DEFAULT_EXPIRATION = 365 days;

    /// @dev Platform statistics
    VerificationStats public stats;

    /// @dev List of all verified users for enumeration
    address[] public verifiedUsers;

    ///////////////////////////////////////////////////////////////////////////////
    ///                             MAPPINGS                                    ///
    ///////////////////////////////////////////////////////////////////////////////

    /// @dev Whether a nullifier hash has been used already
    mapping(uint256 => bool) internal nullifierHashes;

    /// @dev Mapping from user address to their verification data
    mapping(address => UserVerification) internal userVerifications;

    /// @dev Mapping from user type to list of verified addresses
    mapping(UserType => address[]) internal usersByType;

    /// @dev Mapping to track user positions in usersByType arrays for efficient removal
    mapping(UserType => mapping(address => uint256)) internal userPositions;

    /// @dev Mapping to track user positions in verifiedUsers array for efficient removal
    mapping(address => uint256) internal verifiedUserPositions;

    ///////////////////////////////////////////////////////////////////////////////
    ///                                 EVENTS                                 ///
    ///////////////////////////////////////////////////////////////////////////////

    event UserVerified(
        address indexed user,
        uint256 indexed nullifierHash,
        VerificationLevel level,
        UserType userType,
        uint256 expirationTimestamp
    );

    event UserVerificationRevoked(address indexed user, address indexed revoker, string reason);

    event UserTypeUpdated(address indexed user, UserType oldType, UserType newType);

    event VerificationRenewed(address indexed user, uint256 newExpirationTimestamp);

    event BatchVerificationCompleted(address indexed admin, uint256 count, UserType userType);

    event VerificationExpire(address indexed user);

    ///////////////////////////////////////////////////////////////////////////////
    ///                               MODIFIERS                                ///
    ///////////////////////////////////////////////////////////////////////////////

    modifier validAddress(address _address) {
        if (_address == address(0)) revert ZeroAddress();
        _;
    }

    modifier onlyVerified(address user) {
        if (!isUserVerified(user)) revert UserNotVerified(user);
        _;
    }

    modifier notExpired(address user) {
        if (isVerificationExpired(user)) revert VerificationExpired(user);
        _;
    }

    ///////////////////////////////////////////////////////////////////////////////
    ///                              CONSTRUCTOR                               ///
    ///////////////////////////////////////////////////////////////////////////////

    /**
     * @notice Initializes the IdentityManagerV2 contract
     * @param _worldId The WorldID router address for proof verification
     * @param _appId The World ID application identifier
     * @param _actionId The World ID action identifier
     * @param _groupId The World ID group identifier (1 for orb, others for device)
     */
    constructor(address _worldId, string memory _appId, string memory _actionId, uint256 _groupId)
        validAddress(_worldId)
    {
        worldId = IWorldID(_worldId);
        groupId = _groupId;
        externalNullifier = abi.encodePacked(abi.encodePacked(_appId).hashToField(), _actionId).hashToField();

        // Set up roles
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(VERIFIER_ROLE, msg.sender);
        _grantRole(EMERGENCY_ROLE, msg.sender);

        // Verify the deployer as admin
        _directVerify(msg.sender, UserType.ADMIN, VerificationLevel.ORB, 0);
    }

    ///////////////////////////////////////////////////////////////////////////////
    ///                          VERIFICATION FUNCTIONS                        ///
    ///////////////////////////////////////////////////////////////////////////////

    /**
     * @notice Verifies a user with World ID proof
     * @param signal User's wallet address as signal
     * @param root Merkle tree root from World ID
     * @param nullifierHash Unique nullifier to prevent double verification
     * @param proof Zero-knowledge proof from World ID
     * @param userType Type of user being verified
     * @param expirationTimestamp When verification expires (0 for no expiration)
     */
    function verifyAndExecute(
        address signal,
        uint256 root,
        uint256 nullifierHash,
        uint256[8] calldata proof,
        UserType userType,
        uint256 expirationTimestamp
    ) external whenNotPaused nonReentrant validAddress(signal) {
        // Validate inputs
        if (nullifierHashes[nullifierHash]) {
            revert DuplicateNullifier(nullifierHash);
        }
        if (userVerifications[signal].isVerified) {
            revert UserAlreadyVerified(signal);
        }
        if (expirationTimestamp != 0 && expirationTimestamp <= block.timestamp) {
            revert InvalidExpirationTime();
        }

        // Verify World ID proof
        worldId.verifyProof(
            root, groupId, abi.encodePacked(signal).hashToField(), nullifierHash, externalNullifier, proof
        );

        // Record nullifier usage
        nullifierHashes[nullifierHash] = true;

        // Determine verification level based on group ID
        VerificationLevel level = groupId == 1 ? VerificationLevel.ORB : VerificationLevel.DEVICE;

        // Set expiration time
        uint256 finalExpiration = expirationTimestamp == 0 ? block.timestamp + DEFAULT_EXPIRATION : expirationTimestamp;

        // Store verification
        _storeVerification(signal, userType, level, finalExpiration, nullifierHash, "");

        emit UserVerified(signal, nullifierHash, level, userType, finalExpiration);
    }

    /**
     * @notice Emergency verification function for testing (admin only)
     * @param user Address to verify
     * @param userType Type of user
     * @param level Verification level
     */
    function emergencyVerify(address user, UserType userType, VerificationLevel level)
        external
        onlyRole(EMERGENCY_ROLE)
        validAddress(user)
    {
        _directVerify(user, userType, level, block.timestamp + DEFAULT_EXPIRATION);
    }

    /**
     * @notice Batch verify multiple users (admin only)
     * @param users Array of user addresses to verify
     * @param userTypes Array of user types
     * @param levels Array of verification levels
     * @param expirationTimestamps Array of expiration timestamps
     * @param metadataHashes Array of metadata IPFS hashes
     */
    function batchVerifyUsers(
        address[] calldata users,
        UserType[] calldata userTypes,
        VerificationLevel[] calldata levels,
        uint256[] calldata expirationTimestamps,
        string[] calldata metadataHashes
    ) external onlyRole(ADMIN_ROLE) whenNotPaused nonReentrant {
        uint256 length = users.length;
        if (length > MAX_BATCH_SIZE) revert BatchSizeLimitExceeded();
        if (
            length != userTypes.length || length != levels.length || length != expirationTimestamps.length
                || length != metadataHashes.length
        ) {
            revert ArrayLengthMismatch();
        }

        for (uint256 i = 0; i < length;) {
            if (users[i] != address(0) && !userVerifications[users[i]].isVerified) {
                uint256 expiration =
                    expirationTimestamps[i] == 0 ? block.timestamp + DEFAULT_EXPIRATION : expirationTimestamps[i];

                _storeVerification(
                    users[i],
                    userTypes[i],
                    levels[i],
                    expiration,
                    0, // No nullifier for admin verification
                    metadataHashes[i]
                );
            }
            unchecked {
                ++i;
            }
        }

        emit BatchVerificationCompleted(msg.sender, length, userTypes[0]);
    }

    ///////////////////////////////////////////////////////////////////////////////
    ///                          MANAGEMENT FUNCTIONS                          ///
    ///////////////////////////////////////////////////////////////////////////////

    /**
     * @notice Revokes a user's verification
     * @param user Address of user to revoke
     * @param reason Reason for revocation
     */
    function revokeVerification(address user, string calldata reason)
        external
        onlyRole(ADMIN_ROLE)
        whenNotPaused
        onlyVerified(user)
    {
        UserVerification storage verification = userVerifications[user];
        UserType userType = verification.userType;

        // Remove from verified users list
        _removeFromVerifiedUsers(user);
        _removeFromUsersByType(user, userType);

        // Update stats
        _updateStatsOnRevoke(verification.level);

        // Clear verification data
        delete userVerifications[user];

        emit UserVerificationRevoked(user, msg.sender, reason);
    }

    /**
     * @notice Updates user type (admin only)
     * @param user Address of user
     * @param newUserType New user type
     */
    function updateUserType(address user, UserType newUserType)
        external
        onlyRole(ADMIN_ROLE)
        onlyVerified(user)
        notExpired(user)
    {
        UserVerification storage verification = userVerifications[user];
        UserType oldType = verification.userType;

        if (oldType == newUserType) return;

        // Update user type lists
        _removeFromUsersByType(user, oldType);
        _addToUsersByType(user, newUserType);

        verification.userType = newUserType;

        emit UserTypeUpdated(user, oldType, newUserType);
    }

    /**
     * @notice Renews verification expiration
     * @param user Address of user
     * @param newExpirationTimestamp New expiration timestamp
     */
    function renewVerification(address user, uint256 newExpirationTimestamp)
        external
        onlyRole(VERIFIER_ROLE)
        onlyVerified(user)
    {
        if (newExpirationTimestamp <= block.timestamp) {
            revert InvalidExpirationTime();
        }

        userVerifications[user].expirationTimestamp = newExpirationTimestamp;
        emit VerificationRenewed(user, newExpirationTimestamp);
    }

    ///////////////////////////////////////////////////////////////////////////////
    ///                              VIEW FUNCTIONS                            ///
    ///////////////////////////////////////////////////////////////////////////////

    /**
     * @notice Checks if a user is verified and not expired
     * @param user Address to check
     * @return isVerified Whether the user is currently verified
     */
    function getIsVerified(address user) external view returns (bool) {
        return isUserVerified(user);
    }

    /**
     * @notice Checks if a user is verified (internal)
     * @param user Address to check
     * @return Whether the user is verified and not expired
     */
    function isUserVerified(address user) public view returns (bool) {
        UserVerification memory verification = userVerifications[user];
        if (!verification.isVerified) return false;
        if (verification.expirationTimestamp == 0) return true;
        return block.timestamp <= verification.expirationTimestamp;
    }

    /**
     * @notice Checks if a user's verification has expired
     * @param user Address to check
     * @return Whether the verification has expired
     */
    function isVerificationExpired(address user) public view returns (bool) {
        UserVerification memory verification = userVerifications[user];
        if (!verification.isVerified) return false;
        if (verification.expirationTimestamp == 0) return false;
        return block.timestamp > verification.expirationTimestamp;
    }

    /**
     * @notice Gets detailed verification information for a user
     * @param user Address to query
     * @return verification Complete verification data
     */
    function getUserVerification(address user) external view returns (UserVerification memory verification) {
        return userVerifications[user];
    }

    /**
     * @notice Gets verification level for a user
     * @param user Address to query
     * @return level Verification level
     */
    function getVerificationLevel(address user) external view returns (VerificationLevel level) {
        return userVerifications[user].level;
    }

    /**
     * @notice Gets user type
     * @param user Address to query
     * @return userType Type of user
     */
        function getUserType(address user) external view returns (UserType userType) {
        return userVerifications[user].userType;
    }

    /**
     * @notice Gets all verified users of a specific type
     * @param userType Type of users to retrieve
     * @return users Array of user addresses
     */
        function getUsersByType(UserType userType) 
        external 
        view 
        returns (address[] memory users) 
    {
        return usersByType[userType];
    }

    /**
     * @notice Gets total count of verified users by type
     * @param userType Type to count
     * @return count Number of users
     */
    function getUserCountByType(UserType userType) 
        external 
        view 
        returns (uint256 count) 
    {
        return usersByType[userType].length;
    }
}
