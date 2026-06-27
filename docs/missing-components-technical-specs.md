# Neo N3 Swift SDK to C# - Technical Implementation Specifications

## Overview
Detailed technical specifications for implementing each missing component from the Swift SDK in C#.

---

## 🔐 CRYPTO COMPONENTS

### Hash.cs - Core Hashing Utilities
**Swift Reference**: `/crypto/Hash.swift`

```csharp
// Required functionality from Swift:
public static class Hash
{
    // SHA256 twice (Neo's hash256)
    public static byte[] Hash256(byte[] input);
    public static string Hash256(string input);
    
    // RIPEMD160 
    public static byte[] Ripemd160(byte[] input);
    public static string Ripemd160(string input);
    
    // SHA256 then RIPEMD160 (common in Neo)
    public static byte[] Sha256ThenRipemd160(byte[] input);
    
    // HMAC SHA-512
    public static byte[] HmacSha512(byte[] input, byte[] key);
}
```

**Dependencies**: System.Security.Cryptography, potential third-party RIPEMD160

### Bip32ECKeyPair.cs - HD Key Derivation
**Swift Reference**: `/crypto/Bip32ECKeyPair.swift`

```csharp
public class Bip32ECKeyPair : ECKeyPair
{
    public byte[] ChainCode { get; }
    public uint Index { get; }
    public byte Depth { get; }
    public uint Fingerprint { get; }
    
    // BIP32 key derivation
    public Bip32ECKeyPair DeriveChildKey(uint index, bool hardened = false);
    public static Bip32ECKeyPair FromSeed(byte[] seed);
    public static Bip32ECKeyPair FromMnemonic(string mnemonic, string passphrase = "");
}
```

**Dependencies**: BIP32/BIP39 cryptographic libraries

### RIPEMD160.cs - RIPEMD160 Implementation
**Swift Reference**: `/crypto/helpers/RIPEMD160.swift`

```csharp
public class RIPEMD160 : HashAlgorithm
{
    public static byte[] Hash(byte[] input);
    public void Update(byte[] data);
    public byte[] Finalize();
}
```

### ConstantTime.cs - Security Utilities  
**Swift Reference**: `/crypto/helpers/ConstantTime.swift`

```csharp
public static class ConstantTime
{
    // Constant-time comparison to prevent timing attacks
    public static bool Compare(byte[] a, byte[] b);
    public static bool Compare(string a, string b);
    
    // Secure memory operations
    public static void SecureZero(byte[] array);
}
```

---

## 💼 WALLET COMPONENTS

### Bip39Account.cs - BIP39 Account Creation
**Swift Reference**: `/wallet/Bip39Account.swift`

```csharp
public class Bip39Account : Account
{
    public string Mnemonic { get; }
    public string Passphrase { get; }
    
    public static Bip39Account FromMnemonic(string mnemonic, string passphrase = "");
    public static Bip39Account Generate(int wordCount = 12);
    public static bool ValidateMnemonic(string mnemonic);
}
```

### NEP6Account.cs - NEP6 Account Implementation
**Swift Reference**: `/wallet/nep6/NEP6Account.swift`

```csharp
public class NEP6Account
{
    public string Address { get; set; }
    public string Label { get; set; }
    public bool IsDefault { get; set; }
    public string Lock { get; set; }
    public NEP6Contract Contract { get; set; }
    public Dictionary<string, object> Extra { get; set; }
    
    public Account Decrypt(string password, ScryptParams scrypt);
    public void Encrypt(string password, ECKeyPair keyPair, ScryptParams scrypt);
}
```

### NEP6Contract.cs - NEP6 Contract Specification
**Swift Reference**: `/wallet/nep6/NEP6Contract.swift`

```csharp
public class NEP6Contract
{
    public string Script { get; set; }
    public ContractParameter[] Parameters { get; set; }
    public bool Deployed { get; set; }
    
    public VerificationScript GetVerificationScript();
}
```

