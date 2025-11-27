@testable import MQTTNIO
import Testing

@Suite
struct ConnectTests {
    @Test
    func testConnect() async throws {
        try await withTestContext { context in
            let client = context.defaultClient

            for version in MQTTProtocolVersion.allCases {
                client.configuration.protocolVersion = version

                _ = try await client.connect()
                #expect(client.isConnected)

                try await client.disconnect()
                #expect(!client.isConnected)
            }
        }
    }

    @Test
    func testWSConnect() async throws {
        try await withTestContext { context in
            let client = context.wsClient

            for version in MQTTProtocolVersion.allCases {
                client.configuration.protocolVersion = version

                _ = try await client.connect()
                #expect(client.isConnected)

                try await client.disconnect()
                #expect(!client.isConnected)
            }
        }
    }

    #if os(macOS) || os(Linux)
    @Test
    func testTLSConnect() async throws {
        try await withTestContext { context in
            let client = try context.nioSSLTLSClient
            for version in MQTTProtocolVersion.allCases {
                client.configuration.protocolVersion = version

                _ = try await client.connect()
                #expect(client.isConnected)

                try await client.disconnect()
                #expect(!client.isConnected)
            }
        }
    }
    #endif
}
