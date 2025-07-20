# Step 6: Backend Service Integration

**Goal**: Set up backend service integration using Dependencies library for dependency injection and SharingGRDB for reactive UI updates.

## Files to Create

### 6.1 Backend Service Dependency

**File**: `Packages/Lib/Sources/Core/Services/BackendServiceDependency.swift`

````swift
import Dependencies
import Foundation

/// Dependency key for the backend service
public enum BackendServiceKey: DependencyKey {
    public static var liveValue: BackendService = {
        // This will be overridden during app initialization
        fatalError("BackendService not configured. Call BackendServiceKey.configure() during app startup.")
    }()

    public static var testValue: BackendService = MockBackendService()
}

public extension DependencyValues {
    var backendService: BackendService {
        get { self[BackendServiceKey.self] }
        set { self[BackendServiceKey.self] = newValue }
    }
}

// MARK: - Configuration Helper

public extension BackendServiceKey {
    /// Configure the live backend service (call once during app startup)
    static func configure(with service: BackendService) {
        liveValue = service
    }
}### 6.2 Backend Service Initialization

**File**: `Packages/Lib/Sources/Core/Services/BackendInitializer.swift`

```swift
import Dependencies
import Foundation
import LocalBackend

/// Helper for initializing the backend service with Dependencies
public struct BackendInitializer {

    /// Initialize the backend service using Dependencies prepareDependencies
    public static func prepareDependencies() throws {
        // Create and configure the local backend
        let backendType = LocalBackendType()
        let service = try backendType.createService()

        // Configure the dependency
        BackendServiceKey.configure(with: service)

        // Set up SharingGRDB integration
        if let localService = service as? LocalBackendService {
            SharingGRDBSetup.configure(with: localService)
        }
    }

    /// Initialize with custom database URL
    public static func prepareDependencies(databaseURL: URL) throws {
        let backendType = LocalBackendType(databaseURL: databaseURL)
        let service = try backendType.createService()

        BackendServiceKey.configure(with: service)

        if let localService = service as? LocalBackendService {
            SharingGRDBSetup.configure(with: localService)
        }
    }
}
````

### 6.3 SharingGRDB Integration

**File**: `Packages/Lib/Sources/LocalBackend/SharingKeys/SharingGRDBSetup.swift`

```swift
import Foundation
import GRDB
import SharingGRDB

/// Set up SharingGRDB with the local backend database
public struct SharingGRDBSetup {

    /// Configure SharingGRDB to use the local backend's database pool
    public static func configure(with service: LocalBackendService) {
        // Get the database pool from the local backend service
        let dbPool = service.databasePoolForSharing

        // Configure SharingGRDB to use this database pool
        // This allows @Shared properties with BackendQuery keys to work
        SharingGRDB.configure(dbPool)
    }
}
```

### 6.4 Dependencies Integration Helper

**File**: `Packages/Lib/Sources/Core/Services/BackendAppIntegration.swift`

```swift
import Dependencies
import Foundation
import SwiftUI

/// App setup using Dependencies prepareDependencies pattern
public struct BackendAppSetup {

    /// Prepare dependencies for the app (call during app initialization)
    public static func prepareDependencies() throws {
        try BackendInitializer.prepareDependencies()
    }

    /// Prepare dependencies with custom database URL
    public static func prepareDependencies(databaseURL: URL) throws {
        try BackendInitializer.prepareDependencies(databaseURL: databaseURL)
    }
}
```

## Implementation Checklist

- [ ] Create `BackendServiceDependency.swift` with Dependencies key and configuration
- [ ] Create `BackendInitializer.swift` with Dependencies-based initialization
- [ ] Create `SharingGRDBSetup.swift` for database integration
- [ ] Create `BackendAppIntegration.swift` with Dependencies setup helper
- [ ] Add Dependencies package to your project dependencies
- [ ] Test backend initialization works correctly
- [ ] Test SharingGRDB integration with BackendQuery keys
- [ ] Test dependency injection works in view models and views
- [ ] Test mock service works in tests

## Usage Examples

```swift
// In your App.swift - using Dependencies prepareDependencies pattern
import Dependencies

@main
struct XcodeBuilder2App: App {

    init() {
        // Prepare dependencies during app startup
        do {
            try BackendAppSetup.prepareDependencies()
        } catch {
            print("Failed to prepare dependencies: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

// In a view model - using @Dependency
import Dependencies

@MainActor
class ProjectListViewModel: ObservableObject {
    @Dependency(\.backendService) var backendService
    @Published var projects: [Project] = []

    func loadProjects() async {
        do {
            for try await projectIds in backendService.streamAllProjectIds() {
                // Handle project IDs
            }
        } catch {
            print("Failed to load projects: \(error)")
        }
    }
}

// Using @Shared directly in views (works the same)
struct ProjectListView: View {
    @Shared(ProjectQueries.allIds)
    private var projectIds: [String] = []

    var body: some View {
        List(projectIds, id: \.self) { projectId in
            ProjectRowView(projectId: projectId)
        }
    }
}

// In tests - automatic mock injection
class ProjectListTests: XCTestCase {
    func testProjectLoading() async {
        // Dependencies automatically provides testValue (MockBackendService)
        let viewModel = withDependencies {
            // Can override specific test dependencies here if needed
        } operation: {
            ProjectListViewModel()
        }

        await viewModel.loadProjects()
        // Test expectations...
    }
}
```

## Integration Notes

- Uses Dependencies library for clean dependency injection
- Static initialization during app startup with `prepareDependencies`
- SharingGRDB integration enables reactive @Shared properties
- Automatic mock injection in tests via Dependencies
- Simple @Dependency access in view models and other components

## Next Step

After completing this step, proceed to [Step 7: UI Integration](./STEP_7_UI_INTEGRATION.md) to update your existing views to use the new backend abstraction layer.