### NEP6Wallet.cs - Complete NEP6 Wallet
**Swift Reference**: `/wallet/nep6/NEP6Wallet.swift`

```csharp
public class NEP6Wallet
{
    public string Name { get; set; }
    public string Version { get; set; }
    public ScryptParams Scrypt { get; set; }
    public List<NEP6Account> Accounts { get; set; }
    public Dictionary<string, object> Extra { get; set; }
    
    public static NEP6Wallet Load(string json);
    public static NEP6Wallet Load(Stream stream);
    public string Save();
    public void Save(Stream stream);
    
    public NEP6Account CreateAccount(string password);
    public NEP6Account ImportAccount(ECKeyPair keyPair, string password);
}
```

---

## 📜 SCRIPT COMPONENTS

### InteropService.cs - Interop Service Definitions
**Swift Reference**: `/script/InteropService.swift`

```csharp
public static class InteropService
{
    // System interop services
    public const int SYSTEM_STORAGE_GET = 0x925de831;
    public const int SYSTEM_STORAGE_PUT = 0x9bf667ce;
    public const int SYSTEM_RUNTIME_NOTIFY = 0x70e2cba8;
    
    // Crypto interop services  
    public const int SYSTEM_CRYPTO_CHECKSIG = 0x41766716;
    public const int SYSTEM_CRYPTO_CHECKMULTISIG = 0x3cecf5e1;
    
    // Contract interop services
    public const int SYSTEM_CONTRACT_CALL = 0xc6c8b99c;
    
    public static string GetName(int hash);
    public static int GetHash(string name);
}
```

### InvocationScript.cs - Script Invocation
**Swift Reference**: `/script/InvocationScript.swift`

```csharp
public class InvocationScript
{
    public byte[] Script { get; }
    
    public InvocationScript(byte[] script);
    public static InvocationScript Empty { get; }
    
    public int Size { get; }
    public byte[] ToArray();
}
```

### ScriptReader.cs - Script Parser
**Swift Reference**: `/script/ScriptReader.swift`

```csharp
public class ScriptReader
{
    public byte[] Script { get; }
    public int Position { get; set; }
    
    public ScriptReader(byte[] script);
    
    public OpCode ReadOpCode();
    public byte[] ReadBytes(int count);
    public BigInteger ReadInteger();
    public string ReadString();
    
    public bool HasNext();
    public void Reset();
}
```

### VerificationScript.cs - Script Verification
**Swift Reference**: `/script/VerificationScript.swift`

```csharp
public class VerificationScript
{
    public byte[] Script { get; }
    
    public VerificationScript(byte[] script);
    public static VerificationScript FromPublicKey(ECPoint publicKey);
    public static VerificationScript FromMultiSig(int threshold, ECPoint[] publicKeys);
    
    public Hash160 GetScriptHash();
    public int Size { get; }
}
```

---

## 🔧 SERIALIZATION COMPONENTS

### INeoSerializable.cs - Serialization Interface
**Swift Reference**: `/serialization/NeoSerializable.swift`

```csharp
public interface INeoSerializable
{
    void Serialize(BinaryWriter writer);
    void Deserialize(BinaryReader reader);
    int Size { get; }
}

// Extension methods
public static class NeoSerializableExtensions
{
    public static byte[] ToArray(this INeoSerializable serializable);
    public static T FromArray<T>(byte[] data) where T : INeoSerializable, new();
}
```

### OptimizedBinaryWriter.cs - Optimized Binary I/O
**Swift Reference**: `/serialization/OptimizedBinaryWriter.swift`

```csharp
public class OptimizedBinaryWriter : BinaryWriter
{
    public OptimizedBinaryWriter(Stream output) : base(output) { }
    
    // Neo-specific serialization methods
    public void WriteVarInt(long value);
    public void WriteVarBytes(byte[] value);
    public void WriteVarString(string value);
    public void WriteHash160(Hash160 hash);
    public void WriteHash256(Hash256 hash);
    public void WriteECPoint(ECPoint point);
    public void WriteSerializable(INeoSerializable serializable);
}
```

