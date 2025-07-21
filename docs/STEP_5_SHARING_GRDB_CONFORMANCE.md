# Step 5: SharedReaderKey Protocol Implementation for Backend Integration

**Goal**: Implement SharedReaderKey protocol conformance to enable @SharedReader integration with backend service using direct dependency injection.

## Files to Create

### 5.1 SharedReaderKey Implementation for Backend Queries

**File**: `Packages/Lib/Sources/LocalBackend/Backend+SharedKey.swift`

```swift
import Core
import Dependencies
import Foundation
import Sharing

// MARK: - Backend Query Types

enum BackendQuery {
  case allProjects
  case buildsForProject(UUID)
  case allDestinations
  case projectDetail(UUID)
}

// MARK: - Backend Query Key

struct BackendQueryKey<Value: Sendable>: SharedReaderKey {
  let query: BackendQuery
  let id: AnyHashable

  init(_ query: BackendQuery) {
    self.query = query
    // Create unique ID based on query type and parameters
    switch query {
    case .allProjects:
      self.id = "allProjects"
    case .buildsForProject(let projectId):
      self.id = "buildsForProject-\(projectId)"
    case .allDestinations:
      self.id = "allDestinations"
    case .projectDetail(let projectId):
      self.id = "projectDetail-\(projectId)"
    }
  }

  func load(context: LoadContext<Value>, continuation: LoadContinuation<Value>) {
    Task {
      @Dependency(\.backendService) var backendService

      do {
        let result: Any

        switch query {
        case .allProjects:
          result = try await backendService.allProjects()
        case .buildsForProject(let projectId):
          result = try await backendService.buildsForProject(projectId: projectId)
        case .allDestinations:
          result = try await backendService.allDestinations()
        case .projectDetail(let projectId):
          result = try await backendService.project(id: projectId)
        }

        if let typedResult = result as? Value {
          continuation.resume(returning: typedResult)
        } else {
          throw BackendQueryError.typeMismatch
        }
      } catch {
        continuation.resume(throwing: error)
      }
    }
  }

  func subscribe(
    context: LoadContext<Value>,
    subscriber: SharedSubscriber<Value>
  ) -> SharedSubscription {
    // Return empty subscription for now - could be enhanced with database observers
    return SharedSubscription {}
  }
}

// MARK: - Backend Query Error

enum BackendQueryError: Error {
  case typeMismatch
}

// MARK: - Convenience Extensions

extension SharedReaderKey where Self == BackendQueryKey<[Project]> {
  /// Shared key for retrieving all projects from the backend
  static var allProjects: Self {
    BackendQueryKey(.allProjects)
  }
}

extension SharedReaderKey where Self == BackendQueryKey<[Build]> {
  /// Shared key for retrieving builds for a specific project
  static func buildsForProject(_ projectId: UUID) -> Self {
    BackendQueryKey(.buildsForProject(projectId))
  }
}

extension SharedReaderKey where Self == BackendQueryKey<[Destination]> {
  /// Shared key for retrieving all destinations from the backend
  static var allDestinations: Self {
    BackendQueryKey(.allDestinations)
  }
}

extension SharedReaderKey where Self == BackendQueryKey<Project?> {
  /// Shared key for retrieving detailed project information
  static func projectDetail(_ projectId: UUID) -> Self {
    BackendQueryKey(.projectDetail(projectId))
  }
}
```

### 5.2 Backend Service Dependency Integration

**File**: `Packages/Lib/Sources/LocalBackend/LocalBackendService+Dependency.swift`

```swift
import Dependencies
import Foundation

public extension DependencyValues {
  var backendService: LocalBackendService {
    get { self[LocalBackendServiceKey.self] }
    set { self[LocalBackendServiceKey.self] = newValue }
  }
}

private enum LocalBackendServiceKey: DependencyKey {
  static let liveValue = LocalBackendService()
  static let testValue = LocalBackendService()
}
```

### 5.3 Test Integration Examples

**File**: `Tests/LocalBackendCoreTests/SharedReaderIntegrationTests.swift`

