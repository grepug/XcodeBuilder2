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

### Core Module Client/Server Architecture

**Problem**: Core module will be imported by both iOS client and Vapor server, but current structure mixes client/server concerns.

**Solution**: Organize Core with clear Client/Server separation:

```
iOS Client imports:          Vapor Server imports:
- Core/Models (shared)       - Core/Models (shared)
- Core/Client/Services       - Core/Server/Utils
- Core/Client/Dependencies   - Core/Server/Commands
- Core/Shared               - Core/Shared

LocalBackend (iOS only):     RemoteBackend (Vapor server):
- Uses Core/Server/Utils     - Uses Core/Server/Utils
- CLI tools, file system     - Same CLI tools on server
- Local build execution      - Remote build execution
```

**Key Insight**:

- **Client-side**: Protocols, dependency injection, UI abstractions
- **Server-side**: CLI tools, file operations, system commands
- **Shared**: Models, value types, pure functions
- **Backend-agnostic**: Dependency injection works with any backend (Local, Remote, Cloud)

## Implementation Plan

### 6.0 Reorganize Core Module Structure (Prerequisites)

**IMPORTANT**: Before implementing build job abstraction, reorganize Core module for Client/Server separation since it will be imported by both iOS client and Vapor server.

**Current Core Structure** (mixed Client/Server concerns):

```
Core/
├── Models/ (shared - OK)
├── Services/ (client-specific - should be Client/)
└── Utils/ (server-specific - should be Server/)
```

**New Core Structure** (clear separation):

```
Core/
├── Models/ (shared value types)
├── Client/ (iOS client-specific)
│   ├── Services/ (BackendServiceProtocol, dependency injection)
│   └── Dependencies/ (moved from LocalBackend)
├── Server/ (Vapor server-specific)
│   ├── Utils/ (CLI tools, file operations)
│   └── Commands/ (build commands, system operations)
└── Shared/ (truly shared utilities)
```

**File Moves Required**:

1. `Core/Services/` → `Core/Client/Services/` (client protocols)
2. `Core/Utils/` → `Core/Server/Utils/` (server CLI tools)
3. `LocalBackend/BackendService+Dependency.swift` → `Core/Client/Dependencies/BackendService+Dependency.swift`
4. `LocalBackend/BackendQuery+SharingKey.swift` → `Core/Client/Dependencies/BackendQuery+SharingKey.swift`

**Rationale**:

- **Client/Services**: BackendServiceProtocol is client-side abstraction
- **Server/Utils**: XcodeBuildJob, CLI commands are server-side operations
- **Client/Dependencies**: Dependency injection is client-side concern, backend-agnostic
- **Shared separation**: Clear distinction between what's truly shared vs client/server specific

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

### Core Module Reorganization (Step 6.0)

**New Folders**:

- `Packages/Lib/Sources/Core/Client/Services/` - Client-side service protocols
- `Packages/Lib/Sources/Core/Client/Dependencies/` - Backend-agnostic dependency injection
- `Packages/Lib/Sources/Core/Server/Utils/` - Server-side utilities and CLI tools
- `Packages/Lib/Sources/Core/Server/Commands/` - Server-side build commands
- `Packages/Lib/Sources/Core/Shared/` - Truly shared utilities

**File Moves**:

- `Core/Services/BackendServiceProtocol.swift` → `Core/Client/Services/BackendServiceProtocol.swift`
- `Core/Services/BackendModels.swift` → `Core/Client/Services/BackendModels.swift`
- `Core/Services/BackendType.swift` → `Core/Client/Services/BackendType.swift`
- `Core/Utils/XcodeBuildJob.swift` → `Core/Server/Utils/XcodeBuildJob.swift`
- `Core/Utils/XcodeBuildPathManager.swift` → `Core/Server/Utils/XcodeBuildPathManager.swift`
- `Core/Utils/IPAUploader.swift` → `Core/Server/Utils/IPAUploader.swift`
- `Core/Utils/Commands/` → `Core/Server/Commands/`
- `Core/Utils/ensuredURL.swift` → `Core/Shared/ensuredURL.swift` (if truly shared)
- `Core/Utils/updateVersions.swift` → `Core/Server/Utils/updateVersions.swift`
- `LocalBackend/BackendService+Dependency.swift` → `Core/Client/Dependencies/BackendService+Dependency.swift`
- `LocalBackend/BackendQuery+SharingKey.swift` → `Core/Client/Dependencies/BackendQuery+SharingKey.swift`