---

## 🏗️ TRANSACTION COMPONENTS

### NeoTransaction.cs - Core Transaction Implementation
**Swift Reference**: `/transaction/NeoTransaction.swift`

```csharp
public class NeoTransaction : INeoSerializable
{
    public byte Version { get; set; }
    public uint Nonce { get; set; }
    public long SystemFee { get; set; }
    public long NetworkFee { get; set; }
    public uint ValidUntilBlock { get; set; }
    public Signer[] Signers { get; set; }
    public TransactionAttribute[] Attributes { get; set; }
    public byte[] Script { get; set; }
    public Witness[] Witnesses { get; set; }
    
    public Hash256 Hash { get; }
    public int Size { get; }
    
    public void Serialize(BinaryWriter writer);
    public void Deserialize(BinaryReader reader);
}
```

### Witness.cs - Transaction Witness
**Swift Reference**: `/transaction/Witness.swift`

```csharp
public class Witness : INeoSerializable
{
    public byte[] InvocationScript { get; set; }
    public byte[] VerificationScript { get; set; }
    
    public int Size { get; }
    public void Serialize(BinaryWriter writer);
    public void Deserialize(BinaryReader reader);
    
    public static Witness Create(byte[] message, ECKeyPair keyPair);
    public static Witness CreateMultiSig(byte[] message, ECKeyPair[] keyPairs, int threshold);
}
```

### AccountSigner.cs - Account-based Signing
**Swift Reference**: `/transaction/AccountSigner.swift`

```csharp
public class AccountSigner : Signer
{
    public Account Account { get; }
    
    public AccountSigner(Account account, WitnessScope scopes) : base(account.ScriptHash, scopes)
    {
        Account = account;
    }
    
    public Witness CreateWitness(byte[] message);
}
```

### ContractParametersContext.cs - Contract Parameter Context
**Swift Reference**: `/transaction/ContractParametersContext.swift`

```csharp
public class ContractParametersContext
{
    public NeoTransaction Transaction { get; }
    public Dictionary<Hash160, ContractParameter[]> Parameters { get; }
    
    public ContractParametersContext(NeoTransaction transaction);
    
    public bool AddSignature(Hash160 scriptHash, ECKeyPair keyPair);
    public bool IsComplete { get; }
    public Witness[] GetWitnesses();
}
```

---

## 📋 CONTRACT COMPONENTS

### ContractManagement.cs - Contract Management Operations
**Swift Reference**: `/contract/ContractManagement.swift`

```csharp
public class ContractManagement : SmartContract
{
    public static readonly Hash160 HASH = Hash160.FromHexString("0xfffdc93764dbaddd97c48f252a53ea4643faa3fd");
    
    public ContractManagement(INeoSharp neoSharp) : base(HASH, neoSharp) { }
    
    public async Task<ContractState> GetContract(Hash160 scriptHash);
    public async Task<ContractState[]> GetContracts();
    public TransactionBuilder Deploy(byte[] nefFile, ContractManifest manifest);
    public TransactionBuilder Update(byte[] nefFile, ContractManifest manifest);
    public TransactionBuilder Destroy();
}
```

### GasToken.cs - GAS Token Contract
**Swift Reference**: `/contract/GasToken.swift`

```csharp
public class GasToken : FungibleToken
{
    public static readonly Hash160 HASH = Hash160.FromHexString("0xd2a4cff31913016155e38e474a2c06d08be276cf");
    
    public GasToken(INeoSharp neoSharp) : base(HASH, neoSharp) { }
    
    public async Task<decimal> UnclaimedGas(Hash160 account);
}
```

### NonFungibleToken.cs - NFT Base Contract
**Swift Reference**: `/contract/NonFungibleToken.swift`

