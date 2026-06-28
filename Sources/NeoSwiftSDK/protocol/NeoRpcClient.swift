import Foundation
#if canImport(Combine)
import Combine
#endif

public class NeoRpcClient: Neo {
    
    public var config: NeoRpcClientConfiguration
    
    /// The NeoNameService resolver script hash that is configured in the ``NeoRpcClientConfiguration``.
    public var nnsResolver: Hash160 { return config.nnsResolver }
    
    /// The interval in milliseconds in which blocks are produced.
    ///
    /// Defaults to ``NeoRpcClientConfiguration/DEFAULT_BLOCK_TIME``.
    public var blockInterval: Int { return config.blockInterval }
    
    /// The interval in milliseconds in which `NeoRpcClient` should poll the Neo node for new block information when observing the blockchain.
    ///
    /// Defaults to ``NeoRpcClientConfiguration/DEFAULT_BLOCK_TIME``.
    public var pollingInterval: Int { return config.pollingInterval }
    
    /// The maximum time in milliseconds that can pass form the construction of a transaction until it gets included in a block.
    /// A transaction becomes invalid after this time increment is surpassed.
    ///
    /// Defaults to ``NeoRpcClientConfiguration/MAX_VALID_UNTIL_BLOCK_INCREMENT_BASE`` divided by the configured block interval.
    public var maxValidUntilBlockIncrement: Int { return config.maxValidUntilBlockIncrement }
    
    internal let service: NeoRpcService
#if canImport(Combine)
    private lazy var rpcEventClient: JsonRpc2_0Rx = {
        return JsonRpc2_0Rx(rpcClient: self, executorService: config.scheduledDispatchQueue)
    }()
#endif
    
    required public init(config: NeoRpcClientConfiguration, service: NeoRpcService) {
        self.config = config
        self.service = service
    }
    
    /// Constructs a new NeoRpcClient instance using the given configuration.
    /// - Parameters:
    ///   - service: A NeoRpcService instance - ``HttpService``
    ///   - config: The ``NeoRpcClientConfiguration`` to use, defaults to a new one
    /// - Returns: The new NeoRpcClient instance
    public static func build( _ service: NeoRpcService, _ config: NeoRpcClientConfiguration = .init()) -> Self {
        return Self.init(config: config, service: service)
    }
    
    /// Allow the transmission of scripts that lead to a ``NeoVMStateType/fault``.
    public func allowTransmissionOnFault() {
        _ = config.allowTransmissionOnFault()
    }
    
    /// Prevent the transmission of scripts that lead to a ``NeoVMStateType/fault``.
    ///
    /// This is set by default.
    public func preventTransmissionOnFault() {
        _ = config.preventTransmissionOnFault()
    }
    
    /// Sets the NeoNameService script hash that should be used to resolve NNS domain names.
    /// - Parameter nnsResolver: The NNS resolver script hash
    public func setNNSResolver(_ nnsResolver: Hash160) {
        _ = config.setNNSResolver(nnsResolver)
    }
    
    /// Gets the configured network magic number.
    ///
    /// The magic number is an ingredient, e.g., when generating the hash of a transaction.
    ///
    /// Only once this method is called for the first time the value is fetched from the connected Neo node.
    /// - Returns: The network's magic number
    public func getNetworkMagicNumberBytes() async throws -> Bytes {
        let magicInt = try await getNetworkMagicNumber() & 0xFFFFFFFF
        return UInt32(magicInt).bigEndianBytes
    }
    
    /// Gets the configured network magic number as an integer.
    ///
    /// The magic number is an ingredient, e.g., when generating the hash of a transaction.
    ///
    /// Only once this method is called for the first time the value is fetched from the connected Neo node.
    /// - Returns: The network's magic number
    public func getNetworkMagicNumber() async throws -> Int {
        if config.networkMagic == nil {
            let version = try await getVersion().send().getResult()
            guard let protocolConfig = version.protocol else {
                throw NeoError.illegalState("Unable to read Network Magic Number from Version")
            }
            _ = try config.setNetworkMagic(protocolConfig.network)
            syncConfigFromVersion(protocolConfig)
        }
        return config.networkMagic!
    }

    private func syncConfigFromVersion(_ protocolConfig: NeoGetVersion.NeoVersion.NeoProtocol) {
        if config.addressVersion == NeoRpcClientConfiguration.DEFAULT_ADDRESS_VERSION,
           protocolConfig.addressVersion >= 0 && protocolConfig.addressVersion <= 0xFF {
            _ = config.setAddressVersion(Byte(protocolConfig.addressVersion))
        }
        if config.blockInterval == NeoRpcClientConfiguration.DEFAULT_BLOCK_TIME {
            _ = config.setBlockInterval(protocolConfig.msPerBlock)
        }
        if config.maxValidUntilBlockIncrement == NeoRpcClientConfiguration.MAX_VALID_UNTIL_BLOCK_INCREMENT_BASE / NeoRpcClientConfiguration.DEFAULT_BLOCK_TIME {
            _ = config.setMaxValidUntilBlockIncrement(protocolConfig.maxValidUntilBlockIncrement)
        }
    }

    private func address(_ scriptHash: Hash160) -> String {
        scriptHash.toAddress(addressVersion: config.addressVersion)
    }

    private func scriptHash(from address: String) throws -> Hash160 {
        try Hash160.fromAddress(address, addressVersion: config.addressVersion)
    }
    
    // MARK: Blockchain Methods
    
    /// Gets the hash of the latest block in the blockchain.
    /// - Returns: The request object
    public func getBestBlockHash() -> Request<NeoBlockHash, Hash256> {
        return .init(method: "getbestblockhash", params: [], service: service)
    }
    
    /// Gets the block hash of the corresponding block based on the specified block index.
    /// - Parameter blockIndex: The block index
    /// - Returns: The request object
    public func getBlockHash(_ blockIndex: Int) -> Request<NeoBlockHash, Hash256> {
        return .init(method: "getblockhash", params: [blockIndex], service: service)
    }
    
