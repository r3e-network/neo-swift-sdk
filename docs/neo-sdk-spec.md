# Neo SDK Interface & Structure Specification (Language-Agnostic)

Version: **0.1 (draft)**  
Reference implementation studied: **NeoSwiftSDK** (Swift SDK) with an API style compatible with **neow3j**.

This document defines a **common public SDK surface** for Neo N3 across languages (C, C++, Java, JS/TS, Rust, Go, …). It focuses on **module boundaries, type definitions, and method semantics** so different SDKs can expose the “same” API while still being idiomatic in each language.

---

## 1) Goals

- Provide a **portable, consistent SDK structure**: same conceptual modules, same method set, same parameter ordering/meaning.
- Define **canonical types** (`Hash160`, `Hash256`, `Signer`, `Witness`, `ContractParameter`, …) and **canonical RPC methods**.
- Support both:
  - **Low-level** RPC access (JSON-RPC request/response).
  - **High-level** workflows (build script → build tx → sign → send → await confirmation).
- Be implementable in languages with/without:
  - OOP / generics / exceptions / async-await.

## 2) Non-goals

- This is **not** a replacement for Neo’s protocol specs, NEPs, or Neo node RPC documentation.
- This spec does **not** mandate a single serialization library, crypto backend, or HTTP client.
- This spec does **not** define new RPC methods; it standardizes an SDK interface over existing Neo N3 JSON-RPC and common plugin RPCs.

---

## 3) Recommended SDK Module Layout

Language SDKs should map these modules to packages/namespaces/crates as appropriate:

- `core`
  - constants, shared config, error types, result helpers
- `types`
  - `Hash160`, `Hash256`, `NeoVMState`, `CallFlags`, `NodePluginType`, etc.
- `crypto`
  - keypairs, signatures, WIF, NEP-2, hashing, constant-time helpers
- `serialization`
  - Neo binary encoding helpers (reader/writer), `NeoSerializable`
- `script`
  - `ScriptBuilder`, opcodes/interop, script parsers (optional)
- `rpc` (a.k.a. `protocol`)
  - JSON-RPC request/response, transport, `NeoRpcClient`, polling/subscriptions
- `tx`
  - `TransactionBuilder`, `Transaction`, `Signer`, `Witness`, attributes, witness rules
- `wallet`
  - `Account`, `Wallet`, NEP-6 models (file format)
- `contract`
  - `SmartContract` base wrapper, NEP-17/NEP-11 wrappers, native contracts, NNS, NEP-9 URI (optional)
- `extras` (optional)
  - Neo-Express RPCs, dev helpers, experimental features

---

## 4) Canonical Primitive & Core Types

### 4.1 Bytes and Encodings

- `Bytes`: an ordered byte array (`uint8[]`).
- `HexString`: hexadecimal, case-insensitive. SDKs **MUST accept** an optional `0x` prefix for inputs.  
  SDKs **SHOULD output** hex without a prefix unless explicitly requested.
- `Base64String`: standard base64 encoding.
- `Base58CheckString`: Base58Check (Neo addresses, WIF, NEP-2).

### 4.2 Hash Types

These are **value types** (copyable/immutable where possible):

- `Hash160`
  - length: **20 bytes**
  - string form: **40 hex chars** (big-endian)
  - conversions:
    - `fromAddress(address) -> Hash160`
    - `toAddress(addressVersion) -> Address`
    - `fromScript(scriptBytes) -> Hash160` (SHA256 then RIPEMD160, then little-endian ↔ big-endian normalization per Neo convention)
- `Hash256`
  - length: **32 bytes**
  - string form: **64 hex chars** (big-endian)
  - conversions:
    - `fromBytes(bytesBE) -> Hash256`
    - `toBytesLE()/toBytesBE()`

### 4.3 Big Integer

NeoVM integers are arbitrary precision. SDKs **MUST** support:

- an unbounded `BigInt` (or a pair `(sign, magnitudeBytes)` in C-like environments)
- JSON serialization of large integers as **decimal strings** (recommended to avoid JS precision loss).

### 4.4 Address

- `Address`: Base58Check-encoded string.
- Must validate:
  - version byte == configured `addressVersion`
  - checksum = first 4 bytes of `hash256(payload)`

### 4.5 Public Keys and Signatures

- Curve: **secp256r1 / NIST P-256** (Neo N3).
- `PublicKey`:
  - compressed SEC1 encoding preferred (33 bytes), uncompressed accepted for parsing.
- `Signature`:
  - Neo transaction witnesses use **64 bytes** (`r || s`), each 32-byte big-endian.
  - Some message-signing helpers may also carry a recovery id `v` (optional).

### 4.6 Units, Ranges, and Time

SDKs should standardize on these domain units to avoid cross-language ambiguity:

- **Block index / height**: non-negative integer (fits in `uint32` on-chain, but SDKs may use a wider host integer).
- **GAS fractions**: Neo fees and many on-chain values are expressed in **fractions** (10^-8).  
  Define a canonical type `GasFraction` / `Fixed8` as an integer count of 10^-8 units (fits in signed 64-bit in practice).
- **Token amounts**: for NEP-17/NEP-11, SDKs must support:
  - integer **fractions** for on-chain values (`amountFractions`)
  - decimal amounts for UX (`amountDecimal`) with conversion using `decimals`
- **Timestamps**:
  - When RPC/plugin methods accept time ranges, treat them as **milliseconds since Unix epoch** unless the node method explicitly documents otherwise.
  - SDKs should provide helpers to convert to/from language-native date/time types.

### 4.7 CallFlags

NeoVM call flags control contract call permissions (used in script building and some native contract APIs).

Canonical bit values:

```text
CallFlags (byte bitmask):
  None        = 0x00
  ReadStates  = 0x01
  WriteStates = 0x02
  AllowCall   = 0x04
  AllowNotify = 0x08

  States      = ReadStates | WriteStates   (= 0x03)
  ReadOnly    = ReadStates | AllowCall     (= 0x05)
  All         = States | AllowCall | AllowNotify (= 0x0F)
```

SDKs **MUST** serialize call flags as a single byte in scripts where required.

### 4.8 WitnessScope (Signer Scope)

Witness scopes constrain where a signature/witness can be used.

Canonical bit values (byte bitmask):

```text
WitnessScope:
  None           = 0x00
  CalledByEntry  = 0x01
  CustomContracts= 0x10
  CustomGroups   = 0x20
  WitnessRules   = 0x40
  Global         = 0x80
```

Rules:

- `Global` is **mutually exclusive** with other scopes.
- `None` indicates the witness is only valid for the transaction itself (not for contract calls).
- If `CustomContracts` is present, `allowedContracts` must be provided (max **16** entries).
- If `CustomGroups` is present, `allowedGroups` must be provided (max **16** entries).
- If `WitnessRules` is present, `rules` must be provided (max **16** rules).

SDKs should expose helpers to:

- combine scopes into a single byte
- extract scopes from a combined byte

### 4.9 NeoVMState

Invocation state is represented in RPC as either:

- a string: `NONE`, `HALT`, `FAULT`, `BREAK`
- or an integer bitmask (rare, but SDKs should accept it)

Canonical mapping:

```text
NeoVMState:
  NONE  = 0
  HALT  = 1
  FAULT = 2
  BREAK = 4
```

