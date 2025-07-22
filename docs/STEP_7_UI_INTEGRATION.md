# Step 7: UI Integration (DEFERRED TO STEP 9)

**Status**: 🔄 **This step has been moved to Step 9. Complete Step 8 (@Shared Integration Layer) first.**

**Reason**: We need to create the @Shared integration layer before we can update UI components.

**Current Priority**: [Step 8: @Shared Integration Layer](./STEP_8_SHARED_INTEGRATION.md)

## What We've Accomplished So Far

✅ **Step 1-6: Backend Abstraction Layer**

- ✅ Core protocol definitions (BackendService)
- ✅ Value types for data transfer (ProjectValue, SchemeValue, etc.)
- ✅ LocalBackend implementation with GRDB
- ✅ Build job management with LocalBuildJobManager actor
- ✅ Git repository operations (fetchVersions, fetchBranches)
- ✅ Dependency injection setup
- ✅ Comprehensive test coverage

## Current Implementation Status

### ✅ **Completed Components:**

1. **BackendService Protocol** (`Core/Client/Services/BackendServiceProtocol.swift`)

   - All CRUD operations for projects, schemes, builds
   - Reactive streaming methods
   - Build job operations (create, start, cancel, delete)
   - Git repository operations (fetchVersions, fetchBranches)

2. **LocalBackend Implementation** (`LocalBackend/LocalBackendService.swift`)

   - Full implementation of BackendService protocol
   - Integration with GRDB database
   - LocalBuildJobManager actor for build execution
   - Git operations using GitCommand

3. **Shared Models** (`Core/Shared/Models/`)

   - XcodeBuildPayload and XcodeBuildProgress
   - Version with validation
   - GitBranch for repository information
   - BuildJob status and progress types

4. **Dependency Injection** (`Core/Client/Dependencies/`)

   - BackendServiceKey with proper fatalError setup
   - Requires explicit configuration during app initialization

5. **Test Coverage** (`Tests/LocalBackendCoreTests/`)
   - Complete CRUD operation tests
   - Git repository operation tests (fetchVersions, fetchBranches)
   - Error handling and edge case coverage

### 🔄 **Still Required:**

1. **@Shared and Observation Integration**

   - BackendQuery keys for reactive data access
   - Domain model queries for automatic conversion
   - Integration with swift-sharing for reactive UI updates

2. **UI Layer Updates**
   - Update existing views to use BackendService instead of direct GRDB
   - Implement @Shared properties for reactive data binding
   - Create backend-aware view models

## Next Steps Priority

1. **Complete Backend Query System** (Required before UI integration)
2. **Create @Shared Integration Layer**
3. **Update UI Components** (This step)
4. **Migration Strategy**
5. **Testing and Validation**

## Files to Update and Create

### 7.1 Update ProjectList to Use Backend Abstraction

**File**: `XcodeBuilder2/Screens/ProjectList/ProjectList.swift` (create new container pattern)

```swift
// Container View Pattern
struct ProjectListContainer: View {
    @SharedReader private var projectIds: [String] = []

    init() {
        _projectIds = .init(wrappedValue: [], .allProjectIds)
    }

    var body: some View {
        ProjectList(projectIds: projectIds)
            .task {
                try? await $projectIds.load(.allProjectIds)
            }
    }
}

// Presentation View Pattern
struct ProjectList: View {
    let projectIds: [String]

    var body: some View {
        // Pure SwiftUI presentation code
        // No @SharedReader or data loading logic
    }
}
```

**File**: `XcodeBuilder2/Screens/ProjectList/ProjectListItemView.swift` (create container pattern)

```swift
// Container View Pattern
struct ProjectListItemViewContainer: View {
    let projectId: String

    @SharedReader private var project: ProjectValue? = nil
    @SharedReader(.schemeIds(projectId: projectId)) private var schemeIds: [UUID] = []
    @SharedReader(.latestBuilds(projectId: projectId, limit: 3)) private var recentBuilds: [BuildModelValue] = []

    init(projectId: String) {
        _project = .init(wrappedValue: nil, .project(id: projectId))
    }

    var body: some View {
        ProjectListItemView(
            project: project,
            schemeIds: schemeIds,
            recentBuilds: recentBuilds
        )
        .task(id: projectId) {
            try? await $project.load(.project(id: projectId))
            try? await $schemeIds.load()
            try? await $recentBuilds.load()
        }
    }
}

// Presentation View Pattern
struct ProjectListItemView: View {
    let project: ProjectValue?
    let schemeIds: [UUID]
    let recentBuilds: [BuildModelValue]

    var body: some View {
        // Pure SwiftUI presentation code
        // Display project info, schemes count, recent builds
    }
}
```

### 7.2 Update ProjectDetailView

**File**: `XcodeBuilder2/Screens/ProjectDetail/ProjectDetailView.swift` (create container pattern)

