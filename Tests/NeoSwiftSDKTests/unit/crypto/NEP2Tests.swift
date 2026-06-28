
import XCTest
@testable import NeoSwiftSDK

class NEP2Tests: XCTestCase {
 
    func testDecryptWithDefaultScryptParams() {
        XCTAssertEqual(
            try? NEP2.decryptSecure(defaultAccountPassword, defaultAccountEncryptedPrivateKey).withPrivateKeyBytes { $0 },
            defaultAccountPrivateKey.bytesFromHex
        )
    }
    
    func testDecryptWithNonDefaultScryptParams() {
        let params = ScryptParams(256, 1, 1)
        let encrypted = "6PYM7jHL3uwhP8uuHP9fMGMfJxfyQbanUZPQEh1772iyb7vRnUkbkZmdRT"
        XCTAssertEqual(
            try? NEP2.decryptSecure(defaultAccountPassword, encrypted, params).withPrivateKeyBytes { $0 },
            defaultAccountPrivateKey.bytesFromHex
        )
    }
    
    func testEncryptWithDefaultScryptParams() {
        let keyPair = try! ECKeyPair.create(privateKey: defaultAccountPrivateKey.bytesFromHex)
        XCTAssertEqual(
            try? NEP2.encrypt(defaultAccountPassword, keyPair),
            defaultAccountEncryptedPrivateKey
        )
    }
    
    func testEncryptWithNonDefaultScryptParams() {
        let params = ScryptParams(256, 1, 1)
        let expected = "6PYM7jHL3uwhP8uuHP9fMGMfJxfyQbanUZPQEh1772iyb7vRnUkbkZmdRT"
        let keyPair = try! ECKeyPair.create(privateKey: defaultAccountPrivateKey.bytesFromHex)
        XCTAssertEqual(
            try? NEP2.encrypt(defaultAccountPassword, keyPair, params),
            expected
        )
    }

    
}