SDKs **MUST** treat `FAULT` as an error state for “safe” high-level calls unless the caller explicitly opts into fault-tolerant behavior.

### 4.10 NodePluginType (Capabilities)

Many RPC methods are only available when specific plugins are enabled on the node. SDKs should model plugin presence as strings and/or an enum-like set.

Common plugin names seen in the ecosystem include:

- `ApplicationLogs`
- `RpcNep17Tracker`
- `RpcNep11Tracker`
- `StateService`
- `RpcServerPlugin`

SDKs **SHOULD** provide a capability check helper based on `listplugins()`, and **MUST** surface a clear error when a required plugin method is called against a node that does not support it.

### 4.11 Role and RecordType (Used by Native Contracts)

Some standard wrappers use small enums that appear both in scripts and RPC JSON:

```text
Role (byte):
  StateValidator    = 0x04
  Oracle            = 0x08
  NeoFSAlphabetNode = 0x10

RecordType (byte) for NNS:
  A     = 1
  CNAME = 5
  TXT   = 16
  AAAA  = 28
```

---

## 5) Error Model (Cross-Language)

SDKs must expose a stable error taxonomy. Exact mechanics vary:

- Exception-based languages: throw typed errors.
- Result-based languages (Rust/Go/C): return `Result<T, NeoError>` / `(T, error)` / `(code, message)`.

### 5.1 Canonical Error Categories

- `InvalidArgument`
- `InvalidState`
- `SerializationError`
- `CryptoError`
- `TransportError`
- `RpcError` (JSON-RPC error object)
- `InvocationFault` (NeoVM FAULT state)
- `UnsupportedOperation`

### 5.2 RPC Error Object

Mirror JSON-RPC 2.0:

```text
RpcError {
  code: int
  message: string
  data?: string | object
}
```

SDKs **SHOULD** preserve the raw `data` payload (stringified JSON if necessary).

---

## 6) Transport + JSON-RPC Core

### 6.1 RpcRequest and RpcResponse

Canonical wire model:

```text
RpcRequest {
  jsonrpc = "2.0"
  id: int | string
  method: string
  params: array
}

RpcResponse<T> {
  jsonrpc = "2.0"
  id: int | string
  result?: T
  error?: RpcError
  rawResponse?: string   // optional feature
}
```

### 6.2 Transport Interface

SDKs **MUST** allow injecting a transport implementation:

```text
interface RpcTransport {
  send(requestJson: string) -> string
  // async-capable variants are expected in most languages
}
```

Standard transports:

- `HttpTransport(baseUrl, headers?, timeout?)`
- (Optional) `WebSocketTransport(...)`

### 6.3 Client Configuration

```text
NeoClientConfig {
  addressVersion: byte
  networkMagic?: uint32          // if unset, client may fetch via getversion
  blockIntervalMs: int           // default ~15000ms on Neo N3
  pollingIntervalMs: int         // used for polling-based subscriptions
  maxValidUntilBlockIncrement: int
  allowTransmissionOnFault: bool // default false
  nnsResolver?: Hash160          // default mainnet resolver unless configured
  includeRawResponses?: bool
}
```

### 6.4 Neo Binary Serialization (Required for Transactions)

Even though it’s “internal”, SDKs must implement Neo N3 binary serialization to support offline transaction construction and signing.

Required primitives:

- **Little-endian** integer encoding for on-wire binary fields (do not rely on host endianness).
- `VarInt` length encoding:
  - `< 0xFD`: 1 byte
  - `0xFD` + `uint16` (LE)
  - `0xFE` + `uint32` (LE)
  - `0xFF` + `uint64` (LE)
- `VarBytes`: `VarInt(len)` followed by `len` raw bytes.
- `VarString`: UTF-8 bytes encoded as `VarBytes`.
- Serializable arrays/lists: `VarInt(count)` followed by each element’s binary encoding.
- Hash endianness:
  - human-readable hex string is typically **big-endian**
  - Neo binary serialization of hashes is typically **little-endian** (reverse bytes when writing/reading).

### 6.5 RPC Wire Encoding Rules (Base64 vs Hex vs Address)

Neo JSON-RPC uses a mix of encodings. SDKs **MUST** normalize these consistently so applications behave the same across languages.

#### 6.5.1 Canonical encodings

- **Binary blobs** (scripts, raw transactions, storage keys/values, proofs, byte arrays) are typically encoded as **base64 strings** in JSON-RPC.
- **Hashes** (`Hash160`, `Hash256`) are encoded as **hex strings** (usually without `0x` prefix).
- **Addresses** are Base58Check strings and appear in some RPCs (especially plugin methods and wallet RPCs).

SDKs should:

- accept **Bytes**, **hex**, or **base64** inputs at the public API boundary (where ergonomic)
- encode to the **exact on-wire form required by the RPC method**
- return both:
  - a decoded/typed form (e.g., `Bytes`, `Hash256`)
  - and optionally a “raw” string form (base64/hex) for tooling/interoperability

#### 6.5.2 Methods that require base64 parameters (common)

From the NeoSwiftSDK reference, these RPC parameters are sent as base64:

- `sendrawtransaction`: raw transaction bytes
- `calculatenetworkfee`: raw transaction bytes
- `invokescript`: script bytes
- `getstorage`: storage key bytes
- `getstate`, `getproof`, `verifyproof`, `findstates`: key/proof bytes

#### 6.5.3 Methods that use addresses on-wire

Some RPCs require **addresses** instead of script-hash hex strings, even though the logical input is a `Hash160`:

- token tracker plugin:
  - `getnep17balances`, `getnep17transfers`
  - `getnep11balances`, `getnep11transfers`, `getnep11properties`
- `getunclaimedgas`
- wallet RPC transfers (`sendfrom`, `sendtoaddress`, `sendmany`) use addresses for `from`/`to`
- wallet RPC key ops (`dumpprivkey`) use address

SDKs **MUST** perform `Hash160 ↔ Address` conversion using the configured `addressVersion`.

### 6.6 JSON Decoding Robustness (Required)

Neo nodes and plugins sometimes encode numeric and binary fields inconsistently across versions (e.g., numbers as JSON strings).

SDKs **MUST**:

- accept numeric fields as either **JSON numbers** or **decimal strings** where reasonable
- accept hash fields with or without an optional `0x` prefix
- ignore unknown JSON fields for forward compatibility

---

## 7) RPC Client Interface (Neo N3 JSON-RPC + Common Plugins)

### 7.1 Canonical Shape

To be maximally portable, SDKs should expose a **non-overloaded** canonical API:

- Languages with overloading can add overloads.
- Languages without overloading (C, Go, Rust) should keep distinct method names.

The reference style is “request object + send”:

```text
interface NeoRpcClient {
  config(): NeoClientConfig
  // Each method returns a RpcCall<T> / Request<T> which can be executed.
}

interface RpcCall<T> {
  send() -> RpcResponse<T>            // or -> T and raise/return errors
}
```

#### 7.1.1 Canonical-to-RPC Method Mapping (Neo N3 JSON-RPC)

This spec standardizes **SDK method names** and also requires consistent mapping to Neo’s JSON-RPC method strings and parameters.

Conventions used below:

