import Foundation
@testable import MQTTNIO
import Testing

@Suite
struct MQTT5Tests {
    private func limitedClient(_ context: MQTTTestContext) -> MQTTClient {
        MQTTClient(configuration: .init(
            target: .host("localhost", port: 1886),
            protocolVersion: .version5,
            reconnectMode: .none
        ), eventLoopGroupProvider: .shared(context.group))
    }

    @Test
    func maxKeepAlive() async throws {
        try await withTestContext { context in
            let client = limitedClient(context)
            client.configuration.keepAliveInterval = .seconds(60)

            let response = try await client.connect()
            #expect(response.keepAliveInterval == .seconds(30))
        }
    }

    @Test
    func defaultBrokerConfiguration() async throws {
        try await withTestContext { context in
            let client = context.defaultClient

            let response = try await client.connect()
            #expect(response.brokerConfiguration.isRetainAvailable == true)
            #expect(response.brokerConfiguration.maximumPacketSize == nil)
            #expect(response.brokerConfiguration.maximumQoS == .exactlyOnce)
        }
    }

    @Test
    func limitedBrokerConfiguration() async throws {
        try await withTestContext { context in
            let client = limitedClient(context)

            let response = try await client.connect()
            #expect(response.brokerConfiguration.isRetainAvailable == false)
            #expect(response.brokerConfiguration.maximumPacketSize == 100)
            #expect(response.brokerConfiguration.maximumQoS == .atLeastOnce)
        }
    }

    @Test
    func maximumPacketSize() async throws {
        try await withTestContext { context in
            let client = limitedClient(context)
            try await client.connect()

            let topic = "mqtt-nio/tests/maximum-packet-size"

            let smallPublish = Data(repeating: 1, count: 10)
            try await client.publish(.bytes(smallPublish.byteBuffer), to: topic)

            let largePublish = Data(repeating: 1, count: 100)
            do {
                try await client.publish(.bytes(largePublish.byteBuffer), to: topic)
                Issue.record("Expected packetTooLarge error")
            } catch {
                #expect((error as? MQTTProtocolError)?.code == .packetTooLarge)
            }

            #expect(client.isConnected)
        }
    }

    @Test
    func maximumQoS() async throws {
        try await withTestContext { context in
            let client = limitedClient(context)
            try await client.connect()

            let topic = "mqtt-nio/tests/maximum-qos"

            try await client.publish("test1", to: topic, qos: .atMostOnce)
            try await client.publish("test2", to: topic, qos: .atLeastOnce)
            try await client.publish("test3", to: topic, qos: .exactlyOnce)
        }
    }

    @Test
    func noLocal() async throws {
        try await withTestContext { context in
            let client = context.defaultClient
            try await client.connect()

            let topic = "mqtt-nio/tests/no-local"
            let payload = "Hello World!"

            try await client.subscribe(to: topic, options: .init(noLocalMessages: true))

            do {
                _ = try await waitForMessages(client, expectedCount: 1, timeout: .seconds(1)) {
                    try await client.publish(payload, to: topic)
                }
                Issue.record("Should not receive payload when noLocal flag is used")
            } catch is TestTimeoutError {
                // expected
            }
        }
    }

    @Test
    func retainAsPublishedFalse() async throws {
        try await withTestContext { context in
            let client = context.defaultClient
            try await client.connect()

            let topic = "mqtt-nio/tests/retain-as-published-false"
            let payload = "Hello World!"

            try await client.publish(to: topic, retain: true)

            try await client.subscribe(to: topic, options: .init(retainAsPublished: false))
            
            let messages = try await waitForMessages(client, expectedCount: 1, timeout: .seconds(1)) {
                try await client.publish(payload, to: topic, retain: true)
            }
            #expect(messages.first?.payload.string == payload)
            #expect(messages.first?.retain == false)

            try await client.publish(to: topic, retain: true)
        }
    }

    @Test
    func retainAsPublishedTrue() async throws {
        try await withTestContext { context in
            let client = context.defaultClient
            try await client.connect()

            let topic = "mqtt-nio/tests/retain-as-published-true"
            let payload = "Hello World!"

            try await client.publish(to: topic, retain: true)

            try await client.subscribe(to: topic, options: .init(retainAsPublished: true))
            
            let messages = try await waitForMessages(client, expectedCount: 1, timeout: .seconds(1)) {
                try await client.publish(payload, to: topic, retain: true)
            }
            #expect(messages.first?.payload.string == payload)
            #expect(messages.first?.retain == true)

            try await client.publish(to: topic, retain: true)
        }
    }

}
