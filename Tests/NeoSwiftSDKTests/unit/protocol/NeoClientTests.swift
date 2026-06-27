import XCTest
@testable import NeoSwiftSDK

class NeoClientTests: XCTestCase {

    func testGetBlockCountUsesTypedOperationSurface() async throws {
        let json = """
{
    "jsonrpc": "2.0",
    "id": 1,
    "result": 1000
}
"""
        var method: String?
        let mockUrlSession = MockURLSession()
            .requestInterceptor { request in
                guard let body = request.httpBody,
                      let object = try? JSONSerialization.jsonObject(with: body) as? [String: Any] else {
                    return XCTFail("No JSON-RPC request body")
                }
                method = object["method"] as? String
            }
            .data(["getblockcount": json.data(using: .utf8)!])
        let service = HttpService(urlSession: mockUrlSession)
        let client = NeoClient(config: .init(service: service))

        let output = try await client.getBlockCount()

        XCTAssertEqual(method, "getblockcount")
        XCTAssertEqual(output.count, 1000)
    }

    func testGetBlockHashUsesTypedInputAndOutput() async throws {
        let json = """
{
    "jsonrpc": "2.0",
    "id": 1,
    "result": "0x6b209f2c15bbf5989d8c8dbec9ee6f83699ef95a0cb0d6e9570edeb15febaab1"
}
"""
        var params: [Any]?
        let mockUrlSession = MockURLSession()
            .requestInterceptor { request in
                guard let body = request.httpBody,
                      let object = try? JSONSerialization.jsonObject(with: body) as? [String: Any] else {
                    return XCTFail("No JSON-RPC request body")
                }
                params = object["params"] as? [Any]
            }
            .data(["getblockhash": json.data(using: .utf8)!])
        let service = HttpService(urlSession: mockUrlSession)
        let client = NeoClient(config: .init(service: service))

        let output = try await client.getBlockHash(input: GetBlockHashInput(blockIndex: 123))

        XCTAssertEqual(params as? [Int], [123])
        XCTAssertEqual(output.blockHash, try Hash256("0x6b209f2c15bbf5989d8c8dbec9ee6f83699ef95a0cb0d6e9570edeb15febaab1"))
    }

}
