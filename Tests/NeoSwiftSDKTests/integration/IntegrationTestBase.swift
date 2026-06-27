import XCTest
@testable import NeoSwiftSDK

/// Base class for integration tests with common setup and utilities
class IntegrationTestBase: XCTestCase {
    
    var rpcClient: NeoRpcClient!
    var testWallet: Wallet!
    var testAccount: Account!
    
    // Test network configuration
    let testNetUrl = URL(string: "https://testnet1.neo.coz.io:443")!
    let mainNetUrl = URL(string: "https://mainnet1.neo.coz.io:443")!
    
    // Use testnet by default for integration tests
    var networkUrl: URL {
        return testNetUrl
    }
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Initialize NeoRpcClient with test network
        rpcClient = NeoRpcClient.build(HttpService(url: networkUrl))
        
        // Create test wallet and account
        testAccount = try Account.create()
        testWallet = try Wallet.withAccounts([testAccount])
            .name("IntegrationTestWallet")
            .version("1.0")
    }
    
    override func tearDown() async throws {
        rpcClient = nil
        testWallet = nil
        testAccount = nil
        try await super.tearDown()
    }
    
    // MARK: - Helper Methods
    
    /// Wait for a transaction to be included in a block
    func waitForTransaction(_ txHash: Hash256, timeout: TimeInterval = 30) async throws -> NeoGetTransaction? {
        let startTime = Date()
        
        while Date().timeIntervalSince(startTime) < timeout {
            let response = try await rpcClient.getTransaction(txHash).send()
            if response.error == nil, response.transaction != nil {
                return response
            }
            
            // Wait 1 second before next attempt
            try await Task.sleep(nanoseconds: 1_000_000_000)
        }
        
        return nil
    }
    
    /// Get current block height
    func getCurrentBlockHeight() async throws -> Int {
        let response = try await rpcClient.getBlockCount().send()
        guard let count = response.blockCount else {
            throw IntegrationTestError.invalidResponse("Failed to get block count")
        }
        return count - 1
    }
    
    /// Verify contract deployment
    func verifyContractDeployment(_ scriptHash: Hash160) async throws -> Bool {
        let response = try await rpcClient.getContractState(scriptHash).send()
        return response.contractState != nil
    }
    
    /// Check account balance
    func getAccountBalance(_ account: Account, token: Hash160) async throws -> Int {
        // Get NEP-17 balances for the account's script hash
        let scriptHash = try account.getScriptHash()
        let response = try await rpcClient.getNep17Balances(scriptHash).send()
        let balances = response.balances?.balances ?? []
        guard let amount = balances.first(where: { $0.assetHash == token })?.amount else {
            return 0
        }
        return try Int(string: amount)
    }
}

/// Integration test specific errors
enum IntegrationTestError: LocalizedError {
    case invalidResponse(String)
    case timeout(String)
    case insufficientFunds
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse(let message):
            return "Invalid response: \(message)"
        case .timeout(let message):
            return "Operation timeout: \(message)"
        case .insufficientFunds:
            return "Insufficient funds for test"
        }
    }
}