    /// Gets the corresponding block information according to the specified block hash.
    /// - Parameters:
    ///   - blockHash: The block hash
    ///   - returnFullTransactionObjects: Whether to get block information with all transaction objects or just the block header
    /// - Returns: The request object
    public func getBlock(_ blockHash: Hash256, _ returnFullTransactionObjects: Bool) -> Request<NeoGetBlock, NeoBlock> {
        if returnFullTransactionObjects {
            return .init(method: "getblock", params: [blockHash.string, 1], service: service)
        } else {
            return getBlockHeader(blockHash)
        }
    }
    
    /// Gets the corresponding block information for the specified block hash.
    /// - Parameter blockHash: The block hash
    /// - Returns: The request object
    public func getRawBlock(_ blockHash: Hash256) -> Request<NeoGetRawBlock, String> {
        return .init(method: "getblock", params: [blockHash.string, 0], service: service)
    }
    
    /// Gets the corresponding block information according to the specified block index.
    /// - Parameters:
    ///   - blockIndex: The block index
    ///   - returnFullTransactionObjects: Whether to get block information with all transaction objects or just the block header
    /// - Returns: The request object
    public func getBlock(_ blockIndex: Int, _ returnFullTransactionObjects: Bool) -> Request<NeoGetBlock, NeoBlock> {
        if returnFullTransactionObjects {
            return .init(method: "getblock", params: [blockIndex, 1], service: service)
        } else {
            return getBlockHeader(blockIndex)
        }
    }
    
    /// Gets the corresponding block information according to the specified block index.
    /// - Parameter blockIndex: The block index
    /// - Returns: The request object
    public func getRawBlock(_ blockIndex: Int) -> Request<NeoGetRawBlock, String> {
        return .init(method: "getblock", params: [blockIndex, 0], service: service)
    }
    
    /// Gets the block header count of the blockchain.
    /// - Returns: The request object
    public func getBlockHeaderCount() -> Request<NeoBlockHeaderCount, Int> {
        return .init(method: "getblockheadercount", params: [], service: service)
    }
    
    /// Gets the block count of the blockchain.
    /// - Returns: The request object
    public func getBlockCount() -> Request<NeoBlockCount, Int> {
        return .init(method: "getblockcount", params: [], service: service)
    }
    
    /// Gets the corresponding block header information according to the specified block hash.
    /// - Parameter blockHash: The block hash
    /// - Returns: The request object
    public func getBlockHeader(_ blockHash: Hash256) -> Request<NeoGetBlock, NeoBlock> {
        return .init(method: "getblockheader", params: [blockHash.string, 1], service: service)
    }
    
    /// Gets the corresponding block header information according to the specified index.
    /// - Parameter blockIndex: The block index
    /// - Returns: The request object
    public func getBlockHeader(_ blockIndex: Int) -> Request<NeoGetBlock, NeoBlock> {
        return .init(method: "getblockheader", params: [blockIndex, 1], service: service)
    }
    
    /// Gets the corresponding block header information according to the specified block hash.
    /// - Parameter blockHash: The block hash
    /// - Returns: The request object
    public func getRawBlockHeader(_ blockHash: Hash256) -> Request<NeoGetRawBlock, String> {
        return .init(method: "getblockheader", params: [blockHash.string, 0], service: service)
    }
    
    /// Gets the corresponding block header information according to the specified index.
    /// - Parameter blockIndex: The block index
    /// - Returns: The request object
    public func getRawBlockHeader(_ blockIndex: Int) -> Request<NeoGetRawBlock, String> {
        return .init(method: "getblockheader", params: [blockIndex, 0], service: service)
    }
    
    /// Gets the native contracts list, which includes the basic information of native contracts and the contract descriptive file `manifest.json`.
    /// - Returns: The request object
    public func getNativeContracts() -> Request<NeoGetNativeContracts, [NativeContractState]> {
        return .init(method: "getnativecontracts", params: [], service: service)
    }
    
    /// Gets the contract information.
    /// - Parameter contractHash: The contract script hash
    /// - Returns: The request object
    public func getContractState(_ contractHash: Hash160) -> Request<NeoGetContractState, ContractState> {
        return .init(method: "getcontractstate", params: [contractHash.string], service: service)
    }
    
    /// Gets the native contract information by its name.
    ///
    /// This RPC only works for native contracts.
    /// - Parameter contractName: The name of the native contract
    /// - Returns: The request object
    public func getNativeContractState(_ contractName: String) -> Request<NeoGetContractState, ContractState> {
        return .init(method: "getcontractstate", params: [contractName], service: service)
    }
    
    /// Gets a list of unconfirmed or confirmed transactions in memory.
    /// - Returns: The request object
    public func getMemPool() -> Request<NeoGetMemPool, NeoGetMemPool.MemPoolDetails> {
        return .init(method: "getrawmempool", params: [1], service: service)
    }
    
    /// Gets a list of confirmed transactions in memory.
    /// - Returns: The request object
    public func getRawMemPool() -> Request<NeoGetRawMemPool, [Hash256]> {
        return .init(method: "getrawmempool", params: [], service: service)
    }
    
    /// Gets the corresponding transaction information based on the specified transaction hash.
    /// - Parameter txHash: The transaction hash
    /// - Returns: The request object
    public func getTransaction(_ txHash: Hash256) -> Request<NeoGetTransaction, Transaction> {
        return .init(method: "getrawtransaction", params: [txHash.string, 1], service: service)
    }
    
    /// Gets the corresponding transaction information based on the specified transaction hash.
    /// - Parameter txHash: The transaction hash
    /// - Returns: The request object
    public func getRawTransaction(_ txHash: Hash256) -> Request<NeoGetRawTransaction, String> {
        return .init(method: "getrawtransaction", params: [txHash.string, 0], service: service)
    }
    
