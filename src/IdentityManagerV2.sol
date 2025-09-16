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
    constructor(
        address _worldId,
        string memory _appId,
        string memory _actionId,
        uint256 _groupId
    ) validAddress(_worldId) {
        worldId = IWorldID(_worldId);
        groupId = _groupId;
        externalNullifier = abi
            .encodePacked(abi.encodePacked(_appId).hashToField(), _actionId)
            .hashToField();

        // Set up roles
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(VERIFIER_ROLE, msg.sender);
        _grantRole(EMERGENCY_ROLE, msg.sender);

        // Verify the deployer as admin
        _directVerify(msg.sender, UserType.ADMIN, VerificationLevel.ORB, 0);
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
}
