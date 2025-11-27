import Foundation
import Logging
@testable import MQTTNIO
import NIO
#if canImport(NIOSSL)
import NIOSSL
#endif
#if canImport(Network)
import Network
#endif
import NIOTransportServices
import Testing

struct MQTTTestContext {
    enum ClientSetupError: Error {
        case invalidCertificateData
    }

    private(set) var group: EventLoopGroup

    #if canImport(Network)
    @available(macOS 10.14, iOS 12.0, tvOS 12.0, watchOS 6.0, *)
    private var tsGroup: NIOTSEventLoopGroup?
    #endif

    init() throws {
        configureLogging()
        try BrokerHarness.shared.startIfNeeded()
        group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        #if canImport(Network)
        if #available(macOS 10.14, iOS 12.0, tvOS 12.0, watchOS 6.0, *) {
            tsGroup = NIOTSEventLoopGroup()
        }
        #endif
    }

    func shutdown() {
        try? group.syncShutdownGracefully()
        #if canImport(Network)
        if #available(macOS 10.14, iOS 12.0, tvOS 12.0, watchOS 6.0, *) {
            try? tsGroup?.syncShutdownGracefully()
        }
        #endif
    }

    var defaultClient: MQTTClient {
        MQTTClient(configuration: .init(
            target: .host("localhost", port: 1883),
            reconnectMode: .none
        ), eventLoopGroupProvider: .shared(group))
    }

    var wsClient: MQTTClient {
        MQTTClient(configuration: .init(
            target: .host("localhost", port: 1884),
            webSockets: .enabled,
            reconnectMode: .none
        ), eventLoopGroupProvider: .shared(group))
    }

    var tlsNoVerifyClient: MQTTClient {
        MQTTClient(configuration: .init(
            target: .host("localhost", port: 8883),
            tls: .noVerification,
            reconnectMode: .none
        ), eventLoopGroupProvider: .shared(eventLoopGroupForTLS))
    }

    var wsTLSNoVerifyClient: MQTTClient {
        MQTTClient(configuration: .init(
            target: .host("localhost", port: 8884),
            tls: .noVerification,
            webSockets: .enabled,
            reconnectMode: .none
        ), eventLoopGroupProvider: .shared(eventLoopGroupForTLS))
    }

    var nioSSLTLSClient: MQTTClient {
        get throws {
            let rootDir = URL(fileURLWithPath: #file)
                .deletingLastPathComponent()
                .deletingLastPathComponent()
                .deletingLastPathComponent()
                .deletingLastPathComponent()
            let caCertifcateURL = rootDir.appendingPathComponent("mosquitto/certs/ca.crt")
            let caCertificate = try NIOSSLCertificate.fromPEMFile(caCertifcateURL.path)[0]

            var tlsConfig = TLSConfiguration.makeClientConfiguration()
            tlsConfig.certificateVerification = .noHostnameVerification
            tlsConfig.trustRoots = .certificates([caCertificate])

            return MQTTClient(configuration: .init(
                target: .host("localhost", port: 8883),
                tls: .nioSSL(tlsConfig)
            ), eventLoopGroupProvider: .shared(group))
        }
    }

    #if canImport(Network)
    @available(macOS 10.14, iOS 12.0, tvOS 12.0, watchOS 6.0, *)
    var transportServicesTLSClient: MQTTClient {
        get throws {
            let rootDir = URL(fileURLWithPath: #file)
                .deletingLastPathComponent()
                .deletingLastPathComponent()
                .deletingLastPathComponent()
                .deletingLastPathComponent()
            let caCertifcateURL = rootDir.appendingPathComponent("mosquitto/certs/ca.der")

            let caCertificateData = try Data(contentsOf: caCertifcateURL)
            guard let caCertificate = SecCertificateCreateWithData(nil, caCertificateData as CFData) else {
                throw ClientSetupError.invalidCertificateData
            }

            let tlsConfig = TSTLSConfiguration(
                certificateVerification: .noHostnameVerification,
                trustRoots: .certificates([caCertificate])
            )

            return MQTTClient(configuration: .init(
                target: .host("localhost", port: 8883),
                tls: .transportServices(tlsConfig)
            ), eventLoopGroupProvider: .shared(eventLoopGroupForTLS))
        }
    }
    #endif

    private var eventLoopGroupForTLS: EventLoopGroup {
        #if canImport(Network)
        if #available(macOS 10.14, iOS 12.0, tvOS 12.0, watchOS 6.0, *) {
            if let tsGroup = tsGroup { return tsGroup }
        }
        #endif
        return group
    }

    func wait(seconds: Int) async {
        try? await Task.sleep(for: .seconds(seconds))
    }
}

func withTestContext(_ body: (MQTTTestContext) async throws -> Void) async throws {
    let context = try MQTTTestContext()
    defer { context.shutdown() }
    try await body(context)
}

private func configureLogging() {
    if !isLoggingConfigured {
        _ = isLoggingConfigured
    }
}

private let isLoggingConfigured: Bool = {
    LoggingSystem.bootstrap { label in
        var handler = StreamLogHandler.standardOutput(label: label)
        handler.logLevel = .debug
        return handler
    }
    return true
}()
