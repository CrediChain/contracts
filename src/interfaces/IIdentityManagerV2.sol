// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

/**
 * @title IIdentityManagerV2
 * @notice Interface for the enhanced IdentityManagerV2 contract
 * @dev This interface defines all external functions for identity verification management
 */
interface IIdentityManagerV2 {
        // Enums
    enum VerificationLevel { NONE, DEVICE, ORB }
        enum UserType { STUDENT, INSTITUTION, VERIFIER, ADMIN }

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
}