# Swift to C# Dependency Mapping for Neo Blockchain SDK

## Executive Summary

This document provides a comprehensive mapping of Swift dependencies used in NeoSwiftSDK to their C# equivalents for the NeoCSharp port. All identified Swift packages have suitable C# alternatives that provide equivalent or superior functionality.

## Dependency Analysis

### 1. BigInt (1.4.0-2.0.0) → Multiple C# Options

**Swift Package**: `https://github.com/leif-ibsen/BigInt`
- **Purpose**: Large integer arithmetic operations
- **Usage**: Cryptographic calculations, blockchain operations

**C# Equivalents**:
1. **System.Numerics.BigInteger** (Built-in) ✅ **RECOMMENDED**
   - Native .NET implementation
   - Zero additional dependencies
   - Excellent performance
   - Full arithmetic operations support
   
2. **NBitcoin BigInteger** (Alternative)
   - Part of NBitcoin library
   - BouncyCastle-based implementation
   - Includes blockchain-specific utilities

**Migration Strategy**: Use `System.Numerics.BigInteger` for all large integer operations. No external dependencies required.

### 2. SwiftECC (3.4.1-4.0.0) → BouncyCastle + System.Cryptography

**Swift Package**: `https://github.com/leif-ibsen/SwiftECC`
- **Purpose**: Elliptic curve cryptography (ECDSA, ECDH, ECIES)
- **Usage**: Digital signatures, key exchange, encryption

**C# Equivalents**:
1. **BouncyCastle.Cryptography (2.3.1)** ✅ **PRIMARY**
   - Comprehensive ECC support
   - Multiple curve support (secp256k1, secp256r1)
   - ECDSA, ECDH, ECIES implementations
   - Neo blockchain compatible

2. **System.Security.Cryptography.ECDsa** (Built-in)
   - Limited to NIST curves (secp256r1/P-256)
   - No secp256k1 support
   - Use for secp256r1 operations only

**Implementation Notes**:
- BouncyCastle required for secp256k1 (Bitcoin-style curves)
- Built-in .NET crypto for secp256r1 (NIST P-256)
- Performance: .NET native > BouncyCastle, but both acceptable

### 3. CryptoSwift (1.6.0-2.0.0) → System.Security.Cryptography

**Swift Package**: `https://github.com/krzyzanowskim/CryptoSwift`
- **Purpose**: Cryptographic operations (SHA, AES, HMAC)
- **Usage**: Hashing, symmetric encryption, message authentication

**C# Equivalents**:
1. **System.Security.Cryptography** (Built-in) ✅ **RECOMMENDED**
   - SHA256, SHA512, MD5 implementations
   - AES encryption with multiple modes
   - HMAC support
   - Cross-platform compatibility
   
2. **Modern Authenticated Encryption**:
   - `AesGcm` for authenticated encryption
   - `ChaCha20Poly1305` for modern AEAD
   - `AesCcm` for CCM mode

**Example Migrations**:
```csharp
// SHA256
byte[] hash = SHA256.HashData(data);

// HMAC-SHA256
byte[] hmac = HMACSHA256.HashData(key, message);

// AES-GCM (recommended)
using var aesGcm = new AesGcm(key);
aesGcm.Encrypt(nonce, plaintext, ciphertext, tag);
```

### 4. swift-scrypt (1.0.0-2.0.0) → Scrypt.NET

**Swift Package**: `https://github.com/greymass/swift-scrypt`
- **Purpose**: Scrypt key derivation function
- **Usage**: Password-based key derivation, wallet security

**C# Equivalents**:
1. **Scrypt.NET (1.3.0)** ✅ **RECOMMENDED**
   - Direct port of original C implementation
   - Compatible hash generation
   - No external dependencies
   - Available via NuGet

2. **Alternative Options**:
   - `CryptSharp` (broader crypto library)
   - `NetScrypt` (C wrapper approach)

**Configuration Compatibility**:
- Same parameters: N, r, p, dkLen
- Identical output to Swift implementation
- Performance comparable to native Swift

### 5. BIP39 (1.0.1-2.0.0) → NBitcoin.BIP39

**Swift Package**: `https://github.com/pengpengliu/BIP39`
- **Purpose**: BIP39 mnemonic phrase generation/validation
- **Usage**: HD wallet seed phrase handling

**C# Equivalents**:
1. **NBitcoin Mnemonic Class** ✅ **RECOMMENDED**
   - Complete BIP39 implementation
   - Multi-language wordlist support
   - Checksum validation
   - HD key derivation integration
   
2. **Alternative Options**:
   - `BIP39.NET` (standalone implementation)
   - `dotnetstandard-bip39` (lightweight option)

**Feature Parity**:
```csharp
// Generate mnemonic
var mnemonic = new Mnemonic(Wordlist.English);

// Validate existing mnemonic
var mnemonic = new Mnemonic("word list here", Wordlist.English);
bool isValid = mnemonic.IsValidChecksum;

// Derive HD key
var hdRoot = mnemonic.DeriveExtKey("passphrase");
```

## Language Feature Mapping

### Swift → C# Architecture Patterns

