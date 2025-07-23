#!/usr/bin/env node

const testOutput = `➜  Lib git:(feature/backend-abstraction-layer) ✗ swift test
Building for debugging...
[1/1] Write swift-version--58304C5D6DBC2206.txt
Build complete! (0.23s)
Test Suite 'All tests' started at 2025-07-23 11:07:39.857.
Test Suite 'All tests' passed at 2025-07-23 11:07:39.858.
         Executed 0 tests, with 0 failures (0 unexpected) in 0.000 (0.001) seconds
􀟈  Test run started.
􀄵  Testing Library Version: 124.4
􀄵  Target Platform: arm64e-apple-macos14.0
􀟈  Suite "LocalBackend Core Tests" started.
􀟈  Test "Debug real crash log parsing" started.
􀟈  Suite "SharedReaderKey Backend Integration Tests" started.
􀟈  Suite "CrashLogThreadInfo Tests" started.
􀟈  Suite "Shell Command Runner Tests" started.
􀟈  Test "Fetch branches from valid repository" started.
􀟈  Test "Create build" started.
􀟈  Test "Create project" started.
􀟈  Test "Delete project" started.
􀟈  Test "Fetch branches from invalid repository" started.
􀟈  Test "Delete scheme" started.
􀟈  Test "Delete non-existent project" started.
􀟈  Test "Git operations with malformed URL" started.
􀟈  Test "Fetch versions from valid repository" started.
􀟈  Test "Combined outputs disabled" started.
􀟈  Test "Fetch versions from invalid repository" started.
􀟈  Test "Basic workflow integration" started.
􀟈  Test "Command for output - failure with pattern" started.
􀟈  Test "Git command with error pattern" started.
􀟈  Test "Update project" started.
􀟈  Test "Xcode configuration" started.
􀟈  Test "Streaming command execution" started.
􀟈  Test "Shell command result properties" started.
􀟈  Test "Streaming with pattern monitoring - error detected" started.
􀟈  Test "Create scheme" started.
􀟈  Test "Shell error descriptions" started.
􀟈  Test "Streaming collect lines" started.
􀟈  Test "Xcode build command with error pattern" started.
􀟈  Test "Basic command execution with failure" started.
􀟈  Test "Command for output - with whitespace trimming" started.
􀟈  Test "Non-existent command" started.
􀟈  Test "Pattern matching - no match found" started.
􀟈  Test "Command for output - success" started.
􀟈  Test "Streaming with pattern monitoring" started.
􀟈  Test "@SharedReader supports complex data relationships" started.
􀟈  Test "Pattern matching - no patterns configured" started.
􀟈  Test "Parse single thread" started.
􀟈  Test "Pattern matching - error pattern found and enabled" started.
􀟈  Test "Parse multiple threads with crash" started.
􀟈  Test "Git configuration" started.
􀟈  Test "Combined outputs enabled" started.
􀟈  Test "Command with stderr output" started.
􀟈  Test "@SharedReader works with different data types" started.
􀟈  Test "Default configuration" started.
􀟈  Test "@SharedReader works in SwiftUI-style view model" started.
􀟈  Test "@SharedReader provides loading states and error handling" started.
􀟈  Test "Command for output - failure with exit code" started.
􀟈  Test "Parse main thread variations" started.
􀟈  Test "Parse with thread state interruption" started.
􀟈  Test "@SharedReader supports dynamic key switching" started.
􀟈  Test "Pattern matching - case insensitive" started.
􀟈  Test "Common error patterns" started.
􀟈  Test "Parse complex stack traces" started.
􀟈  Test "@SharedReader automatically updates multiple consumers" started.
􀟈  Test "Parse content with no threads" started.
􀟈  Test "Basic command execution with success" started.
􀟈  Test "CrashLogThread hashable conformance" started.
􀟈  Test "Parse large crash log performance" started.
􀟈  Test "Parse threads with no stack traces" started.
􀟈  Test "Parse file name and line number from stack traces" started.
􀟈  Test "Parse malformed thread headers" started.
􀟈  Test "Parse stack traces with special characters" started.
􀟈  Test "CrashLogThread sendable conformance" started.
􀟈  Test "Parse crashed thread" started.
􀟈  Test "CrashLogThread codable conformance" started.
􀟈  Test "Parse empty content" started.
􀟈  Test "Parse thread with name" started.
Found 4 threads:
Thread 0: main=true, crashed=false, frames=2
database path :memory:
database path :memory:
  0: libswiftCore.dylib - swift::RefCounts<swift::RefCountBitsT<(swift::RefCountInlinedness)1>>::formWeakReference() + 132
  1: libswiftCore.dylib - swift_weakInit + 32
Thread 1: main=false, crashed=false, frames=1
database path :memory:
database path :memory:
database path :memory:
  0: libsystem_pthread.dylib - start_wqthread + 0
Thread 4: main=false, crashed=true, frames=2
  0: ContextApp - closure #1 in closure #1 in BackgroundTaskManager.add(id:operation:mapError:) (in ContextApp)  + 1445248
database path :memory:
database path :memory:
  1: ContextApp - partial apply for closure #1 in closure #1 in BackgroundTaskManager.add(id:operation:mapError:) (in ContextApp) (/<compiler-generated>:0) + 1450276
Thread 7: main=false, crashed=false, frames=1
  0: libsystem_kernel.dylib - mach_msg2_trap + 8
database path :memory:
database path :memory:
database path :memory:
database path :memory:
database path :memory:
database path :memory:
database path :memory:
database path :memory:
database path :memory:
database path :memory:
database path :memory:
database path :memory:
􁁛  Test "Debug real crash log parsing" passed after 0.055 seconds.
􁁛  Test "Xcode configuration" passed after 0.056 seconds.
􁁛  Test "Shell command result properties" passed after 0.056 seconds.
􁁛  Test "Shell error descriptions" passed after 0.056 seconds.
􁁛  Test "Combined outputs disabled" passed after 0.057 seconds.
􁁛  Test "Basic command execution with failure" passed after 0.056 seconds.
􁁛  Test "Command for output - with whitespace trimming" passed after 0.057 seconds.
􁁛  Test "Xcode build command with error pattern" passed after 0.057 seconds.
􁁛  Test "Command for output - failure with pattern" passed after 0.057 seconds.
􁁛  Test "Git command with error pattern" passed after 0.057 seconds.
􁁛  Test "Parse single thread" passed after 0.057 seconds.
􁁛  Test "Pattern matching - no match found" passed after 0.057 seconds.
􁁛  Test "Pattern matching - no patterns configured" passed after 0.057 seconds.
􁁛  Test "Command for output - success" passed after 0.057 seconds.
􁁛  Test "Command with stderr output" passed after 0.059 seconds.
􁁛  Test "Git configuration" passed after 0.059 seconds.
􁁛  Test "Default configuration" passed after 0.058 seconds.
Cleaned up database files
Cleaned up database files
􁁛  Test "Pattern matching - error pattern found and enabled" passed after 0.060 seconds.
􁁛  Test "Non-existent command" passed after 0.062 seconds.
􁁛  Test "Parse main thread variations" passed after 0.062 seconds.
􁁛  Test "Parse with thread state interruption" passed after 0.062 seconds.
􁁛  Test "Common error patterns" passed after 0.062 seconds.
􁁛  Test "Parse complex stack traces" passed after 0.062 seconds.
􁁛  Test "Parse multiple threads with crash" passed after 0.063 seconds.
􁁛  Test "Parse content with no threads" passed after 0.062 seconds.
􁁛  Test "CrashLogThread hashable conformance" passed after 0.062 seconds.
􁁛  Test "Combined outputs enabled" passed after 0.064 seconds.
􁁛  Test "Pattern matching - case insensitive" passed after 0.063 seconds.
􁁛  Test "Parse threads with no stack traces" passed after 0.062 seconds.
􁁛  Test "Parse malformed thread headers" passed after 0.062 seconds.
􁁛  Test "Command for output - failure with exit code" passed after 0.063 seconds.
􁁛  Test "CrashLogThread sendable conformance" passed after 0.062 seconds.
􁁛  Test "Parse file name and line number from stack traces" passed after 0.063 seconds.
􁁛  Test "Parse stack traces with special characters" passed after 0.063 seconds.
􁁛  Test "Parse empty content" passed after 0.062 seconds.
􁁛  Test "Parse crashed thread" passed after 0.063 seconds.
􁁛  Test "Parse thread with name" passed after 0.063 seconds.
􁁛  Test "CrashLogThread codable conformance" passed after 0.063 seconds.
􁁛  Test "Basic command execution with success" passed after 0.063 seconds.
Cleaned up database files
Cleaned up database files
Cleaned up database files
􁁛  Test "Delete non-existent project" passed after 0.070 seconds.
􁁛  Test "Create project" passed after 0.070 seconds.
􁁛  Test "Update project" passed after 0.073 seconds.
Cleaned up database files
􁁛  Test "Delete project" passed after 0.073 seconds.
􁁛  Test "Create scheme" passed after 0.073 seconds.
Cleaned up database files
􁁛  Test "Delete scheme" passed after 0.075 seconds.
􁁛  Test "Create build" passed after 0.075 seconds.
Warning: Neither git operation failed with malformed URL - this may be environment-specific
Cleaned up database files
􁁛  Test "Git operations with malformed URL" passed after 0.078 seconds.
􁁛  Test "@SharedReader works in SwiftUI-style view model" passed after 0.079 seconds.
􁁛  Test "@SharedReader works with different data types" passed after 0.080 seconds.
Cleaned up database files
􁁛  Test "Basic workflow integration" passed after 0.083 seconds.
􁁛  Test "@SharedReader provides loading states and error handling" passed after 0.082 seconds.
􁁛  Test "@SharedReader supports complex data relationships" passed after 0.083 seconds.
􁁛  Test "@SharedReader supports dynamic key switching" passed after 0.082 seconds.
􁁛  Test "@SharedReader automatically updates multiple consumers" passed after 0.089 seconds.
􁁛  Suite "SharedReaderKey Backend Integration Tests" passed after 0.091 seconds.
􁁛  Test "Parse large crash log performance" passed after 0.154 seconds.
􁁛  Suite "CrashLogThreadInfo Tests" passed after 0.157 seconds.
fetchVersions returned 0 versions for invalid repo (this is acceptable)
Cleaned up database files
􁁛  Test "Fetch versions from invalid repository" passed after 1.032 seconds.
fetchBranches returned 0 branches for invalid repo (this is acceptable)
Cleaned up database files
􁁛  Test "Fetch branches from invalid repository" passed after 1.070 seconds.
Found branches: ["bugfix-404-1212", "bugfix-407", "bugfix-408", "bugfix-408-hanhan-feb", "bugfix-hanhan-1127"]
Cleaned up database files
􁁛  Test "Fetch branches from valid repository" passed after 1.773 seconds.
Cleaned up database files
􁁛  Test "Fetch versions from valid repository" passed after 1.775 seconds.
􁁛  Suite "LocalBackend Core Tests" passed after 1.775 seconds.
`;