    /// Gets the stored value according to the contract hash and the key.
    /// - Parameters:
    ///   - contractHash: The contract hash
    ///   - keyHexString: The key to look up in storage as a hexadecimal string
    /// - Returns: The request object
    public func getStorage(_ contractHash: Hash160, _ keyHexString: String) -> Request<NeoGetStorage, String> {
        return .init(method: "getstorage", params: [contractHash.string, keyHexString.base64Encoded], service: service)
    }

    /// Finds storage items by contract hash and key prefix.
    /// - Parameters:
    ///   - contractHash: The contract hash
    ///   - keyPrefixHex: The storage key prefix as a hexadecimal string
    ///   - start: The start index (default 0)
    /// - Returns: The request object
    public func findStorage(_ contractHash: Hash160, _ keyPrefixHex: String, _ start: Int = 0) -> Request<NeoFindStorage, NeoFindStorage.FindStorageResult> {
        return .init(method: "findstorage", params: [contractHash.string, keyPrefixHex.base64Encoded, start], service: service)
    }

    /// Finds storage items by contract hash and key prefix.
    /// - Parameters:
    ///   - contractHash: The contract hash
    ///   - keyPrefixHex: The storage key prefix as a hexadecimal string
    /// - Returns: The request object
    public func findStorage(_ contractHash: Hash160, _ keyPrefixHex: String) -> Request<NeoFindStorage, NeoFindStorage.FindStorageResult> {
        return findStorage(contractHash, keyPrefixHex, 0)
    }

    /// Finds storage items by contract id and key prefix.
    /// - Parameters:
    ///   - contractId: The contract id
    ///   - keyPrefixHex: The storage key prefix as a hexadecimal string
    ///   - start: The start index (default 0)
    /// - Returns: The request object
    public func findStorage(_ contractId: Int, _ keyPrefixHex: String, _ start: Int = 0) -> Request<NeoFindStorage, NeoFindStorage.FindStorageResult> {
        return .init(method: "findstorage", params: [contractId, keyPrefixHex.base64Encoded, start], service: service)
    }

    /// Finds storage items by contract id and key prefix.
    /// - Parameters:
    ///   - contractId: The contract id
    ///   - keyPrefixHex: The storage key prefix as a hexadecimal string
    /// - Returns: The request object
    public func findStorage(_ contractId: Int, _ keyPrefixHex: String) -> Request<NeoFindStorage, NeoFindStorage.FindStorageResult> {
        return findStorage(contractId, keyPrefixHex, 0)
    }

    /// Finds storage items by native contract name and key prefix.
    /// - Parameters:
    ///   - contractName: The native contract name
    ///   - keyPrefixHex: The storage key prefix as a hexadecimal string
    ///   - start: The start index (default 0)
    /// - Returns: The request object
    public func findStorage(_ contractName: String, _ keyPrefixHex: String, _ start: Int = 0) -> Request<NeoFindStorage, NeoFindStorage.FindStorageResult> {
        return .init(method: "findstorage", params: [contractName, keyPrefixHex.base64Encoded, start], service: service)
    }

    /// Finds storage items by native contract name and key prefix.
    /// - Parameters:
    ///   - contractName: The native contract name
    ///   - keyPrefixHex: The storage key prefix as a hexadecimal string
    /// - Returns: The request object
    public func findStorage(_ contractName: String, _ keyPrefixHex: String) -> Request<NeoFindStorage, NeoFindStorage.FindStorageResult> {
        return findStorage(contractName, keyPrefixHex, 0)
    }
    
    /// Gets the transaction height with the specified transaction hash.
    /// - Parameter txHash: The transaction hash
    /// - Returns: The request object
    public func getTransactionHeight(_ txHash: Hash256) -> Request<NeoGetTransactionHeight, Int> {
        return .init(method: "gettransactionheight", params: [txHash.string], service: service)
    }
    
    /// Gets the validators of the next block.
    /// - Returns: The request object
    public func getNextBlockValidators() -> Request<NeoGetNextBlockValidators, [NeoGetNextBlockValidators.Validator]> {
        return .init(method: "getnextblockvalidators", params: [], service: service)
    }

    /// Gets the candidates list for the next block validators.
    /// - Returns: The request object
    public func getCandidates() -> Request<NeoGetCandidates, [NeoGetNextBlockValidators.Validator]> {
        return .init(method: "getcandidates", params: [], service: service)
    }
    
    /// Gets the public key list of current Neo committee members.
    /// - Returns: The request object
    public func getCommittee() -> Request<NeoGetCommittee, [String]> {
        return .init(method: "getcommittee", params: [], service: service)
    }
    
    // MARK: Node Methods
    
    /// Gets the current number of connections for the node.
    /// - Returns: The request object
    public func getConnectionCount() -> Request<NeoConnectionCount, Int> {
        return .init(method: "getconnectioncount", params: [], service: service)
    }
    
    /// Gets a list of nodes that the node is currently connected or disconnected from.
    /// - Returns: The request object
    public func getPeers() -> Request<NeoGetPeers, NeoGetPeers.Peers> {
        return .init(method: "getpeers", params: [], service: service)
    }
    
    /// Gets the version information of the node.
    /// - Returns: The request object
    public func getVersion() -> Request<NeoGetVersion, NeoGetVersion.NeoVersion> {
        return .init(method: "getversion", params: [], service: service)
    }
    
    /// Broadcasts a transaction over the NEO network.
    /// - Parameter rawTransactionHex: The raw transaction in hexadecimal
    /// - Returns: The request object
    public func sendRawTransaction(_ rawTransactionHex: String) -> Request<NeoSendRawTransaction, NeoSendRawTransaction.RawTransaction> {
        return .init(method: "sendrawtransaction", params: [rawTransactionHex.base64Encoded], service: service)
    }
    
