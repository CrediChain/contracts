// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "./SoulBoundNFT.sol";
import "./IdentityManager.sol";

/**
 * @title CrediChainCore
 * @dev Core contract that manages the issuance and revocation of credentials in the form of soulbound NFTs,
 * as well as managing verified educational institutions and users.
 * @notice This contract allows verified institutions to issue credentials to verified users and revoke them.
 */
contract CrediChainCore is Ownable {
    error OnlyTheIssuerCanRevoke();
    error CrediChainCore__OnlyVerifiedInstitutions();
    error CrediChainCore__OnlyVerifiedUsers();

    SoulBoundNFT public soulBoundNFT;
    IdentityManager public identityManager;

    mapping(address => bool) public verifiedInstitutions;
    mapping(uint256 => address) public credentialIssuers;

    event InstitutionVerified(address indexed institution);
    event InstitutionRemoved(address indexed institution);
    event CredentialIssued(
        address indexed to,
        uint256 indexed tokenId,
        address indexed issuer
    );

    /**
     * @notice Initializes the CrediChainCore contract with the SoulBoundNFT and IdentityManager addresses.
     * @param _soulBoundNFT The address of the SoulBoundNFT contract.
     * @param _identityManager The address of the IdentityManager contract.
     */
    constructor(
        address _soulBoundNFT,
        address _identityManager
    ) Ownable(msg.sender) {
        soulBoundNFT = SoulBoundNFT(_soulBoundNFT);
        identityManager = IdentityManager(_identityManager);
        verifiedInstitutions[msg.sender] = true;
    }

    /**
     * @notice Modifier to ensure that the caller is a verified institution and verified with world id.
     */
    modifier onlyVerifiedInstitution() {
        if (
            !verifiedInstitutions[msg.sender] &&
            !identityManager.getIsVerified(msg.sender)
        ) {
            revert CrediChainCore__OnlyVerifiedInstitutions();
        }
        _;
    }

    /**
     * @notice Modifier to ensure that the target user is verified by the IdentityManager contract.
     * @param user The address of the user to check for verification.
     */
    modifier onlyVerifiedUser(address user) {
        if (!identityManager.getIsVerified(user)) {
            revert CrediChainCore__OnlyVerifiedUsers();
        }
        _;
    }

    /**
     * @notice Verifies an institution, allowing it to issue credentials.
     * @dev Can only be called by the contract owner.
     * @param institution The address of the institution to verify.
     */
    function verifyInstitution(address institution) public onlyOwner {
        verifiedInstitutions[institution] = true;
        emit InstitutionVerified(institution);
    }

    /**
     * @notice Removes a verified institution, preventing it from issuing credentials.
     * @dev Can only be called by the contract owner.
     * @param institution The address of the institution to remove.
     */
    function removeInstitution(address institution) public onlyOwner {
        verifiedInstitutions[institution] = false;
        emit InstitutionRemoved(institution);
    }

    /**
     * @notice Issues a credential (soulbound NFT) to a verified user.
     * @dev Can only be called by a verified institution.
     * @param to The address of the user to receive the credential.
     * @param uri The URI that points to the metadata of the credential.
     */
    function issueCredential(
        address to,
        string memory uri
    )
        public
        onlyVerifiedInstitution
        onlyVerifiedUser(to)
        returns (uint256 tokenId)
    {
        tokenId = soulBoundNFT.safeMint(msg.sender, to, uri);
        credentialIssuers[tokenId] = msg.sender;
        emit CredentialIssued(to, tokenId, msg.sender);
        return tokenId;
    }

    /**
     * @notice Revokes a credential, deleting its issuer record and burning the NFT.
     * @dev Only the institution that issued the credential can revoke it.
     * @param tokenId The ID of the credential to revoke.
     */
    function revokeCredential(uint256 tokenId) public onlyVerifiedInstitution {
        if (credentialIssuers[tokenId] != msg.sender) {
            revert OnlyTheIssuerCanRevoke();
        }
        soulBoundNFT.revoke(msg.sender, tokenId);
        delete credentialIssuers[tokenId];
    }

    /**
     * @notice Retrieves the issuer of a specific credential.
     * @param tokenId The ID of the credential.
     * @return issuer The address of the institution that issued the credential.
     */
    function getCredentialIssuer(
        uint256 tokenId
    ) public view returns (address) {
        return credentialIssuers[tokenId];
    }

    function getIsInstitutuinVerified(
        address institution
    ) public view returns (bool) {
        return verifiedInstitutions[institution];
    }

    /**
     * @notice Retrieves all the NFTs owned by the user.
     * @param _add The address of the user.
     * @return NFTData structure representing The list of NFTs owned by the user.
     */
    function getStudentCredentials(
        address _add
    ) public view returns (SoulBoundNFT.NFTData[] memory) {
        return soulBoundNFT.getTokensByAddress(_add);
    }
}
