
import XCTest
@testable import NeoSwiftSDK

class ContractManagementTests: XCTestCase {
    
    private let CONTRACTMANAGEMENT_SCRIPTHASH = try! Hash160("fffdc93764dbaddd97c48f252a53ea4643faa3fd")
    private let TESTCONTRACT_NEF_FILE = Bundle.module.url(forResource: "TestContract", withExtension: "nef")!
    private let TESTCONTRACT_MANIFEST_FILE = Bundle.module.url(forResource: "TestContract.manifest", withExtension: "json")!
    
    private var mockUrlSession: MockURLSession!
    private var rpcClient: NeoRpcClient!
    
    private let account1 = try! Account.fromWIF("L1WMhxazScMhUrdv34JqQb1HFSQmWeN2Kpc1R9JGKwL7CDNP21uR")
    
    override func setUp() {
        mockUrlSession = .init()
        rpcClient = .build(HttpService(urlSession: mockUrlSession), .init(networkMagic: 769))
    }
    
    public func testGetContractById() async throws {
        _ = mockUrlSession.data(["getcontractstate": JSON.from("contractstate")])
        _ = mockUrlSession.invokeFunctions(["getContractById": JSON.from("management_getContract")])
        
        let contractHash = try Hash160("0xf61eebf573ea36593fd43aa150c055ad7906ab83")
        
        let state = try await ContractManagement(rpcClient).getContractById(12)
        XCTAssertEqual(state.hash, contractHash)
        XCTAssertEqual(state.id, 12)
        XCTAssertEqual(state.manifest.name, "neow3j")
    }
    
    public func testGetContractById_nonExistent() async throws {
        _ = mockUrlSession.data(["invokefunction": JSON.from("management_contractstate_notexistent")])
        do {
            _ = try await ContractManagement(rpcClient).getContractById(20)
            XCTFail("No exception")
        } catch {
            XCTAssert(error is NeoError)
            XCTAssertEqual(error.localizedDescription, "Could not get the contract hash for the provided id.")
        }
    }
    
    public func testDeployWithoutData() async throws {
        _ = mockUrlSession.data(["invokescript": JSON.from("management_deploy"),
                                 "getblockcount": JSON.from("getblockcount_1000"),
                                 "calculatenetworkfee": JSON.from("calculatenetworkfee")])
        
        let nef = try NefFile.readFromFile(TESTCONTRACT_NEF_FILE)
        
        let manifest = try JSONDecoder().decode(ContractManifest.self, from: Data(contentsOf: TESTCONTRACT_MANIFEST_FILE))
        let txBuilder = try ContractManagement(rpcClient).deploy(nef, manifest)
        guard let expectedScript = txBuilder.script else {
            XCTFail("Expected deploy transaction builder to contain a script.")
            return
        }
        
        let tx = try await txBuilder
            .signers(AccountSigner.calledByEntry(account1))
            .sign()
        
        XCTAssertEqual(tx.script, expectedScript)
    }
    
    public func testDeployWithData() async throws {
        _ = mockUrlSession.data(["invokescript": JSON.from("management_deploy"),
                                 "getblockcount": JSON.from("getblockcount_1000"),
                                 "calculatenetworkfee": JSON.from("calculatenetworkfee")])
        
        let nef = try NefFile.readFromFile(TESTCONTRACT_NEF_FILE)
        
        let manifest = try JSONDecoder().decode(ContractManifest.self, from: Data(contentsOf: TESTCONTRACT_MANIFEST_FILE))
        
        let data = ContractParameter.string("some data")
        let txBuilder = try ContractManagement(rpcClient).deploy(nef, manifest, data)
        guard let expectedScript = txBuilder.script else {
            XCTFail("Expected deploy transaction builder to contain a script.")
            return
        }
        
        let tx = try await txBuilder
            .signers(AccountSigner.calledByEntry(account1))
            .sign()
        
        XCTAssertEqual(tx.script, expectedScript)
    }
    
}
