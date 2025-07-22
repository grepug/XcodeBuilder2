#!/usr/bin/env node

const testOutput = `􀟈  Test run started.
􀄵  Testing Library Version: 124.4
􀄵  Target Platform: arm64e-apple-macos14.0
􀟈  Suite "LocalBackend Core Tests" started.
􀟈  Suite "CrashLogThreadInfo Tests" started.
􀟈  Test "Debug real crash log parsing" started.
􀟈  Suite "Shell Command Runner Tests" started.
􀟈  Suite "SharedReaderKey Backend Integration Tests" started.
􀟈  Test "Fetch versions from valid repository" started.
􀟈  Test "Git operations with malformed URL" started.
􀟈  Test "Delete scheme" started.
􀟈  Test "Delete non-existent project" started.
􀟈  Test "Create build" started.
􀟈  Test "Create project" started.
􀟈  Test "Delete project" started.
􀟈  Test "Fetch versions from invalid repository" started.
􀟈  Test "Fetch branches from invalid repository" started.
􀟈  Test "Basic workflow integration" started.
􀟈  Test "Update project" started.
􀟈  Test "Streaming command execution" started.
􀟈  Test "Fetch branches from valid repository" started.
􀟈  Test "Xcode build command with error pattern" started.
􀟈  Test "Streaming collect lines" started.
􀟈  Test "Create scheme" started.
􀟈  Test "@SharedReader works in SwiftUI-style view model" started.
􀟈  Test "@SharedReader automatically updates multiple consumers" started.
􀟈  Test "Service factory creation" started.
􀟈  Test "Shell error descriptions" started.
􀟈  Test "Basic command execution with failure" started.
􀟈  Test "Pattern matching - no match found" started.
􀟈  Test "Pattern matching - case insensitive" started.
􀟈  Test "@SharedReader provides loading states and error handling" started.
􀟈  Test "@SharedReader supports dynamic key switching" started.
􀟈  Test "@SharedReader works with different data types" started.
􀟈  Test "Command for output - success" started.
􀟈  Test "Git command with error pattern" started.
􀟈  Test "Git configuration" started.
􀟈  Test "Common error patterns" started.
􀟈  Test "Pattern matching - no patterns configured" started.
􀟈  Test "Streaming with pattern monitoring" started.
􀟈  Test "Command with stderr output" started.
􀟈  Test "Command for output - failure with pattern" started.
􀟈  Test "@SharedReader supports complex data relationships" started.
􀟈  Test "Combined outputs disabled" started.
􀟈  Test "Command for output - failure with exit code" started.
􀟈  Test "Pattern matching - error pattern found and enabled" started.
􀟈  Test "Streaming with pattern monitoring - error detected" started.
􀟈  Test "Xcode configuration" started.
􀟈  Test "Shell command result properties" started.
􀟈  Test "Default configuration" started.
􀟈  Test "Basic command execution with success" started.
􀟈  Test "Non-existent command" started.
􀟈  Test "Command for output - with whitespace trimming" started.
􀟈  Test "Combined outputs enabled" started.
􀟈  Test "Parse threads with no stack traces" started.
􀟈  Test "Parse crashed thread" started.
􀟈  Test "Parse complex stack traces" started.
􀟈  Test "Parse main thread variations" started.
􀟈  Test "Parse stack traces with special characters" started.
􀟈  Test "Parse with thread state interruption" started.
􀟈  Test "CrashLogThread hashable conformance" started.
􀟈  Test "CrashLogThread codable conformance" started.
􀟈  Test "Parse file name and line number from stack traces" started.
database path :memory:
database path :memory:
database path :memory:
database path :memory:
database path :memory:
database path :memory:
database path :memory:
database path :memory:
database path :memory:
Found 4 threads:
Thread 0: main=true, crashed=false, frames=2
  0: libswiftCore.dylib - swift::RefCounts<swift::RefCountBitsT<(swift::RefCountInlinedness)1>>::formWeakReference() + 132
  1: libswiftCore.dylib - swift_weakInit + 32
Thread 1: main=false, crashed=false, frames=1
  0: libsystem_pthread.dylib - start_wqthread + 0
Thread 4: main=false, crashed=true, frames=2
  0: ContextApp - closure #1 in closure #1 in BackgroundTaskManager.add(id:operation:mapError:) (in ContextApp)  + 1445248
  1: ContextApp - partial apply for closure #1 in closure #1 in BackgroundTaskManager.add(id:operation:mapError:) (in ContextApp) (/<compiler-generated>:0) + 1450276
Thread 7: main=false, crashed=false, frames=1
  0: libsystem_kernel.dylib - mach_msg2_trap + 8
􀟈  Test "CrashLogThread sendable conformance" started.
􀟈  Test "Parse large crash log performance" started.
􀟈  Test "Parse malformed thread headers" started.
􀟈  Test "Parse content with no threads" started.
􀟈  Test "Parse empty content" started.
􀟈  Test "Parse single thread" started.
database path :memory:
􀟈  Test "Parse multiple threads with crash" started.
􀟈  Test "Parse thread with name" started.
database path :memory:
database path :memory:
database path :memory:
􁁛  Test "Debug real crash log parsing" passed after 0.050 seconds.
􁁛  Test "Service factory creation" passed after 0.058 seconds.
􁁛  Test "Shell error descriptions" passed after 0.058 seconds.
􁁛  Test "Basic command execution with failure" passed after 0.062 seconds.
Warning: Neither git operation failed with malformed URL - this may be environment-specific
􁁛  Test "Command for output - success" passed after 0.065 seconds.
􁁛  Test "Git configuration" passed after 0.065 seconds.
􁁛  Test "Pattern matching - no match found" passed after 0.065 seconds.
􁁛  Test "Common error patterns" passed after 0.065 seconds.
􁁛  Test "Pattern matching - case insensitive" passed after 0.065 seconds.
􁁛  Test "Xcode build command with error pattern" passed after 0.065 seconds.
􁁛  Test "Git command with error pattern" passed after 0.067 seconds.
􁁛  Test "Pattern matching - no patterns configured" passed after 0.067 seconds.
􁁛  Test "Command with stderr output" passed after 0.067 seconds.
􁁛  Test "Command for output - failure with pattern" passed after 0.067 seconds.
􁁛  Test "Xcode configuration" passed after 0.066 seconds.
􁁛  Test "Shell command result properties" passed after 0.066 seconds.
􁁛  Test "Default configuration" passed after 0.067 seconds.
􁁛  Test "Combined outputs disabled" passed after 0.067 seconds.
􁁛  Test "Command for output - failure with exit code" passed after 0.067 seconds.
􁁛  Test "Pattern matching - error pattern found and enabled" passed after 0.067 seconds.
􁁛  Test "Parse threads with no stack traces" passed after 0.066 seconds.
􁁛  Test "Parse crashed thread" passed after 0.066 seconds.
􁁛  Test "Parse complex stack traces" passed after 0.066 seconds.
􁁛  Test "Parse main thread variations" passed after 0.066 seconds.
􁁛  Test "Parse stack traces with special characters" passed after 0.066 seconds.
􁁛  Test "Parse with thread state interruption" passed after 0.066 seconds.
􁁛  Test "CrashLogThread codable conformance" passed after 0.066 seconds.
􁁛  Test "CrashLogThread hashable conformance" passed after 0.066 seconds.
􁁛  Test "Parse file name and line number from stack traces" passed after 0.066 seconds.
􁁛  Test "CrashLogThread sendable conformance" passed after 0.065 seconds.
􁁛  Test "Basic command execution with success" passed after 0.067 seconds.
􁁛  Test "Parse malformed thread headers" passed after 0.065 seconds.
􁁛  Test "Parse content with no threads" passed after 0.065 seconds.
􁁛  Test "Parse empty content" passed after 0.065 seconds.
􁁛  Test "Parse single thread" passed after 0.065 seconds.
􁁛  Test "Combined outputs enabled" passed after 0.067 seconds.
􁁛  Test "Command for output - with whitespace trimming" passed after 0.067 seconds.
􁁛  Test "Parse thread with name" passed after 0.054 seconds.
􁁛  Test "Delete non-existent project" passed after 0.069 seconds.
􁁛  Test "Non-existent command" passed after 0.068 seconds.
􁁛  Test "Create project" passed after 0.071 seconds.
􁁛  Test "Git operations with malformed URL" passed after 0.076 seconds.
􁁛  Test "Streaming with pattern monitoring - error detected" passed after 0.077 seconds.
􁁛  Test "Parse multiple threads with crash" passed after 0.064 seconds.
􁁛  Test "Delete project" passed after 0.083 seconds.
􁁛  Test "Create scheme" passed after 0.085 seconds.
􁁛  Test "Update project" passed after 0.088 seconds.
􁁛  Test "Delete scheme" passed after 0.090 seconds.
􁁛  Test "Create build" passed after 0.090 seconds.
􁁛  Test "@SharedReader provides loading states and error handling" passed after 0.105 seconds.
􁁛  Test "@SharedReader works in SwiftUI-style view model" passed after 0.109 seconds.
􁁛  Test "@SharedReader works with different data types" passed after 0.109 seconds.
􁁛  Test "Basic workflow integration" passed after 0.110 seconds.
􁁛  Test "@SharedReader supports dynamic key switching" passed after 0.110 seconds.
􁁛  Test "@SharedReader automatically updates multiple consumers" passed after 0.116 seconds.
􁁛  Test "Parse large crash log performance" passed after 0.150 seconds.
􁁛  Suite "CrashLogThreadInfo Tests" passed after 0.154 seconds.
􁁛  Test "@SharedReader supports complex data relationships" passed after 0.706 seconds.
􁁛  Suite "SharedReaderKey Backend Integration Tests" passed after 0.707 seconds.
fetchBranches returned 0 branches for invalid repo (this is acceptable)
􁁛  Test "Fetch branches from invalid repository" passed after 1.377 seconds.
fetchVersions returned 0 versions for invalid repo (this is acceptable)
􁁛  Test "Fetch versions from invalid repository" passed after 1.379 seconds.
Found branches: ["1", "102259828-freestanding-pthreads-package", "105255151", "109911673-playground-transform-option-flag", "20230906"]
􁁛  Test "Fetch branches from valid repository" passed after 1.582 seconds.`;

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
