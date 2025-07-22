# Step 6: Abstract Build Job Operations into Backend Service

## Overview

The current `BuildManager` directly uses `XcodeBuildJob` which contains CLI command tools and violates our clean architecture separation. The UI layer should not have direct access to system commands and build tools. We need to abstract build job operations into the backend service protocol.

## Current Problem

- `BuildManager` (UI layer) directly imports and uses `XcodeBuildJob`
- CLI command tools (`xcodebuild`, file system operations) are exposed to UI layer
- Build job management logic is mixed with UI concerns
- Violates clean architecture principles (UI → Backend → System)

## Solution Architecture

```
UI Layer (BuildManager)
    ↓ (protocols only)
BackendServiceProtocol (Abstract Interface)
    ↓ (different implementations)
LocalBackendService → XcodeBuildJob + CLI Tools (local builds)
RemoteBackendService → HTTP API calls (remote server builds)
CloudBackendService → Cloud Provider APIs (cloud builds)
```

## Implementation Plan

### 6.1 Extend Backend Service Protocol

Add build job management method signatures to `BackendServiceProtocol`:

- `createBuildJob(payload: XcodeBuildPayload, buildModel: BuildModelValue) async throws`
- `startBuildJob(buildId: UUID) -> AsyncSequence<BuildProgressUpdate, Error>`
- `cancelBuildJob(buildId: UUID) async`
- `deleteBuildJob(buildId: UUID) async throws`
- `getBuildJobStatus(buildId: UUID) -> BuildJobStatus?`

**NOTE**: These are protocol requirements only - NO default implementations since each backend type has completely different approaches.

### 6.2 Create Clean Value Types

Define backend-agnostic value types for UI layer:

```swift
// In Core module - shared by all backends
public struct BuildProgressUpdate: Sendable {
    public let buildId: UUID
    public let progress: Double
    public let message: String
    public let timestamp: Date
}

public enum BuildJobStatus: Sendable {
    case idle
    case running(progress: Double)
    case completed
    case failed(Error)
    case cancelled
}

public struct XcodeBuildPayload: Sendable {
    // Clean value type - no CLI-specific details
    // Can be used by local builds, sent over HTTP, etc.
}
```

### 6.3 Implement Backend-Specific Build Logic

Each backend implements build methods according to their approach:

```swift
// LocalBackendService implementation
extension LocalBackendService {
    // LOCAL-SPECIFIC: Uses XcodeBuildJob for CLI commands
    public func createBuildJob(payload: XcodeBuildPayload, buildModel: BuildModelValue) async throws {
        // XcodeBuildJob integration only available in local backend
    }
}

// RemoteBackendService implementation (future)
extension RemoteBackendService {
    // REMOTE-SPECIFIC: Uses HTTP APIs to remote server
    public func createBuildJob(payload: XcodeBuildPayload, buildModel: BuildModelValue) async throws {
        // HTTP API calls to build server
    }
}
```

Each backend service implements build job methods completely differently:

**LocalBackendService** (uses XcodeBuildJob directly):

```swift
extension LocalBackendService {
    public func createBuildJob(payload: XcodeBuildPayload, buildModel: BuildModelValue) async throws {
        // Create build record in database
        try await createBuild(buildModel)
        // XcodeBuildJob will be created when startBuildJob is called
    }

    public func startBuildJob(buildId: UUID) -> some AsyncSequence<BuildProgressUpdate, Error> {
        // Creates XcodeBuildJob internally and streams progress
        // Direct CLI access to xcodebuild, git, etc.
    }

    public func cancelBuildJob(buildId: UUID) async {
        // Cancel local XcodeBuildJob task
        buildJobManager.cancelJob(buildId)
    }
}
```

**RemoteBackendService** (hypothetical - uses HTTP):

```swift
extension RemoteBackendService {
    public func createBuildJob(payload: XcodeBuildPayload, buildModel: BuildModelValue) async throws {
        // HTTP POST to remote build server
        try await httpClient.post("/builds", body: payload)
    }

    public func startBuildJob(buildId: UUID) -> some AsyncSequence<BuildProgressUpdate, Error> {
        // WebSocket or Server-Sent Events for progress updates
        // No local CLI tools - all remote
    }

    public func cancelBuildJob(buildId: UUID) async {
        // HTTP DELETE to cancel remote build
        try await httpClient.delete("/builds/\(buildId)")
    }
}
```

**CloudBackendService** (hypothetical - uses cloud APIs):

```swift
extension CloudBackendService {
    public func startBuildJob(buildId: UUID) -> some AsyncSequence<BuildProgressUpdate, Error> {
        // AWS CodeBuild, Google Cloud Build, etc.
        // Cloud provider SDK calls
    }
}
```

### 6.4 Update BuildManager

Refactor `BuildManager` to be **completely backend-agnostic**:

- Remove direct `XcodeBuildJob` usage
- Remove CLI imports and system dependencies
- Use `@Dependency(\.backendService)` - **ANY** backend service
- Simplify to pure UI state management
- BuildManager works with LocalBackend, RemoteBackend, MockBackend, etc.

```swift
@Observable
class BuildManager {
    @Dependency(\.backendService) var backendService // ← Any backend!

    func createJob(payload: XcodeBuildPayload, buildModel: BuildModel) async throws {
        // Universal - works with ANY backend service
        try await backendService.createBuildJob(payload: payload, buildModel: buildModel.toValue())
    }
}
```

### 6.5 Update Dependencies

