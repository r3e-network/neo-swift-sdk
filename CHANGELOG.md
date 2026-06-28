# Changelog

All notable changes to neo-swift-sdk will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [4.0.1] - 2026-06-28

### Fixed
- Fixed GitHub Actions build workflow registration and static CI job names for branch and tag validation.
- Fixed Swift 6.1 macOS release builds by keeping the Combine async publisher bridge's unchecked sendability boundary local to the bridge.
- Fixed dependency vulnerability scanning by auditing SwiftPM remote pins against OSV's SwiftURL ecosystem instead of invoking an unsupported `Package.resolved` lockfile extractor.
- Fixed Combine polling tests so block progression is deterministic and warning-clean under Swift 6.1 macOS concurrency checks.
- Fixed Semgrep release gating by using a pinned HTTPS client for OSV queries and excluding vendored SwiftECC fixture material from secret-scan noise.

## [4.0.0] - 2026-06-28

### Added
- Added structured JSON-RPC error propagation through `RpcResponseError`.
- Added address-version-aware Hash160, byte, string, RPC request, and stack-item conversion helpers for private and mixed Neo networks.
- Added secure NEP-2 encryption/decryption overloads and secure-key signing paths for witnesses, invocation scripts, and transactions.
- Added tests for plaintext RPC transport rejection, structured RPC errors, custom address-version RPC parameters, strict typed-client hex validation, and invalid Base64 storage responses.

### Changed
- Neo N3 v3.10.0 protocol compatibility was checked against `neo-project/neo-node` tag `v3.10.0`.
- `Account` now treats `SecureECKeyPair` as authoritative key material; legacy key export is explicit and deprecated.
- `Bip39Account` now stores its mnemonic in secure memory and requires explicit `exportMnemonic()` for recovery phrase export.
- `NeoClient` storage and raw-transaction inputs use typed `Bytes`, reject malformed hex at construction, and return decoded storage bytes plus the original Base64 string.
- `HttpService` now rejects non-local plaintext HTTP by default and redacts non-2xx HTTP response bodies from thrown errors.
- `Response.getResult()` now throws structured RPC errors instead of flattening node error details.
- Test request serialization no longer uses async task/semaphore bridging and is warning-clean under Swift 6.
- CI now runs the full test suite with warnings-as-errors and adds repo-wide secret plus dependency vulnerability scans.

### Fixed
- Fixed instance address-version handling so node metadata updates the client configuration without mutating global address utilities.
- Fixed contract stack-item address decoding to honor the connected client address version.
- Fixed stack parsing bounds checks in native contract helpers and record-state mapping.
- Fixed multisig signing to throw when a required private key is missing instead of silently compacting signatures.
- Fixed temporary BIP-39 and NEP-2 key material cleanup paths.

## [3.0.1] - 2026-06-28

### Changed
- `BinaryReader` primitive and varint reads now throw deserialization errors on truncated input instead of trapping on out-of-bounds array access.
- `SecureBytes` accessors now throw after secure memory is cleared instead of aborting the process.
- `NeoTransaction.sender` is now optional, with `getSender()` for workflows that require a sender.
- HTTP transport now applies a configurable request timeout and rejects non-2xx HTTP responses before JSON-RPC decoding.

### Fixed
- Fixed `ContractParameter.integer(BInt)` JSON encoding and large integer decoding.
- Fixed `ScriptBuilder.pushParam` parameter payload validation so mismatched internal values throw typed SDK errors instead of force-casting.
- Fixed malformed map decoding in contract parameters and stack items so missing keys or values throw deserialization errors.
- Fixed Swift 6 warning blockers for retroactive conformances, raw-response decoding, and hash-cache concurrency.

### Removed
- Removed tracked local orchestration databases, C# port artifacts, orphaned Neo C# gitlinks, and generated release-summary files from the Swift SDK package.

## [3.0.0] - 2026-06-28

### Added
- Added `NeoClient`, an AWS SDK-style operation facade with typed input/output models for representative node, blockchain, wallet, signing, relay, and DeferredRelay operations.
- Added Neo N3 v3.10.0 `getversion` regression coverage, including RPC metadata and protocol lists.
- Added Neo N3 v3.10.0 RPC support for `signmsg`, `verifymsg`, `sign`, `relay`, `getpendingvaliduntilrelay`, and `getrawpendingtx`.

### Changed
- Renamed the SwiftPM package identity to `neo-swift-sdk`, the SwiftPM product and module to `NeoSwiftSDK`, and the primary application client to `NeoClient`.
- Renamed the low-level JSON-RPC request builder to `NeoRpcClient` and its configuration/service types to `NeoRpcClientConfiguration` and `NeoRpcService`.
- Updated Neo N3 compatibility to v3.10.0.
- Widened `NeoGetVersion.NeoProtocol.initialGasDistribution` to `UInt64` to match the v3.10.0 node protocol model.
- Updated invocation diagnostics decoding to accept the Neo N3 v3.10.0 `diagnostics.traces` tree and diagnostics responses that omit `storagechanges`.

### Fixed
- Iterator traversal now attempts to terminate node sessions even when traversal or item mapping throws.
- Default iterator mapping now throws a typed cast error instead of force-casting.
- Transaction builder now deduplicates duplicate `Conflicts` attributes so serialized transactions follow Neo N3 v3.10.0 validation rules.

