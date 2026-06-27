import Foundation

/// AWS-style operation client facade for Neo JSON-RPC.
///
/// This facade keeps the existing ``NeoRpcClient`` request API available while offering
/// typed operation inputs and outputs for new code.
public final class NeoClient {

    public final class NeoClientConfiguration {
        public var service: NeoRpcService
        public var rpcClientConfiguration: NeoRpcClientConfiguration

        public init(service: NeoRpcService = HttpService(), rpcClientConfiguration: NeoRpcClientConfiguration = .init()) {
            self.service = service
            self.rpcClientConfiguration = rpcClientConfiguration
        }
    }

    public let config: NeoClientConfiguration
    public let rpcClient: NeoRpcClient

    public init(config: NeoClientConfiguration = .init()) {
        self.config = config
        self.rpcClient = NeoRpcClient.build(config.service, config.rpcClientConfiguration)
    }

    public convenience init(endpoint: URL, rpcClientConfiguration: NeoRpcClientConfiguration = .init()) {
        self.init(config: .init(service: HttpService(url: endpoint), rpcClientConfiguration: rpcClientConfiguration))
    }

    public func getBlockCount(input: GetBlockCountInput = GetBlockCountInput()) async throws -> GetBlockCountOutput {
        let count = try await rpcClient.getBlockCount().send().getResult()
        return GetBlockCountOutput(count: count)
    }

    public func getBlockHash(input: GetBlockHashInput) async throws -> GetBlockHashOutput {
        let blockHash = try await rpcClient.getBlockHash(input.blockIndex).send().getResult()
        return GetBlockHashOutput(blockHash: blockHash)
    }

    public func getBestBlockHash(input: GetBestBlockHashInput = GetBestBlockHashInput()) async throws -> GetBestBlockHashOutput {
        let blockHash = try await rpcClient.getBestBlockHash().send().getResult()
        return GetBestBlockHashOutput(blockHash: blockHash)
    }

    public func getVersion(input: GetVersionInput = GetVersionInput()) async throws -> GetVersionOutput {
        let version = try await rpcClient.getVersion().send().getResult()
        return GetVersionOutput(version: version)
    }

    public func getStorage(input: GetStorageInput) async throws -> GetStorageOutput {
        let value = try await rpcClient.getStorage(input.contractHash, input.keyHexString).send().getResult()
        return GetStorageOutput(value: value)
    }
    
    public func sendRawTransaction(input: SendRawTransactionInput) async throws -> SendRawTransactionOutput {
        let rawTransaction = try await rpcClient.sendRawTransaction(input.rawTransactionHex).send().getResult()
        return SendRawTransactionOutput(hash: rawTransaction.hash)
    }
    
    public func signMessage(input: SignMessageInput) async throws -> SignMessageOutput {
        let signatureSet = try await rpcClient.signMessage(input.message, input.avoidSignatureReplay).send().getResult()
        return SignMessageOutput(signatureSet: signatureSet)
    }
    
    public func verifyMessage(input: VerifyMessageInput) async throws -> VerifyMessageOutput {
        let verification = try await rpcClient
            .verifyMessage(input.message, input.signatureHex, input.publicKeyHex, input.saltHex, input.avoidSignatureReplay)
            .send()
            .getResult()
        return VerifyMessageOutput(verification: verification)
    }
    
    public func sign(input: SignInput) async throws -> SignOutput {
        let context = try await rpcClient.sign(input.context).send().getResult()
        return SignOutput(context: context)
    }
    
    public func relay(input: RelayInput) async throws -> RelayOutput {
        let relay = try await rpcClient.relay(input.context).send().getResult()
        return RelayOutput(hash: relay.hash)
    }
    
    public func getPendingValidUntilRelay(input: GetPendingValidUntilRelayInput = GetPendingValidUntilRelayInput()) async throws -> GetPendingValidUntilRelayOutput {
        let pendingState = try await rpcClient.getPendingValidUntilRelay().send().getResult()
        return GetPendingValidUntilRelayOutput(pendingState: pendingState)
    }
    
    public func getRawPendingTransaction(input: GetRawPendingTransactionInput) async throws -> GetRawPendingTransactionOutput {
        let transaction = try await rpcClient.getRawPendingTransaction(input.transactionHash).send().getResult()
        return GetRawPendingTransactionOutput(rawTransaction: transaction)
    }
    
    public func getPendingTransaction(input: GetPendingTransactionInput) async throws -> GetPendingTransactionOutput {
        let transaction = try await rpcClient.getPendingTransaction(input.transactionHash).send().getResult()
        return GetPendingTransactionOutput(transaction: transaction)
    }

}

public struct GetBlockCountInput: Codable, Hashable {
    public init() {}
}

public struct GetBlockCountOutput: Codable, Hashable {
    public let count: Int

