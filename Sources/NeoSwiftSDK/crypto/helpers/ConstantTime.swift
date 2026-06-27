import Foundation

/// Provides constant-time operations for security-sensitive comparisons
public enum ConstantTime {
    
    /// Performs a constant-time comparison of two byte arrays
    /// - Parameters:
    ///   - lhs: First byte array
    ///   - rhs: Second byte array
    /// - Returns: true if arrays are equal, false otherwise
    public static func areEqual(_ lhs: [UInt8], _ rhs: [UInt8]) -> Bool {
        guard lhs.count == rhs.count else {
            return false
        }
        
        var result: UInt8 = 0
        for i in 0..<lhs.count {
            result |= lhs[i] ^ rhs[i]
        }
        
        return result == 0
    }
    
    /// Performs a constant-time comparison of two strings
    /// - Parameters:
    ///   - lhs: First string
    ///   - rhs: Second string
    /// - Returns: true if strings are equal, false otherwise
    public static func areEqual(_ lhs: String, _ rhs: String) -> Bool {
        guard let lhsData = lhs.data(using: .utf8),
              let rhsData = rhs.data(using: .utf8) else {
            return false
        }
        
        return areEqual([UInt8](lhsData), [UInt8](rhsData))
    }
    
    /// Performs a constant-time comparison of two Data objects
    /// - Parameters:
    ///   - lhs: First data
    ///   - rhs: Second data
    /// - Returns: true if data objects are equal, false otherwise
    public static func areEqual(_ lhs: Data, _ rhs: Data) -> Bool {
        return areEqual([UInt8](lhs), [UInt8](rhs))
    }
    
    /// Selects between two values in constant time
    /// - Parameters:
    ///   - condition: If true (1), select a; if false (0), select b
    ///   - a: First value
    ///   - b: Second value
    /// - Returns: Selected value
    public static func select<T: FixedWidthInteger>(_ condition: Bool, _ a: T, _ b: T) -> T {
        let mask: T = condition ? ~T.zero : T.zero
        return (a & mask) | (b & ~mask)
    }
    
    /// Copies bytes in constant time regardless of the condition
    /// - Parameters:
    ///   - condition: If true, perform actual copy; if false, perform dummy operations
    ///   - source: Source bytes
    ///   - destination: Destination buffer
    public static func conditionalCopy(_ condition: Bool, source: [UInt8], destination: inout [UInt8]) {
        guard source.count == destination.count else { return }
        
        let mask = UInt8(condition ? 0xFF : 0x00)
        for i in 0..<source.count {
            destination[i] = (source[i] & mask) | (destination[i] & ~mask)
        }
    }
}
