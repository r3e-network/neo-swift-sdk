# neo-swift-sdk Production Deployment Guide

Use this checklist before shipping an app or service that depends on `neo-swift-sdk`.

## Runtime Configuration

Create one application-level `NeoClient` for high-level operations:

```swift
import NeoSwiftSDK

let client = NeoClient(endpoint: URL(string: "https://mainnet1.neo.coz.io:443")!)
let version = try await client.getVersion().version
```

Use `NeoRpcClient` when you need request-builder access:

```swift
let service = HttpService(url: URL(string: "https://mainnet1.neo.coz.io:443")!)
let rpcClient = NeoRpcClient.build(service, NeoRpcClientConfiguration())
```

If your deployment targets a private network, set `networkMagic` explicitly or load it once through `getversion` before signing transactions.

## Endpoint Strategy

For production:

- Use HTTPS.
- Maintain a short allowlist of trusted RPC endpoints.
- Fail over only to endpoints serving the same network.
- Monitor `getversion`, block height, latency, and relay errors.
- Do not mix mainnet, testnet, and private-network clients in the same signer path.

Example endpoint pool:

```swift
final class NeoRpcPool {
    private let clients: [NeoRpcClient]
    private var index = 0

    init(endpoints: [URL]) {
        clients = endpoints.map { NeoRpcClient.build(HttpService(url: $0)) }
    }

    func next() -> NeoRpcClient {
        defer { index = (index + 1) % clients.count }
        return clients[index]
    }
}
```

## Transaction Deployment Checklist

Before relay:

- Confirm the script bytes match the intended operation.
- Confirm signer accounts and witness scopes.
- Confirm fee budget and token decimals.
- Confirm `validUntilBlock` is within the current relay window.
- Deduplicate `Conflicts` attributes by hash.
- For Neo 3.10.0 `relay`, verify the `ContractParametersContext` is complete and network-matched.

## Wallet Operations

Node wallet RPCs such as `signmsg`, `verifymsg`, `sign`, `sendfrom`, `sendmany`, and `canceltransaction` require an opened node wallet and may fail if the node rejects relay or fee limits. Treat those failures as definitive unless you intentionally queue a `NotYetValid` transaction through DeferredRelay.

## DeferredRelay

Neo N3 v3.10.0 can expose DeferredRelay plugin RPCs:

```swift
let pending = try await client.getPendingValidUntilRelay().pendingState
```

Only rely on this API when the plugin is enabled on the target node. A standard node may reject the same `NotYetValid` transaction directly.

## Verification

Run before release:

```bash
swift test
swift test --filter SecurityTests
ENABLE_NETWORK_TESTS=true swift test --filter IntegrationTests
```

Also run your application-level smoke test against the exact RPC endpoint set used in production.
