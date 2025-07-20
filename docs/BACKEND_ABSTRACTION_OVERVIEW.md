# Backend Abstraction Layer - Implementation Plan

## Overview

This plan introduces a backend abstraction layer to separate the UI from the specific persistence implementation (currently SharingGRDB), enabling future backend options like HTTP APIs while maintaining current reactive UI patterns.

## Current Architecture

- **SharingGRDB** as persistence with direct database access
- **@Dependency(\.defaultDatabase)** for dependency injection
- **@Fetch**, **@FetchOne**, **@FetchAll** for reactive UI binding
- **FetchKeyRequest** protocols for complex queries
- Container pattern: list containers load IDs, cell containers load models

## Goals

1. **Backend Abstraction**: Protocol-based architecture decoupling UI from persistence
2. **SharingGRDB Adapter**: Wrap SharingGRDB with value types and AsyncSequences
3. **SharingKey Integration**: Custom `BackendQuery<T>` for reactive UI binding
4. **Container Architecture**: Maintain `@Shared` data access pattern
5. **Stream-Based API**: Unified `streamX` methods for immediate + reactive updates
6. **Direct Mutations**: Explicit service calls with proper error handling
7. **Future Backends**: Support HTTP APIs, CloudKit via `BackendType` protocol
8. **Seamless Migration**: Zero breaking changes with gradual adoption path

## Architecture Design

### Target Structure

- **Core Target**: Domain models, protocols, value types, SharingKeys
- **LocalBackend Target**: SharingGRDB adapter implementation

### Key Components

1. Backend Model Protocols (contracts for data models)
2. Value Types (backend-agnostic structures)
3. BackendService Protocol (operations with AsyncSequence streams)
4. BackendQuery SharingKey (generic reactive binding)
5. Protocol-Based Conversions (work with any conforming type)
6. SharingGRDB Adapter (concrete implementation)

### File Structure

```
Packages/Lib/
├── Package.swift
├── Package.resolved
├── Sources/
│   ├── Core/
│   │   ├── Models/
│   │   │   ├── Build.swift                                    # Domain model
│   │   │   ├── BuildLog.swift                                 # Domain model
│   │   │   ├── CrashLog.swift                                 # Domain model
│   │   │   ├── Database.swift                                 # Domain model
│   │   │   ├── Destination.swift                              # Domain model
│   │   │   ├── ExportOption.swift                             # Domain model
│   │   │   ├── Project.swift                                  # Domain model
│   │   │   ├── Scheme.swift                                   # Domain model
│   │   │   ├── Build+BackendConversion.swift                  # Backend conversion extension
│   │   │   ├── BuildLog+BackendConversion.swift               # Backend conversion extension
│   │   │   ├── CrashLog+BackendConversion.swift               # Backend conversion extension
│   │   │   ├── Project+BackendConversion.swift                # Backend conversion extension
│   │   │   └── Scheme+BackendConversion.swift                 # Backend conversion extension
│   │   ├── Services/
│   │   │   ├── BackendModels.swift                            # Protocols & value types
│   │   │   ├── BackendServiceProtocol.swift                   # Core service protocol
│   │   │   ├── BackendType.swift                              # Backend type protocol
│   │   │   ├── BackendConversions.swift                       # Conversion protocols
│   │   │   ├── BackendConversionUtilities.swift               # Conversion utilities
│   │   │   ├── BackendServiceRegistry.swift                  # Service registry
│   │   │   ├── BackendServiceSharing.swift                    # SharingKey integration
│   │   │   ├── BackendServiceProvider.swift                   # Provider protocol
│   │   │   ├── BackendInitializer.swift                       # Setup helpers
│   │   │   └── BackendAppIntegration.swift                    # SwiftUI integration
│   │   ├── SharingKeys/
│   │   │   ├── BackendQuery.swift                             # Universal SharingKey
│   │   │   ├── BackendQuery+SharingKey.swift                  # SharingKey conformance
│   │   │   ├── BackendQueryExtensions.swift                   # Type-safe builders
│   │   │   └── BackendQueryUsage.swift                        # Documentation & examples
│   │   ├── Requests/
│   │   │   ├── AllProjectRequest.swift                        # Existing request
│   │   │   └── ProjectDetailRequest.swift                     # Existing request
│   │   └── Utils/
│   │       └── ... (existing utility files)
│   └── LocalBackend/
│       ├── Models/
│       │   ├── GRDBModels.swift                               # GRDB record conformance
│       │   └── GRDBAssociations.swift                         # GRDB model relationships
│       ├── Database/
│       │   └── DatabaseMigration.swift                        # Table creation & migration
│       ├── SharingKeys/
│       │   ├── BackendQuery+SharingGRDB.swift                 # SharingGRDB protocol conformance
│       │   ├── DomainModelQuerySupport.swift                  # Domain model query support
│       │   └── BackendSharingConfiguration.swift              # SharingGRDB configuration
│       ├── LocalBackendService.swift                          # Main service implementation
│       └── LocalBackendType.swift                             # Backend type implementation
└── Tests/
    └── xcode-builder-2Tests/
        ├── CrashLogThreadInfoTests.swift                      # Existing test
        ├── DebugCrashLogParsing.swift                          # Existing test
        ├── ShellCommandRunnerTests.swift                       # Existing test
        └── MigrationTests/
            ├── MigrationTests.swift                            # Migration test suite
            ├── BackupUtilities.swift                           # Backup utilities
            ├── MigrationCoordinator.swift                      # Migration coordinator
            ├── MigrationFeatureFlags.swift                     # Feature flags
            ├── HybridProjectListView.swift                     # Hybrid view example
            ├── MigrationView.swift                             # Migration UI
            └── MigrationMonitoring.swift                       # Metrics & monitoring
```

