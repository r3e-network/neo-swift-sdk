
import XCTest
@testable import NeoSwiftSDK

class GasTokenTests: XCTestCase {
        
    private let rpcClient = NeoRpcClient.build(HttpService())
    
    public func testName() async {
        let name = try! await GasToken(rpcClient).getName()
        XCTAssertEqual(name, "GasToken")
    }
    
    public func testSymbol() async {
        let symbol = try! await GasToken(rpcClient).getSymbol()
        XCTAssertEqual(symbol, "GAS")
    }
    
    public func testDecimals() async {
        let decimals = try! await GasToken(rpcClient).getDecimals()
        XCTAssertEqual(decimals, 8)
    }
    
    public func testScriptHash() {
        XCTAssertEqual(GasToken(rpcClient).scriptHash.string, "d2a4cff31913016155e38e474a2c06d08be276cf")
    }
    
}
