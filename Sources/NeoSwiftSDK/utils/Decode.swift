import BigInt
import Foundation

public protocol StringDecodable {
    init(string: String) throws
    var string: String { get }
}

extension StringDecodable {
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        try self.init(string: string)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(string)
    }
    
}

public class SafeDecode<T: StringDecodable & Codable>: Codable {
    
    let value: T
    
    init(_ value: T) {
        self.value = value
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let value = try? container.decode(T.self) { self.value = value }
        else {
            let string = try container.decode(String.self)
            let value = try T(string: string)
            self.value = value
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value.string)
    }
    
}

@propertyWrapper
public struct StringDecode<T: StringDecodable & Codable & Hashable>: Codable, Hashable {
    
    public var wrappedValue: T
    
    public init(wrappedValue: T) {
        self.wrappedValue = wrappedValue
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.wrappedValue = try container.decode(SafeDecode<T>.self).value
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.wrappedValue)
    }
    
}


extension Bool: StringDecodable {
    
    public init(string: String) throws {
        guard let bool = Bool(string) else {
            throw NeoError.illegalArgument("Unable to decode Bool from JSON string '\(string)'")
        }
        self = bool
    }
    
    public var string: String {
        return String(describing: self)
    }
    
}

extension BInt: StringDecodable, @retroactive Decodable, @retroactive Encodable {
    
    public init(string: String) throws {
        guard let bInt = BInt(string) else {
            throw NeoError.illegalArgument("Unable to decode BigInt from JSON string '\(string)'")
        }
        self = bInt
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let int = try? container.decode(Int.self) {
            self = BInt(int)
        } else {
            self = try BInt(string: container.decode(String.self))
        }
    }
    
    public var string: String {
        asString()
    }
    
}

extension Int: StringDecodable {
    
    public init(string: String) throws {
        guard let int = Int(string) else {
            throw NeoError.illegalArgument("Unable to decode Int from JSON string '\(string)'")
        }
        self = int
    }
    
    public var string: String {
        return String(self)
    }
    
}

extension UInt64: StringDecodable {

    public init(string: String) throws {
        guard let uint = UInt64(string) else {
            throw NeoError.illegalArgument("Unable to decode UInt64 from JSON string '\(string)'")
        }
        self = uint
    }

    public var string: String {
        return String(self)
    }

}

extension Bytes: StringDecodable {
    
    public init(string: String) {
        self = string.base64Decoded
    }
    
    public var string: String {
        return String(bytes: self, encoding: .utf8) ?? ""
    }
    
}

extension AnyHashable: @retroactive Decodable, @retroactive Encodable {
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let value = try? container.decode(String.self) { self = value }
        else if let value = try? container.decode(Int.self) { self = value }
        else if let value = try? container.decode(Int64.self) { self = value }
        else if let value = try? container.decode(UInt64.self) { self = value }
        else if let value = try? container.decode(BInt.self) { self = value }
        else if let value = try? container.decode(Double.self) { self = value }
        else if let value = try? container.decode(Bool.self) { self = value }
        else if let value = try? container.decode([AnyHashable].self) { self = value }
        else if let value = try? container.decode([AnyHashable : AnyHashable].self) { self = value }
        else { throw NeoError.illegalArgument("Unable to decode AnyHashable") }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch base {
        case let value as String: try container.encode(value)
        case let value as Int: try container.encode(value)
        case let value as Int64: try container.encode(value)
        case let value as UInt64: try container.encode(value)
        case let value as BInt: try container.encode(value)
        case let value as Bool: try container.encode(value)
        case let value as Double: try container.encode(value)
        case let value as [AnyHashable]: try container.encode(value)
        case let value as [AnyHashable: AnyHashable]: try container.encode(value)
        case let value as TransactionAttribute: try container.encode(value)
        case let value as ContractParameter: try container.encode(value)
        case let value as [ContractParameter]: try container.encode(value)
        case let value as ContractParametersContext: try container.encode(value)
        case let value as TransactionSigner: try container.encode(value)
        case let value as [TransactionSigner]: try container.encode(value)
        case let value as TransactionSendToken: try container.encode(value)
        case let value as [TransactionSendToken]: try container.encode(value)
        default: throw NeoError.illegalArgument("Unable to encode AnyHashable \(self)")
        }
    }
    
}

@propertyWrapper
public struct SingleValueOrNilArray<T: Codable>: Codable {
    
    public var wrappedValue: [T]
    
    public init(wrappedValue: [T]) {
        self.wrappedValue = wrappedValue
    }
    
    public init(from decoder: Decoder) throws {
        guard let container = try? decoder.singleValueContainer() else {
            self.wrappedValue = []
            return
        }
        if let t = try? container.decode(T.self) {
            self.wrappedValue = [t]
        } else if let t = try? container.decode([T].self) {
            self.wrappedValue = t
        } else {
            self.wrappedValue = []
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.wrappedValue)
    }
    
}

extension SingleValueOrNilArray: Equatable where T: Equatable { }
extension SingleValueOrNilArray: Hashable where T: Hashable { }

public class RawResponseJSONDecoder: JSONDecoder, @unchecked Sendable {
    
    public override func decode<T>(_ type: T.Type, from data: Data) throws -> T where T : Decodable {
        let t = try super.decode(T.self, from: data)
        if var r = t as? HasRawResponse {
            r.rawResponse = String(data: data, encoding: .utf8)
            guard let decoded = r as? T else {
                throw NeoError.illegalArgument("Decoded response with raw payload could not be cast to \(T.self).")
            }
            return decoded
        }
        return t
    }
    
}
