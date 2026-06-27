public class NeoSignMessage: Response<NeoSignMessage.SignatureSet> {
    
    public var signMessage: SignatureSet? {
        return result
    }
    
    public struct SignatureSet: Codable, Hashable {
        
        public let curve: String
        public let algorithm: String
        public let mode: String
        public let payload: String
        public let signatures: [Signature]
        
        public init(curve: String, algorithm: String, mode: String, payload: String, signatures: [Signature]) {
            self.curve = curve
            self.algorithm = algorithm
            self.mode = mode
            self.payload = payload
            self.signatures = signatures
        }
        
    }
    
    public struct Signature: Codable, Hashable {
        
        public let address: String
        public let publicKey: String
        public let signature: String
        public let salt: String
        
        public init(address: String, publicKey: String, signature: String, salt: String) {
            self.address = address
            self.publicKey = publicKey
            self.signature = signature
            self.salt = salt
        }
        
        enum CodingKeys: String, CodingKey {
            case address, signature, salt
            case publicKey = "publickey"
        }
        
    }
    
}

public class NeoVerifyMessage: Response<NeoVerifyMessage.Verification> {
    
    public var verifyMessage: Verification? {
        return result
    }
    
    public struct Verification: Codable, Hashable {
        
        public let address: String
        public let publicKey: String
        public let signature: String
        public let salt: String
        public let status: String
        
        public var isValid: Bool {
            return status == "Valid"
        }
        
        public init(address: String, publicKey: String, signature: String, salt: String, status: String) {
            self.address = address
            self.publicKey = publicKey
            self.signature = signature
            self.salt = salt
            self.status = status
        }
        
        enum CodingKeys: String, CodingKey {
            case address, signature, salt, status
            case publicKey = "publickey"
        }
        
    }
    
}

public class NeoSign: Response<ContractParametersContext> {
    
    public var signedContext: ContractParametersContext? {
        return result
    }
    
}

public class NeoRelay: Response<NeoRelay.RelayResult> {
    
    public var relay: RelayResult? {
        return result
    }
    
    public struct RelayResult: Codable, Hashable {
        
        public let hash: Hash256
        
        public init(hash: Hash256) {
            self.hash = hash
        }
        
    }
    
}

public class NeoGetPendingValidUntilRelay: Response<NeoGetPendingValidUntilRelay.PendingState> {
    
    public var pendingState: PendingState? {
        return result
    }
    
    public struct PendingState: Codable, Hashable {
        
        public let height: Int
        public let maxValidUntilBlockIncrement: Int
        public let pending: [PendingTransaction]
        public let enabled: Bool
        public let pendingCheckFrequency: Int
        public let pendingRelayMaxTransactions: Int
        public let count: Int
        
        public init(height: Int, maxValidUntilBlockIncrement: Int, pending: [PendingTransaction], enabled: Bool, pendingCheckFrequency: Int, pendingRelayMaxTransactions: Int, count: Int) {
            self.height = height
            self.maxValidUntilBlockIncrement = maxValidUntilBlockIncrement
            self.pending = pending
            self.enabled = enabled
            self.pendingCheckFrequency = pendingCheckFrequency
            self.pendingRelayMaxTransactions = pendingRelayMaxTransactions
            self.count = count
        }
        
        enum CodingKeys: String, CodingKey {
            case height, pending, enabled, count
            case maxValidUntilBlockIncrement = "maxvaliduntilblockincrement"
            case pendingCheckFrequency = "pendingcheckfrequency"
            case pendingRelayMaxTransactions = "pendingrelaymaxtransactions"
        }
        
    }
    
    public struct PendingTransaction: Codable, Hashable {
        
        public let hash: Hash256
        public let validUntilBlock: Int
        public let size: Int
        public let blocksUntilDeadline: Int?
        
        public init(hash: Hash256, validUntilBlock: Int, size: Int, blocksUntilDeadline: Int?) {
            self.hash = hash
            self.validUntilBlock = validUntilBlock
            self.size = size
            self.blocksUntilDeadline = blocksUntilDeadline
        }
        
        enum CodingKeys: String, CodingKey {
            case hash, size
            case validUntilBlock = "validuntilblock"
            case blocksUntilDeadline = "blocksuntildeadline"
        }
        
    }
    
}

public class NeoGetRawPendingTransaction: Response<String> {
    
    public var rawPendingTransaction: String? {
        return result
    }
    
}

public class NeoGetPendingTransaction: Response<Transaction> {
    
    public var pendingTransaction: Transaction? {
        return result
    }
    
}
