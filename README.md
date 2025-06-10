# 🔐 KYC Token Gating Smart Contract

A Clarity smart contract that implements **KYC (Know Your Customer) verification** and **one-time access passes** for permissioned access control on the Stacks blockchain.

## 🚀 Features

### 🆔 KYC Verification System
- Users can submit KYC verification by paying a fee
- Admin can manually verify users
- Only KYC-verified users can access premium features
- KYC status can be revoked by admin

### 🎫 One-Time Access Passes
- Purchase time-limited access passes (expires after set blocks)
- Passes are consumed after single use
- Different pass types supported
- Automatic expiration system

### 👑 Premium Features
- Gated access to premium functionality
- Admin-controlled premium user management
- KYC requirement for all premium features

## 📋 Contract Functions

### Public Functions

#### KYC Management
- `submit-kyc-verification()` - Pay fee to get KYC verified
- `admin-verify-kyc(user)` - Admin manually verifies user
- `revoke-kyc(user)` - Admin revokes user's KYC status

#### Access Pass System  
- `purchase-access-pass(pass-type)` - Buy a one-time access pass
- `use-access-pass(pass-id)` - Consume an access pass
- `access-premium-feature(feature-name)` - Access premium functionality

#### Admin Controls
- `grant-premium-access(user)` - Give user premium access
- `revoke-premium-access(user)` - Remove premium access
- `update-kyc-fee(new-fee)` - Change KYC verification fee
- `update-pass-price(new-price)` - Change access pass price
- `update-pass-validity(blocks)` - Change pass validity period
- `batch-verify-kyc(users)` - Verify multiple users at once
- `emergency-withdraw()` - Withdraw contract balance

### Read-Only Functions
- `is-kyc-verified(user)` - Check if user is KYC verified
- `get-pass-details(user, pass-id)` - Get access pass information
- `is-pass-valid(user, pass-id)` - Check if pass is valid and unused
- `has-premium-access(user)` - Check if user has premium access
- `get-user-pass-count(user)` - Get total passes owned by user
- `get-contract-info()` - Get contract configuration

## 🛠️ Usage Examples

### Deploy and Test

```bash
clarinet console
```

### KYC Verification
```clarity
(contract-call? .kyc-token-gating submit-kyc-verification)
```

### Purchase Access Pass
```clarity
(contract-call? .kyc-token-gating purchase-access-pass "premium-content")
```

### Use Access Pass
```clarity
(contract-call? .kyc-token-gating use-access-pass u1)
```

### Check KYC Status
```clarity
(contract-call? .kyc-token-gating is-kyc-verified 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)
```

## ⚙️ Configuration

### Default Settings
- **KYC Fee**: 1 STX (1,000,000 microSTX)
- **Pass Price**: 0.5 STX (500,000 microSTX)  
- **Pass Validity**: 144 blocks (~24 hours)

### Error Codes
- `u100` - Unauthorized access
- `u101` - User not KYC verified
- `u102` - Access pass already used
- `u103` - Access pass not found
- `u104` - Insufficient balance
- `u105` - Access pass expired
- `u106` - User already KYC verified

## 🔒 Security Features

- ✅ Owner-only admin functions
- ✅ KYC requirement for sensitive operations
- ✅ Automatic pass expiration
- ✅ Single-use pass consumption
- ✅ Fee-based KYC verification
- ✅ Emergency withdrawal capability

## 🎯 Use Cases

- **Content Platforms**: Gate premium content behind KYC + passes
- **DeFi Protocols**: Compliance-required financial services
- **Gaming**: Time-limited access to special events
- **Marketplaces**: Verified seller/buyer programs
- **DAOs**: Governance participation requirements

## 📦 Installation

1. Clone into your Clarinet project
2. Deploy the contract
3. Configure fees and validity periods
4. Start verifying users and selling passes!

---

*Built with ❤️ for the Stacks ecosystem*
```

**Git Commit Message:**
```
feat: implement KYC token gating with one-time access passes
```

**GitHub Pull Request Title:**
```
🔐 Add KYC Token Gating Smart Contract with One-Time Access Passes
```

**GitHub Pull Request Description:**
```
## Summary
Implements a comprehensive KYC token gating system with one-time access passes for permissioned access control.

## Features Added
- **KYC Verification System**: Fee-based user verification with admin controls
- **One-Time Access Passes**: Purchasable, expirable, single-use tokens
- **Premium Feature Gating**: Restricted access requiring KYC verification
- **Admin Management**: Batch operations, fee updates, emergency controls

## Key Components
- KYC verification with configurable fees
- Time-limited access passes that expire after use
- Premium feature access control
- Comprehensive admin management functions
- Emergency withdrawal and batch operations

## Use Cases
Perfect for content platforms, DeFi protocols, gaming, and any application requiring compliance-based access control.

## Testing
All functions include proper error handling and access controls. Ready for deployment and testing in Clarinet environment.

