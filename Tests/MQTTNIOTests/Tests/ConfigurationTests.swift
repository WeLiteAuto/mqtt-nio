import Foundation
@testable import MQTTNIO
import Testing

@Suite
struct ConfigurationTests {
    private func configuration(forURL urlString: String) throws -> MQTTConfiguration {
        guard let url = URL(string: urlString) else {
            Issue.record("Invalid url passed")
            throw URLError(.badURL)
        }
        return MQTTConfiguration(url: url)
    }

    @Test
    func ipURL() throws {
        let configuration = try configuration(forURL: "192.168.1.123")
        #expect(configuration.target == .host("192.168.1.123", port: 1883))
        #expect(configuration.tls == nil)
        #expect(configuration.webSockets == nil)
    }

    @Test
    func ipPortURL() throws {
        let configuration = try configuration(forURL: "192.168.1.123:1234")
        #expect(configuration.target == .host("192.168.1.123", port: 1234))
        #expect(configuration.tls == nil)
        #expect(configuration.webSockets == nil)
    }

    @Test
    func hostURL() throws {
        let configuration = try configuration(forURL: "test.mosquitto.org")
        #expect(configuration.target == .host("test.mosquitto.org", port: 1883))
        #expect(configuration.tls == nil)
        #expect(configuration.webSockets == nil)
    }

    @Test
    func schemeURL() throws {
        let configuration = try configuration(forURL: "mqtt://test.mosquitto.org")
        #expect(configuration.target == .host("test.mosquitto.org", port: 1883))
        #expect(configuration.tls == nil)
        #expect(configuration.webSockets == nil)
    }

    @Test
    func sslURL() throws {
        let configuration = try configuration(forURL: "mqtts://test.mosquitto.org")
        #expect(configuration.target == .host("test.mosquitto.org", port: 8883))
        #expect(configuration.tls != nil)
        #expect(configuration.webSockets == nil)
    }

    @Test
    func webSocketURL() throws {
        let configuration = try configuration(forURL: "ws://test.mosquitto.org")
        #expect(configuration.target == .host("test.mosquitto.org", port: 80))
        #expect(configuration.tls == nil)
        #expect(configuration.webSockets == .enabled)
    }

    @Test
    func webSocketURLWithPath() throws {
        let configuration = try configuration(forURL: "ws://test.mosquitto.org/some-path")
        #expect(configuration.target == .host("test.mosquitto.org", port: 80))
        #expect(configuration.tls == nil)
        #expect(configuration.webSockets == .init(path: "/some-path"))
    }

    @Test
    func webSocketURLWithQuery() throws {
        let configuration = try configuration(forURL: "ws://test.mosquitto.org?key1=value1&key2=value2")
        #expect(configuration.target == .host("test.mosquitto.org", port: 80))
        #expect(configuration.tls == nil)
        #expect(configuration.webSockets == .init(path: "?key1=value1&key2=value2"))
    }

    @Test
    func webSocketURLWithPathAndQuery() throws {
        let configuration = try configuration(forURL: "ws://test.mosquitto.org/some-other-path?key1=value1&key2=value2")
        #expect(configuration.target == .host("test.mosquitto.org", port: 80))
        #expect(configuration.tls == nil)
        #expect(configuration.webSockets == .init(path: "/some-other-path?key1=value1&key2=value2"))
    }

    @Test
    func webSocketHTTPURL() throws {
        let configuration = try configuration(forURL: "http://test.mosquitto.org")
        #expect(configuration.target == .host("test.mosquitto.org", port: 80))
        #expect(configuration.tls == nil)
        #expect(configuration.webSockets == .enabled)
    }

    @Test
    func webSocketSSLURL() throws {
        let configuration = try configuration(forURL: "wss://test.mosquitto.org")
        #expect(configuration.target == .host("test.mosquitto.org", port: 443))
        #expect(configuration.tls != nil)
        #expect(configuration.webSockets == .enabled)
    }

    @Test
    func webSocketHTTPSSLURL() throws {
        let configuration = try configuration(forURL: "https://test.mosquitto.org")
        #expect(configuration.target == .host("test.mosquitto.org", port: 443))
        #expect(configuration.tls != nil)
        #expect(configuration.webSockets == .enabled)
    }

    @Test
    func portURL() throws {
        let configuration = try configuration(forURL: "mqtt://test.mosquitto.org:8883")
        #expect(configuration.target == .host("test.mosquitto.org", port: 8883))
        #expect(configuration.tls == nil)
        #expect(configuration.webSockets == nil)
    }

    @Test
    func wsPortURL() throws {
        let configuration = try configuration(forURL: "wss://test.mosquitto.org:8091")
        #expect(configuration.target == .host("test.mosquitto.org", port: 8091))
        #expect(configuration.tls != nil)
        #expect(configuration.webSockets == .enabled)
    }

    @Test
    func invalidScheme() throws {
        let configuration = try configuration(forURL: "ssh://test.mosquitto.org")
        #expect(configuration.target == .host("test.mosquitto.org", port: 1883))
        #expect(configuration.tls == nil)
        #expect(configuration.webSockets == nil)
    }
}
