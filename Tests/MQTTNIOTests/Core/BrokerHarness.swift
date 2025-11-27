import Foundation
import NIOConcurrencyHelpers

/// Lightweight test harness that spawns local Mosquitto brokers required by the
/// integration tests. It launches the following listeners:
///  - 1883 / 8883 / 1884 / 8884 from `mosquitto-default.conf`
///  - 1885 from `mosquitto-authenticated.conf`
///  - 1886 from `mosquitto-limited.conf`
///
/// The harness starts brokers once per test run and tears them down when all
/// tests have finished.
final class BrokerHarness: @unchecked Sendable {
    enum Error: Swift.Error, CustomStringConvertible {
        case missingMosquittoBinary
        case failedToStartProcess(arguments: [String])

        var description: String {
            switch self {
            case .missingMosquittoBinary:
                return "Unable to locate `mosquitto` executable in PATH"
            case .failedToStartProcess(let arguments):
                return "Failed to start mosquitto with arguments: \(arguments)"
            }
        }
    }

    static let shared = BrokerHarness()

    private let lock = NIOLock()
    private var processes: [Process] = []

    private init() {}

    /// Start the mosquitto instances if they are not already running.
    func startIfNeeded() throws {
        try lock.withLock {
            guard processes.isEmpty else { return }

            guard let mosquittoPath = Self.findExecutable(named: "mosquitto") else {
                throw Error.missingMosquittoBinary
            }

            let rootDir = Self.repositoryRoot()

            let configPaths = [
                rootDir.appendingPathComponent("mosquitto/mosquitto-default.conf"),
                rootDir.appendingPathComponent("mosquitto/mosquitto-authenticated.conf"),
                rootDir.appendingPathComponent("mosquitto/mosquitto-limited.conf"),
            ]

            for configURL in configPaths {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: mosquittoPath)
                process.arguments = ["-c", configURL.path, "-v"]
                process.currentDirectoryURL = rootDir

                // Capture logs in case the broker fails to boot; they are still
                // helpful when printed to STDOUT.
                let pipe = Pipe()
                process.standardOutput = pipe
                process.standardError = pipe

                pipe.fileHandleForReading.readabilityHandler = { handle in
                    let data = handle.availableData
                    if !data.isEmpty, let text = String(data: data, encoding: .utf8) {
                        print(text, terminator: "")
                    }
                }

                do {
                    try process.run()
                } catch {
                    throw Error.failedToStartProcess(arguments: process.arguments ?? [])
                }

                processes.append(process)
            }
        }
    }

    /// Terminate any running mosquitto instances.
    func stop() {
        lock.withLock {
            for process in processes {
                if process.isRunning {
                    process.terminate()
                    process.waitUntilExit()
                }
            }
            processes.removeAll()
        }
    }

    private static func findExecutable(named name: String) -> String? {
        let paths = (ProcessInfo.processInfo.environment["PATH"] ?? "").split(separator: ":")
        for path in paths {
            let candidate = URL(fileURLWithPath: String(path)).appendingPathComponent(name)
            if FileManager.default.isExecutableFile(atPath: candidate.path) {
                return candidate.path
            }
        }
        return nil
    }
}

extension BrokerHarness {
    fileprivate static func repositoryRoot() -> URL {
        var candidate = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent() // Core

        while candidate.path != "/" {
            let manifest = candidate.appendingPathComponent("Package.swift")
            if FileManager.default.fileExists(atPath: manifest.path) {
                return candidate
            }
            candidate.deleteLastPathComponent()
        }

        fatalError("Unable to locate repository root containing Package.swift")
    }
}
