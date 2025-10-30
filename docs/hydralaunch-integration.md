# HydraLaunch Integration

## Overview

This hydra-pay project serves as the **backend WebSocket API service** for the [HydraLaunch](https://github.com/carlosa8c/HydraLaunch) payment gateway application.

## Architecture

```
HydraLaunch (TypeScript/NestJS + React)
    ↓ WebSocket API (ws://localhost:4003)
hydra-pay (Haskell) ← [THIS PROJECT]
    ↓ WebSocket API
Hydra Node (cardano-hydra 1.1.0)
    ↓ Cardano Protocol
Cardano L1 Blockchain
```

## Integration Details

### HydraLaunch Components

**Backend**: NestJS (TypeScript)
- `packages/backend/src/blockchain/hydra-pay.service.ts` - WebSocket client for hydra-pay
- `packages/backend/src/hydra/` - Hydra orchestration and wallet bridge
- `packages/backend/src/payments/` - Payment processing with Hydra flow

**Frontend**: React + TypeScript
- `packages/frontend/src/components/PaymentPage.tsx` - Checkout UI with Hydra status
- Real-time payment status updates via Hydra channel lifecycle

### hydra-pay Protocol (This Project)

WebSocket API exposed on port 4003 implementing:

#### Message Types

**Channel Lifecycle:**
```typescript
// Create payment channel
{ tag: "create", name: string, participants: string[] }
→ { tag: "HeadIsOpen", name: string, ... }

// Close channel
{ tag: "close", name: string }
→ { tag: "HeadIsClosed", name: string, ... }

// Remove channel
{ tag: "remove", name: string }
```

**Fund Management:**
```typescript
// Lock funds into Hydra head
{ tag: "lock", channelName: string, address: string, lovelace: number }
→ { tag: "UnsignedTx", tx: string }

// Submit signed transaction
{ tag: "submit", channelName: string, signedTx: string }
→ { tag: "TxConfirmed", ... }
```

**Payments:**
```typescript
// Send instant payment within open channel
{ tag: "send", channelName: string, fromAddress: string, toAddress: string, lovelace: number }
→ { tag: "PaymentComplete", ... }
```

**Status:**
```typescript
// Get channel status
{ tag: "status", channelName: string }
→ { tag: "ChannelStatus", status: string, participants: string[], balance: number }
```

### Payment Flow in HydraLaunch

1. **Customer Checkout** (Frontend)
   - User clicks "Pay with Hydra" button
   - Frontend calls HydraLaunch API to create payment intent

2. **Payment Creation** (HydraLaunch Backend)
   - Creates payment record in database
   - Calls `HydraPayService.createPaymentChannel()` via WebSocket
   - Returns payment ID to frontend

3. **Fund Locking** (HydraLaunch Backend → hydra-pay)
   - `HydraPayService.lockFunds()` generates unsigned transaction
   - Frontend prompts user to sign with Cardano wallet
   - Signed tx submitted via `submitSignedTransaction()`
   - Monitors L1 confirmation

4. **Channel Opening** (hydra-pay → Hydra Node)
   - Once lock tx confirmed on L1, Hydra head opens
   - hydra-pay sends `HeadIsOpen` message
   - HydraLaunch updates payment status to "Processing"

5. **Instant Payment** (Within Hydra Head)
   - `HydraPayService.sendPayment()` executes instant transfer
   - Near-zero fees, instant confirmation
   - Payment marked as "Completed"

6. **Settlement** (Close Channel)
   - `HydraPayService.closeChannel()` triggers L1 fanout
   - Funds settled back to L1 addresses
   - Channel removed

## Configuration

### HydraLaunch Environment Variables

```env
# Hydra Transport (only hydra-pay supported)
HYDRA_TRANSPORT=hydra-pay

# WebSocket URL for this service
HYDRA_PAY_URL=ws://localhost:4003

# Cardano network
HYDRA_NETWORK=preprod  # or mainnet

# Wallet configuration
WALLET_SEED=<deterministic-seed>
```

### hydra-pay Configuration

See `config/` directory for:
- Network-specific genesis files (preprod, mainnet, etc.)
- Hydra protocol parameters
- Backend configuration

## API Requirements from HydraLaunch

### Current Features Used

- ✅ Create payment channels with multiple participants
- ✅ Lock funds from customer address
- ✅ Send instant payments within open channels
- ✅ Close channels and settle to L1
- ✅ Query channel status
- ✅ Transaction signing workflow (unsigned → signed → submit)

### Desired Future Enhancements

**From HydraLaunch docs/next_features.md:**

1. **Hydra 1.0+ Features** (Phase 13)
   - Incremental commits/decommits
   - Multi-head management
   - Advanced fanout strategies

2. **Head Lifecycle Management**
   - Head capacity monitoring (UTXOs, utilization)
   - Performance scoring
   - Automatic scaling recommendations
   - Payment routing optimization

3. **Enhanced Status Reporting**
   - Real-time UTXOs count
   - Channel utilization percentage
   - Performance metrics
   - Error details and recovery suggestions

4. **Settlement Optimization**
   - Batch settlement operations
   - Settlement analytics
   - Automatic settlement triggers based on capacity

## Testing

### Verify hydra-pay Service

```bash
# Check if service is running
curl http://localhost:4003/health

# Test WebSocket connection
wscat -c ws://localhost:4003
```

### Test from HydraLaunch

```bash
# Health check (should show hydra-pay transport)
curl http://localhost:5001/api/health/hydra

# Expected response
{"status":"healthy","transport":"hydra-pay","timestamp":"..."}

# Run checkout test
cd HydraLaunch
pnpm checkout:test
```

## Upgrade Context

**This Migration**: Upgrading hydra-pay to support:
- Hydra 1.1.0 (latest stable)
- GHC 9.6.7 (modern Haskell compiler)
- Modern Cardano packages (cardano-node 10.4.1)

**Why Critical**: HydraLaunch is blocked from using new Hydra features until hydra-pay supports them. This upgrade unblocks:
- Latest Hydra protocol improvements
- Performance enhancements
- New API capabilities
- Security updates

## Related Documentation

- [HydraLaunch Architecture](https://github.com/carlosa8c/HydraLaunch/blob/main/docs/architecture.md)
- [Hydra Pay Integration Plan](https://github.com/carlosa8c/HydraLaunch/blob/main/docs/hydra-pay-integration.md)
- [Hydra Official Docs](https://hydra.family/head-protocol/)

## Contact Points

### Key Files in This Project (hydra-pay)

- `backend/src/Backend.hs` - Main WebSocket API server
- `hydra-pay/src/` - Core Hydra payment logic
- `hydra-pay-core/src/` - Shared types and utilities

### Key Files in HydraLaunch

- `packages/backend/src/blockchain/hydra-pay.service.ts` - WebSocket client
- `packages/backend/src/payments/payments.service.ts` - Payment orchestration
- `packages/frontend/src/components/PaymentPage.tsx` - Checkout UI
