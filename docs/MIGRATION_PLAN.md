# Hydra Pay Migration Plan: GHC 8.10.7 → GHC 9.6+ with React Frontend

## Executive Summary

**Problem**: The project is locked to GHC 8.10.7 by the Obelisk framework, but modern Cardano dependencies (ouroboros-consensus → lsm-tree) require GHC 9.2+ with Cabal 3.4+.

**Solution**: Abandon Obelisk, upgrade backend to GHC 9.6+, rewrite frontend in React (1,350 lines, ~2-3 weeks effort).

**Benefits**:
- Modern Cardano stack with latest features/security
- React frontend compatible with your other projects
- Simpler build system (no GHCJS complexity)
- Better developer experience
- Easier to hire frontend developers

---

## Current Architecture

```
┌─────────────────────────────────────────────────┐
│ Frontend (Reflex-DOM + GHCJS)                   │
│ - 1 file: Frontend.hs (~1,350 lines)            │
│ - Compiles Haskell → JavaScript                 │
│ - Uses Obelisk framework                        │
│ - Locked to GHC 8.10.7                          │
└─────────────────┬───────────────────────────────┘
                  │ WebSocket: /hydra/api
                  │ Messages: HydraPay.Api types
┌─────────────────▼───────────────────────────────┐
│ Backend (Snap + WebSockets)                     │
│ - Uses: hydra-pay, hydra-pay-core               │
│ - Cardano/Hydra business logic                  │
│ - WebSocket API server                          │
│ - Currently GHC 8.10.7                          │
└─────────────────────────────────────────────────┘
```

## Target Architecture

```
┌─────────────────────────────────────────────────┐
│ Frontend (React + TypeScript)                   │
│ - Clean React components                        │
│ - WebSocket client library                      │
│ - Modern tooling (Vite/Next.js)                 │
│ - No GHC dependency                             │
└─────────────────┬───────────────────────────────┘
                  │ WebSocket: /hydra/api
                  │ Messages: JSON (same protocol)
┌─────────────────▼───────────────────────────────┐
│ Backend (Snap + WebSockets)                     │
│ - Uses: hydra-pay, hydra-pay-core               │
│ - Cardano/Hydra business logic                  │
│ - WebSocket API server                          │
│ - Upgraded to GHC 9.6+                          │
└─────────────────────────────────────────────────┘
```

---

## Phase 1: Backend Migration to GHC 9.6+ (2-3 weeks)

### 1.1 Remove Obelisk Framework
**Effort**: 2-3 days

Current structure:
```
cardano-project/
  default.nix           # Uses Obelisk's reflex-platform
  base.nix
backend/
  backend.cabal         # Depends on: obelisk-backend, obelisk-route
frontend/               # REMOVE THIS ENTIRE DIRECTORY
common/
  common.cabal          # Depends on: obelisk-route
```

**Steps**:
1. Delete `frontend/` directory entirely
2. Remove Obelisk from `cardano-project/default.nix`:
   - Remove Obelisk imports
   - Switch to standard Haskell.nix or pure Nix setup
   - Set `compiler-nix-name = "ghc966"`
3. Update `backend/backend.cabal`:
   - Remove `obelisk-backend` dependency
   - Remove `obelisk-route` dependency  
   - Keep `snap-core`, `websockets-snap` for WebSocket server