### New Files (Step 6.1-6.5)

- `Packages/Lib/Sources/Core/Models/BuildJob.swift` - Clean value types for all backends
- `Packages/Lib/Sources/LocalBackend/LocalBuildJobManager.swift` - XcodeBuildJob integration (LOCAL ONLY)
- `docs/STEP_7_BACKEND_SERVICE_CONTAINER.md` - Renamed from STEP_6
- `docs/STEP_8_UI_INTEGRATION.md` - Renamed from STEP_7

### Modified Files

- `Packages/Lib/Sources/Core/Client/Services/BackendServiceProtocol.swift` - Add build job method signatures (NO implementations)
- `Packages/Lib/Sources/LocalBackend/LocalBackendService.swift` - Implement LOCAL build job methods using XcodeBuildJob
- `XcodeBuilder2/Screens/Entry/BuildManager.swift` - **Become completely backend-agnostic**
- `docs/STEP_*` - Renumber all existing steps +1

## Expected Benefits

1. **Clear Client/Server Separation**: Core module organized for both iOS client and Vapor server imports
2. **Backend Agnostic UI**: BuildManager works with Local, Remote, Cloud, or any future backend
3. **Implementation Flexibility**: Each backend can use completely different approaches (CLI, HTTP, Cloud APIs)
4. **Clean Architecture**: UI layer only deals with value types and protocol interfaces
5. **Shared Code Reusability**: Server can import Core/Models and Core/Server, Client imports Core/Models and Core/Client
6. **Testability**: Easy to test with MockBackendService implementing the protocol methods
7. **Extensibility**: New backend services can be added with completely custom build implementations
8. **Separation of Concerns**: UI handles state, LocalBackend handles CLI tools, RemoteBackend handles HTTP, etc.
9. **Type Safety**: Strongly typed interfaces between all layers
10. **No Leaky Abstractions**: XcodeBuildJob stays completely within Core/Server (used by LocalBackendService)
11. **Dependency Injection Clarity**: Backend-agnostic dependency injection in Core/Client

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

1. **Reorganize Core module structure** (Client/Server separation for iOS + Vapor compatibility)
2. **Move dependency injection files** from LocalBackend to Core/Client/Dependencies
3. **Create protocol method signatures** (non-breaking)
4. **Implement LocalBackendService build job methods** using XcodeBuildJob
5. **Create parallel BuildManager methods** using backend service dependency
6. **Test with LocalBackendService and MockBackendService**
7. **Remove old direct XcodeBuildJob usage** from BuildManager
8. **Verify BuildManager is backend-agnostic**

## Implementation Strategy

### Phase 0: Core Module Reorganization
```bash
# Create new folder structure
mkdir -p Packages/Lib/Sources/Core/Client/{Services,Dependencies}
mkdir -p Packages/Lib/Sources/Core/Server/{Utils,Commands}
mkdir -p Packages/Lib/Sources/Core/Shared

# Move files to proper locations
mv Core/Services/* Core/Client/Services/
mv Core/Utils/XcodeBuildJob.swift Core/Server/Utils/
mv Core/Utils/XcodeBuildPathManager.swift Core/Server/Utils/
mv Core/Utils/IPAUploader.swift Core/Server/Utils/
mv Core/Utils/Commands Core/Server/Commands/
mv Core/Utils/updateVersions.swift Core/Server/Utils/
mv LocalBackend/BackendService+Dependency.swift Core/Client/Dependencies/
mv LocalBackend/BackendQuery+SharingKey.swift Core/Client/Dependencies/

# Update imports throughout codebase
```

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