- `Hash160Hex` / `Hash256Hex`: hex string form (no `0x` prefix).
- `Base64(data)`: base64 encoding of raw bytes.
- `Address(hash160)`: Base58Check address derived from a script hash using configured `addressVersion`.

Core RPC mapping (derived from NeoSwiftSDK):

| Canonical SDK method | JSON-RPC method | Params (wire order) |
|---|---|---|
| `getBestBlockHash()` | `getbestblockhash` | `[]` |
| `getBlockHash(i)` | `getblockhash` | `[i]` |
| `getBlockByHash(h, true)` | `getblock` | `[Hash256Hex(h), 1]` |
| `getBlockByHash(h, false)` | `getblockheader` | `[Hash256Hex(h), 1]` |
| `getRawBlockByHash(h)` | `getblock` | `[Hash256Hex(h), 0]` |
| `getBlockByIndex(i, true)` | `getblock` | `[i, 1]` |
| `getBlockByIndex(i, false)` | `getblockheader` | `[i, 1]` |
| `getRawBlockByIndex(i)` | `getblock` | `[i, 0]` |
| `getBlockHeaderCount()` | `getblockheadercount` | `[]` |
| `getBlockCount()` | `getblockcount` | `[]` |
| `getBlockHeaderByHash(h)` | `getblockheader` | `[Hash256Hex(h), 1]` |
| `getBlockHeaderByIndex(i)` | `getblockheader` | `[i, 1]` |
| `getRawBlockHeaderByHash(h)` | `getblockheader` | `[Hash256Hex(h), 0]` |
| `getRawBlockHeaderByIndex(i)` | `getblockheader` | `[i, 0]` |
| `getNativeContracts()` | `getnativecontracts` | `[]` |
| `getContractState(s)` | `getcontractstate` | `[Hash160Hex(s)]` |
| `getNativeContractState(name)` | `getcontractstate` | `[name]` |
| `getMemPool()` | `getrawmempool` | `[1]` |
| `getRawMemPool()` | `getrawmempool` | `[]` |
| `getTransaction(tx)` | `getrawtransaction` | `[Hash256Hex(tx), 1]` |
| `getRawTransaction(tx)` | `getrawtransaction` | `[Hash256Hex(tx), 0]` |
| `getStorage(c, key)` | `getstorage` | `[Hash160Hex(c), Base64(key)]` |
| `getTransactionHeight(tx)` | `gettransactionheight` | `[Hash256Hex(tx)]` |
| `getNextBlockValidators()` | `getnextblockvalidators` | `[]` |
| `getCommittee()` | `getcommittee` | `[]` |
| `getConnectionCount()` | `getconnectioncount` | `[]` |
| `getPeers()` | `getpeers` | `[]` |
| `getVersion()` | `getversion` | `[]` |
| `sendRawTransaction(rawTx)` | `sendrawtransaction` | `[Base64(rawTx)]` |
| `submitBlock(blockBytes)` | `submitblock` | `[HexString(blockBytes)]` *(node-dependent; some deployments may accept base64)* |
| `invokeFunction(h, f, p, s, false)` | `invokefunction` | `[Hash160Hex(h), f, p, Signers(s)]` |
| `invokeFunction(h, f, p, s, true)` | `invokefunction` | `[Hash160Hex(h), f, p, Signers(s), true]` |
| `invokeScript(script, s, false)` | `invokescript` | `[Base64(script), Signers(s)]` |
| `invokeScript(script, s, true)` | `invokescript` | `[Base64(script), Signers(s), true]` |
| `traverseIterator(sess, iter, n)` | `traverseiterator` | `[sess, iter, n]` |
| `terminateSession(sess)` | `terminatesession` | `[sess]` |
| `invokeContractVerify(h, p, s)` | `invokecontractverify` | `[Hash160Hex(h), p, Signers(s)]` |
| `getUnclaimedGas(a)` | `getunclaimedgas` | `[Address(a)]` |
| `listPlugins()` | `listplugins` | `[]` |
| `validateAddress(addr)` | `validateaddress` | `[addr]` |
| `closeWallet()` | `closewallet` | `[]` |
| `openWallet(path, pass)` | `openwallet` | `[path, pass]` |
| `dumpPrivKey(a)` | `dumpprivkey` | `[Address(a)]` |
| `getWalletBalance(token)` | `getwalletbalance` | `[Hash160Hex(token)]` |
| `getNewAddress()` | `getnewaddress` | `[]` |
| `getWalletUnclaimedGas()` | `getwalletunclaimedgas` | `[]` |
| `importPrivKey(wif)` | `importprivkey` | `[wif]` |
| `calculateNetworkFee(rawTx)` | `calculatenetworkfee` | `[Base64(rawTx)]` |
| `listAddress()` | `listaddress` | `[]` |
| `sendFrom(token, from, to, amount)` | `sendfrom` | `[Hash160Hex(token), Address(from), Address(to), amount]` |
| `sendMany(transfers)` | `sendmany` | `[transfers]` |
| `sendMany(from, transfers)` | `sendmany` | `[Address(from), transfers]` |
| `sendToAddress(token, to, amount)` | `sendtoaddress` | `[Hash160Hex(token), Address(to), amount]` |
| `getApplicationLog(tx)` | `getapplicationlog` | `[Hash256Hex(tx)]` |
| `getNep17Balances(a)` | `getnep17balances` | `[Address(a)]` |
| `getNep17Transfers(a)` | `getnep17transfers` | `[Address(a)]` |
| `getNep17Transfers(a, fromMs)` | `getnep17transfers` | `[Address(a), fromMs]` |
| `getNep17Transfers(a, fromMs, toMs)` | `getnep17transfers` | `[Address(a), fromMs, toMs]` |
| `getNep11Balances(a)` | `getnep11balances` | `[Address(a)]` |
| `getNep11Transfers(a)` | `getnep11transfers` | `[Address(a)]` |
| `getNep11Transfers(a, fromMs)` | `getnep11transfers` | `[Address(a), fromMs]` |
| `getNep11Transfers(a, fromMs, toMs)` | `getnep11transfers` | `[Address(a), fromMs, toMs]` |
| `getNep11Properties(a, tokenId)` | `getnep11properties` | `[Address(a), tokenId]` |
| `getStateRoot(i)` | `getstateroot` | `[i]` |
| `getProof(root, c, key)` | `getproof` | `[Hash256Hex(root), Hash160Hex(c), Base64(key)]` |
| `verifyProof(root, proof)` | `verifyproof` | `[Hash256Hex(root), Base64(proof)]` |
| `getStateHeight()` | `getstateheight` | `[]` |
| `getState(root, c, key)` | `getstate` | `[Hash256Hex(root), Hash160Hex(c), Base64(key)]` |
| `findStates(root, c, prefix, start?, count?)` | `findstates` | `[Hash256Hex(root), Hash160Hex(c), Base64(prefix), (Base64(start))?, count?]` |

Where `Signers(s)` converts SDK `Signer[]` into the RPC JSON `TransactionSigner[]` form.

Neo-Express mapping (optional):

