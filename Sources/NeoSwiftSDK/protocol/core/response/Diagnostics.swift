
public struct Diagnostics: Codable, Hashable {
    
    public let invokedContracts: InvokedContract
    public let storageChanges: [StorageChange]
    public let traces: Trace?
    
    public init(invokedContracts: InvokedContract, storageChanges: [StorageChange] = [], traces: Trace? = nil) {
        self.invokedContracts = invokedContracts
        self.storageChanges = storageChanges
        self.traces = traces
    }
    
    enum CodingKeys: String, CodingKey {
        case invokedContracts = "invokedcontracts"
        case storageChanges = "storagechanges"
        case traces
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        invokedContracts = try container.decode(InvokedContract.self, forKey: .invokedContracts)
        storageChanges = try container.decodeIfPresent([StorageChange].self, forKey: .storageChanges) ?? []
        traces = try container.decodeIfPresent(Trace.self, forKey: .traces)
    }
    
    public struct InvokedContract: Codable, Hashable {
        
        public let hash: Hash160
        public let invokedContracts: [InvokedContract]?
        
        public init(hash: Hash160, invokedContracts: [InvokedContract]?) {
            self.hash = hash
            self.invokedContracts = invokedContracts
        }
        
        enum CodingKeys: String, CodingKey {
            case hash, invokedContracts = "call"
        }
        
    }
    
    public struct Trace: Codable, Hashable {
        
        public let type: String
        public let hash: Hash160?
        public let method: String?
        public let args: [StackItem]?
        public let returnValue: StackItem?
        public let isNative: Bool?
        public let calls: [Trace]?
        
        public init(type: String, hash: Hash160? = nil, method: String? = nil, args: [StackItem]? = nil, returnValue: StackItem? = nil, isNative: Bool? = nil, calls: [Trace]? = nil) {
            self.type = type
            self.hash = hash
            self.method = method
            self.args = args
            self.returnValue = returnValue
            self.isNative = isNative
            self.calls = calls
        }
        
        enum CodingKeys: String, CodingKey {
            case type, hash, method, args, isNative, calls
            case returnValue = "return"
        }
        
    }
    
    public struct StorageChange: Codable, Hashable {
        
        public let state: String
        public let key: String
        public let value: String
        
        public init(state: String, key: String, value: String) {
            self.state = state
            self.key = key
            self.value = value
        }
        
    }
    
}
