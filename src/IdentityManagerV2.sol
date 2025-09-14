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

}