| Canonical SDK method | JSON-RPC method |
|---|---|
| `expressGetPopulatedBlocks()` | `expressgetpopulatedblocks` |
| `expressGetNep17Contracts()` | `expressgetnep17contracts` |
| `expressGetContractStorage(h)` | `expressgetcontractstorage` |
| `expressListContracts()` | `expresslistcontracts` |
| `expressCreateCheckpoint(name)` | `expresscreatecheckpoint` |
| `expressListOracleRequests()` | `expresslistoraclerequests` |
| `expressCreateOracleResponseTx(attr)` | `expresscreateoracleresponsetx` |
| `expressShutdown()` | `expressshutdown` |

### 7.2 Blockchain Methods

```text
getBestBlockHash() -> Hash256
getBlockHash(blockIndex: int) -> Hash256

getBlockByHash(blockHash: Hash256, includeTxObjects: bool) -> NeoBlock
getBlockByIndex(blockIndex: int, includeTxObjects: bool) -> NeoBlock
getRawBlockByHash(blockHash: Hash256) -> Bytes             // RPC uses Base64String
getRawBlockByIndex(blockIndex: int) -> Bytes               // RPC uses Base64String

getBlockHeaderCount() -> int
getBlockCount() -> int
getBlockHeaderByHash(blockHash: Hash256) -> NeoBlock       // header-only shape
getBlockHeaderByIndex(blockIndex: int) -> NeoBlock
getRawBlockHeaderByHash(blockHash: Hash256) -> Bytes       // RPC uses Base64String
getRawBlockHeaderByIndex(blockIndex: int) -> Bytes         // RPC uses Base64String

getNativeContracts() -> NativeContractState[]
getContractState(contractHash: Hash160) -> ContractState
getNativeContractState(contractName: string) -> ContractState

getMemPool() -> MemPoolDetails
getRawMemPool() -> Hash256[]

getTransaction(txHash: Hash256) -> Transaction
getRawTransaction(txHash: Hash256) -> Bytes                // RPC uses Base64String
getTransactionHeight(txHash: Hash256) -> int

getStorage(contractHash: Hash160, key: Bytes) -> Bytes?    // RPC uses Base64String for key/value

getNextBlockValidators() -> NextBlockValidator[]
getCommittee() -> string[]                                  // public keys as hex strings
```

### 7.3 Node Methods

```text
getConnectionCount() -> int
getPeers() -> Peers
getVersion() -> NeoVersion

sendRawTransaction(rawTx: Bytes) -> RawTransactionResult    // RPC uses Base64String
submitBlock(serializedBlock: Bytes) -> bool                 // encoding may be node-specific; SDK should support hex/base64 on-wire
```

### 7.4 SmartContract Methods

```text
invokeFunction(
  contractHash: Hash160,
  function: string,
  params?: ContractParameter[],
  signers?: Signer[],
  diagnostics?: bool
) -> InvocationResult

invokeScript(
  script: Bytes,
  signers?: Signer[],
  diagnostics?: bool
) -> InvocationResult

invokeContractVerify(
  contractHash: Hash160,
  params: ContractParameter[],
  signers?: Signer[]
) -> InvocationResult

// Iterator sessions (when enabled on node)
traverseIterator(sessionId: string, iteratorId: string, count: int) -> StackItem[]
terminateSession(sessionId: string) -> bool

getUnclaimedGas(account: Hash160) -> UnclaimedGas            // RPC uses Address(account)
```

### 7.5 Utilities Methods

```text
listPlugins() -> Plugin[]
validateAddress(address: string) -> ValidateAddressResult
```

### 7.6 Wallet RPC Methods (neo-cli wallet plugin)

These require a node with wallet functionality enabled.

```text
openWallet(path: string, password: string) -> bool
closeWallet() -> bool
listAddress() -> AddressInfo[]
getNewAddress() -> string
dumpPrivKey(account: Hash160) -> string                      // WIF; RPC uses Address(account)
importPrivKey(wif: string) -> AddressInfo
getWalletBalance(tokenHash: Hash160) -> WalletBalance
getWalletUnclaimedGas() -> string

calculateNetworkFee(rawTx: Bytes) -> NetworkFee              // RPC uses Base64String

sendFrom(tokenHash: Hash160, from: Hash160, to: Hash160, amount: int) -> Transaction  // RPC uses addresses for from/to
sendToAddress(tokenHash: Hash160, to: Hash160, amount: int) -> Transaction            // RPC uses address for to
sendMany(from?: Hash160, transfers: TransactionSendToken[]) -> Transaction            // RPC uses address for from
```

### 7.7 TokenTracker Plugin (RpcNep17Tracker / RpcNep11Tracker)

```text
// Note: token-tracker RPCs take an address string on-wire: Address(account)
getNep17Balances(account: Hash160) -> Nep17Balances
getNep17Transfers(account: Hash160, fromMs?: int64, toMs?: int64) -> Nep17Transfers

getNep11Balances(account: Hash160) -> Nep11Balances
getNep11Transfers(account: Hash160, fromMs?: int64, toMs?: int64) -> Nep11Transfers
getNep11Properties(account: Hash160, tokenId: string) -> map<string,string>
```

### 7.8 ApplicationLogs Plugin

```text
getApplicationLog(txHash: Hash256) -> ApplicationLog
```

### 7.9 StateService Plugin

```text
getStateRoot(blockIndex: int) -> StateRoot
getStateHeight() -> StateHeight
getState(rootHash: Hash256, contractHash: Hash160, key: Bytes) -> Bytes?               // RPC uses Base64String

getProof(rootHash: Hash256, contractHash: Hash160, storageKey: Bytes) -> Bytes         // RPC uses Base64String
verifyProof(rootHash: Hash256, proofData: Bytes) -> Bytes?                             // RPC uses Base64String

findStates(
  rootHash: Hash256,
  contractHash: Hash160,
  keyPrefix: Bytes,
  startKey?: Bytes,
  count?: int
) -> FindStatesResult
```

### 7.10 Neo-Express (Optional)

```text
expressGetPopulatedBlocks() -> PopulatedBlocks
expressGetNep17Contracts() -> Nep17Contract[]
expressGetContractStorage(contractHash: Hash160) -> ContractStorageEntry[]
expressListContracts() -> ExpressContractState[]
expressCreateCheckpoint(filename: string) -> string
expressListOracleRequests() -> OracleRequest[]
expressCreateOracleResponseTx(oracleResponseAttribute: TransactionAttribute) -> string
expressShutdown() -> ExpressShutdown
```

### 7.11 Canonical RPC Data Models (JSON Shapes)

This section defines the **canonical response structures** used by the RPC methods in this spec.

Rules:

- SDKs **MUST** ignore unknown fields when decoding JSON.
- SDKs **MUST** accept numbers encoded as either JSON numbers or decimal strings where observed in the ecosystem.
- Any field documented as `Base64String` represents **raw bytes** encoded as base64 on the wire.
- Any field documented as `HexString` represents **raw bytes** encoded as hex (usually without `0x`).

#### 7.11.1 Block and Transaction

