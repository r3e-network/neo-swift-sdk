#if canImport(Combine)
import Combine
#endif
import Foundation
@testable import NeoSwiftSDK

public class MockNeoRpcClient: NeoRpcClient {
    
#if canImport(Combine)
    public var overrideCatchUpToLatestAndSubscribeToNewBlocksPublisher = false
    
    public override func catchUpToLatestAndSubscribeToNewBlocksPublisher(_ startBlock: Int, _ fullTransactionObjects: Bool) -> AnyPublisher<NeoGetBlock, Error> {
        if overrideCatchUpToLatestAndSubscribeToNewBlocksPublisher {
            return [MockBlocks.createBlock(1000), MockBlocks.createBlock(1001), MockBlocks.createBlock(1002)]
                .publisher.setFailureType(to: Error.self).eraseToAnyPublisher()
        } else { return super.catchUpToLatestBlockPublisher(startBlock, fullTransactionObjects) }
    }
#endif
    
}