```csharp
public class NonFungibleToken : SmartContract
{
    public NonFungibleToken(Hash160 scriptHash, INeoSharp neoSharp) : base(scriptHash, neoSharp) { }
    
    public async Task<decimal> BalanceOf(Hash160 owner);
    public async Task<string> OwnerOf(string tokenId);
    public async Task<Dictionary<string, object>> Properties(string tokenId);
    public async Task<IEnumerable<string>> TokensOf(Hash160 owner);
    
    public TransactionBuilder Transfer(Hash160 to, string tokenId, object data = null);
}
```

---

## 🌐 PROTOCOL COMPONENTS

### INeoSharp.cs - Main SDK Interface
**Swift Reference**: `/protocol/NeoRpcClient.swift`

```csharp
public interface INeoSharp
{
    NeoSharpConfig Config { get; }
    
    // Block operations
    Task<NeoBlock> GetBlock(Hash256 blockHash);
    Task<NeoBlock> GetBlock(uint blockIndex);
    Task<uint> GetBlockCount();
    
    // Transaction operations  
    Task<Transaction> GetTransaction(Hash256 txHash);
    Task<NeoSendRawTransaction> SendRawTransaction(byte[] rawTransaction);
    
    // Contract operations
    Task<InvocationResult> InvokeFunction(Hash160 scriptHash, string function, ContractParameter[] parameters);
    Task<InvocationResult> InvokeScript(byte[] script);
    
    // Account operations
    Task<NeoGetNep17Balances> GetNep17Balances(Hash160 account);
    Task<NeoGetNep17Transfers> GetNep17Transfers(Hash160 account);
    
    // Utility operations
    Task<NeoValidateAddress> ValidateAddress(string address);
    Task<NeoGetVersion> GetVersion();
}
```

### NeoSharp.cs - Main Implementation
**Swift Reference**: `/protocol/core/Neo.swift`

```csharp
public class NeoSharp : INeoSharp
{
    private readonly HttpService httpService;
    
    public NeoSharp(NeoSharpConfig config)
    {
        Config = config;
        httpService = new HttpService(config.NodeUrl);
    }
    
    public NeoSharpConfig Config { get; }
    
    // Implement all interface methods with HTTP service calls
}
```

---

## 🛠️ UTILITY COMPONENTS

### Array Extensions
**Swift Reference**: `/utils/Array.swift`

```csharp
public static class ArrayExtensions
{
    public static T[] Slice<T>(this T[] array, int start, int length);
    public static T[] Reverse<T>(this T[] array);
    public static bool IsEmpty<T>(this T[] array);
}
```

### Bytes Extensions
**Swift Reference**: `/utils/Bytes.swift`

```csharp
public static class BytesExtensions
{
    public static string ToHexString(this byte[] bytes, bool prefix = false);
    public static byte[] FromHexString(this string hex);
    public static byte[] Reverse(this byte[] bytes);
    public static byte[] Concat(this byte[] first, byte[] second);
}
```

### String Extensions  
**Swift Reference**: `/utils/String.swift`

```csharp
public static class StringExtensions
{
    public static byte[] ToBytes(this string str);
    public static string CleanHexPrefix(this string hex);
    public static bool IsHex(this string str);
    public static BigInteger ToBigInteger(this string str);
}
```

---

## IMPLEMENTATION NOTES

### Security Considerations
- All cryptographic operations must use secure implementations
- Constant-time operations for sensitive data comparisons
- Secure memory handling for private keys
- Input validation for all public methods

### Performance Considerations
- Optimize binary serialization for large transactions
- Cache frequently used values (script hashes, addresses)
- Use memory pools for byte array operations
- Consider async/await patterns for network operations

### Compatibility Requirements  
- Must be compatible with existing Neo N3 network
- Binary serialization must match Neo protocol exactly
- Transaction signatures must be verifiable by Neo nodes
- Wallet files must be compatible with other Neo wallets

This technical specification provides the foundation for implementing all missing components from the Swift SDK in C#.