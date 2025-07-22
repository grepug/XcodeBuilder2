//
//  ShellCommandRunner.swift
//
//
//  Created by Kai Shao on 2024/4/12.
//

import Foundation

/// Errors that can occur during shell command execution
public enum ShellError: Error, LocalizedError, Equatable {
    case commandFailed(command: String, exitCode: Int32, errorOutput: String)
    case invalidOutput(String)
    case processLaunchFailed(Error)
    case patternMatchFailure(command: String, output: String, pattern: String)
    
    public static func == (lhs: ShellError, rhs: ShellError) -> Bool {
        switch (lhs, rhs) {
        case (.commandFailed(let lCmd, let lCode, let lErr), .commandFailed(let rCmd, let rCode, let rErr)):
            return lCmd == rCmd && lCode == rCode && lErr == rErr
        case (.invalidOutput(let lMsg), .invalidOutput(let rMsg)):
            return lMsg == rMsg
        case (.processLaunchFailed(let lErr), .processLaunchFailed(let rErr)):
            return lErr.localizedDescription == rErr.localizedDescription
        case (.patternMatchFailure(let lCmd, let lOut, let lPat), .patternMatchFailure(let rCmd, let rOut, let rPat)):
            return lCmd == rCmd && lOut == rOut && lPat == rPat
        default:
            return false
        }
    }
    
    public var errorDescription: String? {
        switch self {
        case .commandFailed(let command, let exitCode, let errorOutput):
            return "Command '\(command)' failed with exit code \(exitCode): \(errorOutput)"
        case .invalidOutput(let message):
            return "Invalid command output: \(message)"
        case .processLaunchFailed(let error):
            return "Failed to launch process: \(error.localizedDescription)"
        case .patternMatchFailure(let command, let output, let pattern):
            return "Command '\(command)' failed - found error pattern '\(pattern)' in output: \(output)"
        }
    }
}

/// Configuration for shell command execution
public struct ShellCommandConfig: Sendable {
    /// Error patterns to check for in standard output
    public let errorPatterns: [String]
    /// Whether to throw an error if any error pattern is found
    public let failOnErrorPattern: Bool
    /// Whether to combine stdout and stderr into a single output stream
    public let combineOutputs: Bool
    
    public init(
        errorPatterns: [String] = [],
        failOnErrorPattern: Bool = false,
        combineOutputs: Bool = false
    ) {
        self.errorPatterns = errorPatterns
        self.failOnErrorPattern = failOnErrorPattern
        self.combineOutputs = combineOutputs
    }
    
    /// Common error patterns for various tools
    public static let commonErrorPatterns = [
        "error:", "Error:", "ERROR:",
        "failed:", "Failed:", "FAILED:",
        "fatal:", "Fatal:", "FATAL:",
        "exception:", "Exception:", "EXCEPTION:",
        "Build FAILED",
        "Command failed",
        "No such file or directory",
        "Permission denied",
        "command not found"
    ]
    
    /// Configuration for Xcode build commands
    public static let xcodeConfig = ShellCommandConfig(
        errorPatterns: [
            "Build FAILED",
            "** BUILD FAILED **",
            "error:",
            "fatal error:",
            "Command failed",
            "The following build commands failed:"
        ],
        failOnErrorPattern: true,
        combineOutputs: true
    )
    
    /// Configuration for Git commands
    public static let gitConfig = ShellCommandConfig(
        errorPatterns: [
            "error:",
            "fatal:",
            "Permission denied",
            "No such file or directory",
            "not a git repository"
        ],
        failOnErrorPattern: true
    )
}

/// Result of a shell command execution
public struct ShellCommandResult: Sendable {
    public let output: String
    public let errorOutput: String
    public let exitCode: Int32
    public let matchedErrorPattern: String?
    
    public var isSuccess: Bool {
        return exitCode == 0 && matchedErrorPattern == nil
    }
    
    public var combinedOutput: String {
        if errorOutput.isEmpty {
            return output
        } else if output.isEmpty {
            return errorOutput
        } else {
            return output + "\n" + errorOutput
        }
    }
}

