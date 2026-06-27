
import XCTest
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
@testable import NeoSwiftSDK

class HttpServiceTests: XCTestCase {
    
    func testAddHeader() {
        let httpService = HttpService()
        
        let headerName = "customized_header0"
        let headerValue = "customized_value0"
        httpService.addHeader(headerName, headerValue)
        XCTAssertEqual(httpService.headers[headerName], headerValue)
    }
    
    func testAddHeaders() {
        let httpService = HttpService()

        let headerName1 = "customized_header1"
        let headerValue1 = "customized_value1"
        
        let headerName2 = "customized_header2"
        let headerValue2 = "customized_value2"
    
        let headersToAdd = [headerName1 : headerValue1, headerName2 : headerValue2]
        
        httpService.addHeaders(headersToAdd)
        
        XCTAssertEqual(httpService.headers[headerName1], headerValue1)
        XCTAssertEqual(httpService.headers[headerName2], headerValue2)
    }
    
    public func testURLError() async {
//        let content = "400 Error"
        let error = URLError(.badServerResponse)
        
        let httpService = HttpService(urlSession: MockURLSession().error(error))
        let request = Request<Response<NeoBlockCount>, NeoBlockCount>(method: "getblockCount", params: [], service: httpService)
        
        do {
            _ = try await httpService.send(request)
            XCTFail("No exception")
        } catch {
            XCTAssert(error.localizedDescription.contains("Invalid response received: \(URLError.Code.badServerResponse.rawValue);"))
        }
    }

    public func testHTTPStatusError() async {
        let response = HTTPURLResponse(url: HttpService.DEFAULT_URL, statusCode: 503, httpVersion: nil, headerFields: nil)!
        let httpService = HttpService(urlSession: MockURLSession().data(Data("node unavailable".utf8)).response(response))
        let request = Request<Response<NeoBlockCount>, NeoBlockCount>(method: "getblockcount", params: [], service: httpService)

        do {
            _ = try await httpService.send(request)
            XCTFail("No exception")
        } catch {
            XCTAssertEqual(error.localizedDescription, "HTTP 503 Service Unavailable: node unavailable")
        }
    }

    public func testRequestTimeoutConfiguration() async throws {
        let mockSession = MockURLSession().requestInterceptor { request in
            XCTAssertEqual(request.timeoutInterval, 7)
        }
        let httpService = HttpService(urlSession: mockSession, requestTimeout: 7)
        let request = Request<Response<NeoBlockCount>, NeoBlockCount>(method: "getblockcount", params: [], service: httpService)

        _ = try? await httpService.send(request)
    }
    
    func testRawResponse() async {
        let json = """
{
    "id": 67,
    "jsonrpc": "2.0",
    "result": {
        "port": 1234,
        "nonce": 12345678,
        "useragent": "\\/NEO:2.7.6\\/"
    }
}
"""
        let httpServiceNoRaw = HttpService(urlSession: MockURLSession().data(json.data(using: .utf8)!))
        let httpServiceRaw = HttpService(urlSession: MockURLSession().data(json.data(using: .utf8)!), includeRawResponses: true)

        let requestNoRaw = Request<NeoGetVersion, NeoGetVersion.NeoVersion>(method: "getversion", params: [], service: httpServiceNoRaw)
        let requestRaw = Request<NeoGetVersion, NeoGetVersion.NeoVersion>(method: "getversion", params: [], service: httpServiceRaw)

        let nonRawResponse = try! await httpServiceNoRaw.send(requestNoRaw)
        let rawResponse = try! await httpServiceRaw.send(requestRaw)
        
        XCTAssertNil(nonRawResponse.rawResponse)
        XCTAssertEqual(rawResponse.rawResponse, json)
    }
    
}
