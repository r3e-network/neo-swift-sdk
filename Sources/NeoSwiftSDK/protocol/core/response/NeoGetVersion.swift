import BigInt

public class NeoGetVersion: Response<NeoGetVersion.NeoVersion> {
    
    public var version: NeoVersion? {
        return result
    }
    
    public struct NeoVersion: Codable, Hashable {
        
        public let tcpPort: Int?
        public let wsPort: Int?
        public let nonce: Int
        public let userAgent: String
        public let rpc: NeoRpc?
        public let `protocol`: NeoProtocol?
        
        public init(tcpPort: Int?, wsPort: Int?, nonce: Int, userAgent: String, rpc: NeoRpc? = nil, neoProtocol: NeoProtocol) {
            self.tcpPort = tcpPort
            self.wsPort = wsPort
            self.nonce = nonce
            self.userAgent = userAgent
            self.rpc = rpc
            self.protocol = neoProtocol
        }
        
        enum CodingKeys: String, CodingKey {
            case nonce, rpc, `protocol`
            case tcpPort = "tcpport"
            case wsPort = "wsport"
            case userAgent = "useragent"
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            tcpPort = try container.decodeIfPresent(SafeDecode<Int>.self, forKey: .tcpPort)?.value
            wsPort = try container.decodeIfPresent(SafeDecode<Int>.self, forKey: .wsPort)?.value
            nonce = try container.decode(SafeDecode<Int>.self, forKey: .nonce).value
            userAgent = try container.decode(String.self, forKey: .userAgent)
            rpc = try container.decodeIfPresent(NeoRpc.self, forKey: .rpc)
            `protocol` = try container.decodeIfPresent(NeoProtocol.self, forKey: .protocol)
        }
        
        public struct NeoRpc: Codable, Hashable {
            
            public let maxIteratorResultItems: Int
            public let sessionEnabled: Bool
            
            public init(maxIteratorResultItems: Int, sessionEnabled: Bool) {
                self.maxIteratorResultItems = maxIteratorResultItems
                self.sessionEnabled = sessionEnabled
            }
            
            enum CodingKeys: String, CodingKey {
                case maxIteratorResultItems = "maxiteratorresultitems"
                case sessionEnabled = "sessionenabled"
            }

            public init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                maxIteratorResultItems = try container.decode(SafeDecode<Int>.self, forKey: .maxIteratorResultItems).value
                sessionEnabled = try container.decode(Bool.self, forKey: .sessionEnabled)
            }
            
        }
        
        public struct NeoProtocol: Codable, Hashable {
            
            public let network: Int
            public let validatorsCount: Int?
            public let msPerBlock: Int
            public let maxValidUntilBlockIncrement: Int
            public let maxTraceableBlocks: Int
            public let addressVersion: Int
            public let maxTransactionsPerBlock: Int
            public let memoryPoolMaxTransactions: Int
            public let initialGasDistribution: UInt64
            public let hardforks: [Hardfork]?
            public let standbyCommittee: [String]?
            public let seedList: [String]?
            
            public init(network: Int, validatorsCount: Int?, msPerBlock: Int, maxValidUntilBlockIncrement: Int, maxTraceableBlocks: Int, addressVersion: Int, maxTransactionsPerBlock: Int, memoryPoolMaxTransactions: Int, initialGasDistribution: UInt64, hardforks: [Hardfork]? = nil, standbyCommittee: [String]? = nil, seedList: [String]? = nil) {
                self.network = network
                self.validatorsCount = validatorsCount
                self.msPerBlock = msPerBlock
                self.maxValidUntilBlockIncrement = maxValidUntilBlockIncrement
                self.maxTraceableBlocks = maxTraceableBlocks
                self.addressVersion = addressVersion
                self.maxTransactionsPerBlock = maxTransactionsPerBlock
                self.memoryPoolMaxTransactions = memoryPoolMaxTransactions
                self.initialGasDistribution = initialGasDistribution
                self.hardforks = hardforks
                self.standbyCommittee = standbyCommittee
                self.seedList = seedList
            }
            
            enum CodingKeys: String, CodingKey {
                case network
                case validatorsCount = "validatorscount"
                case msPerBlock = "msperblock"
                case maxValidUntilBlockIncrement = "maxvaliduntilblockincrement"
                case maxTraceableBlocks = "maxtraceableblocks"
                case addressVersion = "addressversion"
                case maxTransactionsPerBlock = "maxtransactionsperblock"
                case memoryPoolMaxTransactions = "memorypoolmaxtransactions"
                case initialGasDistribution = "initialgasdistribution"
                case hardforks
                case standbyCommittee = "standbycommittee"
                case seedList = "seedlist"
            }

            public init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                network = try container.decode(SafeDecode<Int>.self, forKey: .network).value
                validatorsCount = try container.decodeIfPresent(SafeDecode<Int>.self, forKey: .validatorsCount)?.value
                msPerBlock = try container.decode(SafeDecode<Int>.self, forKey: .msPerBlock).value
                maxValidUntilBlockIncrement = try container.decode(SafeDecode<Int>.self, forKey: .maxValidUntilBlockIncrement).value
                maxTraceableBlocks = try container.decode(SafeDecode<Int>.self, forKey: .maxTraceableBlocks).value
                addressVersion = try container.decode(SafeDecode<Int>.self, forKey: .addressVersion).value
                maxTransactionsPerBlock = try container.decode(SafeDecode<Int>.self, forKey: .maxTransactionsPerBlock).value
                memoryPoolMaxTransactions = try container.decode(SafeDecode<Int>.self, forKey: .memoryPoolMaxTransactions).value
                initialGasDistribution = try container.decode(SafeDecode<UInt64>.self, forKey: .initialGasDistribution).value
                hardforks = try container.decodeIfPresent([Hardfork].self, forKey: .hardforks)
                standbyCommittee = try container.decodeIfPresent([String].self, forKey: .standbyCommittee)
                seedList = try container.decodeIfPresent([String].self, forKey: .seedList)
            }
            
            public struct Hardfork: Codable, Hashable {
                
                public let name: String
                public let blockHeight: Int
                
                public init(name: String, blockHeight: Int) {
                    self.name = name
                    self.blockHeight = blockHeight
                }
                
                enum CodingKeys: String, CodingKey {
                    case name
                    case blockHeight = "blockheight"
                }

                public init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    name = try container.decode(String.self, forKey: .name)
                    blockHeight = try container.decode(SafeDecode<Int>.self, forKey: .blockHeight).value
                }
                
            }
            
        }
        
    }
    
}