- Move `XcodeBuildJob` dependency from UI to LocalBackend module
- Ensure UI layer has no system/CLI dependencies
- Update dependency injection configuration

## Files to Modify

### New Files

- `Packages/Lib/Sources/Core/Models/BuildJob.swift` - Clean value types for all backends
- `Packages/Lib/Sources/LocalBackend/LocalBuildJobManager.swift` - XcodeBuildJob integration (LOCAL ONLY)
- `docs/STEP_7_BACKEND_SERVICE_CONTAINER.md` - Renamed from STEP_6
- `docs/STEP_8_UI_INTEGRATION.md` - Renamed from STEP_7

### Modified Files

- `Packages/Lib/Sources/Core/Services/BackendServiceProtocol.swift` - Add build job method signatures (NO implementations)
- `Packages/Lib/Sources/LocalBackend/LocalBackendService.swift` - Implement LOCAL build job methods using XcodeBuildJob
- `XcodeBuilder2/Screens/Entry/BuildManager.swift` - **Become completely backend-agnostic**
- `docs/STEP_*` - Renumber all existing steps +1

## Expected Benefits

1. **Backend Agnostic UI**: BuildManager works with Local, Remote, Cloud, or any future backend
2. **Implementation Flexibility**: Each backend can use completely different approaches (CLI, HTTP, Cloud APIs)
3. **Clean Architecture**: UI layer only deals with value types and protocol interfaces
4. **Testability**: Easy to test with MockBackendService implementing the protocol methods
5. **Extensibility**: New backend services can be added with completely custom build implementations
6. **Separation of Concerns**: UI handles state, LocalBackend handles CLI tools, RemoteBackend handles HTTP, etc.
7. **Type Safety**: Strongly typed interfaces between all layers
8. **No Leaky Abstractions**: XcodeBuildJob stays completely within LocalBackendService

## Architecture Benefits

**Before**: Tight coupling between UI and local build tools

```swift
BuildManager → XcodeBuildJob  // ❌ UI coupled to local CLI tools
```

**After**: Clean abstraction with backend-specific implementations

````swift
BuildManager → BackendServiceProtocol
    ↓
LocalBackendService → XcodeBuildJob         // Local: CLI tools
RemoteBackendService → HTTPClient           // Remote: API calls
CloudBackendService → CloudProviderSDK     // Cloud: Provider APIs
MockBackendService → InMemorySimulation    // Testing: Mock data
## Migration Strategy

1. **Create protocol method signatures** (non-breaking)
2. **Implement LocalBackendService build job methods** using XcodeBuildJob
3. **Create parallel BuildManager methods** using backend service dependency
4. **Test with LocalBackendService and MockBackendService**
5. **Remove old direct XcodeBuildJob usage** from BuildManager
6. **Verify BuildManager is backend-agnostic**

## Implementation Strategy

### Phase 1: Protocol Foundation
```swift
protocol BackendServiceProtocol {
    // New method signatures - each backend implements differently
    func createBuildJob(payload: XcodeBuildPayload, buildModel: BuildModelValue) async throws
    func startBuildJob(buildId: UUID) -> some AsyncSequence<BuildProgressUpdate, Error>
    func cancelBuildJob(buildId: UUID) async
    // ... other signatures - NO default implementations
}
````

### Phase 2: LocalBackendService Implementation

```swift
extension LocalBackendService {
    // LOCAL-SPECIFIC implementation using XcodeBuildJob
    public func startBuildJob(buildId: UUID) -> some AsyncSequence<BuildProgressUpdate, Error> {
        // Create XcodeBuildJob, run local CLI commands
        let xcodeBuildJob = XcodeBuildJob(payload: payload) { log in ... }
        return xcodeBuildJob.startBuild().map { progress in
            BuildProgressUpdate(buildId: buildId, progress: progress.progress, ...)
        }
    }
}
```

### Phase 3: RemoteBackendService Implementation (Future)

```swift
extension RemoteBackendService {
    // REMOTE-SPECIFIC implementation using HTTP
    public func startBuildJob(buildId: UUID) -> some AsyncSequence<BuildProgressUpdate, Error> {
        // WebSocket connection to remote build server
        return httpClient.streamBuildProgress(buildId: buildId)
    }
}
```

## Validation

- [ ] **UI layer has no CLI/system imports** - BuildManager only imports Core
- [ ] **BuildManager works with ANY backend service** - Test with Local and Mock backends
- [ ] **All build operations go through backend service** - No direct XcodeBuildJob usage
- [ ] **Backend-specific implementations work correctly** - Each backend uses appropriate approach (CLI/HTTP/APIs)
- [ ] **Build progress streams work correctly** - AsyncSequence streaming maintained
- [ ] **Build cancellation works properly** - Backend-specific cancellation logic
- [ ] **File system operations abstracted** - Only backends handle file operations
- [ ] **Backend-specific logic isolated** - XcodeBuildJob only in LocalBackendService
- [ ] **Tests pass for all build scenarios** - Backend-specific and integration tests
- [ ] **Protocol-oriented architecture maintained** - Clean separation between protocol and implementations

## Next Steps

After this step:

1. **BuildManager becomes a pure UI component** - no system dependencies
2. **Each backend service implements build functionality differently** - Local uses CLI, Remote uses HTTP, Cloud uses APIs
3. **Easy to add new backend types** - implement protocol methods with backend-specific approach
4. **Testing becomes straightforward** - MockBackendService implements protocol with test data
5. **Architecture is ready for Step 7** - Backend Service Container and dependency injection
