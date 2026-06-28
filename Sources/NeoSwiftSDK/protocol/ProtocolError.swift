
import Foundation

public struct RpcResponseError: LocalizedError, Codable, Hashable, Sendable {

    public let code: Int
    public let message: String
    public let data: String?

    public init(code: Int, message: String, data: String? = nil) {
        self.code = code
        self.message = message
        self.data = data
    }

    public var string: String {
        guard let data else {
            return "Error(\(code)): \(message)"
        }
        return "Error(\(code)): \(message) data: \(data)"
    }

    public var errorDescription: String? {
        string
    }

}

public enum ProtocolError: LocalizedError, Sendable {
    
    case rpcResponseError(_ error: RpcResponseError)
    case invocationFaultState(_ error: String)
    case clientConnection(_ message: String)
    case stackItemCastError(_ item: StackItem, _ target: String)
    case illegalState(_ message: String)
    
    public var errorDescription: String? {
        switch self {
        case .rpcResponseError(let error): return "The Neo node responded with an error: \(error.string)"
        case .invocationFaultState(let error): return "The invocation resulted in a FAULT VM state. The VM exited due to the following exception: \(error)"
        case .clientConnection(let message): return message
        case .stackItemCastError(let item, let target): return "Cannot cast stack item \(item.jsonValue) to a \(target)."
        case .illegalState(let message): return message
        }
    }
}
