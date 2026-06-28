
import XCTest
@testable import NeoSwiftSDK

class Bip39AccountTests: XCTestCase {
    
    func testGenerateAndRecoverBip39Account() {
        let pw = "Insecure Pa55w0rd"
        let a1 = try! Bip39Account.create(pw)
        let mnemonic = try! a1.exportMnemonic()
        let a2 = try! Bip39Account.fromBip39Mnemonic(pw, mnemonic)
        XCTAssertEqual(a1.address, a2.address)
        XCTAssertNotNil(a1.secureKeyPair)
        XCTAssertEqual(a1.publicKey, a2.publicKey)
        XCTAssertEqual(mnemonic, try! a2.exportMnemonic())
        XCTAssertFalse(mnemonic.isEmpty)
    }
    
}
