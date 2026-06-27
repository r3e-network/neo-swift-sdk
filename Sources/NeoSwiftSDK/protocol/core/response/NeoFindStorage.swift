
public class NeoFindStorage: Response<NeoFindStorage.FindStorageResult> {

    public var findStorage: FindStorageResult? {
        return result
    }

    public struct FindStorageResult: Codable, Hashable {

        public let truncated: Bool
        public let next: Int
        public let results: [ContractStorageEntry]

        public init(truncated: Bool, next: Int, results: [ContractStorageEntry]) {
            self.truncated = truncated
            self.next = next
            self.results = results
        }

        enum CodingKeys: String, CodingKey {
            case truncated, next, results
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            truncated = try container.decode(Bool.self, forKey: .truncated)
            next = try container.decode(SafeDecode<Int>.self, forKey: .next).value
            results = try container.decode([ContractStorageEntry].self, forKey: .results)
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(truncated, forKey: .truncated)
            try container.encode(next, forKey: .next)
            try container.encode(results, forKey: .results)
        }

    }

}