    /// Relays a fully signed contract-parameters context.
    ///
    /// This RPC is available on Neo N3 v3.10.0+ nodes and accepts the context shape produced by ``NeoTransaction/toContractParametersContext()`` or ``sign(_:)``.
    /// - Parameter context: The completed signature context to relay
    /// - Returns: The request object
    public func relay(_ context: ContractParametersContext) -> Request<NeoRelay, NeoRelay.RelayResult> {
        return .init(method: "relay", params: [context], service: service)
    }
    
    /// Broadcasts a new block over the NEO network.
    /// - Parameter serializedBlockAsHex: The block in hexadecimal
    /// - Returns: The request object
    public func submitBlock(_ serializedBlockAsHex: String) -> Request<NeoSubmitBlock, Bool> {
        return .init(method: "submitblock", params: [serializedBlockAsHex], service: service)
    }
    
    // MARK: SmartContract Methods
    
    /// Invokes the function with `functionName` of the smart contract with the specified contract hash.
    /// - Parameters:
    ///   - contractHash: The contract hash to invoke
    ///   - functionName: The function to invoke
    ///   - signers: The signers
    /// - Returns: The request object
    public func invokeFunction(_ contractHash: Hash160, _ functionName: String, _ signers: [Signer]) -> Request<NeoInvokeFunction, InvocationResult> {
        return invokeFunction(contractHash, functionName, [], signers)
    }
    
    /// Invokes the function with `functionName` of the smart contract with the specified contract hash.
    /// - Parameters:
    ///   - contractHash: The contract hash to invoke
    ///   - functionName: The function to invoke
    ///   - contractParams: The parameters of the function
    ///   - signers: The signers
    /// - Returns: The request object
    public func invokeFunction(_ contractHash: Hash160, _ functionName: String, _ contractParams: [ContractParameter], _ signers: [Signer]) -> Request<NeoInvokeFunction, InvocationResult> {
        let signers = signers.map(TransactionSigner.init)
        return .init(method: "invokefunction", params: [contractHash.string, functionName, contractParams, signers], service: service)
    }
    
    /// Invokes the function with `functionName` of the smart contract with the specified contract hash.
    ///
    /// Includes diagnostics from the invocation.
    /// - Parameters:
    ///   - contractHash: The contract hash to invoke
    ///   - functionName: The function to invoke
    ///   - signers: The signers
    /// - Returns: The request object
    public func invokeFunctionDiagnostics(_ contractHash: Hash160, _ functionName: String, _ signers: [Signer]) -> Request<NeoInvokeFunction, InvocationResult> {
        return invokeFunctionDiagnostics(contractHash, functionName, [], signers)
    }
    
    /// Invokes the function with `functionName` of the smart contract with the specified contract hash.
    ///
    /// Includes diagnostics from the invocation.
    /// - Parameters:
    ///   - contractHash: The contract hash to invoke
    ///   - functionName: The function to invoke
    ///   - contractParams: The parameters of the function
    ///   - signers: The signers
    /// - Returns: The request object
    public func invokeFunctionDiagnostics(_ contractHash: Hash160, _ functionName: String, _ params: [ContractParameter], _ signers: [Signer] = []) -> Request<NeoInvokeFunction, InvocationResult> {
        let signers = signers.map(TransactionSigner.init)
        return .init(method: "invokefunction", params: [contractHash.string, functionName, params, signers, true], service: service)
    }
    
    /// Invokes a script.
    /// - Parameters:
    ///   - scriptHex: The script to invoke
    ///   - signers: The signers
    /// - Returns: The request object
    public func invokeScript(_ scriptHex: String, _ signers: [Signer] = []) -> Request<NeoInvokeScript, InvocationResult> {
        let signers = signers.map(TransactionSigner.init)
        return .init(method: "invokescript", params: [scriptHex.base64Encoded, signers], service: service)
    }
    
    /// Invokes a script.
    ///
    /// Includes diagnostics from the invocation.
    /// - Parameters:
    ///   - scriptHex: The script to invoke
    ///   - signers: The signers
    /// - Returns: The request object
    public func invokeScriptDiagnostics(_ scriptHex: String, _ signers: [Signer] = []) -> Request<NeoInvokeScript, InvocationResult> {
        let signers = signers.map(TransactionSigner.init)
        return .init(method: "invokescript", params: [scriptHex.base64Encoded, signers, true], service: service)
    }
    
    /// Returns the results from an iterator.
    ///
    /// The results are limited to `count` items. If `count` is greater than `MaxIteratorResultItems` in the Neo Node's configuration file, this request fails.
    /// - Parameters:
    ///   - sessionId: The session id
    ///   - iteratorId: The iterator id
    ///   - count: The maximal number of stack items returned
    /// - Returns: The request object
    public func traverseIterator(_ sessionId: String, _ iteratorId: String, _ count: Int) -> Request<NeoTraverseIterator, [StackItem]> {
        return .init(method: "traverseiterator", params: [sessionId, iteratorId, count], service: service)
    }
    
    /// Terminates an open session.
    /// - Parameter sessionId: The session id
    /// - Returns: The request object
    public func terminateSession(_ sessionId: String) -> Request<NeoTerminateSession, Bool> {
        return .init(method: "terminatesession", params: [sessionId], service: service)
    }
    
    /// Invokes a contract in verification mode.
    ///
    /// Requires an open wallet on the Neo node that contains the accounts for the signers.
    /// - Parameters:
    ///   - contractHash: The contract hash
    ///   - methodParameters: A list of parameters of the verify function
    ///   - signers: The signers
    /// - Returns: The request object
    public func invokeContractVerify(_ contractHash: Hash160, _ methodParameters: [ContractParameter] = [], _ signers: [Signer] = []) -> Request<NeoInvokeContractVerify, InvocationResult> {
        let signers = signers.map(TransactionSigner.init)
        return .init(method: "invokecontractverify", params: [contractHash.string, methodParameters, signers], service: service)
    }
    
