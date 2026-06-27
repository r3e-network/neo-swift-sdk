import Foundation

// MARK: Test Credential Loading

#if DEBUG
// Load test credentials from external file - only available in debug builds
private struct TestCredentials: Codable {
    struct Account: Codable {
        let address: String?
        let scriptHash: String?
        let verificationScript: String?
        let publicKey: String?
        let privateKey: String?
        let encryptedPrivateKey: String?
        let wif: String?
        let password: String?
    }
    
    let defaultAccount: Account
    let committeeAccount: Account
    let client1Account: Account
}

private let testCredentials: TestCredentials = {
    guard let url = Bundle.module.url(forResource: "test-credentials", withExtension: "json"),
          let data = try? Data(contentsOf: url),
          let credentials = try? JSONDecoder().decode(TestCredentials.self, from: data) else {
        fatalError("Failed to load test credentials. Ensure test-credentials.json exists in test resources.")
    }
    return credentials
}()

// MARK: Default Account

let defaultAccountAddress = testCredentials.defaultAccount.address!
let defaultAccountScriptHash = testCredentials.defaultAccount.scriptHash!
let defaultAccountVerificationScript = testCredentials.defaultAccount.verificationScript!
let defaultAccountPublicKey = testCredentials.defaultAccount.publicKey!
let defaultAccountPrivateKey = testCredentials.defaultAccount.privateKey!
let defaultAccountEncryptedPrivateKey = testCredentials.defaultAccount.encryptedPrivateKey!
let defaultAccountWIF = testCredentials.defaultAccount.wif!
let defaultAccountPassword = testCredentials.defaultAccount.password!

// MARK: Committee Account

let committeeAccountAddress = testCredentials.committeeAccount.address!
let committeeAccountScriptHash = testCredentials.committeeAccount.scriptHash!
let committeeAccountVerificationScript = testCredentials.committeeAccount.verificationScript!

// MARK: Client 1 Account

let client1AccountWIF = testCredentials.client1Account.wif!

#else
// In release builds, these should not be available
#error("Test credentials should not be used in release builds")
#endif

// MARK: Native Contracts
// These are public blockchain constants, safe to include

let contractManagementHash = "fffdc93764dbaddd97c48f252a53ea4643faa3fd"
let stdLibHash = "acce6fd80d44e1796aa0c2c625e9e4e0ce39efc0"
let cryptoLibHash = "726cb6e0cd8628a1350a611384688911ab75f51b"
let ledgerContractHash = "da65b600f7124ce6c79950c1772a36403104f2be"
let neoTokenHash = "ef4073a0f2b305a38ec4050e4d3d28bc40ea63f5"
let gasTokenHash = "d2a4cff31913016155e38e474a2c06d08be276cf"
let gasTokenName = "GasToken"
let policyContractHash = "cc5e4edd9f5f8dba8bb65734541df7a1c081c67b"
let roleManagementHash = "49cf4e5378ffcd4dec034fd98a174c5491e395e2"
let oracleContractHash = "fe924b7cfe89ddd271abaf7210a80a7e11178758"
let nameServiceHash = "7a8fcf0392cd625647907afa8e45cc66872b596b"