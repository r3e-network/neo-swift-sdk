import XCTest
@testable import NeoSwiftSDK

/// Integration tests for wallet operations
final class WalletIntegrationTests: IntegrationTestBase {
    
    func testCreateAndSaveWallet() async throws {
        // Create a new wallet with multiple accounts
        let account1 = try Account.create()
        let account2 = try Account.create()
        let exportPassword = "TestPassword123!"
        try account1.encryptPrivateKey(exportPassword)
        try account2.encryptPrivateKey(exportPassword)
        
        let wallet = try Wallet.withAccounts([account1, account2])
            .name("TestWallet")
            .version("1.0")
        
        // Verify wallet properties
        XCTAssertEqual(wallet.name, "TestWallet")
        XCTAssertEqual(wallet.version, "1.0")
        XCTAssertEqual(wallet.accounts.count, 2)
        
        // Test NEP6 export
        let nep6Wallet = try wallet.toNEP6Wallet()
        XCTAssertFalse(nep6Wallet.accounts.isEmpty)
        
        // Test wallet reconstruction from NEP6
        let reconstructedWallet = try Wallet.fromNEP6Wallet(nep6Wallet)
        XCTAssertEqual(reconstructedWallet.accounts.count, 2)
        
        // Test passed - no cleanup needed for memory-only wallet
    }
    
    func testMultiSigAccount() async throws {
        // Create multiple key pairs
        let keyPair1 = try ECKeyPair.createEcKeyPair()
        let keyPair2 = try ECKeyPair.createEcKeyPair()
        let keyPair3 = try ECKeyPair.createEcKeyPair()
        
        let publicKeys = [
            keyPair1.publicKey,
            keyPair2.publicKey,
            keyPair3.publicKey
        ]
        
        // Create 2-of-3 multi-sig account
        let multiSigAccount = try Account.createMultiSigAccount(publicKeys, 2)
        
        // Verify multi-sig properties
        XCTAssertEqual(multiSigAccount.signingThreshold, 2)
        XCTAssertEqual(multiSigAccount.nrOfParticipants, 3)
        XCTAssertTrue(multiSigAccount.isMultiSig)
        
        // Verify verification script
        guard let verificationScript = multiSigAccount.verificationScript else {
            XCTFail("Multi-sig account should have verification script")
            return
        }
        XCTAssertFalse(verificationScript.script.isEmpty)
    }
    
    func testAccountEncryption() async throws {
        // Create account with known private key
        let keyPair = try ECKeyPair.createEcKeyPair()
        let account = try Account(keyPair: keyPair)
        
        // Test NEP2 encryption
        let password = "TestPassword123!"
        try account.encryptPrivateKey(password)
        
        // Verify encrypted format
        guard let encryptedKey = account.encryptedPrivateKey else {
            XCTFail("Account should have encrypted private key after encryption")
            return
        }
        XCTAssertTrue(encryptedKey.hasPrefix("6P"))
        XCTAssertEqual(encryptedKey.count, 58)
        
        // Test decryption
        let decryptedKeyPair = try NEP2.decryptSecure(password, encryptedKey)
        let decryptedAccount = try Account(secureKeyPair: decryptedKeyPair)
        XCTAssertEqual(account.address, decryptedAccount.address)
        XCTAssertEqual(try account.getScriptHash(), try decryptedAccount.getScriptHash())
    }
    
    func testWalletAccountOperations() async throws {
        var wallet = try Wallet.create()
        
        // Add accounts
        let account1 = try Account.create()
        let account2 = try Account.create()
        
        wallet = try wallet.addAccounts([account1, account2])
        XCTAssertEqual(wallet.accounts.count, 3) // 1 default + 2 added
        
        // Remove account
        let removed = try wallet.removeAccount(account1)
        XCTAssertTrue(removed)
        XCTAssertEqual(wallet.accounts.count, 2)
        XCTAssertNil(wallet.accounts.first { $0.address == account1.address })
        
        // Set default account
        let scriptHash = try account2.getScriptHash()
        wallet = try wallet.defaultAccount(scriptHash)
        XCTAssertEqual(wallet.defaultAccount?.address, account2.address)
    }
    
    func testAccountBalanceQuery() async throws {
        // This test requires a funded testnet account
        // Skip if no testnet access
        guard ProcessInfo.processInfo.environment["ENABLE_NETWORK_TESTS"] == "true" else {
            throw XCTSkip("Network tests disabled")
        }
        
        // Use a known testnet address with balance
        let testAddress = "NTrezR3C4X8aMLVg7vozt5wguyNfFhwuFx"
        let account = try Account.fromAddress(testAddress)
        
        // Query NEP17 balances
        let balances = try await account.getNep17Balances(rpcClient)
        
        // Should have at least GAS balance
        XCTAssertFalse(balances.isEmpty)
        
        // Check for specific tokens  
        let gasBalance = balances.first { $0.key == GasToken.SCRIPT_HASH }
        XCTAssertNotNil(gasBalance)
    }
}