/// Actor responsible for running shell commands asynchronously
private actor CommandRunner {
    private var standardOutput = ""
    private var errorOutput = ""
    private let config: ShellCommandConfig
    
    init(config: ShellCommandConfig = ShellCommandConfig()) {
        self.config = config
    }
    
    func appendStandardOutput(_ output: String) {
        standardOutput += output
    }
    
    func appendErrorOutput(_ output: String) {
        errorOutput += output
    }
    
    func getOutputs() -> (standard: String, error: String) {
        return (standardOutput, errorOutput)
    }
    
    /// Checks if any error patterns match in the given text
    private func checkErrorPatterns(in text: String) async -> String? {
        for pattern in config.errorPatterns {
            if text.localizedCaseInsensitiveContains(pattern) {
                return pattern
            }
        }
        return nil
    }
    
    /// Runs a shell command and returns an async stream of output
    func runStreaming(_ command: String) -> AsyncThrowingStream<String, Error> {
        let (stream, continuation) = AsyncThrowingStream<String, Error>.makeStream()
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-c", command]
        
        let standardPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = standardPipe
        process.standardError = errorPipe
        
        // Handle standard output
        standardPipe.fileHandleForReading.readabilityHandler = { [weak self] fileHandle in
            let data = fileHandle.availableData
            guard !data.isEmpty else { return }
            
            if let output = String(data: data, encoding: .utf8) {
                Task { [weak self] in
                    await self?.appendStandardOutput(output)
                    
                    // Check for error patterns if configured
                    if let self = self,
                       self.config.failOnErrorPattern,
                       let matchedPattern = await self.checkErrorPatterns(in: output) {
                        let error = ShellError.patternMatchFailure(
                            command: command,
                            output: output,
                            pattern: matchedPattern
                        )
                        continuation.finish(throwing: error)
                        return
                    }
                }
                continuation.yield(output)
            }
        }
        
        // Handle error output
        errorPipe.fileHandleForReading.readabilityHandler = { [weak self] fileHandle in
            let data = fileHandle.availableData
            guard !data.isEmpty else { return }
            
            if let error = String(data: data, encoding: .utf8) {
                Task { [weak self] in
                    await self?.appendErrorOutput(error)
                }
                
                // If combining outputs, also yield error output
                if self?.config.combineOutputs == true {
                    continuation.yield(error)
                }
            }
        }
        
        // Handle process termination
        process.terminationHandler = { [weak self] process in
            standardPipe.fileHandleForReading.readabilityHandler = nil
            errorPipe.fileHandleForReading.readabilityHandler = nil
            
            Task { [weak self] in
                guard let self = self else { return }
                let outputs = await self.getOutputs()
                
                // Check for error patterns in final output
                let combinedOutput = self.config.combineOutputs ? outputs.standard + outputs.error : outputs.standard
                let matchedPattern = await self.checkErrorPatterns(in: combinedOutput)
                
                if process.terminationStatus != 0 {
                    let error = ShellError.commandFailed(
                        command: command,
                        exitCode: process.terminationStatus,
                        errorOutput: outputs.error
                    )
                    continuation.finish(throwing: error)
                } else if self.config.failOnErrorPattern, let pattern = matchedPattern {
                    let error = ShellError.patternMatchFailure(
                        command: command,
                        output: combinedOutput,
                        pattern: pattern
                    )
                    continuation.finish(throwing: error)
                } else {
                    continuation.finish()
                }
            }
        }
        
        // Handle cancellation
        continuation.onTermination = { reason in
            switch reason {
            case .cancelled:
                process.terminate()
            default:
                break
            }
        }
        
        // Launch the process
        do {
            try process.run()
        } catch {
            continuation.finish(throwing: ShellError.processLaunchFailed(error))
        }

        return stream
    }
    
    /// Runs a shell command and returns the complete result
    func runComplete(_ command: String) async throws -> ShellCommandResult {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-c", command]
        
        let standardPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = standardPipe
        process.standardError = errorPipe
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let standardData = standardPipe.fileHandleForReading.readDataToEndOfFile()
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            
            let standardOutput = String(data: standardData, encoding: .utf8) ?? ""
            let errorOutput = String(data: errorData, encoding: .utf8) ?? ""
            
            // Check for error patterns
            let combinedOutput = config.combineOutputs ? standardOutput + errorOutput : standardOutput
            let matchedPattern = await checkErrorPatterns(in: combinedOutput)
            
            let result = ShellCommandResult(
                output: standardOutput,
                errorOutput: errorOutput,
                exitCode: process.terminationStatus,
                matchedErrorPattern: matchedPattern
            )
            
            // Throw error if pattern matching is enabled and pattern found
            if config.failOnErrorPattern, let pattern = matchedPattern {
                throw ShellError.patternMatchFailure(
                    command: command,
                    output: combinedOutput,
                    pattern: pattern
                )
            }
            
            return result
        } catch {
            throw ShellError.processLaunchFailed(error)
        }
    }
}

