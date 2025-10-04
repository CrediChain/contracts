// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

/**
 * @title IIdentityManagerV2
 * @notice Interface for the enhanced IdentityManagerV2 contract
 * @dev This interface defines all external functions for identity verification management
 */
interface IIdentityManagerV2 {
    // Enums
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

    // Structs
    struct UserVerification {
        bool isVerified;
        VerificationLevel level;
        UserType userType;
        uint256 verificationTimestamp;
        uint256 expirationTimestamp;
        uint256 nullifierHash;
        string metadata;
    }

    struct VerificationStats {
        uint256 totalVerifications;
        uint256 deviceVerifications;
        uint256 orbVerifications;
        uint256 activeVerifications;
        uint256 expiredVerifications;
    }

    // Events
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
    event VerificationExpired(address indexed user);

    // Core verification functions
    function verifyAndExecute(
        address signal,
        uint256 root,
        uint256 nullifierHash,
        uint256[8] calldata proof,
        UserType userType,
        uint256 expirationTimestamp
    ) external;

    function batchVerifyUsers(
        address[] calldata users,
        UserType[] calldata userTypes,
        VerificationLevel[] calldata levels,
        uint256[] calldata expirationTimestamps,
        string[] calldata metadataHashes
    ) external;

    function emergencyVerify(
        address user,
        UserType userType,
        VerificationLevel level
    ) external;

    // Management functions
    function revokeVerification(address user, string calldata reason) external;
    
}
