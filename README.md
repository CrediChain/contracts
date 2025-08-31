# Credichain V2 🎓⛓️

**Credichain V2** is an advanced decentralized platform for secure verification and credential issuance, featuring enhanced security, batch operations, reputation systems, and comprehensive analytics. Building on the foundation of V1, this version introduces multi-role access control, credential expiration, institution reputation tracking, and gas-optimized batch operations.

## 🚀 What's New in V2

### Enhanced Security & Access Control
- **Multi-role Access Control**: Separate roles for admins, institution verifiers, and emergency responders
- **Reentrancy Protection**: All state-changing functions protected against reentrancy attacks
- **Emergency Pause**: Circuit breaker functionality for emergency situations
- **Input Validation**: Comprehensive input validation with custom errors for gas optimization

### Advanced Features
- **Batch Operations**: Issue up to 50 credentials in a single transaction
- **Credential Expiration**: Support for time-limited credentials
- **Institution Reputation System**: Dynamic reputation scoring based on credential issuance and revocation
- **Credential Types**: Support for degrees, certificates, diplomas, licenses, and badges
- **Enhanced Metadata**: IPFS integration and comprehensive credential metadata


-----------------------------------------------------------------------------------------

## Project Overview

Credichain addresses the problem of secure institutional data verification by leveraging blockchain technology, decentralized identity, and non-transferable token standards. Institutions must be verified by the platform's owner, and students must authenticate with **World ID** to engage with the platform and transact credentials.

The platform provides the following key functionalities:
- **Institution Verification**: Institutions need to be verified by the Credichain owner to enlist and issue credentials.
- **Credential Issuance**: Verified institutions can issue **Soulbound NFTs** to students, representing academic credentials that are tied permanently to the student's identity.
- **Credential Revocation**: Institutions can revoke credentials in case of fraudulent activity or errors.
- **Student Verification**: Students use **World ID** to authenticate their identity before receiving credentials.

## Tech Stack

- **Forge**: Testing and deployment framework for Ethereum smart contracts.
- **Anvil**: Local Ethereum node for testing and simulation.
- **Cast**: Utility for interacting with contracts and sending transactions.
- **Base OnchainKit**: Smart wallets to manage user credentials and transactions.
- **OpenZeppelin**: Standard libraries for implementing **Soulbound NFTs**.
- **World ID**: Privacy-preserving decentralized identity solution for authenticating students.

## Contracts Overview

1. **IdentityManager.sol**  
   Manages World ID-based verification for students and institutions, ensuring only verified users can participate in the platform.
   
2. **CrediChainCore.sol**  
   Core contract that handles institution verification, credential issuance, and revocation.

3. **SoulBoundNFT.sol**  
   Implements Soulbound NFTs using OpenZeppelin’s non-transferable token standard, ensuring credentials are permanently linked to the recipient's identity.

## Contract Addresses

- **IdentityManager.sol**: https://base-sepolia.blockscout.com/address/0x436fB1cd4852235459D4806DD1d4958e7692E461?tab=write_contract
- **CrediChainCore.sol**: https://base-sepolia.blockscout.com/address/0x65EfAe4dBF1A5765636B2704b5Fa039Dc7515558?tab=write_contract
- **SoulBoundNFT.sol**: https://base-sepolia.blockscout.com/address/0x123C83BCbC38934BB033ea24d9DD6d98B7F1f552?tab=write_contract=

## Usage

### Installation

Clone the repository and install dependencies:

```shell
$ git clone https://github.com/your-repo/credichain
$ cd credichain
$ forge install
```

### Building the Project

To compile the smart contracts:

```shell
$ forge build
```

### Testing

We use Forge for testing the contracts to ensure the system is secure and functions as expected. Run the following command to execute all tests:

```shell
$ forge test
```

This will run a suite of tests to check the integrity of the credential issuance process, institution verification, student authentication, and NFT minting.

### Gas Snapshots

To track gas usage during contract interactions, use:

```shell
$ forge snapshot
```

This helps ensure the platform is optimized for minimal gas consumption during credential issuance and verification.

### Local Node (Anvil)

To simulate local Ethereum transactions and test smart contract interactions, you can start an Anvil local node:

```shell
$ anvil
```



### Cast Commands

You can use Cast to interact with the contracts directly. For example, to verify an institution on the platform:

```shell
$ cast send <CrediChainCore_Address> "verifyInstitution(address institutionAddress)" --private-key <your_private_key>
```



### Deployment Addresses

After deploying, paste the deployed contract addresses here:

- **IdentityManager.sol**: `__Paste_IdentityManager_Address__`
- **CrediChainCore.sol**: `__Paste_CrediChainCore_Address__`
- **SoulBoundNFT.sol**: `__Paste_SoulBoundNFT_Address__`

## How the System Works

1. **Student Verification with World ID**  
   Students authenticate using **World ID**, ensuring privacy-preserving and decentralized identity verification.

2. **Institution Verification**  
   Institutions are verified by the platform owner using the **CrediChainCore** contract. Once verified, they can issue credentials.

3. **Credential Issuance (Soulbound NFTs)**  
   Verified institutions issue **Soulbound NFTs** to students, representing their academic credentials. These tokens are non-transferable and permanently linked to the student's **OnchainKit** smart wallet.

4. **Credential Revocation**  
   In case of fraudulent activity or data correction, institutions can revoke issued credentials through the **CrediChainCore** contract.

## Testing Methodology

We use a combination of fuzz testing and unit testing to simulate real-world scenarios and edge cases:

- **Fuzz Testing**: Stress-tests the contracts to identify any potential breakdowns under various conditions.
- **Unit Testing**: Verifies the core functionality of student verification, institution verification, credential issuance, and revocation.

You can run all tests using the `forge test` command.

## Conclusion

Credichain leverages blockchain and decentralized identity solutions to provide a secure and efficient platform for student credential verification. With the use of **Soulbound NFTs**, **World ID**, and **Base OnchainKit**, the system ensures a tamper-proof, scalable, and incentivized approach to managing institutional data, offering significant benefits for students and institutions alike.
