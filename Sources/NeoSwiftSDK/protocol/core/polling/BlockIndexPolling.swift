#if canImport(Combine)
import Combine
import Foundation

public actor BlockIndexActor {
    
    var blockIndex: Int? = nil
    
    func setIndex(_ index: Int) {
        blockIndex = index
    }
    
}

public struct BlockIndexPolling {
    
    var currentBlockIndex = BlockIndexActor()
    
    public func blockIndexPublisher(_ rpcClient: NeoRpcClient, _ executor: DispatchQueue, _ pollingInterval: Int) -> AnyPublisher<Int, Error> {
        return Timer.publish(every: Double(pollingInterval) / 1000, on: .main, in: .common)
            .autoconnect()
            .setFailureType(to: Error.self)
            .asyncMap { _ -> [Int]? in
                let latestBlockIndex = try await rpcClient.getBlockCount().send().getResult() - 1
                if await currentBlockIndex.blockIndex == nil {
                    await currentBlockIndex.setIndex(latestBlockIndex)
                    return [latestBlockIndex]
                }
                let currentIdx = await currentBlockIndex.blockIndex ?? 0
                if latestBlockIndex > currentIdx {
                    await currentBlockIndex.setIndex(latestBlockIndex)
                    return Array((currentIdx + 1)...latestBlockIndex)
                }
                return nil
            }
            .compactMap { $0 }
            .flatMap { $0.publisher.setFailureType(to: Error.self) }
            .subscribe(on: executor)
            .eraseToAnyPublisher()
    }
    
}


extension Publisher {
    /// Maps values using an async transformation without blocking threads
    func asyncMap<T>(
        _ transform: @escaping (Output) async throws -> T
    ) -> Publishers.FlatMap<Future<T, Error>, Self> {
        flatMap(maxPublishers: .max(1)) { value in
            Future<T, Error> { promise in
                nonisolated(unsafe) let promise = promise
                nonisolated(unsafe) let value = value
                nonisolated(unsafe) let transform = transform
                Task {
                    do {
                        let output = try await transform(value)
                        promise(.success(output))
                    } catch {
                        promise(.failure(error))
                    }
                }
            }
        }
    }
    
    /// Legacy syncMap for backward compatibility - DEPRECATED
    @available(*, deprecated, renamed: "asyncMap", message: "Use asyncMap instead to avoid thread blocking")
    func syncMap<T>(
        _ transform: @escaping (Output) async throws -> T
    ) -> Publishers.FlatMap<Future<T, Error>, Self> {
        return asyncMap(transform)
    }
}
#endif
