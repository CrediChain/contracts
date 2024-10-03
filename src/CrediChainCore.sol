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

    SoulBoundNFT public soulBoundNFT;
    IdentityManager public identityManager;

    mapping(address => bool) public verifiedInstitutions;
    mapping(uint256 => address) public credentialIssuers;

    event InstitutionVerified(address indexed institution);
    event InstitutionRemoved(address indexed institution);
    event CredentialIssued(address indexed to, uint256 indexed tokenId, address indexed issuer);

    error CrediChainCore__OnlyVerifiedInstitutions();
    error CrediChainCore__OnlyVerifiedUsers();

    constructor(address _soulBoundNFT, address _identityManager) Ownable(msg.sender) {
        soulBoundNFT = SoulBoundNFT(_soulBoundNFT);
        identityManager = IdentityManager(_identityManager);
    }

    modifier onlyVerifiedInstitution() {
        if (!verifiedInstitutions[msg.sender]) revert CrediChainCore__OnlyVerifiedInstitutions();
        _;
    }

    modifier onlyVerifiedUser(address user) {
        if (!identityManager.getIsVerified(user)) revert CrediChainCore__OnlyVerifiedUsers();
        _;
    }

    function verifyInstitution(address institution) public onlyOwner {
        verifiedInstitutions[institution] = true;
        emit InstitutionVerified(institution);
    }

    function removeInstitution(address institution) public onlyOwner {
        verifiedInstitutions[institution] = false;
        emit InstitutionRemoved(institution);
    }

    function issueCredential(address to, string memory uri) public onlyVerifiedInstitution onlyVerifiedUser(to) {
        uint256 tokenId = soulBoundNFT.safeMint(to, uri);
        credentialIssuers[tokenId] = msg.sender;
        emit CredentialIssued(to, tokenId, msg.sender);
    }

    function revokeCredential(uint256 tokenId) public {
        if (credentialIssuers[tokenId] != msg.sender) {
            revert OnlyTheIssuerCanRevoke();
        }
        soulBoundNFT.revoke(tokenId);
        delete credentialIssuers[tokenId];
    }

    function getCredentialIssuer(uint256 tokenId) public view returns (address) {
        return credentialIssuers[tokenId];
    }
}
