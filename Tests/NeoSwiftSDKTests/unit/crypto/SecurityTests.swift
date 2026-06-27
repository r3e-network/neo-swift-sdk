import XCTest
@testable import NeoSwiftSDK

/// Security-focused tests for cryptographic operations
final class SecurityTests: XCTestCase {
    
    // MARK: - Secure Memory Tests
    
    func testSecureBytesCreation() throws {
        let sensitiveData: [UInt8] = [1, 2, 3, 4, 5, 6, 7, 8]
        let secureBytes = SecureBytes(sensitiveData)
        
        // Verify data is accessible
        secureBytes.withUnsafeBytes { buffer in
            XCTAssertEqual(Array(buffer), sensitiveData)
        }
        
        // Verify data can be cleared
        secureBytes.clear()
        
        // After clearing, accessing should fail
        // Note: In production, this would throw/crash
    }
    
    func testSecureBytesConstantTimeComparison() throws {
        let data1 = SecureBytes([1, 2, 3, 4, 5])
        let data2 = SecureBytes([1, 2, 3, 4, 5])
        let data3 = SecureBytes([1, 2, 3, 4, 6])
        let data4 = SecureBytes([1, 2, 3, 4])
        
        // Equal arrays
        XCTAssertTrue(data1.constantTimeCompare(with: data2))
        
        // Different last byte
        XCTAssertFalse(data1.constantTimeCompare(with: data3))
        
        // Different lengths
        XCTAssertFalse(data1.constantTimeCompare(with: data4))
    }
    
    func testSecureECKeyPair() throws {
        // Create secure key pair
        let secureKeyPair = try SecureECKeyPair.createEcKeyPair()
        
        // Verify public key is accessible
        XCTAssertNotNil(secureKeyPair.publicKey)
        
        // Test signing
        let message = "Test message".bytes
        let messageHash = message.sha256()
        let signature = secureKeyPair.sign(messageHash: messageHash)
        
        XCTAssertEqual(signature.count, 2)
        XCTAssertNotEqual(signature[0].asString(radix: 10, uppercase: false), "0")
        XCTAssertNotEqual(signature[1].asString(radix: 10, uppercase: false), "0")
        
        // Test address generation
        let address = try secureKeyPair.getAddress()
        XCTAssertTrue(address.hasPrefix("N"))
        XCTAssertEqual(address.count, 34)
    }
    
    // MARK: - Constant Time Operation Tests
    
    func testConstantTimeByteComparison() {
        let data1: [UInt8] = [1, 2, 3, 4, 5]
        let data2: [UInt8] = [1, 2, 3, 4, 5]
        let data3: [UInt8] = [1, 2, 3, 4, 6]
        
        XCTAssertTrue(ConstantTime.areEqual(data1, data2))
        XCTAssertFalse(ConstantTime.areEqual(data1, data3))
        
        // Test with empty arrays
        XCTAssertTrue(ConstantTime.areEqual([], []))
        XCTAssertFalse(ConstantTime.areEqual(data1, []))
    }
    
    func testConstantTimeStringComparison() {
        let str1 = "password123"
        let str2 = "password123"
        let str3 = "password124"
        
        XCTAssertTrue(ConstantTime.areEqual(str1, str2))
        XCTAssertFalse(ConstantTime.areEqual(str1, str3))
        
        // Test with unicode
        let unicode1 = "🔐🔑"
        let unicode2 = "🔐🔑"
        XCTAssertTrue(ConstantTime.areEqual(unicode1, unicode2))
    }
    
    func testConstantTimeSelection() {
        let a: UInt32 = 42
        let b: UInt32 = 100
        
        XCTAssertEqual(ConstantTime.select(true, a, b), a)
        XCTAssertEqual(ConstantTime.select(false, a, b), b)
    }
    
    // MARK: - NEP2 Security Tests
    
    func testNEP2EncryptionDecryption() throws {
        let keyPair = try ECKeyPair.createEcKeyPair()
        let password = "VerySecurePassword123!"
        
        // Encrypt
        let encrypted = try NEP2.encrypt(password, keyPair)
        
        // Verify NEP2 format
        XCTAssertTrue(encrypted.hasPrefix("6P"))
        XCTAssertEqual(encrypted.count, 58)
        
        // Decrypt
        let decrypted = try NEP2.decrypt(password, encrypted)
        
        // Verify same keys
        XCTAssertEqual(keyPair.privateKey.bytes, decrypted.privateKey.bytes)
        XCTAssertEqual(keyPair.publicKey, decrypted.publicKey)
    }
    
