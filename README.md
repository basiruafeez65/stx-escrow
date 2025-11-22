```markdown
# STX Escrow Smart Contract

A decentralized escrow smart contract for the Stacks blockchain that securely holds STX tokens between parties until conditions are met.

## Overview

This contract implements a three-party escrow mechanism where:
- **Client (Buyer)**: Deposits STX funds into escrow
- **Seller (Vendor)**: Receives payment upon delivery confirmation
- **Arbiter (Judge)**: Resolves disputes by deciding refund or release

## Features

 **Secure Fund Custody**: Contract holds funds as neutral custodian  
 **Multiple Resolution Paths**: Release to seller, refund to client, or arbiter decision  
 **Auto-Refund**: Automatic refund if deadline passes without release  
 **Role-Based Access Control**: Each party can only perform authorized actions  
 **State Tracking**: Real-time status of escrow (unfunded, funded, released, refunded)

## Functions

### Initialization
**`init(buyer, vendor, judge, stx-amount, lock-duration)`**
- Sets up the escrow agreement with all parties and terms
- Validates that all principals are unique and amounts are positive

### Deposits & Payments
**`deposit()`**
- Called by client to mark funds as received by contract
- Client must send STX to contract address separately

**`release()`**
- Called by seller to request payment release
- Transfers full escrow amount to seller and marks as released

**`request-refund()`**
- Called by client to request refund before delivery
- Transfers full amount back to client

### Dispute Resolution
**`arbiter-decision(decision)`**
- Called by arbiter to resolve disputes
- `u1` = release to seller
- `u2` = refund to client

**`auto-refund()`**
- Public function for anyone to trigger auto-refund after deadline
- Only works if funds are still held and no release has occurred

### Status & Info
**`get-details()`** - Returns all escrow parameters and current state  
**`get-status()`** - Returns current status as string (unfunded/funded/released/refunded)

## Error Codes

| Code | Error | Description |
|------|-------|-------------|
| 100 | ERR_NOT_CLIENT | Only client can call this function |
| 101 | ERR_NOT_SELLER | Only seller can call this function |
| 102 | ERR_NOT_ARBITER | Only arbiter can call this function |
| 103 | ERR_INVALID_AMOUNT | Invalid amount or duration provided |
| 104 | ERR_ALREADY_RELEASED | Funds already released |
| 105 | ERR_ALREADY_REFUNDED | Funds already refunded |
| 106 | ERR_NOT_FUNDED | Escrow not yet funded |

## Usage Example

```clarity
;; 1. Initialize escrow
(contract-call? .stx-escrow init
  'SP1234...client
  'SP5678...seller
  'SP9012...arbiter
  u1000000  ;; 1M microSTX
  u52560    ;; ~1 year in blocks
)

;; 2. Client deposits funds (sends STX to contract address)

;; 3. On successful delivery - Seller releases payment
(contract-call? .stx-escrow release)

;; 4. OR Arbiter resolves dispute
(contract-call? .stx-escrow arbiter-decision u1)  ;; release to seller

;; 5. Check status anytime
(contract-call? .stx-escrow get-status)
```

## Security Considerations

 **Important Notes**:
- Client must send STX directly to the contract address before calling `deposit()`
- Once funds are received, only designated roles can move them
- Arbiter can only act if funds haven't already been released or refunded
- Auto-refund ensures funds don't get locked indefinitely

## Contract State Variables

- `client`: Principal address of buyer
- `seller`: Principal address of vendor
- `arbiter`: Principal address of dispute resolver
- `amount`: STX amount in microSTX
- `funded`: Boolean flag indicating funds received
- `released`: Boolean flag indicating payment released to seller
- `refunded`: Boolean flag indicating refund to client
- `deadline`: Block height for auto-refund trigger

## License

MIT

## Author

Developed for Stacks blockchain ecosystem
