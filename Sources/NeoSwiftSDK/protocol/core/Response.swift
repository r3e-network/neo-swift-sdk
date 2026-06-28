
import Foundation

protocol HasRawResponse {
    var rawResponse: String? { get set }
}

public class Response<T: Codable>: Codable, HasRawResponse {
    
    @StringDecode public private(set) var id: Int
    public let jsonrpc: String
    public let result: T?
    public let error: Error?
    public var rawResponse: String?
    
    public init(_ result: T) {
        self.id = 1
        self.jsonrpc = "2.0"
        self.result = result
        self.error = nil
        self.rawResponse = nil
    }
    
    public var hasError: Bool {
        return error != nil
    }
    
    public func getResult() throws -> T {
        if let error = error {
            throw ProtocolError.rpcResponseError(error.rpcError)
        }
        guard let result = result else {
            throw ProtocolError.illegalState("No result in response and no error")
        }
        return result
    }
    
    public struct Error: LocalizedError, Codable, Hashable {
        
        public let code: Int
        public let message: String
        public let data: String?
        
        public init(code: Int, message: String, data: String? = nil) {
            self.code = code
            self.message = message
            self.data = data
        }
        
        public init(from decoder: Decoder) throws {
            let container: KeyedDecodingContainer<Response<T>.Error.CodingKeys> = try decoder.container(keyedBy: Response<T>.Error.CodingKeys.self)
            self.code = try container.decode(Int.self, forKey: Response<T>.Error.CodingKeys.code)
            self.message = try container.decode(String.self, forKey: Response<T>.Error.CodingKeys.message)
            self.data = try container.decodeIfPresent(RawJsonValue.self, forKey: .data)?.jsonString
        }
        
        public var string: String {
            return "Error{code=\(code), message=\(message), data=\(String(describing: data))}"
        }

        public var rpcError: RpcResponseError {
            .init(code: code, message: message, data: data)
        }
        
        public var errorDescription: String? {
            return string
        }

    }
    
}

private enum RawJsonValue: Codable, Hashable {

    case string(String)
    case integer(Int64)
    case unsignedInteger(UInt64)
    case double(Double)
    case bool(Bool)
    case object([String: RawJsonValue])
    case array([RawJsonValue])
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Int64.self) {
            self = .integer(value)
        } else if let value = try? container.decode(UInt64.self) {
            self = .unsignedInteger(value)
        } else if let value = try? container.decode(Double.self) {
            self = .double(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode([String: RawJsonValue].self) {
            self = .object(value)
        } else if let value = try? container.decode([RawJsonValue].self) {
            self = .array(value)
        } else {
            throw NeoError.illegalArgument("Unable to decode raw JSON value.")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value): try container.encode(value)
        case .integer(let value): try container.encode(value)
        case .unsignedInteger(let value): try container.encode(value)
        case .double(let value): try container.encode(value)
        case .bool(let value): try container.encode(value)
        case .object(let value): try container.encode(value)
        case .array(let value): try container.encode(value)
        case .null: try container.encodeNil()
        }
    }

    var jsonString: String? {
        guard case .null = self else {
            return (try? JSONEncoder().encode(self)).flatMap { String(data: $0, encoding: .utf8) }
        }
        return nil
    }

}