4. Update `common/common.cabal`:
   - Remove `obelisk-route` dependency
   - Implement simple routing manually (it's just route parsing)

**Files to modify**:
- `cardano-project/default.nix` - Remove Obelisk, set GHC 9.6.6
- `backend/backend.cabal` - Remove Obelisk deps
- `backend/src/Backend.hs` - Replace Obelisk routing with Snap routes
- `common/common.cabal` - Remove Obelisk deps
- `common/src/Common/Route.hs` - Implement route parsing without Obelisk

### 1.2 Upgrade GHC and Cardano Dependencies
**Effort**: 1-2 weeks

1. **Update GHC version**:
   ```nix
   # cardano-project/default.nix
   compiler-nix-name = "ghc966";  # or ghc982 for latest
   ```

2. **Update Cardano dependency thunks**:
   All thunks in `dep/` and `cardano-project/dep/` need updating:
   - `cardano-node` → latest version (requires lsm-tree support)
   - `cardano-ledger` → latest version
   - `ouroboros-consensus` → latest version (with lsm-tree)
   - `ouroboros-network` → latest version
   - `hydra` → latest version
   
   ```bash
   cd dep/cardano-node
   git fetch && git checkout <latest-tag>
   nix-prefetch-git . > github.json
   ```

3. **Update package overlays**:
   `cardano-project/cardano-overlays/cardano-packages/default.nix`:
   - Restore packages currently set to `null`:
     - `lsm-tree` - now compatible with GHC 9.6
     - `bloomfilter-blocked` - now compatible
     - `cardano-lmdb` - now compatible
     - `non-integral` - now compatible
     - `data-elevator` - now needed
   - Update base constraints: change `base >=4.14 && <4.18` → `base >=4.18 && <5`
   - Remove `doJailbreak` where possible (cleaner builds)

4. **Fix breaking changes**:
   GHC 9.6 has some breaking changes:
   - `ListTuple` extension changes
   - Some type inference changes
   - Update language extensions in `.cabal` files

**Expected issues**:
- Type inference changes may require explicit signatures
- Some Cardano APIs may have changed between versions
- Build times will be long initially (rebuilding entire stack)

### 1.3 Build and Test Backend
**Effort**: 3-5 days

1. **Get clean build**:
   ```bash
   ./build-in-docker.sh
   # Fix any remaining compilation errors
   ```

2. **Test core functionality**:
   - Start backend: `./result/bin/backend`
   - Verify WebSocket endpoint works: `ws://localhost:8000/hydra/api`
   - Test with simple WebSocket client
   - Verify Cardano node connection
   - Test Hydra operations

3. **Document API**:
   Extract WebSocket message types from `HydraPay.Api`:
   ```haskell
   data ApiMsg
     = ApiError Text
     | WalletInfo {...}
     | TransactionUpdate {...}
     -- etc.
   ```
   Create JSON schema documentation for frontend team

---

## Phase 2: React Frontend Development (2-3 weeks)

### 2.1 Project Setup
**Effort**: 1 day

Use Vite for fast development:
```bash
npm create vite@latest hydrapay-frontend -- --template react-ts
cd hydrapay-frontend
npm install
npm install ws  # WebSocket client
npm install @tanstack/react-query  # For state management
npm install tailwindcss  # Current frontend uses Tailwind
```

**Project structure**:
```
hydrapay-frontend/
├── src/
│   ├── components/
│   │   ├── Wallet.tsx          # Main wallet view
│   │   ├── Transactions.tsx    # Transaction list
│   │   ├── ApiDocs.tsx         # API documentation page
│   │   └── Layout.tsx          # Common layout/nav
│   ├── hooks/
│   │   ├── useWebSocket.ts     # WebSocket connection hook
│   │   └── useHydraPay.ts      # Hydra Pay API wrapper
│   ├── types/
│   │   └── api.ts              # TypeScript types for API messages
│   ├── App.tsx
│   └── main.tsx
├── package.json
└── vite.config.ts
```

### 2.2 WebSocket Integration
**Effort**: 2-3 days

Create TypeScript types matching Haskell API:
```typescript
// src/types/api.ts
export type ApiMsg =
  | { tag: 'ApiError'; error: string }
  | { tag: 'WalletInfo'; address: string; balance: number; ... }
  | { tag: 'TransactionUpdate'; txId: string; ... }
  // ... match all Haskell types
```

WebSocket hook:
```typescript
// src/hooks/useWebSocket.ts
import { useEffect, useState } from 'react';

export function useWebSocket<T>(url: string) {
  const [message, setMessage] = useState<T | null>(null);
  const [connected, setConnected] = useState(false);
  
  useEffect(() => {
    const ws = new WebSocket(url);
    
    ws.onopen = () => setConnected(true);
    ws.onmessage = (event) => {
      const data = JSON.parse(event.data);
      setMessage(data);
    };
    ws.onerror = () => setConnected(false);
    ws.onclose = () => setConnected(false);
    
    return () => ws.close();
  }, [url]);
  
  return { message, connected };
}
```

Hydra Pay API wrapper:
```typescript
// src/hooks/useHydraPay.ts
import { useWebSocket } from './useWebSocket';
import type { ApiMsg } from '../types/api';

export function useHydraPay() {
  const endpoint = getEndpoint(); // window.location logic
  const { message, connected } = useWebSocket<ApiMsg>(endpoint);
  
  // Parse messages and provide typed state
  const [walletInfo, setWalletInfo] = useState(null);
  const [transactions, setTransactions] = useState([]);
  const [error, setError] = useState<string | null>(null);
  
  useEffect(() => {
    if (!message) return;
    
    switch (message.tag) {
      case 'WalletInfo':
        setWalletInfo(message);
        break;
      case 'TransactionUpdate':
        // Update transaction list
        break;
      case 'ApiError':
        setError(message.error);
        break;
    }
  }, [message]);
  
  return { walletInfo, transactions, error, connected };
}
```

### 2.3 UI Components
**Effort**: 1-2 weeks

Port existing Haskell UI to React components. Current UI has:

1. **Wallet View** (~400 lines Haskell → ~150 lines React):
   - Display address, balance
   - Show UTXOs
   - Transaction history
   - Send funds form

2. **API Documentation** (~300 lines → ~100 lines):
   - Interactive API explorer
   - Request/response examples
   - Authentication setup

3. **Settings/Config** (~200 lines → ~80 lines):
   - Network selection
   - API key management
   - Node connection status

**Component example** (Wallet):
```tsx
// src/components/Wallet.tsx
import { useHydraPay } from '../hooks/useHydraPay';

export function Wallet() {
  const { walletInfo, transactions, connected } = useHydraPay();
  
  if (!connected) {
    return <div>Connecting to Hydra Pay...</div>;
  }
  
  return (
    <div className="wallet">
      <h1>Wallet</h1>
      <div className="balance">
        <span>Balance:</span>
        <span>{walletInfo?.balance || 0} ADA</span>
      </div>
      
      <TransactionList transactions={transactions} />
      <SendFundsForm />
    </div>
  );
}
```

### 2.4 Styling
**Effort**: 2-3 days

Current frontend uses Tailwind CSS - keep the same:
```bash
npm install -D tailwindcss postcss autoprefixer
npx tailwindcss init -p
```

Port existing styles from `frontend/src/Frontend.hs`:
- Extract all `"class"` attribute values
- Convert to React `className` props
- Keep same design system (fonts, colors, spacing)

---

## Phase 3: Integration and Deployment (1 week)

### 3.1 Backend Integration
**Effort**: 2-3 days

1. **Serve React frontend from backend**:
   ```haskell
   -- backend/src/Backend.hs
   import Snap.Util.FileServe (serveDirectory)
   
   backend :: Backend BackendRoute FrontendRoute
   backend = Backend
     { _backend_run = \serve -> do
         serve $ \case
           BackendRoute_Missing :=> Identity () -> do
             -- Serve static files from React build
             serveDirectory "./frontend-dist"
   ```

2. **Build script**:
   ```bash
   #!/bin/bash
   # build-all.sh
   
   # Build React frontend
   cd hydrapay-frontend
   npm run build
   cd ..
   
   # Copy to backend static dir
   rm -rf backend/frontend-dist
   cp -r hydrapay-frontend/dist backend/frontend-dist
   
   # Build backend
   ./build-in-docker.sh
   ```

3. **Update Nix build**:
   ```nix
   # default.nix - add frontend build
   let
     frontend = pkgs.buildNpmPackage {
       name = "hydrapay-frontend";
       src = ./hydrapay-frontend;
       npmDepsHash = "...";
       buildPhase = "npm run build";
       installPhase = "cp -r dist $out";
     };
   in
   # ... backend build with frontend copied in
   ```

### 3.2 Testing
**Effort**: 2-3 days

1. **Manual testing**:
   - Test all wallet operations
   - Test transaction creation/submission
   - Test error handling
   - Test reconnection after disconnect

2. **Cross-browser testing**:
   - Chrome/Brave
   - Firefox
   - Safari
   - Mobile browsers

3. **API compatibility**:
   - Verify all message types work correctly
   - Check edge cases (large UTXOs, many transactions, etc.)

### 3.3 Documentation
**Effort**: 1 day

Update README.md:
- New build instructions
- Frontend development setup
- API documentation
- Deployment guide

---

## Timeline Summary

| Phase | Task | Effort | Dependencies |
|-------|------|--------|--------------|
| 1.1 | Remove Obelisk | 2-3 days | - |
| 1.2 | Upgrade GHC/Cardano | 1-2 weeks | 1.1 |
| 1.3 | Test backend | 3-5 days | 1.2 |
| 2.1 | React setup | 1 day | - (parallel) |
| 2.2 | WebSocket integration | 2-3 days | 1.3, 2.1 |
| 2.3 | UI components | 1-2 weeks | 2.2 |
| 2.4 | Styling | 2-3 days | 2.3 |
| 3.1 | Integration | 2-3 days | 1.3, 2.4 |
| 3.2 | Testing | 2-3 days | 3.1 |
| 3.3 | Documentation | 1 day | 3.2 |

**Total estimated time**: 6-8 weeks with 1 developer, 4-5 weeks with 2 developers (backend + frontend in parallel)

---

## Risk Mitigation

### Risk 1: Cardano API Breaking Changes
**Likelihood**: High  
**Impact**: Medium  
**Mitigation**: 
- Review Cardano changelog before upgrading
- Test incrementally (one package at a time)
- Keep old version in separate branch

### Risk 2: WebSocket Protocol Incompatibilities
**Likelihood**: Low  
**Impact**: High  
**Mitigation**:
- Document protocol thoroughly before frontend work
- Create protocol test suite
- Version the protocol

### Risk 3: Performance Issues with GHC 9.6
**Likelihood**: Low  
**Impact**: Medium  
**Mitigation**:
- Benchmark before and after
- Profile hot paths
- Optimize incrementally

### Risk 4: React Frontend Complexity
**Likelihood**: Low  
**Impact**: Low  
**Mitigation**:
- Use your existing React expertise from other project
- Keep components simple and focused
- Reuse component patterns from other project

---

## Success Criteria

- ✅ Backend builds and runs on GHC 9.6+
- ✅ All Cardano/Hydra operations work as before
- ✅ React frontend provides same functionality as old frontend
- ✅ WebSocket communication is stable
- ✅ UI/UX matches or improves upon original
- ✅ Build process is documented and repeatable
- ✅ Code is compatible with your other React project

---

## Future Enhancements (Post-Migration)

Once migration is complete, you can:
1. Share React components between this and your other project
2. Add automated tests (Jest/Vitest for frontend, Hspec for backend)
3. Improve UI/UX with modern React patterns
4. Add features easier with modern tooling
5. Upgrade to latest Cardano features as they release

---

## Getting Started

1. **Review this plan** - discuss timeline and approach
2. **Create migration branch**: `git checkout -b migration/ghc96-react`
3. **Start with Phase 1.1** - remove Obelisk dependencies
4. **Set up React project** in parallel (Phase 2.1)
5. **Iterate through phases** with regular testing

Questions or concerns? Let's discuss before proceeding.
