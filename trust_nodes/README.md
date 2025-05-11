# TrustNodes

A decentralized reputation system built on verified human identities using the Stacks blockchain.

![TrustNodes](https://placehold.co/600x400?text=TrustNodes)

## Overview

TrustNodes is a blockchain-based reputation system that enables users to build verifiable digital identities through mutual attestations. By leveraging cryptographic principles and decentralized consensus, the system creates a web of trust where reputation scores are derived from peer verification.

## Features

- **Identity Registration**: Users can register their blockchain identities within the system
- **Attestation Mechanism**: Registered users can attest to the validity of other users' identities
- **Score-based Verification**: Trust scores accumulate through attestations to establish verified status
- **Domain-specific Reputation**: Users can build specialized reputation in specific domains or contexts
- **Verifiable Credentials**: All attestations are publicly verifiable on the blockchain

## Smart Contract Architecture

The TrustNodes smart contract is built on Clarity and includes:

- **Identity Management**: Registration and verification of user identities
- **Attestation System**: Methods to create and update attestations between users
- **Domain Reputation**: Domain-specific endorsements for specialized reputation tracking
- **Administrative Controls**: Threshold settings and system management functions

## Core Functions

### Registration and Identity

```clarity
(define-public (register-identity))
```
Allows a user to register their principal as an identity in the system.

### Attestation Management

```clarity
(define-public (attest-to-identity (attestee principal) (score uint) (context (string-utf8 100))))
```
Creates an attestation from the sender to the specified attestee with a score and contextual information.

```clarity
(define-public (update-attestation (attestee principal) (score uint) (context (string-utf8 100))))
```
Updates an existing attestation with new score and context values.

### Domain Expertise

```clarity
(define-public (endorse-for-domain (identity principal) (domain (string-ascii 20)) (score uint)))
```
Endorses a user for a specific domain of expertise or context.

### Read-only Functions

```clarity
(define-read-only (get-identity-info (identity principal)))
(define-read-only (get-attestation (attester principal) (attestee principal)))
(define-read-only (get-domain-reputation (identity principal) (domain (string-ascii 20))))
```
Retrieve identity information, attestation details, and domain-specific reputation scores.

## Trust Mechanics

TrustNodes uses a threshold-based verification system:
- Each user starts unverified
- Attestations from other users increase verification score
- Upon reaching the verification threshold (default: 3), the identity becomes verified
- Verification status enables additional platform capabilities

## Use Cases

- **Professional Credentials**: Verify expertise in specific domains
- **Community Trust Networks**: Build reputation within decentralized communities
- **Service Provider Verification**: Establish trust for service providers
- **Decentralized Identity**: Foundation for self-sovereign identity systems
- **Reputation Portability**: Transferable reputation across compatible applications

## Getting Started

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) for local development
- [Hiro Wallet](https://wallet.hiro.so/) for interacting with the deployed contract

### Deployment

1. Clone the repository
2. Install dependencies
   ```bash
   npm install
   ```
3. Deploy to testnet
   ```bash
   clarinet deploy --testnet
   ```

## Development

To run tests locally:

```bash
clarinet test
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contact

For questions or collaboration opportunities, please open an issue in this repository.

---

*TrustNodes - Building a web of trust on the blockchain*