// Parse test results
function analyzeTestOutput(output) {
  const lines = output.split("\n");
  const tests = {
    started: [],
    passed: [],
    failed: [],
    skipped: [],
    warnings: [],
    errors: [],
  };

  lines.forEach((line) => {
    const cleanLine = line.trim();

    // Extract test names that started
    if (cleanLine.includes('Test "') && cleanLine.includes("started")) {
      const match = cleanLine.match(/Test "([^"]+)" started/);
      if (match) tests.started.push(match[1]);
    }

    // Extract test names that passed
    if (cleanLine.includes('Test "') && cleanLine.includes("passed after")) {
      const match = cleanLine.match(/Test "([^"]+)" passed after/);
      if (match) tests.passed.push(match[1]);
    }

    // Extract test names that failed
    if (
      cleanLine.includes('Test "') &&
      (cleanLine.includes("failed after") || cleanLine.includes("FAILED"))
    ) {
      const match = cleanLine.match(/Test "([^"]+)" (?:failed|FAILED)/);
      if (match) tests.failed.push(match[1]);
    }

    // Extract warnings
    if (cleanLine.toLowerCase().includes("warning:")) {
      tests.warnings.push(cleanLine);
    }

    // Extract errors
    if (
      cleanLine.toLowerCase().includes("error:") ||
      cleanLine.includes("❌")
    ) {
      tests.errors.push(cleanLine);
    }

    // Extract test suite failures
    if (cleanLine.includes("failures") && !cleanLine.includes("0 failures")) {
      const match = cleanLine.match(/(\d+) failures/);
      if (match && parseInt(match[1]) > 0) {
        tests.errors.push(`Test suite had ${match[1]} failures`);
      }
    }
  });

  return tests;
}

