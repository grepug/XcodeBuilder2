import Testing
import Foundation
@testable import Core

@Suite("Shell Command Runner Tests")
struct ShellCommandRunnerTests {
    
    // MARK: - Basic Command Execution Tests
    
    @Test("Basic command execution with success")
    func testBasicCommandSuccess() async throws {
        let result = try await runShellCommandComplete("echo 'Hello, World!'")
        
        #expect(result.isSuccess)
        #expect(result.exitCode == 0)
        #expect(result.output.trimmingCharacters(in: .whitespacesAndNewlines) == "Hello, World!")
        #expect(result.errorOutput.isEmpty)
        #expect(result.matchedErrorPattern == nil)
    }
    
    @Test("Basic command execution with failure")
    func testBasicCommandFailure() async throws {
        let result = try await runShellCommandComplete("exit 1")
        
        #expect(!result.isSuccess)
        #expect(result.exitCode == 1)
        #expect(result.matchedErrorPattern == nil)
    }
    
    @Test("Command with stderr output")
    func testCommandWithStderr() async throws {
        let result = try await runShellCommandComplete("echo 'error message' >&2")
        
        #expect(result.isSuccess)
        #expect(result.exitCode == 0)
        #expect(result.output.isEmpty)
        #expect(!result.errorOutput.isEmpty)
        #expect(result.errorOutput.contains("error message"))
    }
    
    @Test("Non-existent command")
    func testNonExistentCommand() async throws {
        let result = try await runShellCommandComplete("nonexistentcommand12345")
        
        #expect(!result.isSuccess)
        #expect(result.exitCode == 127)
        #expect(result.errorOutput.contains("command not found"))
    }
    
    // MARK: - Pattern Matching Tests
    
    @Test("Pattern matching - no patterns configured")
    func testPatternMatchingDisabled() async throws {
        let config = ShellCommandConfig(
            errorPatterns: ["error:", "failed:"],
            failOnErrorPattern: false
        )
        
        let result = try await runShellCommandComplete("echo 'error: something went wrong'", config: config)
        
        #expect(!result.isSuccess) // Should be false because pattern was matched
        #expect(result.exitCode == 0)
        #expect(result.output.contains("error: something went wrong"))
        #expect(result.matchedErrorPattern == "error:")
    }
    