    /// Gets the unclaimed GAS of the account with the specified script hash.
    /// - Parameter scriptHash: The account's script hash
    /// - Returns: The request object
    public func getUnclaimedGas(_ scriptHash: Hash160) -> Request<NeoGetUnclaimedGas, NeoGetUnclaimedGas.GetUnclaimedGas> {
        return .init(method: "getunclaimedgas", params: [address(scriptHash)], service: service)
    }
    
    // MARK: Utilities Methods
    
    /// Gets a list of plugins loaded by the node.
    /// - Returns: The request object
    public func listPlugins() -> Request<NeoListPlugins, [NeoListPlugins.Plugin]> {
        return .init(method: "listplugins", params: [], service: service)
    }
    
    /// Verifies whether the address is a valid NEO address.
    /// - Parameter address: The address to verify
    /// - Returns: The request object
    public func validateAddress(_ address: String) -> Request<NeoValidateAddress, NeoValidateAddress.Result> {
        return .init(method: "validateaddress", params: [address], service: service)
    }
    
    // MARK: Wallet Methods
    
    /// Closes the current wallet.
    /// - Returns: The request object
    public func closeWallet() -> Request<NeoCloseWallet, Bool> {
        return .init(method: "closewallet", params: [], service: service)
    }
    
    /// Exports the private key of the specified script hash.
    /// - Parameter scriptHash: The account's script hash
    /// - Returns: The request object
    public func dumpPrivKey(_ scriptHash: Hash160) -> Request<NeoDumpPrivKey, String> {
        return .init(method: "dumpprivkey", params: [address(scriptHash)], service: service)
    }
    
    /// Signs a message with all standard accounts in the opened wallet.
    ///
    /// This RPC is available on Neo N3 v3.10.0+ nodes.
    /// - Parameters:
    ///   - message: The message to sign
    ///   - avoidSignatureReplay: Whether to sign the replay-protected payload
    /// - Returns: The request object
    public func signMessage(_ message: String, _ avoidSignatureReplay: Bool = false) -> Request<NeoSignMessage, NeoSignMessage.SignatureSet> {
        return .init(method: "signmsg", params: [message, avoidSignatureReplay], service: service)
    }
    
    /// Verifies a message signature generated by ``signMessage(_:_:)``.
    ///
    /// This RPC is available on Neo N3 v3.10.0+ nodes.
    /// - Parameters:
    ///   - message: The original signed message
    ///   - signatureHex: The signature as a hexadecimal string
    ///   - publicKeyHex: The compressed public key as a hexadecimal string
    ///   - saltHex: The salt returned by ``signMessage(_:_:)``
    ///   - avoidSignatureReplay: Whether replay-protected signing was used
    /// - Returns: The request object
    public func verifyMessage(_ message: String, _ signatureHex: String, _ publicKeyHex: String, _ saltHex: String, _ avoidSignatureReplay: Bool = false) -> Request<NeoVerifyMessage, NeoVerifyMessage.Verification> {
        return .init(method: "verifymsg", params: [message, signatureHex, publicKeyHex, saltHex, avoidSignatureReplay], service: service)
    }
    
    /// Signs a contract-parameters context using the opened wallet.
    ///
    /// This RPC is available on Neo N3 v3.10.0+ nodes.
    /// - Parameter context: The incomplete signature context to sign
    /// - Returns: The request object
    public func sign(_ context: ContractParametersContext) -> Request<NeoSign, ContractParametersContext> {
        return .init(method: "sign", params: [context], service: service)
    }
    
    /// Gets the wallet balance of the corresponding token.
    /// - Parameter tokenHash: The token hash
    /// - Returns: The request object
    public func getWalletBalance(_ tokenHash: Hash160) -> Request<NeoGetWalletBalance, NeoGetWalletBalance.Balance> {
        return .init(method: "getwalletbalance", params: [tokenHash.string], service: service)
    }
    
    /// Creates a new address.
    /// - Returns: The request object
    public func getNewAddress() -> Request<NeoGetNewAddress, String> {
        return .init(method: "getnewaddress", params: [], service: service)
    }
    
    /// Gets the amount of unclaimed GAS in the wallet.
    /// - Returns: The request object
    public func getWalletUnclaimedGas() -> Request<NeoGetWalletUnclaimedGas, String> {
        return .init(method: "getwalletunclaimedgas", params: [], service: service)
    }
    
    /// Imports a private key to the wallet.
    /// - Parameter privateKeyInWIF: The private key in WIF-format
    /// - Returns: The request object
    public func importPrivKey(_ privateKeyInWIF: String) -> Request<NeoImportPrivKey, NeoAddress> {
        return .init(method: "importprivkey", params: [privateKeyInWIF], service: service)
    }
    
    /// Calculates the network fee for the specified transaction.
    /// - Parameter transactionHex: The transaction in hexadecimal
    /// - Returns: The request object
    public func calculateNetworkFee(_ transactionHex: String) -> Request<NeoCalculateNetworkFee, NeoNetworkFee> {
        return .init(method: "calculatenetworkfee", params: [transactionHex.base64Encoded], service: service)
    }
    
    /// Lists all the addresses in the current wallet.
    /// - Returns: The request object
    public func listAddress() -> Request<NeoListAddress, [NeoAddress]> {
        return .init(method: "listaddress", params: [], service: service)
    }

    /// Cancels an unconfirmed transaction by creating and relaying a conflicting transaction.
    /// - Parameters:
    ///   - txHash: The hash of the transaction to cancel
    ///   - signers: The signers for the cancellation transaction
    ///   - extraFee: Optional extra network fee as a string
    /// - Returns: The request object
    public func cancelTransaction(_ txHash: Hash256, _ signers: [Hash160], _ extraFee: String? = nil) -> Request<NeoCancelTransaction, Transaction> {
        var params: [AnyHashable] = [txHash.string, signers.map(\.string)]
        if let extraFee = extraFee {
            params.append(extraFee)
        }
        return .init(method: "canceltransaction", params: params, service: service)
    }
    