#### Package Configuration

- **Core Target**: Domain models, protocols, SharingKeys, services
  - Dependencies: `swift-sharing`
- **LocalBackend Target**: SharingGRDB adapter implementation
  - Dependencies: `Core`, `GRDB.swift`, `SharingGRDB`

## Implementation Steps

| Step | Document                                                          | Description                           |
| ---- | ----------------------------------------------------------------- | ------------------------------------- |
| 1    | [Backend Protocols](./STEP_1_BACKEND_PROTOCOLS.md)                | Define core protocols and value types |
| 2    | [Protocol Conversions](./STEP_2_PROTOCOL_CONVERSIONS.md)          | Implement generic conversion system   |
| 3    | [SharingGRDB Adapter](./STEP_3_SHARINGGRDB_ADAPTER.md)            | Create SharingGRDB backend service    |
| 4    | [Dependency System](./STEP_4_DEPENDENCY_SYSTEM.md)                | Update dependency injection           |
| 5    | [SharingKey Extensions](./STEP_5_SHARING_KEYS.md)                 | Create reactive data binding          |
| 6    | [Backend Service Registry](./STEP_6_BACKEND_SERVICE_CONTAINER.md) | Static backend service management     |
| 7    | [Testing Strategy](./STEP_7_TESTING.md)                           | Comprehensive testing approach        |
| 8    | [Migration Strategy](./STEP_8_MIGRATION_STRATEGY.md)              | Simple manual migration approach      |

## Migration Strategy

### Gradual Adoption

1. Implement backend abstraction alongside existing code
2. Update one UI screen at a time to new pattern
3. Migrate `@Fetch` usage to `@Shared` with `BackendQuery`
4. Remove deprecated direct SharingGRDB access

### Timeline: 4 Weeks

- **Week 1**: Steps 1-3 (Foundation & Adapter)
- **Week 2**: Steps 4-5 (Dependencies & SharingKeys)
- **Week 3**: Step 6 (UI Integration)
- **Week 4**: Steps 7-8 (Testing & Migration)

## Future Considerations

### Additional Backend Examples

```swift
// HTTP API Backend
public struct HTTPAPIBackend: BackendType {
    public let baseURL: URL
    public let apiKey: String

    public func createService() throws -> BackendService {
        return HTTPBackendService(baseURL: baseURL, apiKey: apiKey)
    }
}

// CloudKit Backend
public struct CloudKitBackend: BackendType {
    public let container: CKContainer

    public func createService() throws -> BackendService {
        return CloudKitBackendService(container: container)
    }
}
```

### Advanced Features

- Multi-backend support with sync strategies
- Offline support with cache management
- Real-time sync with WebSocket/SSE
- Schema validation and migration support
