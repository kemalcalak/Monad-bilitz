# Smart Contracts

Solidity smart contracts for the Signature Move Authority System on Monad Testnet.

## Contracts

### HierarchyManager.sol
Manages hierarchical groups and user assignments:
- Create/update groups with authority scores
- Assign users to groups
- Query user authority scores

### SignatureAuthority.sol
Manages contracts and multi-signature approvals:
- Create contracts with required authority scores
- Add signatures from authorized users
- Auto-finalize when score threshold is met

## Setup

### 1. Install Dependencies

```bash
npm install
```

### 2. Configure Environment

Create a `.env` file in the `contracts/` directory:

```env
MONAD_RPC_URL=https://testnet-rpc.monad.xyz
ADMIN_WALLET_PRIVATE_KEY=your-private-key-here
```

### 3. Compile Contracts

```bash
npm run compile
```

### 4. Deploy to Monad Testnet

```bash
npm run deploy
```

This will:
- Deploy `HierarchyManager` contract
- Deploy `SignatureAuthority` contract
- Create 6 demo hierarchy groups (CEO, CFO, CTO, etc.)

### 5. Save Contract Addresses

After deployment, save the contract addresses to your backend `.env`:

```env
HIERARCHY_MANAGER_ADDRESS=0x...
SIGNATURE_AUTHORITY_ADDRESS=0x...
```

## Testing

Run contract tests:

```bash
npm test
```

## Contract Addresses (Monad Testnet)

After deployment, addresses will be displayed. Example:

```
HierarchyManager: 0x1234...
SignatureAuthority: 0x5678...
```

## Demo Hierarchy Groups

The deployment script creates these groups:

| Group ID | Name | Level | Authority Score |
|----------|------|-------|-----------------|
| CEO | Chief Executive Officer | 1 | 100 |
| CFO | Chief Financial Officer | 2 | 80 |
| CTO | Chief Technology Officer | 2 | 80 |
| DEPT_HEAD | Department Head | 3 | 50 |
| MANAGER | Manager | 4 | 30 |
| EMPLOYEE | Employee | 5 | 10 |

## Usage Example

### Create a Contract

```javascript
await signatureAuthority.createContract("CONTRACT_001", 150);
// Requires 150 authority score to finalize
```

### Add Signature

```javascript
await signatureAuthority.addSignature("CONTRACT_001", 80);
// CFO signs (score: 80)
// Contract still pending (80 < 150)

await signatureAuthority.addSignature("CONTRACT_001", 100);
// CEO signs (score: 100)
// Contract auto-finalizes (180 >= 150)
```

## Gas Optimization

Contracts are optimized with:
- Solidity 0.8.24
- Optimizer enabled (200 runs)
- Efficient storage patterns

## Security

- Owner-only functions for critical operations
- Signature uniqueness checks
- Score validation
- Event emission for transparency
