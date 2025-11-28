import Foundation
@testable import MQTTNIO
import Testing

@Suite
struct PublishTests {
    @Test
    func qos0() async throws {
        try await withTestContext { context in
            let client = context.defaultClient

            for version in MQTTProtocolVersion.allCases {
                client.configuration.protocolVersion = version

                try await client.connect()
                let topic = "mqtt-nio/tests/qos0"
                let payload = "Hello World!"
                let qos: MQTTQoS = .atMostOnce

                let response = try await client.subscribe(to: topic, qos: qos)
                #expect(response.result == .success(qos))

                let messages = try await waitForMessages(client, expectedCount: 1) {
                    try await client.publish(payload, to: topic, qos: qos)
                }
                #expect(messages.first?.payload.string == payload)
                #expect(messages.first?.qos == qos)

                try await client.disconnect()
            }
        }
    }

    @Test
    func qos1() async throws {
        try await withTestContext { context in
            let client = context.defaultClient

            for version in MQTTProtocolVersion.allCases {
                client.configuration.protocolVersion = version

                try await client.connect()
                let topic = "mqtt-nio/tests/qos1"
                let payload = "Hello World!"
                let qos: MQTTQoS = .atLeastOnce

                let response = try await client.subscribe(to: topic, qos: qos)
                #expect(response.result == .success(qos))

                let messages = try await waitForMessages(client, expectedCount: 1) {
                    try await client.publish(payload, to: topic, qos: qos)
                }
                #expect(messages.first?.payload.string == payload)
                #expect(messages.first?.qos == qos)

                try await client.disconnect()
            }
        }
    }

    @Test
    func qos2() async throws {
        try await withTestContext { context in
            let client = context.defaultClient

            for version in MQTTProtocolVersion.allCases {
                client.configuration.protocolVersion = version

                try await client.connect()
                let topic = "mqtt-nio/tests/qos2"
                let payload = "Hello World!"
                let qos: MQTTQoS = .exactlyOnce

                let response = try await client.subscribe(to: topic, qos: qos)
                #expect(response.result == .success(qos))

                let messages = try await waitForMessages(client, expectedCount: 1) {
                    try await client.publish(payload, to: topic, qos: qos)
                }
                #expect(messages.first?.payload.string == payload)
                #expect(messages.first?.qos == qos)

                try await client.disconnect()
            }
        }
    }

    @Test
    func retain() async throws {
        try await withTestContext { context in
            let client = context.defaultClient

            for version in MQTTProtocolVersion.allCases {
                client.configuration.protocolVersion = version

                try await client.connect()
                let topic = "mqtt-nio/tests/retain"
                let payload = "Hello World!"

                try await client.publish(to: topic, retain: true)

                try await client.subscribe(to: topic)
                
                let first = try await waitForMessages(client, expectedCount: 1) {
                    try await client.publish(payload, to: topic, retain: true)
                }
                #expect(first.first?.payload.string == payload)
                #expect(first.first?.retain == false)

                try await client.disconnect()
                try await client.connect()
                
                // For the second part, the message comes immediately after subscribe.
                // We must setup listener BEFORE subscribe.
                let second = try await waitForMessages(client, expectedCount: 1) {
                    try await client.subscribe(to: topic)
                }
                #expect(second.first?.payload.string == payload)
                #expect(second.first?.retain == true)

                try await client.publish(to: topic, retain: true)

                try await client.disconnect()
            }
        }
    }

    @Test
    func keepSession() async throws {
        try await withTestContext { context in
            let client = context.defaultClient
            client.configuration.clean = false
            client.configuration.sessionExpiry = .afterInterval(.seconds(60))

            for version in MQTTProtocolVersion.allCases {
                client.configuration.protocolVersion = version

                let topic = "mqtt-nio/tests/keep-session"
                let payload = "Hello World!"

                try await client.connect()
                try await client.subscribe(to: topic)
                try await client.disconnect()
                try await client.connect()
                
                let messages = try await waitForMessages(client, expectedCount: 1) {
                    try await client.publish(payload, to: topic)
                }
                #expect(messages.first?.payload.string == payload)

                try await client.disconnect()
            }
        }
    }

