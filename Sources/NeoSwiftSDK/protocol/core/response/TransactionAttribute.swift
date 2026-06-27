
import BigInt

public enum TransactionAttribute: ByteEnum, CaseIterable {
    
    static let MAX_RESULT_SIZE: Int = 0xffff
    
    public static var allCases: [TransactionAttribute] = [
        .highPriority,
        .oracleResponse(0, .error, ""),
        .notValidBefore(0),
        .conflicts(.ZERO),
        .notaryAssisted(0)
    ]
    
    case highPriority
    case oracleResponse(_ id: Int, _ responseCode: OracleResponseCode, _ result: String)
    case notValidBefore(_ height: Int)
    case conflicts(_ hash: Hash256)
    case notaryAssisted(_ nKeys: Int)
    
    public var jsonValue: String {
        switch self {
        case .highPriority: return "HighPriority"
        case .oracleResponse: return "OracleResponse"
        case .notValidBefore: return "NotValidBefore"
        case .conflicts: return "Conflicts"
        case .notaryAssisted: return "NotaryAssisted"
        }
    }
    
    public var byte: Byte {
        switch self {
        case .highPriority: return 0x01
        case .oracleResponse: return 0x11
        case .notValidBefore: return 0x20
        case .conflicts: return 0x21
        case .notaryAssisted: return 0x22
        }
    }

    public var allowsMultiple: Bool {
        if case .conflicts = self { return true }
        return false
    }
    
}

extension TransactionAttribute: Codable {
    
    public init(from decoder: Decoder) throws {
        if let container = try? decoder.container(keyedBy: CodingKeys.self),
           let typeString = try? container.decode(String.self, forKey: .type),
           let type = TransactionAttribute.fromJsonValue(typeString) {
            switch type {
            case .highPriority: self = .highPriority
            case .oracleResponse:
                let id = try container.decode(SafeDecode<Int>.self, forKey: .id).value
                let responseCode = try container.decode(OracleResponseCode.self, forKey: .code)
                let result = try container.decode(String.self, forKey: .result)
                self = .oracleResponse(id, responseCode, result)
            case .notValidBefore:
                let height = try container.decode(SafeDecode<Int>.self, forKey: .height).value
                self = .notValidBefore(height)
            case .conflicts:
                let hash = try container.decode(Hash256.self, forKey: .hash)
                self = .conflicts(hash)
            case .notaryAssisted:
                let nKeys = try container.decode(SafeDecode<Int>.self, forKey: .nKeys).value
                self = .notaryAssisted(nKeys)
            }
            return
        }

        let singleValue = try decoder.singleValueContainer()
        let typeString = try singleValue.decode(String.self)
        guard let type = TransactionAttribute.fromJsonValue(typeString) else {
            throw NeoError.illegalArgument("\(String(describing: TransactionAttribute.self)) value type not found")
        }
        if case .highPriority = type {
            self = .highPriority
            return
        }
        throw NeoError.illegalArgument("TransactionAttribute requires an object payload for \(type.jsonValue).")
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(jsonValue, forKey: .type)
        switch self {
        case .highPriority:
            break
        case .oracleResponse(let id, let responseCode, let result):
            try container.encode(id, forKey: .id)
            try container.encode(responseCode, forKey: .code)
            try container.encode(result, forKey: .result)
        case .notValidBefore(let height):
            try container.encode(height, forKey: .height)
        case .conflicts(let hash):
            try container.encode(hash, forKey: .hash)
        case .notaryAssisted(let nKeys):
            try container.encode(nKeys, forKey: .nKeys)
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case type, id, code, result, height, hash
        case nKeys = "nkeys"
    }
    
}

extension TransactionAttribute: NeoSerializable {
    
    public var size: Int {
        switch self {
        case .highPriority: return 1
        case .oracleResponse(_, _, let result):
            return 1 + 9 + result.varSize
        case .notValidBefore: return 1 + 4
        case .conflicts: return 1 + NeoConstants.HASH256_SIZE
        case .notaryAssisted: return 1 + 1
        }
    }
    
    public func serialize(_ writer: BinaryWriter) {
        writer.writeByte(byte)
        switch self {
        case .oracleResponse(let id, let responseCode, let result):
            writer.writeInt64(Int64(id))
            writer.writeByte(responseCode.byte)
            writer.writeVarBytes(result.base64Decoded)
        case .notValidBefore(let height):
            writer.writeUInt32(UInt32(height))
        case .conflicts(let hash):
            writer.writeSerializableFixed(hash)
        case .notaryAssisted(let nKeys):
            writer.writeByte(Byte(nKeys))
        case .highPriority:
            break
        }
    }
    
    public static func deserialize(_ reader: BinaryReader) throws -> TransactionAttribute {
        guard let type = TransactionAttribute.valueOf(reader.readByte()) else {
            throw NeoError.deserialization("The deserialized type does not match the type information in the serialized data.")
        }
        switch type {
        case .highPriority:
            return .highPriority
        case .oracleResponse:
            let id = try BInt(magnitude: reader.readBytes(8).reversed()).asInt()!
            let code = try OracleResponseCode.throwingValueOf(reader.readByte())
            let result = try reader.readVarBytes(MAX_RESULT_SIZE).base64Encoded
            return .oracleResponse(id, code, result)
        case .notValidBefore:
            let height = Int(reader.readUInt32())
            return .notValidBefore(height)
        case .conflicts:
            let hash = try Hash256.deserialize(reader)
            return .conflicts(hash)
        case .notaryAssisted:
            let nKeys = Int(reader.readByte())
            return .notaryAssisted(nKeys)
        }
    }
    
}