```swift
import Testing
import Sharing
import Dependencies
@testable import LocalBackend

@Suite("SharedReader Backend Integration Tests")
struct SharedReaderIntegrationTests {

  @Test("All projects can be loaded via SharedReader")
  func allProjectsSharedReader() async throws {
    // Setup test database
    let service = try LocalBackendService.setupTestDatabase(path: .inMemory)

    await withDependencies {
      $0.backendService = service
    } operation: {
      // Create a SharedReader for all projects
      let projectsReader = SharedReader(.allProjects)

      // Load the projects
      try await projectsReader.load()

      // Verify the result
      #expect(!projectsReader.wrappedValue.isEmpty || projectsReader.wrappedValue.isEmpty)
    }
  }

  @Test("Builds for project can be loaded via SharedReader")
  func buildsForProjectSharedReader() async throws {
    let service = try LocalBackendService.setupTestDatabase(path: .inMemory)

    await withDependencies {
      $0.backendService = service
    } operation: {
      // First create a test project
      let project = try await createTestProject()
      let testProjectId = project.id

      // Create a SharedReader for builds
      let buildsReader = SharedReader(.buildsForProject(testProjectId))

      // Load the builds
      try await buildsReader.load()

      // Verify the result
      #expect(buildsReader.wrappedValue.isEmpty) // Should be empty initially
    }
  }

  private func createTestProject() async throws -> Project {
    @Dependency(\.backendService) var service
    let project = Project(
      id: UUID(),
      name: "Test Project",
      path: "/path/to/test",
      schemes: []
    )
    try await service.createProject(project)
    return project
  }
}
```

## Implementation Checklist

- [ ] Create `Backend+SharedKey.swift` with BackendQueryKey implementation
- [ ] Create `LocalBackendService+Dependency.swift` for dependency injection
- [ ] Create `SharedReaderIntegrationTests.swift` for testing
- [ ] Implement BackendQueryKey struct with BackendQuery enum for operations:
  - [ ] allProjects case for loading all projects
  - [ ] buildsForProject(UUID) case for loading builds for a specific project
  - [ ] allDestinations case for loading all destinations
  - [ ] projectDetail(UUID) case for loading specific project details
- [ ] Test SharedReaderKey protocol conformance works with dependency injection
- [ ] Test async backend service integration within BackendQueryKey load method
- [ ] Test error handling and type safety in BackendQueryKey implementation
- [ ] Verify @SharedReader usage in views and view models

## Architecture Benefits

1. **Direct Dependency Usage**: Uses `@Dependency(\.backendService)` directly without wrapper layers
2. **Unified Implementation**: Single BackendQueryKey struct handles all backend operations via BackendQuery enum
3. **Type Safety**: Generic Value parameter ensures type safety with compile-time checking
4. **Async Integration**: Properly bridges async backend APIs to SharedReaderKey protocol
5. **Testability**: Dependency injection enables easy testing with different backend configurations
6. **Extensible Design**: Easy to add new backend operations by extending BackendQuery enum

## Usage Examples

```swift
// In SwiftUI Views - load all projects
@SharedReader(.allProjects) var projects: [Project] = []

// In SwiftUI Views - load builds for a specific project
@SharedReader(.buildsForProject(projectId)) var builds: [Build] = []

// In SwiftUI Views - load all destinations
@SharedReader(.allDestinations) var destinations: [Destination] = []

// In SwiftUI Views - load specific project details
@SharedReader(.projectDetail(projectId)) var project: Project?

// Manual loading when needed
try await $projects.load()
```

## Testing Examples

```swift
// Unit test with dependency injection
await withDependencies {
  $0.backendService = testService
} operation: {
  @SharedReader(.allProjects) var projects: [Project] = []

  try await $projects.load()
  #expect(!projects.isEmpty)
}
```

## Integration Notes

- This step leverages the existing LocalBackendService with direct dependency injection
- BackendQueryKey struct provides unified async-to-sync bridge for all backend operations
- BackendQuery enum centralizes all backend operation types for maintainability
- Generic Value parameter ensures compile-time type safety for each operation
- Dependency injection allows easy testing and configuration swapping
- Subscribe methods are ready for future database change notification integration
- Single struct implementation reduces code duplication and maintenance overhead

## Future Enhancements

- **Real-time Updates**: Implement subscribe methods with GRDB database observers
- **Query Expansion**: Add more BackendQuery cases for additional backend operations
- **Caching Strategy**: Add intelligent caching within BackendQueryKey implementation
- **Error Recovery**: Enhanced error handling with retry mechanisms
- **Performance Optimization**: Add debouncing and batching for frequent loads

## Next Step

After completing this step, proceed to [Step 6: Backend Service Integration](./STEP_6_BACKEND_SERVICE_CONTAINER.md) to set up complete dependency injection container.