    public init(count: Int) {
        self.count = count
    }
}

public struct GetBlockHashInput: Codable, Hashable {
    public let blockIndex: Int

    public init(blockIndex: Int) {
        self.blockIndex = blockIndex
    }
}

public struct GetBlockHashOutput: Codable, Hashable {
    public let blockHash: Hash256

    public init(blockHash: Hash256) {
        self.blockHash = blockHash
    }
}

public struct GetBestBlockHashInput: Codable, Hashable {
    public init() {}
}

public struct GetBestBlockHashOutput: Codable, Hashable {
    public let blockHash: Hash256

    public init(blockHash: Hash256) {
        self.blockHash = blockHash
    }
}

public struct GetVersionInput: Codable, Hashable {
    public init() {}
}

public struct GetVersionOutput: Codable, Hashable {
    public let version: NeoGetVersion.NeoVersion

    public init(version: NeoGetVersion.NeoVersion) {
        self.version = version
    }
}

public struct GetStorageInput: Codable, Hashable {
    public let contractHash: Hash160
    public let keyHexString: String

    public init(contractHash: Hash160, keyHexString: String) {
        self.contractHash = contractHash
        self.keyHexString = keyHexString
    }
}

public struct GetStorageOutput: Codable, Hashable {
    public let value: String

    public init(value: String) {
        self.value = value
    }
}

public struct SendRawTransactionInput: Codable, Hashable {
    public let rawTransactionHex: String

    public init(rawTransactionHex: String) {
        self.rawTransactionHex = rawTransactionHex
    }
}

public struct SendRawTransactionOutput: Codable, Hashable {
    public let hash: Hash256

    public init(hash: Hash256) {
        self.hash = hash
    }
}

public struct SignMessageInput: Codable, Hashable {
    public let message: String
    public let avoidSignatureReplay: Bool

    public init(message: String, avoidSignatureReplay: Bool = false) {
        self.message = message
        self.avoidSignatureReplay = avoidSignatureReplay
    }
}

public struct SignMessageOutput: Codable, Hashable {
    public let signatureSet: NeoSignMessage.SignatureSet

    public init(signatureSet: NeoSignMessage.SignatureSet) {
        self.signatureSet = signatureSet
    }
}

public struct VerifyMessageInput: Codable, Hashable {
    public let message: String
    public let signatureHex: String
    public let publicKeyHex: String
    public let saltHex: String
    public let avoidSignatureReplay: Bool

    public init(message: String, signatureHex: String, publicKeyHex: String, saltHex: String, avoidSignatureReplay: Bool = false) {
        self.message = message
        self.signatureHex = signatureHex
        self.publicKeyHex = publicKeyHex
        self.saltHex = saltHex
        self.avoidSignatureReplay = avoidSignatureReplay
    }
}

public struct VerifyMessageOutput: Codable, Hashable {
    public let verification: NeoVerifyMessage.Verification

    public init(verification: NeoVerifyMessage.Verification) {
        self.verification = verification
    }
}

public struct SignInput: Codable, Hashable {
    public let context: ContractParametersContext

    public init(context: ContractParametersContext) {
        self.context = context
    }
}

public struct SignOutput: Codable, Hashable {
    public let context: ContractParametersContext

    public init(context: ContractParametersContext) {
        self.context = context
    }
}

public struct RelayInput: Codable, Hashable {
    public let context: ContractParametersContext

    public init(context: ContractParametersContext) {
        self.context = context
    }
}

public struct RelayOutput: Codable, Hashable {
    public let hash: Hash256

    public init(hash: Hash256) {
        self.hash = hash
    }
}

public struct GetPendingValidUntilRelayInput: Codable, Hashable {
    public init() {}
}

public struct GetPendingValidUntilRelayOutput: Codable, Hashable {
    public let pendingState: NeoGetPendingValidUntilRelay.PendingState

    public init(pendingState: NeoGetPendingValidUntilRelay.PendingState) {
        self.pendingState = pendingState
    }
}

public struct GetRawPendingTransactionInput: Codable, Hashable {
    public let transactionHash: Hash256

    public init(transactionHash: Hash256) {
        self.transactionHash = transactionHash
    }
}

public struct GetRawPendingTransactionOutput: Codable, Hashable {
    public let rawTransaction: String

    public init(rawTransaction: String) {
        self.rawTransaction = rawTransaction
    }
}

public struct GetPendingTransactionInput: Codable, Hashable {
    public let transactionHash: Hash256

    public init(transactionHash: Hash256) {
        self.transactionHash = transactionHash
    }
}

public struct GetPendingTransactionOutput: Codable, Hashable {
    public let transaction: Transaction

    public init(transaction: Transaction) {
        self.transaction = transaction
    }
}
