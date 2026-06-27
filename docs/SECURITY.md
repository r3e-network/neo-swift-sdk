# neo-swift-sdk Security Guide

This guide covers production use of `neo-swift-sdk` in applications that handle private keys, wallet files, signatures, or transaction relay.

## Key Material

Use secure key containers for private keys:

```swift
import NeoSwiftSDK

let keyPair = try SecureECKeyPair.createEcKeyPair()
let address = try keyPair.getAddress()
```

Do not log WIF values, decrypted private keys, seed phrases, wallet passwords, NEP-2 passphrases, or raw signing payloads that contain secrets.

For persisted keys:

- Prefer NEP-2 encrypted keys.
- Keep passphrases outside source control and build logs.
- Clear temporary key material as soon as the operation finishes.
- Treat test wallets as secrets unless they are explicitly burn-only fixtures.

## RPC Transport

Use HTTPS endpoints in production:

```swift
let client = NeoClient(endpoint: URL(string: "https://mainnet1.neo.coz.io:443")!)
```

When using the request-builder API:

```swift
let rpcClient = NeoRpcClient.build(HttpService(url: endpoint))
let version = try await rpcClient.getVersion().send().getResult()
```

Production services should pin or otherwise control trusted RPC endpoints. Do not sign transactions against an endpoint you do not trust to report the intended network magic and chain state.

## Transaction Signing

Before signing:

- Verify the network magic, script, signers, witness scopes, fees, and `validUntilBlock`.
- Verify the token script hash and amount units.
- Reject unexpected high-priority, conflict, notary, or oracle attributes.
- Keep `Conflicts` attributes deduplicated by hash.

For multi-signature flows, inspect the `ContractParametersContext` before forwarding it to another signer or relay endpoint.

## Neo 3.10.0 Message Signing

`signmsg` and `verifymsg` are wallet RPCs. Treat their output as signatures over the node-defined payload, not arbitrary application authentication unless your application explicitly includes domain separation and replay constraints.

Use `avoidSignatureReplay: true` for network-bound signatures:

```swift
let signed = try await client.signMessage(input: .init(
    message: "example",
    avoidSignatureReplay: true
)).signatureSet
```

## Dependency And CI Hygiene

- Keep dependency ranges bounded.
- Run `swift test` before release.
- Run security-focused tests with `swift test --filter SecurityTests`.
- Scan commits for credentials before pushing.
- Keep release artifacts and coverage uploads free of wallet fixtures.

## Vulnerability Reporting

Report vulnerabilities privately to the maintainers before public disclosure. Include a minimal reproduction, affected version or commit, and the expected impact.