const results = analyzeTestOutput(testOutput);

console.log("🧪 TEST ANALYSIS REPORT");
console.log("========================");
console.log();

console.log(`📊 Summary:`);
console.log(`  • Tests Started: ${results.started.length}`);
console.log(`  • Tests Passed:  ${results.passed.length}`);
console.log(`  • Tests Failed:  ${results.failed.length}`);
console.log(`  • Warnings:      ${results.warnings.length}`);
console.log(`  • Errors:        ${results.errors.length}`);
console.log();

if (results.failed.length > 0) {
  console.log("❌ FAILED TESTS:");
  results.failed.forEach((test) => console.log(`  • ${test}`));
  console.log();
} else {
  console.log("✅ All individual tests passed!");
  console.log();
}

if (results.errors.length > 0) {
  console.log("🚨 ERRORS:");
  results.errors.forEach((error) => console.log(`  • ${error}`));
  console.log();
}

if (results.warnings.length > 0) {
  console.log("⚠️  WARNINGS:");
  results.warnings.forEach((warning) => console.log(`  • ${warning}`));
  console.log();
}

// Check for tests that started but didn't finish
const unfinished = results.started.filter(
  (test) => !results.passed.includes(test) && !results.failed.includes(test)
);

if (unfinished.length > 0) {
  console.log("⏸️  UNFINISHED TESTS (started but no result):");
  unfinished.forEach((test) => console.log(`  • ${test}`));
  console.log();
} else if (results.started.length > 0) {
  console.log("✅ All started tests completed successfully");
  console.log();
}