```text
NeoBlock {
  hash: Hash256
  size: int
  version: int
  previousBlockHash: Hash256
  merkleRoot: Hash256
  time: int                       // block timestamp (node-defined units; commonly seconds)
  index: int
  primary?: int
  nextConsensus: string           // typically a script hash or address (node-defined)
  witnesses?: NeoWitness[]
  tx?: Transaction[] | Hash256[]  // depends on verbosity/fullTxObjects
  confirmations: int
  nextBlockHash?: Hash256
}

NeoWitness {
  invocation: Base64String
  verification: Base64String
}

Transaction {
  hash: Hash256
  size: int
  version: int
  nonce: int
  sender: Hash160 | string        // nodes typically return sender as UInt160 hex; SDKs should accept string and normalize
  sysFee: decimalString           // fees often encoded as decimal strings
  netFee: decimalString
  validUntilBlock: int
  signers: TransactionSigner[]
  attributes: TransactionAttribute[]
  script: Base64String
  witnesses: NeoWitness[]
  blockHash?: Hash256
  confirmations?: int
  blockTime?: int
  vmState?: NeoVMState
}

TransactionSigner {
  account: Hash160
  scopes: string                  // comma-separated scope names in RPC (e.g., "CalledByEntry,CustomContracts")
  allowedContracts?: HexString[]  // UInt160 strings
  allowedGroups?: HexString[]     // compressed pubkeys
  rules?: WitnessRule[]
}

TransactionAttribute (tagged union):
  HighPriority
  OracleResponse { id: int, code: OracleResponseCode, result: Base64String }

OracleResponseCode (string enum, byte-backed):
  Success
  ProtocolNotSupported
  ConsensusUnreachable
  NotFound
  Timeout
  Forbidden
  ResponseTooLarge
  InsufficientFunds
  ContentTypeNotSupported
  Error

WitnessRule { action: WitnessAction, condition: WitnessCondition }
WitnessAction = "Allow" | "Deny"

WitnessCondition (tagged union):
  Boolean { expression: bool }
  Not { expression: WitnessCondition }
  And { expressions: WitnessCondition[] }   // max 16
  Or { expressions: WitnessCondition[] }    // max 16
  ScriptHash { hash: Hash160 }
  Group { group: HexString }               // compressed public key
  CalledByEntry
  CalledByContract { hash: Hash160 }
  CalledByGroup { group: HexString }       // compressed public key
```

#### 7.11.2 Invocation Result, Stack Items, and Diagnostics

```text
InvocationResult {
  script: Base64String
  state: NeoVMState
  gasConsumed: decimalString
  exception?: string
  notifications?: Notification[]
  diagnostics?: Diagnostics
  stack: StackItem[]
  tx?: Base64String
  pendingSignature?: PendingSignature
  session?: string
}

PendingSignature {
  type: string
  data: Base64String
  items: map<string, PendingSignatureItem>
  network: uint32
}

PendingSignatureItem {
  script: Base64String
  parameters: ContractParameter[]
  signatures: map<HexString, Base64String>     // pubKey -> signature
}

Notification {
  contract: Hash160
  eventName: string
  state: StackItem
}

Diagnostics {
  invokedContracts: InvokedContract
  storageChanges: StorageChange[]
}

InvokedContract {
  hash: Hash160
  call?: InvokedContract[]        // recursive call tree
}

StorageChange {
  state: string                   // e.g., "Added", "Changed", "Deleted"
  key: Base64String
  value: Base64String
}

StackItem (tagged union):
  Any(value?: any)
  Pointer(value: BigInt)
  Boolean(value: bool)
  Integer(value: BigInt)
  ByteString(value: Bytes)
  Buffer(value: Bytes)
  Array(value: StackItem[])
  Struct(value: StackItem[])
  Map(value: [{ key: StackItem, value: StackItem }])
  InteropInterface(id: string, interface: string)
```

#### 7.11.3 Contract State and Manifest

```text
ContractState {
  id: int
  updateCounter: int
  hash: Hash160
  nef: ContractNef
  manifest: ContractManifest
}

NativeContractState {
  id: int
  hash: Hash160
  nef: ContractNef
  manifest: ContractManifest
  updateHistory: int[]
}

ContractNef {
  magic: int
  compiler: string
  source?: string
  tokens?: ContractMethodToken[] | ContractMethodToken | null
  script: Base64String
  checksum: int
}

ContractMethodToken {
  hash: Hash160
  method: string
  paramCount: int
  hasReturnValue: bool
  callFlags: CallFlags | string | byte
}

ContractManifest {
  name?: string
  groups?: ContractGroup[] | ContractGroup | null
  features?: object
  supportedStandards?: string[] | string | null
  abi?: ContractABI
  permissions?: ContractPermission[] | ContractPermission | null
  trusts?: "*" | string[] | string | null
  extra?: object
}

ContractABI {
  methods: ContractMethod[]
  events?: ContractEvent[]
}

ContractMethod {
  name: string
  parameters: ContractParameter[]     // manifest ABI parameter descriptors (name+type; no value)
  offset: int
  returnType: ContractParameterType
  safe: bool
}

ContractGroup { pubKey: HexString, signature: Base64String }
ContractPermission { contract: "*" | Hash160 | string, methods: "*" | string[] | string }
```

Note: in practice, some manifest fields may appear as a single value, an array, `"*"`, or be absent; SDKs must tolerate these variants.

#### 7.11.4 Node/Network Models

```text
NeoVersion {
  tcpPort?: int
  wsPort?: int
  nonce: int
  userAgent: string
  protocol?: NeoProtocol
}

NeoProtocol {
  network: uint32
  validatorsCount?: int
  msPerBlock: int
  maxValidUntilBlockIncrement: int
  maxTraceableBlocks: int
  addressVersion: int
  maxTransactionsPerBlock: int
  memoryPoolMaxTransactions: int
  initialGasDistribution: uint64
}

Peers {
  connected: AddressEntry[]
  bad: AddressEntry[]
  unconnected: AddressEntry[]
}

AddressEntry { address: string, port: int }

MemPoolDetails { height: int, verified: Hash256[], unverified: Hash256[] }

NextBlockValidator { publicKey: HexString, votes: decimalString, active: bool }
```

#### 7.11.5 Utility and Wallet RPC Models

```text
Plugin { name: string, version: string, interfaces: string[] }
ValidateAddressResult { address: string, isValid: bool }

AddressInfo (neo-cli wallet RPC) {
  address: Address
  hasKey: bool
  label?: string
  watchOnly: bool
}

WalletBalance { balance: decimalString }   // some nodes return as "balance" or "Balance"

UnclaimedGas { unclaimed: decimalString, address: Address }

NetworkFee { networkFee: decimalString }

RawTransactionResult { hash: Hash256 }

TransactionSendToken {
  asset: Hash160
  value: int | decimalString
  address: Address
}
```

#### 7.11.6 Token Tracker Plugin Models

```text
Nep17Balances { address: Address, balance: Nep17Balance[] }
Nep17Balance { assetHash: Hash160, amount: decimalString, decimals?: string, symbol?: string, name?: string, lastUpdatedBlock: int }

Nep17Transfers { address: Address, sent: Nep17Transfer[], received: Nep17Transfer[] }
Nep17Transfer {
  timestamp: int                  // milliseconds since epoch
  assetHash: Hash160
  transferAddress: Address
  amount: decimalString
  blockIndex: int
  transferNotifyIndex: int
  txHash: Hash256
}

Nep11Balances { address: Address, balance: Nep11Balance[] }
Nep11Balance { assetHash: Hash160, name: string, symbol: string, decimals: string, tokens: Nep11Token[] }
Nep11Token { tokenId: string, amount: decimalString, lastUpdatedBlock: int }

Nep11Transfers { address: Address, sent: Nep11Transfer[], received: Nep11Transfer[] }
Nep11Transfer = Nep17Transfer + { tokenId: string }
```