    /// Opens the specified wallet.
    /// - Parameters:
    ///   - walletPath: The wallet file path
    ///   - password: The password for the wallet
    /// - Returns: The request object
    public func openWallet(_ walletPath: String, _ password: String) -> Request<NeoOpenWallet, Bool> {
        return .init(method: "openwallet", params: [walletPath, password], service: service)
    }
    
    /// Transfers an amount of a token from an account to another account.
    /// - Parameters:
    ///   - tokenHash: The token hash of the NEP-17 contract
    ///   - from: The transferring account's script hash
    ///   - to: The recipient
    ///   - amount: The transfer amount in token fractions
    /// - Returns: The request object
    public func sendFrom(_ tokenHash: Hash160, _ from: Hash160, _ to: Hash160, _ amount: Int) -> Request<NeoSendFrom, Transaction> {
        return .init(method: "sendfrom", params: [tokenHash.string, address(from), address(to), amount], service: service)
    }
    
    /// Transfers an amount of a token from an account to another account.
    /// - Parameters:
    ///   - from: The transferring account's script hash
    ///   - txSendToken: A ``TransactionSendToken`` object containing the token hash, the transferring account's script hash and the transfer amount.
    /// - Returns: The request object
    public func sendFrom(_ from: Hash160, _ txSendToken: TransactionSendToken) throws -> Request<NeoSendFrom, Transaction> {
        return try sendFrom(txSendToken.token, from, scriptHash(from: txSendToken.address), txSendToken.value)
    }
    
    /// Initiates multiple transfers to multiple accounts from the open wallet in a transaction.
    /// - Parameter txSendTokens: a list of ``TransactionSendToken`` objects, that each contains the token hash, the recipient and the transfer amount.
    /// - Returns: The request object
    public func sendMany(_ txSendTokens: [TransactionSendToken]) -> Request<NeoSendMany, Transaction> {
        return .init(method: "sendmany", params: [txSendTokens], service: service)
    }
    
    /// Initiates multiple transfers to multiple accounts from one specific account in a transaction.
    /// - Parameters:
    ///   - from: The transferring account's script hash
    ///   - txSendTokens: a list of ``TransactionSendToken`` objects, that each contains the token hash, the recipient and the transfer amount.
    /// - Returns: The request object
    public func sendMany(_ from: Hash160, _ txSendTokens: [TransactionSendToken]) -> Request<NeoSendMany, Transaction> {
        return .init(method: "sendmany", params: [address(from), txSendTokens], service: service)
    }
    
    /// Transfers an amount of a token to another account.
    /// - Parameters:
    ///   - tokenHash: The token hash of the NEP-17 contract
    ///   - to: The recipient
    ///   - amount: The transfer amount in token fractions
    /// - Returns: The request object
    public func sendToAddress(_ tokenHash: Hash160, _ to: Hash160, _ amount: Int) -> Request<NeoSendToAddress, Transaction> {
        return .init(method: "sendtoaddress", params: [tokenHash.string, address(to), amount], service: service)
    }
    
    /// Transfers an amount of a token asset to another address.
    ///   - txSendToken: A ``TransactionSendToken`` object containing the token hash, the recipient and the transfer amount.
    /// - Returns: The request object
    public func sendToAddress(_ txSendToken: TransactionSendToken) throws -> Request<NeoSendToAddress, Transaction> {
        return try sendToAddress(txSendToken.token, scriptHash(from: txSendToken.address), txSendToken.value)
    }
    
    // MARK: ApplicationLogs
    
    /// Gets the application logs of the specified transaction hash.
    /// - Parameter txHash: The transaction hash
    /// - Returns: The request object
    public func getApplicationLog(_ txHash: Hash256) -> Request<NeoGetApplicationLog, NeoApplicationLog> {
        return .init(method: "getapplicationlog", params: [txHash.string], service: service)
    }
    
    // MARK: TokenTracker NEP-17
    
    /// Gets the balance of all NEP-17 token assets in the specified script hash.
    /// - Parameter scriptHash: The account's script hash
    /// - Returns: The request object
    public func getNep17Balances(_ scriptHash: Hash160) -> Request<NeoGetNep17Balances, NeoGetNep17Balances.Nep17Balances> {
        return .init(method: "getnep17balances", params: [address(scriptHash)], service: service)
    }
    
    /// Gets all the NEP-17 transaction information occurred in the specified script hash.
    /// - Parameter scriptHash: The account's script hash
    /// - Returns: The request object
    public func getNep17Transfers(_ scriptHash: Hash160) -> Request<NeoGetNep17Transfers, NeoGetNep17Transfers.Nep17Transfers> {
        return .init(method: "getnep17transfers", params: [address(scriptHash)], service: service)
    }
    
    /// Gets all the NEP17 transaction information occurred in the specified script hash since the specified time.
    /// - Parameters:
    ///   - scriptHash: The account's script hash
    ///   - from: The timestamp transactions occurred since
    /// - Returns: The request object
    public func getNep17Transfers(_ scriptHash: Hash160, _ from: Date) -> Request<NeoGetNep17Transfers, NeoGetNep17Transfers.Nep17Transfers> {
        return .init(method: "getnep17transfers", params: [address(scriptHash), from.millisecondsSince1970], service: service)
    }
    
    /// Gets all the NEP17 transaction information occurred in the specified script hash in the specified time range.
    /// - Parameters:
    ///   - scriptHash: The account's script hash
    ///   - from: The start timestamp
    ///   - to: The end timestamp
    /// - Returns: The request object
    public func getNep17Transfers(_ scriptHash: Hash160, _ from: Date, _ to: Date) -> Request<NeoGetNep17Transfers, NeoGetNep17Transfers.Nep17Transfers> {
        return .init(method: "getnep17transfers", params: [address(scriptHash), from.millisecondsSince1970, to.millisecondsSince1970], service: service)
    }
    
