
import Foundation

public enum NeoError: LocalizedError {
    
    case illegalArgument(_ message: String? = nil)
    case deserialization(_ message: String? = nil)
    case illegalState(_ message: String? = nil)
    case indexOutOfBounds(_ message: String? = nil)
    case runtime(_ message: String)
    case unsupportedOperation(_ message: String)
    
    public var errorDescription: String? {
        switch self {
        case .illegalArgument(let message):
            return message ?? "Illegal argument provided"
        case .deserialization(let message):
            return message ?? "Failed to deserialize data"
        case .illegalState(let message):
            return message ?? "Illegal state encountered"
        case .indexOutOfBounds(let message):
            return message ?? "Index out of bounds"
        case .runtime(let message), .unsupportedOperation(let message):
            return message
        }
    }
    
}