console.log("📋 DETAILED TEST STATUS:");
console.log("-------------------------");
results.started.forEach((test, index) => {
  const status = results.passed.includes(test)
    ? "✅ PASSED"
    : results.failed.includes(test)
    ? "❌ FAILED"
    : "⏸️  INCOMPLETE";
  console.log(
    `${(index + 1).toString().padStart(2)}. ${status.padEnd(12)} ${test}`
  );
});

if (results.started.length === 0) {
  console.log("ℹ️  No individual test results found in output");
  console.log(
    "   This might be a test suite summary or different test framework"
  );
}

// Look for overall test suite status
const overallStatus =
  testOutput.includes("Test Suite") && testOutput.includes("passed")
    ? "✅ OVERALL: Test suite passed"
    : testOutput.includes("failed")
    ? "❌ OVERALL: Test suite failed"
    : "ℹ️  OVERALL: Status unclear";

console.log();
console.log(overallStatus);

// Summary for quick scanning
if (
  results.failed.length === 0 &&
  results.errors.length === 0 &&
  unfinished.length === 0
) {
  console.log();
  console.log("🎉 CONCLUSION: All tests are working correctly!");
} else {
  console.log();
  console.log(
    "🔍 CONCLUSION: Issues found - check failed/unfinished tests above"
  );
}