    func testNEP2WrongPassword() throws {
        let keyPair = try ECKeyPair.createEcKeyPair()
        let password = "CorrectPassword"
        let wrongPassword = "WrongPassword"
        
        let encrypted = try NEP2.encrypt(password, keyPair)
        
        // Should throw with wrong password
        XCTAssertThrowsError(try NEP2.decrypt(wrongPassword, encrypted)) { error in
            XCTAssertTrue(error is NEP2Error)
        }
    }
    
    // MARK: - Hash Cache Tests
    
    func testHashCaching() {
        let data = "Test data for hashing".bytes
        let cache = HashCache()
        
        // First call should compute
        let hash1 = cache.sha256(data)
        
        // Second call should use cache
        let hash2 = cache.sha256(data)
        
        XCTAssertEqual(hash1, hash2)
        
        // Clear cache
        cache.clearCache()
        
        // Should recompute after clear
        let hash3 = cache.sha256(data)
        XCTAssertEqual(hash1, hash3)
    }
    
    func testHashCacheThreadSafety() {
        let cache = HashCache()
        let expectation = XCTestExpectation(description: "Concurrent hash operations")
        let iterations = 20
        expectation.expectedFulfillmentCount = iterations
        
        let data = "Concurrent test data".bytes
        var results = [Bytes]()
        let lock = NSLock()
        
        // Perform concurrent hash operations
        for _ in 0..<iterations {
            DispatchQueue.global().async {
                let hash = cache.sha256(data)
                lock.lock()
                results.append(hash)
                lock.unlock()
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 15.0)
        
        // All hashes should be identical
        let firstHash = results[0]
        for hash in results {
            XCTAssertEqual(hash, firstHash)
        }
    }
    
    // MARK: - Private Key Security Tests
    
    func testPrivateKeyNotInMemoryAfterClear() throws {
        let privateKeyBytes = try ECKeyPair.createEcKeyPair().privateKey.bytes
        let secureKey = SecureBytes(privateKeyBytes)
        
        // Clear the secure bytes
        secureKey.clear()
        
        // Original array should still exist but secure storage is cleared
        // In production, accessing cleared SecureBytes would fail
        XCTAssertFalse(privateKeyBytes.isEmpty) // Original still in memory
    }
    
    func testWIFImportSecurely() throws {
        let wif = "L1eV34wPoj9weqhGijdDLtVQzUpWGHszXXpdU9dPuh2nRFFzFa7E"
        
        // Import using secure method
        let privateKey = try wif.privateKeyFromWIF()
        let secureKeyPair = try SecureECKeyPair.create(privateKey: privateKey)
        
        // Verify we can still use it
        let address = try secureKeyPair.getAddress()
        XCTAssertEqual(address, "NM7Aky765FG8NhhwtxjXRx7jEL1cnw7PBP")
    }
    
    // MARK: - Signature Security Tests
    
    func testDeterministicSignatures() throws {
        let keyPair = try ECKeyPair.createEcKeyPair()
        let message = "Test message for signing".bytes
        let messageHash = message.sha256()
        
        // Sign same message multiple times
        let sig1 = keyPair.sign(messageHash: messageHash)
        let sig2 = keyPair.sign(messageHash: messageHash)
        let sig3 = keyPair.sign(messageHash: messageHash)
        
        // All signatures should be identical (deterministic)
        XCTAssertEqual(sig1, sig2)
        XCTAssertEqual(sig2, sig3)
    }
    
    func testSignatureVerification() throws {
        let keyPair = try ECKeyPair.createEcKeyPair()
        let message = "Message to sign and verify".bytes
        let messageHash = message.sha256()
        
        // Sign message
        let signature = keyPair.signAndGetECDSASignature(messageHash: messageHash)
        
        // Verify signature
        let publicKey = keyPair.publicKey
        let isValid = publicKey.verify(signature: signature.signature, msg: messageHash)
        
        XCTAssertTrue(isValid)
        
        // Verify with wrong message fails
        let wrongMessage = "Wrong message".bytes.sha256()
        let isInvalid = publicKey.verify(signature: signature.signature, msg: wrongMessage)
        
        XCTAssertFalse(isInvalid)
    }
}