#### 7.11.7 ApplicationLogs Plugin Models

```text
ApplicationLog { txid: Hash256, executions: Execution[] }

Execution {
  trigger: string
  vmState: NeoVMState
  exception?: string
  gasConsumed: decimalString
  stack: StackItem[]
  notifications: Notification[]
}
```

#### 7.11.8 StateService Plugin Models

```text
StateRoot { version: int, index: int, rootHash: Hash256, witnesses: NeoWitness[] }
StateHeight { localRootIndex: int, validatedRootIndex: int }

FindStatesResult {
  firstProof?: Base64String
  lastProof?: Base64String
  truncated: bool
  results: { key: Base64String, value: Base64String }[]
}
```

#### 7.11.9 Neo-Express Models (Optional)

```text
PopulatedBlocks { cacheId: string, blocks: int[] }
Nep17Contract { scriptHash: Hash160, symbol: string, decimals: int }
ContractStorageEntry { key: Base64String, value: Base64String }
ExpressContractState { hash: Hash160, manifest: ContractManifest }
ExpressShutdown { processId: int }
OracleRequest {
  requestId: int
  originalTxid: Hash256
  gasForResponse: int
  url: string
  filter: string
  callbackContract: Hash160
  callbackMethod: string
  userData: Base64String
}
```

---

## 8) Observability / Block Polling (Optional)

NeoSwiftSDK provides a polling-based block stream. Canonical cross-language abstraction:

```text
interface BlockStream {
  next() -> NeoBlock      // blocking or async
  close()
}

subscribeToNewBlocks(fullTxObjects: bool) -> BlockStream
catchUpToLatestBlocks(startIndex: int, fullTxObjects: bool) -> BlockStream
catchUpToLatestAndSubscribe(startIndex: int, fullTxObjects: bool) -> BlockStream
```

Implementation may use:

- polling (`getblockcount` + `getblock`)
- server-side subscriptions (if/when Neo nodes support it broadly)

---

## 9) Scripting & Invocation Data

### 9.1 ContractParameter

SDKs must provide a typed contract parameter model compatible with Neo JSON-RPC:

```text
enum ContractParameterType {
  Any, Boolean, Integer, ByteArray, String,
  Hash160, Hash256, PublicKey, Signature,
  Array, Map, InteropInterface
}

ContractParameter {
  name?: string
  type: ContractParameterType
  value?: any
}
```

Required constructors/helpers (names may be idiomatic):

- `any(null)`
- `bool(bool)`
- `integer(BigInt | int64 | decimalString)`
- `byteArray(Bytes | HexString | Base64String)`
- `string(string)`
- `hash160(Hash160 | Address | HexString)`
- `hash256(Hash256 | HexString)`
- `publicKey(PublicKey | Bytes | HexString)`
- `signature(Signature | Bytes | HexString | Base64String)`
- `array(ContractParameter[])`
- `map([(ContractParameter key, ContractParameter value)])` with the Neo restriction: keys cannot be `Array` or `Map`

#### 9.1.1 ContractParameter JSON Encoding (RPC)

When a `ContractParameter` is sent over JSON-RPC (e.g., `invokefunction`, `invokecontractverify`), SDKs should use Neo’s standard `{ type, value }` representation:

```text
ContractParameterJson {
  name?: string
  type: string                  // e.g., "Integer", "ByteArray", "Hash160"
  value?: any                   // encoding depends on type
}
```

Recommended `value` encodings (wire):

- `Any`: omit `value` or set `value = null` (some nodes use empty string; SDKs should accept both)
- `Boolean`: JSON boolean
- `Integer`: decimal string (preferred) or JSON number when safe
- `ByteArray` / `Signature`: **base64 string**
- `String`: UTF-8 JSON string
- `Hash160` / `Hash256`: hex string (no `0x` prefix)
- `PublicKey`: hex string (compressed SEC1, no `0x` prefix)
- `Array`: JSON array of `ContractParameterJson`
- `Map`: JSON array of `{ key: ContractParameterJson, value: ContractParameterJson }`

### 9.2 ScriptBuilder

At minimum:

```text
ScriptBuilder {
  contractCall(contractHash: Hash160, method: string, params: ContractParameter[], callFlags?: CallFlags)
  sysCall(interop: string | InteropService)
  pushParam(param: ContractParameter)
  toBytes() -> Bytes
}
```

### 9.3 InvocationResult + StackItem

SDKs must model the Neo VM result stack:

- `InvocationResult` (script, state, gasConsumed, exception?, notifications?, stack, sessionId?, diagnostics?, tx?)
- `StackItem` as a tagged union:
  - Any, Boolean, Integer(BigInt), ByteString(Bytes), Buffer(Bytes), Array, Struct, Map, InteropInterface(iteratorId,…)

### 9.4 Iterator Sessions

If the node supports sessions:

- `Iterator<T>(sessionId, iteratorId, mapper)` with:
  - `traverse(count) -> T[]`
  - `terminateSession()`

If sessions are disabled, SDKs **SHOULD** provide “unwrap iterator on-VM” helpers (build a script to traverse and return an array).

---

## 10) Transactions

### 10.1 TransactionBuilder (Invocation Transactions)

Builder pattern (exact method names are idiomatic):

```text
TransactionBuilder(client: NeoRpcClient) {
  version(byte)
  nonce(uint32)
  validUntilBlock(uint32)

  signers(Signer[])
  firstSigner(accountOrHash160)
  attributes(TransactionAttribute[])

  script(Bytes)
  extendScript(Bytes)

  additionalNetworkFee(int64)
  additionalSystemFee(int64)

  callInvokeScript() -> InvocationResult      // dry-run
  getUnsignedTransaction() -> Transaction
  sign() -> Transaction                        // automatic signing for non-multisig accounts
}
```

Required behavior:

- If `validUntilBlock` not set, SDK computes: `currentHeight + maxValidUntilBlockIncrement - 1`.
- SDK may compute base fees by calling:
  - `invokescript` (system fee)
  - `calculatenetworkfee` (network fee)
- If invocation results in FAULT and `allowTransmissionOnFault == false`, builder **MUST** refuse to build/sign/send unless explicitly overridden.

### 10.2 Transaction Model

```text
Transaction {
  version: byte
  nonce: uint32
  validUntilBlock: uint32
  signers: Signer[]
  systemFee: int64
  networkFee: int64
  attributes: TransactionAttribute[]
  script: Bytes
  witnesses: Witness[]

  txId() -> Hash256
  toBytes() -> Bytes
  toHex() -> string

  getHashData(networkMagic: uint32) -> Bytes

  addWitness(Witness)
  addWitnessFromAccount(Account)
  addMultiSigWitness(verificationScript, signaturesByPubKey | accounts[])

  send(client) -> RawTransactionResult
  waitForConfirmation(client, timeout?, pollInterval?) -> int   // returns confirmed block index
  getApplicationLog(client) -> ApplicationLog
}
```