    @Test("Pattern matching - error pattern found and enabled")
    func testPatternMatchingEnabled() async throws {
        let config = ShellCommandConfig(
            errorPatterns: ["error:", "failed:"],
            failOnErrorPattern: true
        )
        
        await #expect(throws: ShellError.self) {
            try await runShellCommandComplete("echo 'error: something went wrong'", config: config)
        }
    }
    
    @Test("Pattern matching - case insensitive")
    func testPatternMatchingCaseInsensitive() async throws {
        let config = ShellCommandConfig(
            errorPatterns: ["ERROR:"],
            failOnErrorPattern: true
        )
        
        await #expect(throws: ShellError.self) {
            try await runShellCommandComplete("echo 'error: lowercase but should match'", config: config)
        }
    }
    
    @Test("Pattern matching - no match found")
    func testPatternMatchingNoMatch() async throws {
        let config = ShellCommandConfig(
            errorPatterns: ["NOTFOUND:", "MISSING:"],
            failOnErrorPattern: true
        )
        
        let result = try await runShellCommandComplete("echo 'success: everything is fine'", config: config)
        
        #expect(result.isSuccess)
        #expect(result.exitCode == 0)
        #expect(result.matchedErrorPattern == nil)
    }
    
    // MARK: - Output Combination Tests
    
    @Test("Combined outputs disabled")
    func testCombinedOutputsDisabled() async throws {
        let config = ShellCommandConfig(combineOutputs: false)
        
        let result = try await runShellCommandComplete("echo 'stdout' && echo 'stderr' >&2", config: config)
        
        #expect(result.isSuccess)
        #expect(result.output.contains("stdout"))
        #expect(result.errorOutput.contains("stderr"))
        #expect(result.combinedOutput.contains("stdout"))
        #expect(result.combinedOutput.contains("stderr"))
    }
    
    @Test("Combined outputs enabled")
    func testCombinedOutputsEnabled() async throws {
        let config = ShellCommandConfig(combineOutputs: true)
        
        let result = try await runShellCommandComplete("echo 'stdout' && echo 'stderr' >&2", config: config)
        
        #expect(result.isSuccess)
        #expect(result.output.contains("stdout"))
        #expect(result.errorOutput.contains("stderr"))
    }
    
    // MARK: - Predefined Configuration Tests
    
    @Test("Xcode configuration")
    func testXcodeConfiguration() async throws {
        let config = ShellCommandConfig.xcodeConfig
        
        #expect(config.failOnErrorPattern)
        #expect(config.combineOutputs)
        #expect(config.errorPatterns.contains("Build FAILED"))
        #expect(config.errorPatterns.contains("error:"))
        #expect(config.errorPatterns.contains("fatal error:"))
    }
    
    @Test("Git configuration")
    func testGitConfiguration() async throws {
        let config = ShellCommandConfig.gitConfig
        
        #expect(config.failOnErrorPattern)
        #expect(!config.combineOutputs)
        #expect(config.errorPatterns.contains("error:"))
        #expect(config.errorPatterns.contains("fatal:"))
        #expect(config.errorPatterns.contains("not a git repository"))
    }
    
    @Test("Xcode build command with error pattern")
    func testXcodeBuildCommandWithError() async throws {
        // Simulate an Xcode build error
        await #expect(throws: ShellError.self) {
            try await runXcodeBuildCommand("echo 'Build FAILED'")
        }
    }
    
    @Test("Git command with error pattern")
    func testGitCommandWithError() async throws {
        // Simulate a Git error
        await #expect(throws: ShellError.self) {
            try await runGitCommand("echo 'fatal: not a git repository'")
        }
    }
    
    // MARK: - Streaming Tests
    
    @Test("Streaming command execution")
    func testStreamingCommandExecution() async throws {
        let stream = await runShellCommandStreaming("echo 'line1' && echo 'line2' && echo 'line3'")
        let output = try await stream.collectOutput()
        
        #expect(output.contains("line1"))
        #expect(output.contains("line2"))
        #expect(output.contains("line3"))
    }
    
    @Test("Streaming with pattern monitoring")
    func testStreamingWithPatternMonitoring() async throws {
        let stream = await runShellCommandStreaming("echo 'success' && echo 'more success'")
        
        let output = try await stream.collectWithPatternMonitoring(errorPatterns: ["error:", "failed:"])
        
        #expect(output.contains("success"))
        #expect(output.contains("more success"))
    }
    
    @Test("Streaming with pattern monitoring - error detected")
    func testStreamingWithPatternMonitoringError() async throws {
        let stream = await runShellCommandStreaming("echo 'success' && echo 'error: something failed'")
        
        await #expect(throws: ShellError.self) {
            try await stream.collectWithPatternMonitoring(errorPatterns: ["error:", "failed:"])
        }
    }
    
    @Test("Streaming collect lines")
    func testStreamingCollectLines() async throws {
        let stream = await runShellCommandStreaming("echo 'line1' && echo 'line2'")
        let lines = try await stream.collectLines()
        
        #expect(lines.count >= 2)
        #expect(lines.joined().contains("line1"))
        #expect(lines.joined().contains("line2"))
    }
    
    // MARK: - Output Processing Tests
    
    @Test("Command for output - success")
    func testCommandForOutputSuccess() async throws {
        let output = try await runShellCommandForOutput("echo 'clean output'")
        
        #expect(output == "clean output")
    }
    
    @Test("Command for output - with whitespace trimming")
    func testCommandForOutputWhitespaceTrimming() async throws {
        let output = try await runShellCommandForOutput("echo '  spaced output  '")
        
        #expect(output == "spaced output")
    }
    
    @Test("Command for output - failure with pattern")
    func testCommandForOutputFailureWithPattern() async throws {
        let config = ShellCommandConfig(
            errorPatterns: ["error:"],
            failOnErrorPattern: true
        )
        
        await #expect(throws: ShellError.self) {
            try await runShellCommandForOutput("echo 'error: failed'", config: config)
        }
    }
    
    @Test("Command for output - failure with exit code")
    func testCommandForOutputFailureWithExitCode() async throws {
        await #expect(throws: ShellError.self) {
            try await runShellCommandForOutput("exit 42")
        }
    }
    
    // MARK: - Error Handling Tests
    
    @Test("Shell error descriptions")
    func testShellErrorDescriptions() async throws {
        let commandFailed = ShellError.commandFailed(
            command: "test command",
            exitCode: 1,
            errorOutput: "test error"
        )
        #expect(commandFailed.errorDescription?.contains("test command") == true)
        #expect(commandFailed.errorDescription?.contains("exit code 1") == true)
        
        let patternFailure = ShellError.patternMatchFailure(
            command: "test command",
            output: "test output",
            pattern: "error:"
        )
        #expect(patternFailure.errorDescription?.contains("test command") == true)
        #expect(patternFailure.errorDescription?.contains("error:") == true)
        
        let invalidOutput = ShellError.invalidOutput("test message")
        #expect(invalidOutput.errorDescription?.contains("test message") == true)
        
        let processLaunchFailed = ShellError.processLaunchFailed(
            NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "test error"])
        )
        #expect(processLaunchFailed.errorDescription?.contains("test error") == true)
    }
    
    // MARK: - Configuration Tests
    
    @Test("Default configuration")
    func testDefaultConfiguration() async throws {
        let config = ShellCommandConfig()
        
        #expect(config.errorPatterns.isEmpty)
        #expect(!config.failOnErrorPattern)
        #expect(!config.combineOutputs)
    }
    
    @Test("Common error patterns")
    func testCommonErrorPatterns() async throws {
        let patterns = ShellCommandConfig.commonErrorPatterns
        
        #expect(patterns.contains("error:"))
        #expect(patterns.contains("Error:"))
        #expect(patterns.contains("ERROR:"))
        #expect(patterns.contains("failed:"))
        #expect(patterns.contains("Failed:"))
        #expect(patterns.contains("FAILED:"))
        #expect(patterns.contains("fatal:"))
        #expect(patterns.contains("Fatal:"))
        #expect(patterns.contains("FATAL:"))
        #expect(patterns.contains("Build FAILED"))
        #expect(patterns.contains("Command failed"))
        #expect(patterns.contains("No such file or directory"))
        #expect(patterns.contains("Permission denied"))
        #expect(patterns.contains("command not found"))
    }
    
    // MARK: - Result Tests
    
    @Test("Shell command result properties")
    func testShellCommandResultProperties() async throws {
        let result = ShellCommandResult(
            output: "test output",
            errorOutput: "test error",
            exitCode: 0,
            matchedErrorPattern: nil
        )
        
        #expect(result.isSuccess)
        #expect(result.combinedOutput == "test output\ntest error")
        
        let resultWithPattern = ShellCommandResult(
            output: "test output",
            errorOutput: "",
            exitCode: 0,
            matchedErrorPattern: "error:"
        )
        
        #expect(!resultWithPattern.isSuccess)
        #expect(resultWithPattern.combinedOutput == "test output")
        
        let resultWithError = ShellCommandResult(
            output: "test output",
            errorOutput: "test error",
            exitCode: 1,
            matchedErrorPattern: nil
        )
        
        #expect(!resultWithError.isSuccess)
    }
}