    // MARK: TokenTracker NEP-11
    
    /// Gets all NEP-11 balances of the specified account.
    /// - Parameter scriptHash: The account's script hash
    /// - Returns: The request object
    public func getNep11Balances(_ scriptHash: Hash160) -> Request<NeoGetNep11Balances, NeoGetNep11Balances.Nep11Balances> {
        return .init(method: "getnep11balances", params: [address(scriptHash)], service: service)
    }
    
    /// Gets all NEP-11 transaction of the given account.
    /// - Parameter scriptHash: The account's script hash
    /// - Returns: The request object
    public func getNep11Transfers(_ scriptHash: Hash160) -> Request<NeoGetNep11Transfers, NeoGetNep11Transfers.Nep11Transfers> {
        return .init(method: "getnep11transfers", params: [address(scriptHash)], service: service)
    }
    
    /// Gets all NEP-11 transaction of the given account since the given time.
    /// - Parameters:
    ///   - scriptHash: The account's script hash
    ///   - from: The date from when to report transactions
    /// - Returns: The request object
    public func getNep11Transfers(_ scriptHash: Hash160, _ from: Date) -> Request<NeoGetNep11Transfers, NeoGetNep11Transfers.Nep11Transfers> {
        return .init(method: "getnep11transfers", params: [address(scriptHash), from.millisecondsSince1970], service: service)
    }
    
    /// Gets all NEP-11 transactions of the given account in the time span between `from` and `to`.
    /// - Parameters:
    ///   - scriptHash: The account's script hash
    ///   - from: The start timestamp
    ///   - to: The end timestamp
    /// - Returns: The request object
    public func getNep11Transfers(_ scriptHash: Hash160, _ from: Date, _ to: Date) -> Request<NeoGetNep11Transfers, NeoGetNep11Transfers.Nep11Transfers> {
        return .init(method: "getnep11transfers", params: [address(scriptHash), from.millisecondsSince1970, to.millisecondsSince1970], service: service)
    }
    
    /// Gets the properties of the token with `tokenId` from the NEP-11 contract with `scriptHash`.
    ///
    /// The properties are a mapping from the property name string to the value string.
    /// The value is plain text if the key is one of the properties defined in the NEP-11 standard.
    /// Otherwise, the value is a Base64-encoded byte array.
    ///
    /// To receive custom property values that consist of nested types (e.g., Maps or Arrays) use ``invokeFunction(_:_:_:)``  to directly invoke the method `properties` of the NEP-11 smart contract.
    /// - Parameters:
    ///   - scriptHash: The account's script hash
    ///   - tokenId: The ID of the token as a hexadecimal string
    /// - Returns: The request object
    public func getNep11Properties(_ scriptHash: Hash160, _ tokenId: String) -> Request<NeoGetNep11Properties, [String : String]> {
        return .init(method: "getnep11properties", params: [address(scriptHash), tokenId], service: service)
    }
    
    // MARK: StateService
    
    /// Gets the state root by the block height.
    /// - Parameter blockIndex: The block index
    /// - Returns: The request object
    public func getStateRoot(_ blockIndex: Int) -> Request<NeoGetStateRoot, NeoGetStateRoot.StateRoot> {
        return .init(method: "getstateroot", params: [blockIndex], service: service)
    }
    
    /// Gets the proof based on the root hash, the contract hash and the storage key.
    /// - Parameters:
    ///   - rootHash: The root hash
    ///   - contractHash: The contract hash
    ///   - storageKeyHex: The storage key
    /// - Returns: The request object
    public func getProof(_ rootHash: Hash256, _ contractHash: Hash160, _ storageKeyHex: String) -> Request<NeoGetProof, String> {
        return .init(method: "getproof", params: [rootHash.string, contractHash.string, storageKeyHex.base64Encoded], service: service)
    }
    
    /// Verifies the proof data and gets the value of the storage corresponding to the key.
    /// - Parameters:
    ///   - rootHash: The root hash
    ///   - proofDataHex: The proof data of the state root
    /// - Returns: The request object
    public func verifyProof(_ rootHash: Hash256, _ proofDataHex: String) -> Request<NeoVerifyProof, String> {
        return .init(method: "verifyproof", params: [rootHash.string, proofDataHex.base64Encoded], service: service)
    }
    
    /// Gets the state root height.
    /// - Returns: The request object
    public func getStateHeight() -> Request<NeoGetStateHeight, NeoGetStateHeight.StateHeight> {
        return .init(method: "getstateheight", params: [], service: service)
    }
    
    /// Gets the state.
    /// - Parameters:
    ///   - rootHash: The root hash
    ///   - contractHash: The contract hash
    ///   - keyHex: The storage key
    /// - Returns: The request object
    public func getState(_ rootHash: Hash256, _ contractHash: Hash160, _ keyHex: String) -> Request<NeoGetState, String> {
        return .init(method: "getstate", params: [rootHash.string, contractHash.string, keyHex.base64Encoded], service: service)
    }
    
    /// Gets a list of states that match the provided key prefix.
    ///
    /// Includes proofs of the first and last entry.
    /// - Parameters:
    ///   - rootHash: The root hash
    ///   - contractHash: The contact hash
    ///   - keyPrefixHex: The key prefix
    ///   - startKeyHex: The start key
    ///   - countFindResultItems: The number of results. An upper limit is defined in the Neo core
    /// - Returns: The request object
    public func findStates(_ rootHash: Hash256, _ contractHash: Hash160, _ keyPrefixHex: String, _ startKeyHex: String?, _ countFindResultItems: Int?) -> Request<NeoFindStates, NeoFindStates.States> {
        var parameters: [AnyHashable] = [rootHash.string, contractHash.string, keyPrefixHex.base64Encoded]
        if let startKeyHex = startKeyHex {
            parameters.append(startKeyHex.base64Encoded)
        }
        if let countFindResultItems = countFindResultItems {
            if startKeyHex == nil { parameters.append("") }
            parameters.append(countFindResultItems)
        }
        return .init(method: "findstates", params: parameters, service: service)
    }
    
