# neo-swift-sdk

[![Swift 5.9+](https://img.shields.io/badge/Swift-5.9+-blue.svg)](https://swift.org)
[![Platforms](https://img.shields.io/badge/Platforms-iOS%20|%20macOS%20|%20tvOS%20|%20watchOS-green.svg)](https://github.com/r3e-network/neo-swift-sdk)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Security](https://img.shields.io/badge/Security-Production%20Ready-brightgreen.svg)](docs/SECURITY.md)

`neo-swift-sdk` is a Swift SDK for Neo N3 applications. It targets Neo N3 v3.10.0 RPC, exposes an AWS SDK-style operation client for application code, and keeps a lower-level JSON-RPC request builder for advanced workflows.

## Features

- `NeoClient`: typed operation facade with input and output models.
- `NeoRpcClient`: lower-level JSON-RPC request builder for full node, wallet, token, state-service, and plugin RPCs.
- Neo N3 v3.10.0 support for `getversion`, `signmsg`, `verifymsg`, `sign`, `relay`, and DeferredRelay RPCs.
- Secure key utilities including `SecureBytes`, `SecureECKeyPair`, NEP-2, WIF, and constant-time helpers.
- Transaction, witness, wallet, contract, NEP-11, NEP-17, NNS, and binary serialization support.
- Combine publishers for block polling and replay.

## Installation

Add the package to `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/r3e-network/neo-swift-sdk", from: "3.0.0")
]
```

Then add the product to your target:

```swift
.product(name: "NeoSwiftSDK", package: "neo-swift-sdk")
```

Import the module:

```swift
import NeoSwiftSDK
```

## Quick Start

Use `NeoClient` for application code. Operations accept typed input structs and return typed output structs.

```swift
import Foundation
import NeoSwiftSDK

let client = NeoClient(endpoint: URL(string: "https://mainnet1.neo.coz.io:443")!)

let blockCount = try await client.getBlockCount().count
let latestHash = try await client
    .getBlockHash(input: .init(blockIndex: blockCount - 1))
    .blockHash

let version = try await client.getVersion().version
print(latestHash.string)
print(version.userAgent)
```

## Raw JSON-RPC

Use `NeoRpcClient` when you need request-level access or an RPC that has not been promoted to the operation facade yet.

```swift
import Foundation
import NeoSwiftSDK

let endpoint = URL(string: "http://localhost:40332")!
let rpcClient = NeoRpcClient.build(
    HttpService(url: endpoint),
    NeoRpcClientConfiguration(networkMagic: 769)
)

let response = try await rpcClient.getBestBlockHash().send()
let bestBlockHash = try response.getResult()
```

## Transactions

Build, sign, and relay transactions with the transaction builder.

```swift
let account = try Account.fromWIF("<wif>")

let script = try ScriptBuilder()
    .contractCall(NeoToken.SCRIPT_HASH, method: "symbol", params: [])
    .toArray()

let transaction = try await TransactionBuilder(rpcClient)
    .script(script)
    .signers(AccountSigner.calledByEntry(account))
    .sign()

let relayResult = try await transaction.send().getResult()
print(relayResult.hash.string)
```

For multi-signature flows, export a contract-parameters context, sign it through a v3.10.0 node wallet, and relay the completed context:

```swift
let unsigned = try await TransactionBuilder(rpcClient)
    .script(script)
    .signers(AccountSigner.calledByEntry(account))
    .getUnsignedTransaction()

let context = try await unsigned.toContractParametersContext()
let signed = try await client.sign(input: .init(context: context)).context
let relayed = try await client.relay(input: .init(context: signed)).hash
```

## Contracts

Contract wrappers use `NeoRpcClient` for request-level access.

```swift
let scriptHash = try Hash160("0x1a70eac53f5882e40dd90f55463cce31a9f72cd4")
let contract = SmartContract(scriptHash: scriptHash, rpcClient: rpcClient)

let result = try await contract.callInvokeFunction(
    "symbol",
    [],
    [AccountSigner.calledByEntry(account)]
)
```

## Neo 3.10.0 RPCs

The SDK includes typed request/response support for SDK-relevant Neo N3 v3.10.0 changes:

```swift
let signatureSet = try await client
    .signMessage(input: .init(message: "hello", avoidSignatureReplay: true))
    .signatureSet

let verification = try await client.verifyMessage(input: .init(
    message: "hello",
    signatureHex: signatureSet.signatures[0].signature,
    publicKeyHex: signatureSet.signatures[0].publicKey,
    saltHex: signatureSet.signatures[0].salt,
    avoidSignatureReplay: true
)).verification

let pending = try await client.getPendingValidUntilRelay().pendingState
print(verification.isValid)
print(pending.count)
```

## Security

For production applications:

- Use `SecureECKeyPair` for private key material.
- Encrypt stored keys with NEP-2.
- Validate transaction scripts, signers, fees, and network magic before signing.
- Avoid logging private keys, WIF values, invocation scripts containing secrets, or wallet passwords.
- Review [docs/SECURITY.md](docs/SECURITY.md) and [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md).

## Testing

```bash
swift test
swift test --filter SecurityTests
ENABLE_NETWORK_TESTS=true swift test --filter IntegrationTests
```

## Documentation

- [Security Guide](docs/SECURITY.md)
- [Deployment Guide](docs/DEPLOYMENT.md)
- [Neo SDK Interface Spec](docs/neo-sdk-spec.md)
- [Changelog](CHANGELOG.md)

## License

`neo-swift-sdk` is released under the MIT License. See [LICENSE](LICENSE) for details.

## Acknowledgements

- The Neo ecosystem and [neow3j](https://github.com/neow3j/neow3j)
- [GrantShares](https://grantshares.io/)
- The Swift cryptography and server-side Swift communities
