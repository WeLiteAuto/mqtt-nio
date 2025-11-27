@testable import MQTTNIO
import Testing

@Suite
struct AuthenticationTests {
    @Test
    func successLogin() async throws {
        try await withTestContext { context in
            let client = context.defaultClient
            client.configuration.credentials = .init(username: "test", password: "p@ssw0rd")

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
    func notAuthorized() async throws {
        try await withTestContext { context in
            let client = context.defaultClient
            client.configuration.credentials = .init(username: "test", password: "invalid")

            for version in MQTTProtocolVersion.allCases {
                client.configuration.protocolVersion = version

                do {
                    _ = try await client.connect()
                    Issue.record("Password is invalid, so connect cannot succeed")
                } catch {
                    #expect((error as? MQTTConnectionError)?.serverReasonCode == .notAuthorized)
                }

                #expect(!client.isConnected)
            }
        }
    }
}