    /// Gets a list of states that match the provided key prefix.
    ///
    /// Includes proofs of the first and last entry.
    /// - Parameters:
    ///   - rootHash: The root hash
    ///   - contractHash: The contract hash
    ///   - keyPrefixHex: The key prefix
    ///   - startKeyHex: The start key
    /// - Returns: The request object
    public func findStates(_ rootHash: Hash256, _ contractHash: Hash160, _ keyPrefixHex: String, _ startKeyHex: String?) -> Request<NeoFindStates, NeoFindStates.States> {
        findStates(rootHash, contractHash, keyPrefixHex, startKeyHex, nil)
    }
    
    /// Gets a list of states that match the provided key prefix.
    ///
    /// Includes proofs of the first and last entry.
    /// - Parameters:
    ///   - rootHash: The root hash
    ///   - contractHash: The contract hash
    ///   - keyPrefixHex: The key prefix
    ///   - countFindResultItems: The number of results. An upper limit is defined in the Neo core
    /// - Returns: The request object
    public func findStates(_ rootHash: Hash256, _ contractHash: Hash160, _ keyPrefixHex: String, _ countFindResultItems: Int?) -> Request<NeoFindStates, NeoFindStates.States> {
        findStates(rootHash, contractHash, keyPrefixHex, nil, countFindResultItems)
    }
    
    /// Gets a list of states that match the provided key prefix.
    ///
    /// Includes proofs of the first and last entry.
    /// - Parameters:
    ///   - rootHash: The root hash
    ///   - contractHash: The contract hash
    ///   - keyPrefixHex: The key prefix
    /// - Returns: The request object
    public func findStates(_ rootHash: Hash256, _ contractHash: Hash160, _ keyPrefixHex: String) -> Request<NeoFindStates, NeoFindStates.States> {
        findStates(rootHash, contractHash, keyPrefixHex, nil, nil)
    }
    
    // MARK: DeferredRelay
    
    /// Gets the DeferredRelay plugin queue for transactions rejected as not yet valid.
    ///
    /// This RPC is available when the Neo N3 v3.10.0+ DeferredRelay plugin is enabled.
    /// - Returns: The request object
    public func getPendingValidUntilRelay() -> Request<NeoGetPendingValidUntilRelay, NeoGetPendingValidUntilRelay.PendingState> {
        return .init(method: "getpendingvaliduntilrelay", params: [], service: service)
    }
    
    /// Gets a queued DeferredRelay transaction as a base64-encoded raw transaction.
    ///
    /// This RPC is available when the Neo N3 v3.10.0+ DeferredRelay plugin is enabled.
    /// - Parameter txHash: The transaction hash
    /// - Returns: The request object
    public func getRawPendingTransaction(_ txHash: Hash256) -> Request<NeoGetRawPendingTransaction, String> {
        return .init(method: "getrawpendingtx", params: [txHash.string, false], service: service)
    }
    
    /// Gets a queued DeferredRelay transaction as a verbose transaction object.
    ///
    /// This RPC is available when the Neo N3 v3.10.0+ DeferredRelay plugin is enabled.
    /// - Parameter txHash: The transaction hash
    /// - Returns: The request object
    public func getPendingTransaction(_ txHash: Hash256) -> Request<NeoGetPendingTransaction, Transaction> {
        return .init(method: "getrawpendingtx", params: [txHash.string, true], service: service)
    }

#if canImport(Combine)
    // MARK: NeoRx
    
    public func blockPublisher(_ fullTransactionObjects: Bool) -> AnyPublisher<NeoGetBlock, Error> {
        return rpcEventClient.blockPublisher(fullTransactionObjects, config.pollingInterval)
    }
    
    public func replayBlocksPublisher(_ startBlock: Int, _ endBlock: Int, _ fullTransactionObjects: Bool) -> AnyPublisher<NeoGetBlock, Error> {
        return rpcEventClient.replayBlocksPublisher(startBlock, endBlock, fullTransactionObjects, true)
    }
    
    public func replayBlocksPublisher(_ startBlock: Int, _ endBlock: Int, _ fullTransactionObjects: Bool, _ ascending: Bool) -> AnyPublisher<NeoGetBlock, Error> {
        return rpcEventClient.replayBlocksPublisher(startBlock, endBlock, fullTransactionObjects, ascending)
    }
    
    public func catchUpToLatestBlockPublisher(_ startBlock: Int, _ fullTransactionObjects: Bool) -> AnyPublisher<NeoGetBlock, Error> {
        return rpcEventClient.catchUpToLatestBlockPublisher(startBlock, fullTransactionObjects, onCaughtUpPublisher: .init(Empty()))
    }
    
    public func catchUpToLatestAndSubscribeToNewBlocksPublisher(_ startBlock: Int, _ fullTransactionObjects: Bool) -> AnyPublisher<NeoGetBlock, Error> {
        return rpcEventClient.catchUpToLatestAndSubscribeToNewBlocksPublisher(startBlock, fullTransactionObjects, config.pollingInterval)
    }
    
    public func subscribeToNewBlocksPublisher(_ fullTransactionObjects: Bool) -> AnyPublisher<NeoGetBlock, Error> {
        return rpcEventClient.blockPublisher(fullTransactionObjects, config.pollingInterval)
    }
#endif
        
}

#if canImport(Combine)
extension NeoRpcClient: NeoRx {}
#endif
