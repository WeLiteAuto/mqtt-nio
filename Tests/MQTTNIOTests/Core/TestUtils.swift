import Foundation
import NIO
@testable import MQTTNIO
import Testing

struct TestTimeoutError: Error {}

func waitForFuture<T: Sendable>(_ future: EventLoopFuture<T>, timeout: Duration = .seconds(2)) async throws -> T {
    try await withThrowingTaskGroup(of: T.self) { group in
        group.addTask {
            try await future.get()
        }
        group.addTask {
            try await Task.sleep(for: timeout)
            throw TestTimeoutError()
        }
        guard let result = try await group.next() else {
            throw TestTimeoutError()
        }
        group.cancelAll()
        return result
    }
}

func waitForMessages(
    _ client: MQTTClient,
    expectedCount: Int = 1,
    timeout: Duration = .seconds(2),
    action: () async throws -> Void
) async throws -> [MQTTMessage] {
    let stream = AsyncStream<MQTTMessage> { continuation in
        let cancellable = client.whenMessage { message in
            continuation.yield(message)
        }
        continuation.onTermination = { @Sendable _ in
            cancellable.cancel()
        }
    }
    
    return try await withThrowingTaskGroup(of: [MQTTMessage].self) { group in
        group.addTask {
            var messages: [MQTTMessage] = []
            for await message in stream {
                messages.append(message)
                if messages.count >= expectedCount {
                    break
                }
            }
            return messages
        }
        
        try await action()
        
        group.addTask {
            try await Task.sleep(for: timeout)
            throw TestTimeoutError()
        }
        
        guard let result = try await group.next() else {
            throw TestTimeoutError()
        }
        group.cancelAll()
        return result
    }
}