### 10.3 Signers and Witnesses

- `Signer`:
  - `signerHash: Hash160`
  - `scopes: WitnessScope[]`
  - `allowedContracts?: Hash160[]`
  - `allowedGroups?: PublicKey[]`
  - `rules?: WitnessRule[]`
- `AccountSigner`: adds `account: Account`
- `ContractSigner`: adds `verifyParams: ContractParameter[]`

`Witness` consists of:

- `InvocationScript` (usually signatures)
- `VerificationScript` (single-sig or multi-sig check script)

### 10.4 Transaction Binary Serialization (Neo N3)

SDKs that support offline signing **MUST** implement Neo’s transaction binary format consistently.

Definitions (from Section 6.4):

- `VarInt`, `VarBytes`, `VarString`
- `VarArray<T> = VarInt(count) + concat(serialize(T[i]))`
- `UInt160` / `UInt256` are serialized in **little-endian** order in Neo binary

#### 10.4.1 Transaction layout

```text
Transaction (with witnesses) :=
  version:           uint8
  nonce:             uint32 (LE)
  systemFee:         int64  (LE)          // GAS fractions (10^-8)
  networkFee:        int64  (LE)          // GAS fractions (10^-8)
  validUntilBlock:   uint32 (LE)
  signers:           VarArray<Signer>
  attributes:        VarArray<TransactionAttribute>
  script:            VarBytes             // invocation script bytes
  witnesses:         VarArray<Witness>
```

The **transaction id** (`txid`) is derived from the transaction **without witnesses**:

```text
unsignedTxBytes = serialize(Transaction without witnesses)
digest = SHA256(unsignedTxBytes)
txidHex = reverse(digest).hex              // display form uses reversed bytes
```

The **signing hash data** is:

```text
hashData = uint32LE(networkMagic) || SHA256(unsignedTxBytes)
```

#### 10.4.2 Signer layout

```text
Signer :=
  account:           UInt160 (LE)
  scopes:            uint8                  // combined WitnessScope bitmask
  if scopes has CustomContracts:
    allowedContracts: VarArray<UInt160>
  if scopes has CustomGroups:
    allowedGroups:    VarArray<PublicKey>   // ECPoint compressed encoding
  if scopes has WitnessRules:
    rules:            VarArray<WitnessRule>
```

Limits:

- maximum total “subitems” per signer across allowed contracts/groups/rules is **16**

#### 10.4.3 Witness layout

```text
Witness :=
  invocationScript:  VarBytes
  verificationScript:VarBytes
```

Single-sig verification scripts are typically `PUSHDATA(pubkey) + SYSCALL(CheckSig)`.  
Multi-sig verification scripts typically push `m`, then `pubkeys`, then `n`, then `SYSCALL(CheckMultisig)`.

#### 10.4.4 TransactionAttribute layout (common)

Attribute encoding begins with a 1-byte type tag.

Common attribute types:

- `HighPriority`:
  - type byte `0x01`
  - no payload
- `OracleResponse`:
  - type byte `0x11`
  - `id: uint64(LE)`
  - `code: uint8` (OracleResponseCode)
  - `result: VarBytes` (oracle response payload bytes)

SDKs should keep the attribute model extensible to support additional attribute types introduced by newer Neo versions.

### 10.5 ContractParametersContext (Offline / Multi-Sig Tooling)

SDKs **SHOULD** provide an export format compatible with Neo tooling (e.g., neo-cli) for partial signing and multi-sig coordination.

Canonical structure:

```text
ContractParametersContext {
  type: "Neo.Network.P2P.Payloads.Transaction"
  hash: Hash256Hex
  data: Base64String                     // unsignedTxBytes
  items: map<string, ContextItem>        // keyed by "0x" + signer script hash
  network: uint32                        // network magic
}

ContextItem {
  script: Base64String                   // verification script bytes
  parameters?: ContractParameter[]       // typically Signature parameters
  signatures: map<HexString, Base64String> // pubKey -> signature
}
```

---

## 11) Wallets, Accounts, and Key Management

### 11.1 Account

Accounts can be:

- **single-sig** (has private key)
- **multi-sig** (no private key; references a verification script and threshold/participants)

Canonical fields:

```text
Account {
  address: Address
  label?: string
  isLocked: bool
  keyPair?: ECKeyPair | SecureECKeyPair
  encryptedPrivateKey?: string         // NEP-2
  verificationScript?: VerificationScript
  signingThreshold?: int
  nrOfParticipants?: int
}
```

Required constructors:

- `create()` (random single-sig)
- `fromWif(wif)`
- `fromAddress(address)` (watch-only)
- `fromScriptHash(hash160)` (watch-only)
- `fromPublicKey(pubKey)` (watch-only but with verification script)
- `createMultiSigAccount(pubKeys, threshold)`
- `createMultiSigAccount(address, threshold, participants)` (metadata-only)

Required methods:

- `getScriptHash() -> Hash160`
- `encryptPrivateKey(password, scryptParams)`
- `decryptPrivateKey(password, scryptParams)`

### 11.2 Wallet

Canonical fields:

```text
Wallet {
  name: string
  version: string
  scryptParams: ScryptParams
  accounts: Account[]
  defaultAccount: Account
}
```

Required methods:

- `create()` / `create(password)` (encrypts default account)
- `addAccounts(accounts[])`
- `removeAccount(accountOrHash160)`
- `setDefaultAccount(accountOrHash160)`
- `toNEP6() -> NEP6Wallet`
- `fromNEP6(file|json|NEP6Wallet) -> Wallet`
- `saveNEP6(path|writer)`

### 11.3 NEP-6 Models

SDKs must be able to read/write NEP-6 JSON:

- `NEP6Wallet`
- `NEP6Account`
- `NEP6Contract`

### 11.4 WIF + NEP-2

Required:

- `wifFromPrivateKey(privateKey32) -> string`
- `privateKeyFromWif(wif) -> Bytes(32)`
- `nep2Encrypt(password, keyPair, scryptParams) -> string`
- `nep2Decrypt(password, nep2String, scryptParams) -> ECKeyPair`

### 11.5 HD Wallets (Optional)

If provided, implement:

- `Bip32KeyPair` derivation from seed / path
- `Bip39Account` creation/recovery

---

## 12) Contract Wrappers (High-Level API)

### 12.1 SmartContract

```text
SmartContract(scriptHash: Hash160, client: NeoRpcClient) {
  buildInvokeFunctionScript(function: string, params: ContractParameter[]) -> Bytes
  invokeFunction(function: string, params: ContractParameter[]) -> TransactionBuilder

  callInvokeFunction(function: string, params?: ContractParameter[], signers?: Signer[]) -> InvocationResult
  callFunctionReturningString(function, params?) -> string
  callFunctionReturningInt(function, params?) -> BigInt/int64
  callFunctionReturningBool(function, params?) -> bool
  callFunctionReturningScriptHash(function, params?) -> Hash160

  // iterator helpers
  callFunctionReturningIterator(function, params?, mapper?) -> Iterator<T>
  callFunctionAndTraverseIterator(function, params?, maxItems, mapper?) -> T[]
  callFunctionAndUnwrapIterator(function, params, maxItems, signers?) -> StackItem[]
}
```

### 12.2 Token Standards

