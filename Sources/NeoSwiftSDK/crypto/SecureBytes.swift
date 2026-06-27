import Foundation

#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
import Darwin
#elseif os(Linux)
import Glibc
#elseif os(Windows)
import ucrt
#endif

/// A secure container for sensitive byte data that ensures proper memory cleanup
/// and protection against memory dumps
public final class SecureBytes {
    private var bytes: UnsafeMutablePointer<UInt8>
    private let count: Int
    private var isCleared: Bool = false
    
    /// Initialize with byte array, copying data to secure memory
    public init(_ data: [UInt8]) {
        self.count = data.count
        self.bytes = UnsafeMutablePointer<UInt8>.allocate(capacity: count)
        
        // Copy data to secure memory
        if count > 0 {
            data.withUnsafeBytes { srcBytes in
                let srcPointer = srcBytes.bindMemory(to: UInt8.self).baseAddress!
                bytes.initialize(from: srcPointer, count: count)
            }
        }
        
        // Lock memory to prevent swapping (best effort, ignore failures)
        _ = mlock(bytes, count)
    }
    
    /// Initialize with specified size, filled with zeros
    public init(count: Int) {
        self.count = count
        self.bytes = UnsafeMutablePointer<UInt8>.allocate(capacity: count)
        bytes.initialize(repeating: 0, count: count)
        _ = mlock(bytes, count)
    }
    
    deinit {
        clear()
    }
    
    /// Securely clear the memory
    public func clear() {
        guard !isCleared else { return }
        
        // Overwrite memory multiple times with random data
        for _ in 0..<3 {
            if let randomBytes = try? SecureRandom.bytes(count: count) {
                if count > 0 {
                    randomBytes.withUnsafeBytes { source in
                        let sourcePointer = source.bindMemory(to: UInt8.self).baseAddress!
                        bytes.initialize(from: sourcePointer, count: count)
                    }
                }
            } else {
                for i in 0..<count {
                    bytes[i] = UInt8((i * 31) & 0xff)
                }
            }
        }
        
        // Final overwrite with zeros
        memset(bytes, 0, count)
        
        // Unlock and deallocate (ignore munlock failures)
        _ = munlock(bytes, count)
        bytes.deallocate()
        isCleared = true
    }
    
    /// Access bytes with a closure, ensuring secure handling
    public func withUnsafeBytes<Result>(_ body: (UnsafeBufferPointer<UInt8>) throws -> Result) rethrows -> Result {
        guard !isCleared else {
            fatalError("Attempted to access cleared SecureBytes")
        }
        let buffer = UnsafeBufferPointer(start: bytes, count: count)
        return try body(buffer)
    }
    
    /// Get a copy of the bytes (use sparingly, as this creates non-secure copies)
    public func toArray() -> [UInt8] {
        guard !isCleared else { return [] }
        return withUnsafeBytes { Array($0) }
    }
    
    /// Update bytes at specific index
    public func update(at index: Int, value: UInt8) {
        guard index >= 0 && index < count && !isCleared else { return }
        bytes[index] = value
    }
    
    /// Compare with another SecureBytes in constant time
    public func constantTimeCompare(with other: SecureBytes) -> Bool {
        guard count == other.count && !isCleared && !other.isCleared else {
            return false
        }
        
        var result: UInt8 = 0
        for i in 0..<count {
            result |= bytes[i] ^ other.bytes[i]
        }
        return result == 0
    }
    
    /// Compare with byte array in constant time
    public func constantTimeCompare(with other: [UInt8]) -> Bool {
        guard count == other.count && !isCleared else {
            return false
        }
        
        var result: UInt8 = 0
        for i in 0..<count {
            result |= bytes[i] ^ other[i]
        }
        return result == 0
    }
}

/// Extension for secure string handling
extension SecureBytes {
    /// Create SecureBytes from a password string
    public convenience init?(password: String) {
        guard let data = password.data(using: .utf8) else { return nil }
        let bytes = [UInt8](data)
        self.init(bytes)
        
        // Clear the intermediate array
        var mutableBytes = bytes
        memset(&mutableBytes, 0, bytes.count)
    }
    
    /// Convert to hexadecimal string (use sparingly)
    public func toHexString() -> String {
        guard !isCleared else { return "" }
        return withUnsafeBytes { buffer in
            buffer.map { String(format: "%02x", $0) }.joined()
        }
    }
}
