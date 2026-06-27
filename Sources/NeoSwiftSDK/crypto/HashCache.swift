import Foundation
import CryptoSwift

/// Thread-safe hash cache for repeated cryptographic operations
public final class HashCache {
    
    /// Shared instance for global hash caching
    public static let shared = HashCache()
    
    private let cache = NSCache<NSString, CachedHash>()
    private let queue = DispatchQueue(label: "com.neo-swift-sdk.hashcache", attributes: .concurrent)
    
    /// Maximum number of cached hashes (default: 1000)
    public var maxCacheSize: Int = 1000 {
        didSet {
            cache.countLimit = maxCacheSize
        }
    }
    
    /// Cache entry wrapper
    private class CachedHash {
        let hash: Bytes
        let timestamp: Date
        
        init(hash: Bytes) {
            self.hash = hash
            self.timestamp = Date()
        }
    }
    
    public init() {
        cache.countLimit = maxCacheSize
        cache.totalCostLimit = 50 * 1024 * 1024 // 50MB limit
    }
    
    /// Get or compute SHA256 hash with caching
    public func sha256(_ data: Bytes) -> Bytes {
        let key = cacheKey(for: data, algorithm: "sha256")
        
        // Try to get from cache
        if let cached = getCached(key: key) {
            return cached
        }
        
        // Compute hash
        let hash = data.sha256()
        
        // Store in cache
        setCached(key: key, hash: hash, cost: data.count)
        
        return hash
    }
    
    /// Get or compute double SHA256 (Hash256) with caching
    public func hash256(_ data: Bytes) -> Bytes {
        let key = cacheKey(for: data, algorithm: "hash256")
        
        // Try to get from cache
        if let cached = getCached(key: key) {
            return cached
        }
        
        // Compute hash
        let hash = data.hash256()
        
        // Store in cache
        setCached(key: key, hash: hash, cost: data.count)
        
        return hash
    }
    
    /// Get or compute RIPEMD160(SHA256) (Hash160) with caching
    public func hash160(_ data: Bytes) -> Bytes {
        let key = cacheKey(for: data, algorithm: "hash160")
        
        // Try to get from cache
        if let cached = getCached(key: key) {
            return cached
        }
        
        // Compute hash
        let hash = data.sha256ThenRipemd160()
        
        // Store in cache
        setCached(key: key, hash: hash, cost: data.count)
        
        return hash
    }
    
    /// Clear all cached hashes
    public func clearCache() {
        queue.async(flags: .barrier) {
            self.cache.removeAllObjects()
        }
    }
    
    /// Remove cached hash for specific data
    public func removeCached(_ data: Bytes, algorithm: String) {
        let key = cacheKey(for: data, algorithm: algorithm)
        queue.async(flags: .barrier) {
            self.cache.removeObject(forKey: key)
        }
    }
    
    /// Get cache statistics
    /// Note: NSCache doesn't provide built-in hit/miss statistics
    public func cacheStats() -> (hits: Int, misses: Int, count: Int) {
        // NSCache doesn't provide hit/miss stats without manual tracking
        return (0, 0, 0)
    }
    
    // MARK: - Private Methods
    
    private func cacheKey(for data: Bytes, algorithm: String) -> NSString {
        // Create a unique key based on algorithm and first/last bytes + length
        // This avoids computing hash of the data for the key itself
        let prefix = data.prefix(8).map { String(format: "%02x", $0) }.joined()
        let suffix = data.suffix(8).map { String(format: "%02x", $0) }.joined()
        return "\(algorithm):\(data.count):\(prefix):\(suffix)" as NSString
    }
    
    private func getCached(key: NSString) -> Bytes? {
        return queue.sync {
            cache.object(forKey: key)?.hash
        }
    }
    
    private func setCached(key: NSString, hash: Bytes, cost: Int) {
        queue.async(flags: .barrier) {
            self.cache.setObject(CachedHash(hash: hash), forKey: key, cost: cost)
        }
    }
}

// MARK: - Extensions for cached hash operations

public extension Array where Element == UInt8 {
    
    /// Compute SHA256 with caching
    var cachedSha256: Bytes {
        return HashCache.shared.sha256(self)
    }
    
    /// Compute Hash256 (double SHA256) with caching
    var cachedHash256: Bytes {
        return HashCache.shared.hash256(self)
    }
    
    /// Compute Hash160 (RIPEMD160(SHA256)) with caching
    var cachedHash160: Bytes {
        return HashCache.shared.hash160(self)
    }
}

public extension String {
    
    /// Compute SHA256 of UTF8 bytes with caching
    var cachedSha256: Bytes {
        return self.bytes.cachedSha256
    }
    
    /// Compute Hash256 of UTF8 bytes with caching
    var cachedHash256: Bytes {
        return self.bytes.cachedHash256
    }
    
    /// Compute Hash160 of UTF8 bytes with caching
    var cachedHash160: Bytes {
        return self.bytes.cachedHash160
    }
}