// MARK: - Public API

/// Runs a shell command and returns an async stream of output lines
/// - Parameters:
///   - command: The shell command to execute
///   - config: Configuration for command execution
/// - Returns: An async throwing stream that yields output as it becomes available
public func runShellCommandStreaming(_ command: String, config: ShellCommandConfig = ShellCommandConfig()) async -> AsyncThrowingStream<String, Error> {
    let runner = CommandRunner(config: config)
    return await runner.runStreaming(command)
}

/// Runs a shell command and returns the complete result
/// - Parameters:
///   - command: The shell command to execute
///   - config: Configuration for command execution
/// - Returns: A ShellCommandResult containing all output and exit status
@discardableResult
public func runShellCommandComplete(_ command: String, config: ShellCommandConfig = ShellCommandConfig()) async throws -> ShellCommandResult {
    let runner = CommandRunner(config: config)
    return try await runner.runComplete(command)
}

/// Runs a shell command and returns only the standard output as a string
/// - Parameters:
///   - command: The shell command to execute
///   - config: Configuration for command execution
/// - Returns: The standard output of the command
/// - Throws: ShellError if the command fails
public func runShellCommandForOutput(_ command: String, config: ShellCommandConfig = ShellCommandConfig()) async throws -> String {
    let result = try await runShellCommandComplete(command, config: config)
    guard result.isSuccess else {
        if let pattern = result.matchedErrorPattern {
            throw ShellError.patternMatchFailure(
                command: command,
                output: result.combinedOutput,
                pattern: pattern
            )
        } else {
            throw ShellError.commandFailed(
                command: command,
                exitCode: result.exitCode,
                errorOutput: result.errorOutput
            )
        }
    }
    return result.output.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
}

// MARK: - Convenience Functions

/// Runs an Xcode build command with appropriate error pattern matching
/// - Parameter command: The xcodebuild command to execute
/// - Returns: The command result
/// - Throws: ShellError if the build fails
public func runXcodeBuildCommand(_ command: String) async throws -> ShellCommandResult {
    return try await runShellCommandComplete(command, config: .xcodeConfig)
}

/// Runs a Git command with appropriate error pattern matching
/// - Parameter command: The git command to execute
/// - Returns: The command result
/// - Throws: ShellError if the git command fails
public func runGitCommand(_ command: String) async throws -> ShellCommandResult {
    return try await runShellCommandComplete(command, config: .gitConfig)
}

// MARK: - AsyncSequence Extensions

public extension AsyncSequence where Element == String {
    /// Collects all elements from the async sequence into a single string
    /// - Returns: A concatenated string of all elements
    /// - Throws: Any error thrown by the async sequence
    @discardableResult
    func collectOutput() async throws -> String {
        var result = ""
        for try await element in self {
            result += element
        }
        return result
    }
    
    /// Collects all elements and returns them as an array of strings
    /// - Returns: An array containing all elements
    /// - Throws: Any error thrown by the async sequence
    func collectLines() async throws -> [String] {
        var lines: [String] = []
        for try await element in self {
            lines.append(element)
        }
        return lines
    }
    
    /// Monitors the stream for error patterns and collects output
    /// - Parameter errorPatterns: Array of error patterns to watch for
    /// - Returns: The collected output
    /// - Throws: ShellError.patternMatchFailure if an error pattern is found
    func collectWithPatternMonitoring(errorPatterns: [String]) async throws -> String {
        var result = ""
        for try await element in self {
            result += element
            
            // Check for error patterns
            for pattern in errorPatterns {
                if element.localizedCaseInsensitiveContains(pattern) {
                    throw ShellError.patternMatchFailure(
                        command: "streaming command",
                        output: result,
                        pattern: pattern
                    )
                }
            }
        }
        return result
    }
}