```swift
// Container View Pattern
struct ProjectDetailViewContainer: View {
    let projectId: String

    @SharedReader private var project: ProjectValue? = nil
    @SharedReader private var schemeIds: [UUID] = []
    @SharedReader private var versionStrings: [String] = []

    @State private var selectedVersion: String? = nil

    init(projectId: String) {
        self.projectId = projectId
        _project = .init(wrappedValue: nil, .project(id: projectId))
        _schemeIds = .init(wrappedValue: [], .schemeIds(projectId: projectId))
        _versionStrings = .init(wrappedValue: [], .buildVersionStrings(projectId: projectId))
    }

    var body: some View {
        ProjectDetailView(
            project: project,
            schemeIds: schemeIds,
            versionStrings: versionStrings,
            selectedVersion: $selectedVersion,
            projectId: projectId
        )
        .task(id: projectId) {
            try? await $project.load(.project(id: projectId))
            try? await $schemeIds.load(.schemeIds(projectId: projectId))
            try? await $versionStrings.load(.buildVersionStrings(projectId: projectId))
        }
        .navigationTitle(project?.displayName ?? "Project")
    }
}

// Presentation View Pattern
struct ProjectDetailView: View {
    let project: ProjectValue?
    let schemeIds: [UUID]
    let versionStrings: [String]
    @Binding var selectedVersion: String?
    let projectId: String

    var body: some View {
        // Pure SwiftUI presentation code
        // Project info sections, schemes list, version history
    }
}

// Additional nested container views as needed:
// - SchemeRowViewContainer
// - VersionRowViewContainer
// - BuildSummaryRowContainer
```

### 7.3 Update BuildDetailView with Container Pattern

**File**: `XcodeBuilder2/Screens/BuildDetail/BuildDetailView.swift` (create container pattern)

```swift
// Container View Pattern
struct BuildDetailViewContainer: View {
    let buildId: UUID

    @SharedReader private var build: BuildModelValue? = nil

    @State private var selectedTab: BuildDetailView.Tab = .logs
    @State private var includeDebugLogs: Bool = false

    init(buildId: UUID) {
        self.buildId = buildId
        _build = .init(wrappedValue: nil, .build(id: buildId))
    }

    var body: some View {
        BuildDetailView(
            build: build,
            buildId: buildId,
            selectedTab: $selectedTab,
            includeDebugLogs: $includeDebugLogs
        )
        .task(id: buildId) {
            try? await $build.load(.build(id: buildId))
        }
        .navigationTitle("Build #\(build?.buildNumber ?? 0)")
    }
}

// Presentation View Pattern
struct BuildDetailView: View {
    let build: BuildModelValue?
    let buildId: UUID
    @Binding var selectedTab: Tab
    @Binding var includeDebugLogs: Bool

    enum Tab: String, CaseIterable {
        case overview = "Overview"
        case logs = "Logs"
        case crashes = "Crashes"
    }

    var body: some View {
        // Pure SwiftUI presentation code
        // Tab view with BuildHeaderView, BuildLogsViewContainer, etc.
    }
}

// Additional nested container views:
// - BuildLogsViewContainer
// - LogEntryViewContainer
// - CrashLogsViewContainer
// - CrashLogRowViewContainer
```

### 7.4 Handle Actions Directly in Views

**Pattern**: Views can perform backend operations directly using @Dependency

````swift
struct ProjectDetailView: View {
    let project: ProjectValue?
    let schemeIds: [UUID]
    let versionStrings: [String]
    @Binding var selectedVersion: String?
    let projectId: String

    @Dependency(\.backendService) private var backendService
    @State private var isLoading = false
    @State private var error: Error?

    var body: some View {
        // UI content...

        Button("Start Build") {
            Task {
                await startBuild(schemeId: someSchemeId)
            }
        }
        .disabled(isLoading)
    }

    private func startBuild(schemeId: UUID) async {
        isLoading = true
        error = nil

        do {
            let build = BuildModelValue(
                id: UUID(),
                schemeId: schemeId,
                versionString: "1.0.0",
                buildNumber: 1,
                status: .queued,
                createdAt: Date(),
                startDate: nil,
                endDate: nil
            )

            try await backendService.createBuild(build)
        } catch {
            self.error = error
        }

        isLoading = false
    }
}

### 7.5 Implementation Guidelines

## Architecture Patterns

### Container View Pattern

- **Purpose**: Handle @SharedReader data loading and management
- **Responsibilities**:
  - Declare @SharedReader properties
  - Load data in `.task` modifiers
  - Pass data to presentation views
  - Handle reactive query updates
- **Naming**: Suffix with `Container` (e.g., `ProjectListContainer`)

### Presentation View Pattern