| Swift Feature | C# Equivalent | Implementation Notes |
|---------------|---------------|---------------------|
| **Package Manager** | .NET Project Structure | Swift Package.swift → NeoCSharp.csproj |
| **Optionals (?)** | Nullable Types | `String?`, `int?`, nullable reference types |
| **Error Handling (throws)** | Exceptions | `throw`, `try-catch` blocks |
| **Extensions** | Extension Methods | `static` methods in `static` classes |
| **Protocols** | Interfaces | `interface` definitions |
| **Enums with Associated Values** | Enums + Classes | Discriminated unions pattern |
| **async/await** | async/await | Direct language support |
| **Generics** | Generics | `<T>` syntax, constraints |
| **Access Control** | Access Modifiers | `public`, `internal`, `private` |

### Specific Swift → C# Mappings

```swift
// Swift Optional
var value: String? = nil
if let unwrapped = value {
    print(unwrapped)
}
```

```csharp
// C# Nullable
string? value = null;
if (value != null) {
    Console.WriteLine(value);
}
```

```swift
// Swift Error Handling
func riskyOperation() throws -> String {
    throw MyError.invalidInput
}
```

```csharp
// C# Exception Handling
string RiskyOperation() {
    throw new InvalidOperationException("Invalid input");
}
```

```swift
// Swift Extension
extension String {
    var hexBytes: [UInt8] { /* implementation */ }
}
```

```csharp
// C# Extension Method
public static class StringExtensions {
    public static byte[] ToHexBytes(this string value) { /* implementation */ }
}
```

## Project Structure Migration

### Swift Package Structure
```
NeoSwiftSDK/
├── Package.swift
├── Sources/
│   └── NeoSwiftSDK/
│       ├── crypto/
│       ├── contract/
│       └── protocol/
└── Tests/
    └── NeoSwiftSDKTests/
```

### C# Project Structure
```
NeoCSharp/
├── src/
│   └── NeoCSharp/
│       ├── NeoCSharp.csproj
│       ├── Crypto/
│       ├── Contract/
│       └── Protocol/
├── tests/
│   └── NeoCSharp.Tests/
└── examples/
    └── NeoCSharp.Examples/
```

## Performance Considerations

### Cryptographic Performance Hierarchy
1. **Native .NET Crypto** (fastest)
   - System.Security.Cryptography
   - Hardware acceleration
   - Platform optimized

2. **BouncyCastle** (acceptable)
   - Pure managed code
   - Cross-platform consistent
   - Comprehensive algorithm support

3. **Third-party Libraries** (varies)
   - NBitcoin (good for Bitcoin operations)
   - Scrypt.NET (optimized for scrypt)

### Memory Management
- **Swift**: Automatic Reference Counting (ARC)
- **C#**: Garbage Collection
- **Impact**: Minimal for crypto operations, consider IDisposable for large buffers

## Recommended NuGet Package Configuration

```xml
<PackageReference Include="BouncyCastle.Cryptography" Version="2.3.1" />
<PackageReference Include="NBitcoin" Version="7.0.43" />
<PackageReference Include="Scrypt.NET" Version="1.3.0" />
<PackageReference Include="System.Text.Json" Version="8.0.5" />
<PackageReference Include="System.Reactive" Version="6.0.1" />
```

## Testing Strategy

### Unit Test Migration
- **Swift**: XCTest framework
- **C#**: xUnit, NUnit, or MSTest
- **Resources**: Test vectors remain identical
- **Mocking**: Moq for C# test doubles

### Compatibility Testing
1. **Cross-implementation validation**
   - Same inputs → same outputs
   - Cryptographic compatibility
   - Blockchain operation equivalence

2. **Performance benchmarking**
   - Crypto operation timing
   - Memory usage patterns
   - Throughput comparisons

## Implementation Recommendations

### Phase 1: Core Dependencies
1. Replace BigInt with `System.Numerics.BigInteger`
2. Implement basic crypto with `System.Security.Cryptography`
3. Add BouncyCastle for advanced ECC operations

### Phase 2: Specialized Libraries
1. Integrate Scrypt.NET for key derivation
2. Add NBitcoin for BIP39 and Bitcoin-compatible operations
3. Implement reactive extensions with System.Reactive

### Phase 3: Optimization
1. Profile performance bottlenecks
2. Optimize crypto operations
3. Implement caching where appropriate

## Risk Assessment

| Risk Level | Component | Mitigation Strategy |
|------------|-----------|-------------------|
| **Low** | BigInteger | Native .NET support |
| **Low** | Basic Crypto | Native .NET support |
| **Medium** | ECC Operations | BouncyCastle proven library |
| **Low** | Scrypt | Direct C port |
| **Low** | BIP39 | NBitcoin mature implementation |

## Conclusion

The migration from Swift dependencies to C# equivalents is highly feasible with excellent library support. The C# ecosystem provides mature, well-tested alternatives for all Swift dependencies. The recommended approach prioritizes native .NET libraries where possible, supplemented by proven third-party libraries (BouncyCastle, NBitcoin) for specialized blockchain operations.

All cryptographic operations can be implemented with equivalent or superior security and performance compared to the original Swift implementation.