**NEP-17 (Fungible)**:

- `symbol()`, `decimals()`, `totalSupply()`
- `balanceOf(accountHash)`
- `transfer(fromHash, toHash, amountFractions, data?) -> TransactionBuilder`
- Optional: NNS-resolved transfers (`to: NNSName`)

**NEP-11 (Non-Fungible)**:

- `balanceOf(ownerHash)` (and for divisible: `balanceOf(ownerHash, tokenId)`)
- `tokensOf(ownerHash) -> Iterator<tokenId>`
- transfers for divisible and non-divisible NFTs
- optional: `tokens()` iterator
- optional: `properties(tokenId)`

### 12.3 Native Contracts (Recommended)

Wrappers with stable script hashes:

- `NeoToken`
- `GasToken`
- `PolicyContract`
- `ContractManagement`
- `RoleManagement`
- `NeoNameService` (NNS)

These wrappers should primarily compose `SmartContract` methods and expose:

- governance and policy methods (e.g., committee, candidates, fee settings)
- deployment helpers (ContractManagement: deploy NEF+manifest)

### 12.4 NNS + NEP-9 URI (Optional)

- `NNSName` validation and parsing
- `NeoURI` builder/parser for NEP-9 transfer URIs

---

## 13) Conformance Levels

To allow partial implementations, SDKs should declare support levels:

- **Core**: transport + RPC client + core types + ContractParameter + InvocationResult/StackItem
- **Standard**: Core + script builder + tx builder + signing + wallet/account + NEP-6 + NEP-2 + NEP-17/11 wrappers
- **Extended**: Standard + NNS + native contracts + iterator helpers + block polling + Neo-Express + witness rules

---

## 14) Mapping to NeoSwiftSDK (Reference)

This table shows how NeoSwiftSDK names map to this spec (useful for other SDK implementers):

- `NeoRpcClient` → `Sources/NeoSwiftSDK/protocol/NeoRpcClient.swift` (`NeoRpcClient` class) + `Sources/NeoSwiftSDK/protocol/core/Neo.swift` (`Neo` protocol)
- `RpcTransport` → `Sources/NeoSwiftSDK/protocol/NeoRpcService.swift` + `Sources/NeoSwiftSDK/protocol/Service.swift` + `Sources/NeoSwiftSDK/protocol/http/HttpService.swift`
- `NeoClientConfig` → `Sources/NeoSwiftSDK/protocol/NeoClient.swift` (`NeoClient.NeoClientConfiguration`) plus `Sources/NeoSwiftSDK/protocol/NeoRpcClientConfiguration.swift` for low-level RPC behavior
- `Request/RpcCall` → `Sources/NeoSwiftSDK/protocol/core/Request.swift`
- `RpcResponse<T>` → `Sources/NeoSwiftSDK/protocol/core/Response.swift`
- Block polling / streams → `Sources/NeoSwiftSDK/protocol/rx/NeoRx.swift`, `Sources/NeoSwiftSDK/protocol/rx/JsonRpc2_0Rx.swift`, `Sources/NeoSwiftSDK/protocol/core/polling/BlockIndexPolling.swift`
- `TransactionBuilder` → `Sources/NeoSwiftSDK/transaction/TransactionBuilder.swift`
- `Transaction` → `Sources/NeoSwiftSDK/transaction/NeoTransaction.swift`
- `Signer/AccountSigner/ContractSigner` → `Sources/NeoSwiftSDK/transaction/Signer.swift`, `Sources/NeoSwiftSDK/transaction/AccountSigner.swift`, `Sources/NeoSwiftSDK/transaction/ContractSigner.swift`
- `Witness/WitnessScope` → `Sources/NeoSwiftSDK/transaction/Witness.swift`, `Sources/NeoSwiftSDK/transaction/WitnessScope.swift`
- `ContractParametersContext` → `Sources/NeoSwiftSDK/transaction/ContractParametersContext.swift`
- `ScriptBuilder` → `Sources/NeoSwiftSDK/script/ScriptBuilder.swift`
- `ContractParameter` → `Sources/NeoSwiftSDK/types/ContractParameter.swift`
- `InvocationResult/StackItem` → `Sources/NeoSwiftSDK/protocol/core/response/InvocationResult.swift`, `Sources/NeoSwiftSDK/protocol/core/stackitem/StackItem.swift`
- Neo binary serialization → `Sources/NeoSwiftSDK/serialization/BinaryReader.swift`, `Sources/NeoSwiftSDK/serialization/BinaryWriter.swift`, `Sources/NeoSwiftSDK/serialization/NeoSerializable.swift`
- `Wallet/Account/NEP-6` → `Sources/NeoSwiftSDK/wallet/Wallet.swift`, `Sources/NeoSwiftSDK/wallet/Account.swift`, `Sources/NeoSwiftSDK/wallet/nep6/*`
- `NEP-2/WIF` → `Sources/NeoSwiftSDK/crypto/NEP2.swift`, `Sources/NeoSwiftSDK/crypto/WIF.swift`
- `SmartContract + wrappers` → `Sources/NeoSwiftSDK/contract/*`
- Core constants + hash/address types → `Sources/NeoSwiftSDK/NeoConstants.swift`, `Sources/NeoSwiftSDK/types/Hash160.swift`, `Sources/NeoSwiftSDK/types/Hash256.swift`

### NeoSwiftSDK Compatibility Notes (Intentional Spec Differences)

This spec is designed to be portable across languages, so it sometimes tightens or reshapes NeoSwiftSDK’s surface:

- **No-overload canonical RPC names**: NeoSwiftSDK uses overloads (e.g., `getBlock(hash, …)` vs `getBlock(index, …)`); the spec defines distinct “ByHash/ByIndex” names so C/Go/Rust can implement consistently.
- **BigInt + JSON safety**: NeoSwiftSDK often uses native `Int` for numeric fields/params; the spec requires an arbitrary-precision integer model and recommends JSON **decimal strings** for integers to avoid JS precision loss.
- **Configurable address version**: the spec treats `addressVersion` as part of client config; SDKs should ensure address validation/encoding uses the configured value (not a hard-coded default).
- **Observability abstraction**: NeoSwiftSDK exposes Combine publishers; the spec describes a language-neutral `BlockStream` concept (can be implemented with polling, async iterators, callbacks, etc.).

---

## 15) Security Considerations (Recommended)

This specification is interface-focused, but Neo SDKs routinely handle private keys and transaction signing. Implementations should follow these baseline rules:

- **Key material**
  - Never log private keys, NEP-2 strings, WIFs, seed phrases, or raw decrypted key bytes.
  - Prefer “secure bytes” containers where the language/runtime supports it; overwrite key buffers after use.
  - Use constant-time comparison for secrets (password checks, MAC comparisons, etc.).
- **Randomness**
  - All key generation and nonce generation must use a cryptographically secure RNG.
- **RPC safety**
  - Apply conservative defaults: timeouts enabled, TLS validation enabled, and bounded retries.
  - Treat RPC error objects and FAULT invocation states as first-class errors; never ignore them silently.
- **Input validation**
  - Validate address version and checksums; reject malformed hex/base64 inputs early.
  - Enforce Neo protocol limits where applicable (e.g., max signers/subitems, tx size, attribute limits).
