# Step 8: Migration Strategy

**Goal**: Simple manual migration from direct GRDB usage to the new backend abstraction layer for this work-in-progress project.

## Migration Overview

Since this is a work-in-progress project and not in production, we can use a simple manual migration approach without complex backup systems or UI migration tools.

## Manual Migration Steps

### Step 1: Backup Your Current Database (Optional)

If you want to keep your existing data for reference:

```bash
# Navigate to your app's database location
# Typically in ~/Library/Application Support/XcodeBuilder2/
cp your-database.db your-database-backup.db
```

### Step 2: Update Dependencies

Add the Dependencies package to your `Package.swift` if not already added:

```swift
dependencies: [
    .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.0.0"),
    // ... other dependencies
]
```

### Step 3: Update Your App Initialization

Replace your current app initialization with the new Dependencies-based setup:

```swift
// In your XcodeBuilder2App.swift
import Dependencies

@main
struct XcodeBuilder2App: App {

    init() {
        // Prepare dependencies during app startup
        do {
            try BackendAppSetup.prepareDependencies()
        } catch {
            print("Failed to prepare dependencies: \(error)")
            // Handle initialization failure appropriately
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

### Step 4: Update View Models

Replace direct GRDB access with @Dependency injection:

```swift
// Before (direct GRDB):
class ProjectListViewModel: ObservableObject {
    private let dbPool: DatabasePool

    init(dbPool: DatabasePool) {
        self.dbPool = dbPool
    }

    func loadProjects() async {
        // Direct GRDB calls...
    }
}

// After (Dependencies):
import Dependencies

@MainActor
class ProjectListViewModel: ObservableObject {
    @Dependency(\.backendService) var backendService

    func loadProjects() async {
        do {
            for try await projectIds in backendService.streamAllProjectIds() {
                // Use backend service...
            }
        } catch {
            print("Failed to load projects: \(error)")
        }
    }
}
```

### Step 5: Update Views with @Shared

Replace manual data loading with @Shared reactive queries:

```swift
// Before (manual loading):
struct ProjectListView: View {
    @StateObject private var viewModel = ProjectListViewModel()

    var body: some View {
        List(viewModel.projects) { project in
            Text(project.name)
        }
        .task {
            await viewModel.loadProjects()
        }
    }
}

// After (@Shared):
struct ProjectListView: View {
    @Shared(ProjectQueries.allIds)
    private var projectIds: [String] = []

    var body: some View {
        List(projectIds, id: \.self) { projectId in
            ProjectRowView(projectId: projectId)
        }
    }
}
```

## Migration Checklist

- [ ] **Backup current database** (optional, for reference)
- [ ] **Add Dependencies package** to Package.swift
- [ ] **Update app initialization** to use `BackendAppSetup.prepareDependencies()`
- [ ] **Create backend service files** from Step 6
- [ ] **Update view models** to use `@Dependency(\.backendService)`
- [ ] **Update views** to use `@Shared` where appropriate
- [ ] **Test data access** - verify existing data works
- [ ] **Test new functionality** - create/update/delete operations
- [ ] **Test reactive updates** - verify @Shared properties update UI
- [ ] **Clean up old code** - remove direct GRDB usage
- [ ] **Update tests** - use Dependencies test support

## Troubleshooting

### Database Path Issues

If the app can't find your existing database:

```swift
// Use custom database path in app initialization
try BackendAppSetup.prepareDependencies(
    databaseURL: URL(fileURLWithPath: "/path/to/your/existing/database.db")
)
```

### Data Not Appearing

1. Verify database schema matches what the LocalBackend expects
2. Check that SharingGRDB is configured correctly
3. Ensure BackendQuery keys are set up properly

### Build Issues

1. Make sure all new files are added to your Xcode project
2. Verify Dependencies package is properly integrated
3. Check import statements in your files

## Post-Migration

After successful migration:

1. **Monitor Performance**: The new abstraction should have minimal performance impact
2. **Test Edge Cases**: Try various scenarios that were working before
3. **Plan Future Backends**: You're now ready to add CloudKit or other backends later
4. **Update Documentation**: Document your specific app's usage patterns

## Rollback (If Needed)

If you encounter issues:

1. Restore your database backup
2. Revert code changes using git
3. Remove the new backend abstraction files
4. Return to direct GRDB usage

Since this is a development project, a simple `git checkout` to the previous working state is the easiest rollback approach.

## Next Steps

After successful migration, you have:

- ✅ Clean backend abstraction layer
- ✅ Reactive UI updates with @Shared
- ✅ Testable code with Dependencies
