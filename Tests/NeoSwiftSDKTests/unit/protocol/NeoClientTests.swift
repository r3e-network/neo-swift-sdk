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

    func testGetStorageUsesTypedBytesInputAndOutput() async throws {
        let json = """
{
    "jsonrpc": "2.0",
    "id": 1,
    "result": "dmFsdWU="
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
            .data(["getstorage": json.data(using: .utf8)!])
        let service = HttpService(urlSession: mockUrlSession)
        let client = NeoClient(config: .init(service: service))
        let contractHash = try Hash160("03febccf81ac85e3d795bc5cbd4e84e907812aa3")

        let output = try await client.getStorage(input: GetStorageInput(contractHash: contractHash, key: Bytes("key".utf8)))

        XCTAssertEqual(params as? [String], [contractHash.string, Bytes("key".utf8).base64Encoded])
        XCTAssertEqual(output.value, Bytes("value".utf8))
        XCTAssertEqual(output.valueBase64String, "dmFsdWU=")
    }

    func testGetStorageRejectsInvalidBase64Response() async throws {
        let json = """
{
    "jsonrpc": "2.0",
    "id": 1,
    "result": "not-base64!"
}
"""
        let mockUrlSession = MockURLSession()
            .data(["getstorage": json.data(using: .utf8)!])
        let service = HttpService(urlSession: mockUrlSession)
        let client = NeoClient(config: .init(service: service))
        let contractHash = try Hash160("03febccf81ac85e3d795bc5cbd4e84e907812aa3")

        do {
            _ = try await client.getStorage(input: GetStorageInput(contractHash: contractHash, key: Bytes("key".utf8)))
            XCTFail("Expected invalid Base64 storage output to throw.")
        } catch ProtocolError.illegalState(let message) {
            XCTAssertEqual(message, "Neo RPC getstorage returned a value that is not valid Base64.")
        }
    }

    func testStorageInputRejectsMalformedHex() throws {
        let contractHash = try Hash160("03febccf81ac85e3d795bc5cbd4e84e907812aa3")

        XCTAssertThrowsError(try GetStorageInput(contractHash: contractHash, keyHexString: "abc")) { error in
            XCTAssertEqual(error.localizedDescription, "Storage key hex must be an even-length hexadecimal string.")
        }
        XCTAssertThrowsError(try GetStorageInput(contractHash: contractHash, keyHexString: "not-hex")) { error in
            XCTAssertEqual(error.localizedDescription, "Storage key hex must be an even-length hexadecimal string.")
        }
    }

    func testSendRawTransactionUsesTypedBytesInput() async throws {
        let json = """
{
    "jsonrpc": "2.0",
    "id": 1,
    "result": {
        "hash": "0xb0748d216c9c0d0498094cdb50407035917b350fc0338c254b78f944f723b770"
    }
}
"""
        var params: [Any]?
        let rawTransaction = Bytes([0x80, 0x00, 0x00, 0x01])
        let mockUrlSession = MockURLSession()
            .requestInterceptor { request in
                guard let body = request.httpBody,
                      let object = try? JSONSerialization.jsonObject(with: body) as? [String: Any] else {
                    return XCTFail("No JSON-RPC request body")
                }
                params = object["params"] as? [Any]
            }
            .data(["sendrawtransaction": json.data(using: .utf8)!])
        let service = HttpService(urlSession: mockUrlSession)
        let client = NeoClient(config: .init(service: service))

        let output = try await client.sendRawTransaction(input: SendRawTransactionInput(rawTransaction: rawTransaction))

        XCTAssertEqual(params as? [String], [rawTransaction.base64Encoded])
        XCTAssertEqual(output.hash, try Hash256("0xb0748d216c9c0d0498094cdb50407035917b350fc0338c254b78f944f723b770"))
    }

    func testSendRawTransactionInputRejectsMalformedHex() {
        XCTAssertThrowsError(try SendRawTransactionInput(rawTransactionHex: "")) { error in
            XCTAssertEqual(error.localizedDescription, "Raw transaction hex must not be empty.")
        }
        XCTAssertThrowsError(try SendRawTransactionInput(rawTransactionHex: "0x123")) { error in
            XCTAssertEqual(error.localizedDescription, "Raw transaction hex must be an even-length hexadecimal string.")
        }
        XCTAssertThrowsError(try SendRawTransactionInput(rawTransactionHex: "zz")) { error in
            XCTAssertEqual(error.localizedDescription, "Raw transaction hex must be an even-length hexadecimal string.")
        }
    }

}