- **Purpose**: Pure SwiftUI UI presentation
- **Responsibilities**:
  - Accept data as parameters
  - Render UI components
  - Handle user interactions (via callbacks)
  - No @SharedReader or data loading logic
- **Naming**: Use descriptive view names (e.g., `ProjectList`, `BuildDetailView`)

### Direct Action Pattern
- **Purpose**: Handle backend operations directly in views using @Dependency
- **Responsibilities**:
  - Use @Dependency(\.backendService) for backend access
  - Manage local loading and error states with @State
  - Provide async action methods within the view
  - Handle user interactions directly
- **Pattern**: No separate action handler classes needed

## Data Loading Patterns

### Basic Container Pattern

```swift
struct SomeViewContainer: View {
    let id: String

    @SharedReader private var data: DataType? = nil

    init(id: String) {
        self.id = id
        _data = .init(wrappedValue: nil, .someQuery(id: id))
    }

    var body: some View {
        SomeView(data: data)
            .task(id: id) {
                try? await $data.load(.someQuery(id: id))
            }
    }
}
````

### Dynamic Query Updates

```swift
// Update query when parameters change
.task(id: [param1, param2] as [AnyHashable]) {
    let queryKey = .newQuery(param1: param1, param2: param2)
    $data = SharedReader(queryKey)
    try? await $data.load(queryKey)
}
```

### Nested Container Views

- Create container views for any component that needs @SharedReader
- Keep the container/presentation separation at every level
- Presentation views only receive computed data

## Error Handling and Loading States

### In Container Views

- Handle data loading errors gracefully
- Pass nil/empty data to presentation views when loading fails
- Use `.task` modifiers for automatic lifecycle management

### In Presentation Views

- Display loading states when data is nil
- Handle empty states appropriately
- Focus on user experience, not data fetching

### In Direct Actions

- Use @Dependency(\.backendService) directly in views for backend operations
- Use @State for local loading and error management
- Handle actions with async methods within the view
- No need for separate action handler classes

## Implementation Checklist

- [ ] **Container Views**: Create container views for all views that need data

  - [ ] `ProjectListContainer`
  - [ ] `ProjectListItemViewContainer`
  - [ ] `ProjectDetailViewContainer`
  - [ ] `SchemeRowViewContainer`
  - [ ] `VersionRowViewContainer`
  - [ ] `BuildSummaryRowContainer`
  - [ ] `BuildDetailViewContainer`
  - [ ] `BuildLogsViewContainer`
  - [ ] `LogEntryViewContainer`
  - [ ] `CrashLogsViewContainer`
  - [ ] `CrashLogRowViewContainer`

- [ ] **Presentation Views**: Update existing views to accept data parameters

  - [ ] Remove all @SharedReader/@Shared usage from presentation views
  - [ ] Accept data via parameters only
  - [ ] Focus on UI rendering and user interactions
  - [ ] Handle loading/empty states gracefully

- [ ] **Direct Actions**: Implement backend operations directly in views

  - [ ] Remove any separate action handler classes
  - [ ] Use @Dependency(\.backendService) in views that need backend operations
  - [ ] Use @State for local loading and error states
  - [ ] Handle user actions with async methods in views

- [ ] **Testing**: Verify architecture works correctly
  - [ ] Container views load data properly
  - [ ] Presentation views render with mock data
  - [ ] Direct actions work with backend service
  - [ ] Reactive updates propagate through containers
  - [ ] Error states are handled gracefully

## Key Changes Made

1. **Container/Presentation Separation**: Clear architectural boundary between data loading and UI presentation

2. **@SharedReader Isolation**: All @SharedReader usage confined to container views only

3. **Pure Presentation Views**: UI views accept only parameters, no data loading responsibilities

4. **Direct Actions**: Backend operations handled directly in views using @Dependency

5. **Reactive Architecture**: Data updates automatically flow from backend through @SharedReader to UI

6. **Type Safety**: Compile-time guarantees for data flow and backend operations

## Usage Patterns

- **Container Views**: `@SharedReader` properties initialized in `init()` with query keys + `.task { try? await $data.load(queryKey) }`
- **Presentation Views**: Accept data parameters + focus on UI rendering
- **Dynamic Queries**: Update SharedReader when parameters change
- **Direct Actions**: `@Dependency(\.backendService)` + async methods in views## Architecture Benefits

- **Separation of Concerns**: Clear boundaries between data loading and presentation
- **Testability**: Presentation views easily testable with mock data
- **Reactive Updates**: Automatic UI updates when backend data changes
- **Type Safety**: Compile-time verification of data types and operations
- **Performance**: Efficient caching and deduplication via @SharedReader
- **Maintainability**: Clear patterns for adding new views and features

## Next Step

After completing this step, proceed to [Step 8: Migration Strategy](./STEP_8_MIGRATION_STRATEGY.md) to plan and execute the migration from your current direct GRDB usage to the new backend abstraction layer.