## [2.2.0] - 2026-02-13

### Security
- Fixed empty catch blocks that could silently swallow errors (VerificationScript.swift, ECKeyPair.swift)

### Fixed
- Fixed cache bug in Token - getTotalSupply, getDecimals, getSymbol now properly cache results
- Fixed force unwrapping issues in TransactionBuilder and NeoTransaction
- Fixed silent error swallowing in BinaryReader deserialization
- Fixed performance issue - wallet balance fetching now parallelized using TaskGroup
- Fixed potential nil dereference in NeoTransaction.sender
- Fixed typos in comments (Token.swift, NeoTransaction.swift)
- Fixed Wallet.swift - changed defaultAccountHash from implicit unwrap to optional
- Fixed Response.swift - added guard for result nil check
- Fixed Request.swift - added guard for neoSwiftService nil check
- Fixed NeoTransaction.swift - removed try! force unwrap in track() method
- Fixed OptimizedBinaryWriter.swift - added empty bytes check before baseAddress access
- Fixed NeoNameService.swift - replaced .map! with safe guard check
- Fixed NNSName.swift - replaced first!/last! with optional binding
- Fixed NeoToken.swift - replaced list! with guard check
- Fixed force unwrapping issues in SmartContract.swift (string, integer, boolean, iteratorId access)
- Fixed force unwrapping issues in Wallet.swift (defaultAccount, removeAccount, withAccounts, getNep17TokenBalances)
- Fixed force unwrapping issues in Account.swift (decryptPrivateKey, encryptPrivateKey, fromNEP6Account)
- Fixed force unwrapping issues in NonFungibleToken.swift (ownersOf, deserializeProperties)
- Fixed BlockIndexPolling thread safety - now uses .main queue and safe optional handling

### Changed
- Added final modifier to core non-inheritable classes for compiler optimization
- Updated Neo N3 compatibility to v3.9.1
- Improved error messages in NeoError for better debugging

## [2.1.0] - 2026-01-21

### Added
- Neo N3 v3.9 RPC coverage for `findstorage`, `getcandidates`, and `canceltransaction`
- Transaction attributes for Conflicts, NotValidBefore, and NotaryAssisted
- Expanded `getversion` decoding for rpc/protocol metadata (hardforks, seedlist, standbycommittee)

### Changed
- Address encoding/validation now respects configured address version
- Transaction attribute de-duplication aligned with node rules

### Tests
- Added attribute serialization round-trip coverage

## [2.0.0] - 2024-12-19

### 🛡️ Security (BREAKING CHANGES)
- **Added** `SecureBytes` class for secure memory management of sensitive data
- **Added** `SecureECKeyPair` class for secure private key handling  
- **Added** `ConstantTime` utility for timing-attack resistant operations
- **Moved** test credentials from source code to external JSON files
- **Added** compile-time protection preventing test data in release builds
- **Updated** NEP2 implementation to use constant-time comparisons
- **Added** dependency version upper bounds for supply chain security

### ⚡ Performance
- **Added** `OptimizedBinaryWriter` with pre-allocated buffers (50-70% faster)
- **Added** `HashCache` for thread-safe caching of repeated hash operations
- **Fixed** async operations to use proper Future patterns instead of blocking semaphores
- **Replaced** O(n) array concatenation with O(1) buffer operations

### 🧪 Testing & Quality
- **Added** comprehensive `SecurityTests` suite for cryptographic operations
- **Added** `IntegrationTestBase` and `WalletIntegrationTests` for end-to-end testing
- **Added** automated security scanning in CI/CD pipeline
- **Added** SwiftLint security rules configuration
- **Added** test coverage reporting

### 📚 Documentation
- **Added** `SECURITY.md` with comprehensive security best practices
- **Added** `DEPLOYMENT.md` with production deployment guide
- **Added** `SECURITY_FIXES_SUMMARY.md` documenting all security improvements
- **Updated** README with security considerations and new APIs

### 🔧 Infrastructure
- **Added** comprehensive CI/CD workflows for build, test, and release
- **Added** automated security scanning with TruffleHog and Semgrep
- **Added** multi-platform builds (macOS, Linux)
- **Added** release automation with changelog generation

### 🔄 Migration Guide

#### From v1.x to v2.0

**For Enhanced Security (Recommended):**
```swift
// Old (v1.x)
let keyPair = try ECKeyPair.createEcKeyPair()

// New (v2.0) - Secure
let secureKeyPair = try SecureECKeyPair.createEcKeyPair()
```

**Performance Optimizations:**
```swift
// Enable hash caching
HashCache.shared.maxCacheSize = 5000

// Use optimized binary writer
let writer = BinaryWriter.optimized()
```

**Security-Critical Comparisons:**
```swift
// Old - Vulnerable to timing attacks
if calculatedHash == expectedHash { }

// New - Constant time
if ConstantTime.areEqual(calculatedHash, expectedHash) { }
```

## [1.x.x] - Previous Versions

See git history for changes in previous versions.

---

### Legend
- 🛡️ Security improvements
- ⚡ Performance improvements  
- 🧪 Testing and quality
- 📚 Documentation
- 🔧 Infrastructure and tooling
- 🔄 Migration information
