import BigInt

public class NeoGetNextBlockValidators: Response<[NeoGetNextBlockValidators.Validator]> {
    
    public var nextBlockValidators: [Validator]? {
        return result
    }
    
    public struct Validator: Codable, Hashable {
        
        public let publicKey: String
        public let votes: String
        public let active: Bool
        
        public init(publicKey: String, votes: String, active: Bool) {
            self.publicKey = publicKey
            self.votes = votes
            self.active = active
        }
        
        enum CodingKeys: String, CodingKey {
            case votes, active
            case publicKey = "publickey"
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            publicKey = try container.decode(String.self, forKey: .publicKey)
            let voteValue = try container.decode(SafeDecode<BInt>.self, forKey: .votes).value
            votes = voteValue.asString()
            active = try container.decodeIfPresent(Bool.self, forKey: .active) ?? false
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(publicKey, forKey: .publicKey)
            try container.encode(votes, forKey: .votes)
            try container.encode(active, forKey: .active)
        }
        
    }
    
}