    @Test
    func notKeepingSession() async throws {
        try await withTestContext { context in
            let client = context.defaultClient
            client.configuration.clean = false
            client.configuration.sessionExpiry = .atClose

            let topic = "mqtt-nio/tests/not-keeping-session"
            let payload = "Hello World!"

            try await client.connect()
            try await client.subscribe(to: topic)
            try await client.disconnect()
            try await client.connect()
            
            do {
                _ = try await waitForMessages(client, expectedCount: 1, timeout: .seconds(2)) {
                    try await client.publish(payload, to: topic)
                }
                Issue.record("Should not receive retained message when session is not kept")
            } catch is TestTimeoutError {
                // expected
            }
        }
    }

    @Test
    func multiSubscribe() async throws {
        try await withTestContext { context in
            let client = context.defaultClient

            for version in MQTTProtocolVersion.allCases {
                client.configuration.protocolVersion = version

                try await client.connect()

                let response = try await client.subscribe(to: [
                    MQTTSubscription(topicFilter: "mqtt-nio/tests/multi-subscribe/1", qos: .atMostOnce),
                    MQTTSubscription(topicFilter: "mqtt-nio/tests/multi-subscribe/2", qos: .atLeastOnce),
                    MQTTSubscription(topicFilter: "mqtt-nio/tests/multi-subscribe/3", qos: .exactlyOnce)
                ])

                #expect(response.results.count == 3)
                #expect(response.results[0] == .success(.atMostOnce))
                #expect(response.results[1] == .success(.atLeastOnce))
                #expect(response.results[2] == .success(.exactlyOnce))

                try await client.disconnect()
            }
        }
    }

    @Test
    func unsubscribe() async throws {
        try await withTestContext { context in
            let client = context.defaultClient

            for version in MQTTProtocolVersion.allCases {
                client.configuration.protocolVersion = version

                try await client.connect()

                let topic = "mqtt-nio/tests/unsubscribe"
                let payload = "Hello World!"

                try await client.subscribe(to: topic)

                // 1. Verify we receive message when subscribed
                let messages = try await waitForMessages(client, expectedCount: 1) {
                    try await client.publish(payload, to: topic)
                }
                #expect(messages.first?.payload.string == payload)

                try await client.unsubscribe(from: topic)

                // 2. Verify we DO NOT receive message after unsubscribe
                do {
                    _ = try await waitForMessages(client, expectedCount: 1, timeout: .seconds(1)) {
                        try await client.publish(payload, to: topic)
                    }
                    Issue.record("Should not have received a message after unsubscribe")
                } catch is TestTimeoutError {
                    // expected
                }

                try await client.disconnect()
            }
        }
    }

    @Test
    func keepAlive() async throws {
        try await withTestContext { context in
            let client = context.defaultClient
            client.configuration.keepAliveInterval = .seconds(1)

            for version in MQTTProtocolVersion.allCases {
                client.configuration.protocolVersion = version

                try await client.connect()
                await context.wait(seconds: 3)

                let topic = "mqtt-nio/tests/keep-alive"
                let payload = "Hello World!"

                #expect(client.isConnected)
                try await client.publish(payload, to: topic)

                try await client.disconnect()
            }
        }
    }

    @Test
    func invalidClient() async throws {
        try await withTestContext { context in
            let client = context.defaultClient
            client.configuration.clientId = ""
            client.configuration.clean = false

            for version in MQTTProtocolVersion.allCases {
                client.configuration.protocolVersion = version

                do {
                    _ = try await client.connect()
                    Issue.record("Should not be able to succesfully connect with an empty client id")
                } catch {
                    guard let reasonCode = (error as? MQTTConnectionError)?.serverReasonCode else {
                        Issue.record("Unexpected error type: \(error)")
                        return
                    }

                    #expect(reasonCode == .clientIdentifierNotValid || reasonCode == .unspecifiedError)
                }
            }
        }
    }
}
