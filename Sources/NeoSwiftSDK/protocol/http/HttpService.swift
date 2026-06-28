
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public class HttpService: Service {
    
    public static let JSON_MEDIA_TYPE = "application/json; charset=utf-8"
    public static let DEFAULT_URL = URL(string: "http://localhost:10333/")!
    
    /// Default NEO Mainnet RPC endpoints
    public static let MAINNET_URLS = [
        URL(string: "https://mainnet1.neo.coz.io:443")!,
        URL(string: "https://mainnet2.neo.coz.io:443")!,
        URL(string: "https://mainnet3.neo.coz.io:443")!
    ]
    
    /// Default NEO Testnet RPC endpoints  
    public static let TESTNET_URLS = [
        URL(string: "https://testnet1.neo.coz.io:443")!,
        URL(string: "https://testnet2.neo.coz.io:443")!
    ]
    
    public let url: URL
    public let includeRawResponses: Bool
    public let requestTimeout: TimeInterval
    public let allowInsecureConnections: Bool
    public private(set) var headers = [String: String]()
    
    private var urlRequester: URLRequester
    
    /// Create an ``HTTPService`` instance
    /// - Parameters:
    ///   - url: The URL to the HTTP service (JSON-RPC)
    ///   - urlSession: (For mocking) The URLRequester (URLSession) with which to make the request
    ///   - includeRawResponses: Option to include or not raw responses on the ``Response`` object
    ///   - requestTimeout: Request timeout in seconds.
    ///   - allowInsecureConnections: Allows non-local plaintext HTTP endpoints. Keep this `false` for production.
    public init(url: URL = HttpService.DEFAULT_URL, urlSession: URLRequester = URLSession.shared, includeRawResponses: Bool = false, requestTimeout: TimeInterval = 30, allowInsecureConnections: Bool = false) {
        self.url = url
        self.urlRequester = urlSession
        self.includeRawResponses = includeRawResponses
        self.requestTimeout = requestTimeout
        self.allowInsecureConnections = allowInsecureConnections
    }
    
    public func performIO(_ payload: Data) async throws -> Data {
        try validateTransportSecurity()
        var request = URLRequest(url: url, timeoutInterval: requestTimeout)
        request.addValue(HttpService.JSON_MEDIA_TYPE, forHTTPHeaderField: "Content-Type")
        headers.forEach { request.addValue($1, forHTTPHeaderField: $0) }
        request.httpMethod = "POST"
        request.httpBody = payload
        do {
            let (data, response) = try await urlRequester.data(from: request)
            if let httpResponse = response as? HTTPURLResponse,
               !(200..<300).contains(httpResponse.statusCode) {
                let reason = HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)
                throw ProtocolError.clientConnection("HTTP \(httpResponse.statusCode) \(reason). Response body omitted to avoid leaking RPC secrets (\(data.count) bytes).")
            }
            return data
        } catch let error as URLError {
            throw ProtocolError.clientConnection("Invalid response received: \(error.errorCode); \(error.localizedDescription)")
        } catch { throw error }
    }
    
    /// Adds an HTTP header to all ``Request`` calls used by this service.
    /// - Parameters:
    ///   - key: The header name (e.g., "Authorization")
    ///   - value: The header value (e.g., "Bearer secretBearer")
    public func addHeader(_ key: String, _ value: String) {
        headers[key] = value
    }
    
    /// Adds multiple HTTP headers to all ``Request`` calls used by this service.
    /// - Parameter headersToAdd: A key-value map containing keys (e.g., "Authorization") and values (e.g., "Bearer secretBearer")
    public func addHeaders(_ headersToAdd: [String : String]) {
        headersToAdd.forEach { headers[$0] = $1 }
    }
    
    internal func setURLSession(_ urlSession: URLSession) {
        self.urlRequester = urlSession
    }

    private func validateTransportSecurity() throws {
        guard url.scheme?.lowercased() == "http", !allowInsecureConnections, !url.isLocalRpcEndpoint else {
            return
        }
        throw ProtocolError.clientConnection("Refusing plaintext HTTP transport for non-local Neo RPC endpoint \(url.redactedEndpointDescription). Use HTTPS or explicitly set allowInsecureConnections for trusted development networks.")
    }
    
}

private extension URL {

    var isLocalRpcEndpoint: Bool {
        guard let host = host?.lowercased() else {
            return false
        }
        return host == "localhost"
            || host.hasSuffix(".localhost")
            || host == "127.0.0.1"
            || host == "::1"
    }

    var redactedEndpointDescription: String {
        var components = URLComponents(url: self, resolvingAgainstBaseURL: false)
        components?.user = nil
        components?.password = nil
        components?.query = nil
        components?.fragment = nil
        return components?.string ?? "\(scheme ?? "unknown")://<redacted>"
    }

}

public protocol URLRequester {
    func data(from request: URLRequest) async throws -> (Data, URLResponse?)
}
