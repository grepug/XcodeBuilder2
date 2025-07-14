//
//  runBash.swift
//
//
//  Created by Kai Shao on 2024/4/12.
//

import Foundation

public enum ShellError2: Error {
    case error(String)
}

private actor CommandRunner {
    var errorOutput = ""

    func setErrorOutput(_ output: String) {
        errorOutput = output
    }

    func run(_ command: String) -> AsyncThrowingStream<String, Error> {
        return .init { continuation in
            let process = Process()
            process.launchPath = "/bin/zsh"
            process.arguments = ["-c", command]

            let pipe = Pipe()
            let pipeError = Pipe()
            process.standardOutput = pipe
            process.standardError = pipeError

            pipe.fileHandleForReading.readabilityHandler = { fileHandle in
                let data = fileHandle.availableData
                continuation.yield(String(data: data, encoding: .utf8) ?? "")
            }

            pipeError.fileHandleForReading.readabilityHandler = { [self] fileHandle in
                let data = fileHandle.availableData
                if let error = String(data: data, encoding: .utf8) {
                    Task {
                        await setErrorOutput(errorOutput + error + "\n")
                    }
                }
            }

            process.terminationHandler = { [self] process in
                pipe.fileHandleForReading.readabilityHandler = nil
                pipeError.fileHandleForReading.readabilityHandler = nil

                if process.terminationStatus != 0 {
                    Task { [self] in
                        let output = await self.errorOutput
                        continuation.finish(throwing: ShellError2.error(output))
                    }
                } else {
                    continuation.finish()
                }
            }

            continuation.onTermination = { reason in
                switch reason {
                case .cancelled:
                    process.terminate()
                default:
                    break
                }
            }

            do {
                try process.run()
            } catch {
                continuation.finish(throwing: error)
            }
        }
    }
}

public func runShellCommand2(_ command: String) async -> AsyncThrowingStream<String, Error> {
    let runner = CommandRunner()
    return await runner.run(command)
}

public extension AsyncSequence where Element == String {
    @discardableResult
    func get() async throws -> String {
        var string = ""
        do {
            for try await str in self {
                string += str
            }

            return string
        } catch {
            throw error
        }
    }
}
