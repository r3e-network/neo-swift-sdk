
/// JSON-RPC 2.0 factory implementation specific to Neo-express nodes.
public class NeoExpressClient: NeoRpcClient, NeoExpress {
    
    public func expressGetPopulatedBlocks() -> Request<NeoExpressGetPopulatedBlocks, PopulatedBlocks> {
        return .init(method: "expressgetpopulatedblocks", params: [], service: service)
    }
    
    /// Gets all deployed contracts that follow the NEP-17 standard.
    ///
    /// Can only be used on a Neo-express node.
    /// - Returns: The request object
    public func expressGetNep17Contracts() -> Request<NeoExpressGetNep17Contracts, [Nep17Contract]> {
        return .init(method: "expressgetnep17contracts", params: [], service: service)
    }
    
    /// Gets the contract storage.
    ///
    /// Can only be used on a Neo-express node.
    /// - Parameter contractHash: The contract hash
    /// - Returns: The request object
    public func expressGetContractStorage(_ contractHash: Hash160) -> Request<NeoExpressGetContractStorage, [ContractStorageEntry]> {
        return .init(method: "expressgetcontractstorage", params: [contractHash.string], service: service)
    }
    
    /// Gets a list of all deployed contracts.
    ///
    /// Can only be used on a Neo-express node.
    /// - Returns: The request object
    public func expressListContracts() -> Request<NeoExpressListContracts, [ExpressContractState]> {
        return .init(method: "expresslistcontracts", params: [], service: service)
    }
    
    /// Creates a checkpoint of the Neo-express node and writes it to a file in the root of the Neo-express instance.
    ///
    /// Can only be used on a Neo-express node.
    /// - Parameter filename: The filename of the checkpoint file
    /// - Returns: The request object
    public func expressCreateCheckpoint(_ filename: String) -> Request<NeoExpressCreateCheckpoint, String> {
        return .init(method: "expresscreatecheckpoint", params: [filename], service: service)
    }
    
    /// Gets a list of all current oracle requests.
    ///
    /// Can only be used on a Neo-express node.
    /// - Returns: The request object
    public func expressListOracleRequests() -> Request<NeoExpressListOracleRequests, [OracleRequest]> {
        return .init(method: "expresslistoraclerequests", params: [], service: service)
    }
    
    /// Creates an oracle response transaction.
    ///
    /// Can only be used on a Neo-express node.
    /// - Parameter oracleResponse: The oracle response object
    /// - Returns: The request object
    public func expressCreateOracleResponseTx(_ oracleResponse: TransactionAttribute) -> Request<NeoExpressCreateOracleResponseTx, String> {
        return .init(method: "expresscreateoracleresponsetx", params: [oracleResponse], service: service)
    }
    
    /// Shuts down the neo-express instance.
    ///
    /// Can only be used on a Neo-express node.
    /// - Returns: The request object
    public func expressShutdown() -> Request<NeoExpressShutdown, ExpressShutdown> {
        return .init(method: "expressshutdown", params: [], service: service)
    }
    
}
