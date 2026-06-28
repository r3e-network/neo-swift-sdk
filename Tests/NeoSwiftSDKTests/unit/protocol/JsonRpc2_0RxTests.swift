#if canImport(Combine)
import Combine
import XCTest
@testable import NeoSwiftSDK

class JsonRpc2_0RxTests: XCTestCase {
    
    var rpcClient: NeoRpcClient!
    var mockUrlSession: MockURLSession!
    
    var cancellables: Set<AnyCancellable> = []
    
    override func setUp() {
        super.setUp()
        mockUrlSession = MockURLSession()
        rpcClient = NeoRpcClient.build(HttpService(urlSession: mockUrlSession), .init(pollingInterval: 50))
    }
    
    public func testReplayBlocksObservable() {
        let neoGetBlocks = [MockBlocks.createBlock(0), MockBlocks.createBlock(1), MockBlocks.createBlock(2)]
        neoGetBlocks.map { encode($0) }.forEach { _ = mockUrlSession.data($0) }
        
        let publisher = rpcClient.replayBlocksPublisher(0, 2, false)
        let expectation = XCTestExpectation()
        var results: [NeoGetBlock] = []
        
        publisher.sink { completion in
            switch completion {
            case .finished: expectation.fulfill()
            case .failure(let error): XCTFail(error.localizedDescription)
            }
        } receiveValue: { results.append($0) }.store(in: &cancellables)
        
        _ = XCTWaiter.wait(for: [expectation], timeout: 5)

        XCTAssertEqual(results.map(\.block), neoGetBlocks.map(\.block!))
    }
    
    public func testReplayBlocksDescendingObservable() {
        let neoGetBlocks = [MockBlocks.createBlock(2), MockBlocks.createBlock(1), MockBlocks.createBlock(0)]
        neoGetBlocks.map { encode($0) }.forEach { _ = mockUrlSession.data($0) }
        
        let publisher = rpcClient.replayBlocksPublisher(0, 2, false, false)
        let expectation = XCTestExpectation()
        var results: [NeoGetBlock] = []
        
        publisher.sink { completion in
            switch completion {
            case .finished: expectation.fulfill()
            case .failure(let error): XCTFail(error.localizedDescription)
            }
        } receiveValue: { results.append($0) }.store(in: &cancellables)
        
        _ = XCTWaiter.wait(for: [expectation], timeout: 5)

        XCTAssertEqual(results.map(\.block), neoGetBlocks.map(\.block!))
    }
    
    public func testCatchUpToLatestAndSubscribeToNewBlockObservable() {
        let neoGetBlocks = [MockBlocks.createBlock(0), MockBlocks.createBlock(1), MockBlocks.createBlock(2), MockBlocks.createBlock(3),
                            MockBlocks.createBlock(4), MockBlocks.createBlock(5), MockBlocks.createBlock(6)]
        
        let blockCounts = (4...7).map { encode(NeoBlockCount($0)) }
        _ = mockUrlSession.data(["getblockcount": blockCounts, "getblockheader": neoGetBlocks.map { encode($0) }])
        
        let publisher = rpcClient.catchUpToLatestAndSubscribeToNewBlocksPublisher(0, false)
        let expectation = XCTestExpectation()
        var results: [NeoGetBlock] = []
        let expectedBlocks = neoGetBlocks.map(\.block!)
        
        let cancellable = publisher.sink { completion in
            switch completion {
            case .finished: expectation.fulfill()
            case .failure(let error): XCTFail(error.localizedDescription)
            }
        } receiveValue: {
            results.append($0)
            if results.count == expectedBlocks.count {
                expectation.fulfill()
            }
        }
        
        cancellable.store(in: &cancellables)
        
        _ = XCTWaiter.wait(for: [expectation], timeout: 5)
        cancellable.cancel()
        
        let receivedBlocks = results.map(\.block!)
        XCTAssertGreaterThanOrEqual(receivedBlocks.count, expectedBlocks.count)
        XCTAssertEqual(Array(receivedBlocks.prefix(expectedBlocks.count)), expectedBlocks)
    }
    
    public func testSubscribeToNewBlockObservable() {
        let neoGetBlocks = [MockBlocks.createBlock(0), MockBlocks.createBlock(1), MockBlocks.createBlock(2), MockBlocks.createBlock(3)]
        
        let blockCounts = (1...4).map { encode(NeoBlockCount($0)) }
        _ = mockUrlSession.data(["getblockcount": blockCounts, "getblockheader": neoGetBlocks.map { encode($0) }])
        
        let publisher = rpcClient.subscribeToNewBlocksPublisher(false)
        let expectation = XCTestExpectation()
        var results: [NeoGetBlock] = []
        let expectedBlocks = neoGetBlocks.map(\.block!)
        
        let cancellable = publisher.sink { completion in
            switch completion {
            case .finished: expectation.fulfill()
            case .failure(let error): XCTFail(error.localizedDescription)
            }
        } receiveValue: {
            results.append($0)
            if results.count == expectedBlocks.count {
                expectation.fulfill()
            }
        }
        
        cancellable.store(in: &cancellables)
        
        _ = XCTWaiter.wait(for: [expectation], timeout: 5)
        cancellable.cancel()
        
        let receivedBlocks = results.map(\.block!)
        XCTAssertGreaterThanOrEqual(receivedBlocks.count, expectedBlocks.count)
        XCTAssertEqual(Array(receivedBlocks.prefix(expectedBlocks.count)), expectedBlocks)
    }
    
    public func encode<T: Response<U>, U: Codable>(_ t: T) -> Data {
        return try! JSONEncoder().encode(t)
    }
    
}
#endif
    
