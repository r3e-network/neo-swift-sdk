
typealias NeoResponse = Response

public struct Request<T, U>: Codable, @unchecked Sendable where T: Response<U> {
        
    public let jsonrpc = "2.0"
    public let method: String
    public let params: [AnyHashable]
    public let id: Int
    private var service: NeoRpcService?
    
    public init(method: String, params: [AnyHashable], service: NeoRpcService) {
        self.method = method
        self.params = params
        self.id = NeoRpcClientConfiguration.REQUEST_COUNTER.getAndIncrement()
        self.service = service
    }
    
    public func send() async throws -> T {
        guard let service = service else {
            throw ProtocolError.illegalState("NeoRpcService not initialized")
        }
        return try await service.send(self)
    }
    
    enum CodingKeys: CodingKey {
        case jsonrpc, method, params, id
    }
    
}
