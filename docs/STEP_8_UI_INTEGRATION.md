# Step 7: UI Integration

**Goal**: Update existing views and view models to use the new backend abstraction layer with @Shared properties and BackendQuery keys.

## Files to Update and Create

### 7.1 Update ProjectList to Use Backend Abstraction

**File**: `XcodeBuilder2/Screens/ProjectList/ProjectList.swift` (update existing file)

```swift
import SwiftUI
import Sharing
import Core

struct ProjectList: View {
    // Replace direct GRDB access with backend queries
    @Shared(ProjectQueries.allIds)
    private var projectIds: [String] = []

    var body: some View {
        NavigationStack {
            Group {
                if projectIds.isEmpty {
                    ContentUnavailableView(
                        "No Projects",
                        systemImage: "folder",
                        description: Text("Add your first project to get started")
                    )
                } else {
                    List(projectIds, id: \.self) { projectId in
                        NavigationLink(destination: ProjectDetailView(projectId: projectId)) {
                            ProjectListItemView(projectId: projectId)
                        }
                    }
                }
            }
            .navigationTitle("Projects")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Add Project") {
                        // Handle add project
                    }
                }
            }
        }
    }
}
```

**File**: `XcodeBuilder2/Screens/ProjectList/ProjectListItemView.swift` (update existing file)

```swift
import SwiftUI
import Sharing
import Core

struct ProjectListItemView: View {
    let projectId: String

    // Use domain model query for automatic conversion
    @Shared(DomainProjectQueries.project(id: projectId))
    private var project: Project?

    @Shared(ProjectQueries.schemeIds(id: projectId))
    private var schemeIds: [UUID] = []

    @Shared(DomainBuildQueries.latestBuilds(projectId: projectId, limit: 3))
    private var recentBuilds: [Build] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(project?.displayName ?? "Loading...")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(project?.bundleIdentifier ?? projectId)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(schemeIds.count) schemes")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if let lastBuild = recentBuilds.first {
                        Text(lastBuild.status.displayName)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(lastBuild.status.color)
                            .foregroundColor(.white)
                            .cornerRadius(4)
                    }
                }
            }

            if !recentBuilds.isEmpty {
                HStack(spacing: 4) {
                    ForEach(recentBuilds.prefix(3), id: \.id) { build in
                        Circle()
                            .fill(build.status.color)
                            .frame(width: 8, height: 8)
                    }

                    if recentBuilds.count > 3 {
                        Text("+\(recentBuilds.count - 3)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    if let lastBuild = recentBuilds.first {
                        Text(RelativeDateTimeFormatter().localizedString(for: lastBuild.createdAt, relativeTo: .now))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Build Status Extensions

private extension BuildStatus {
    var displayName: String {
        switch self {
        case .queued: return "Queued"
        case .running: return "Running"
        case .succeeded: return "Success"
        case .failed: return "Failed"
        case .cancelled: return "Cancelled"
        }
    }

    var color: Color {
        switch self {
        case .queued: return .orange
        case .running: return .blue
        case .succeeded: return .green
        case .failed: return .red
        case .cancelled: return .gray
        }
    }
}
```

### 7.2 Update ProjectDetailView

**File**: `XcodeBuilder2/Screens/ProjectDetail/ProjectDetailView.swift` (update existing file)

```swift
import SwiftUI
import Sharing
import Core

struct ProjectDetailView: View {
    let projectId: String

    @Shared(DomainProjectQueries.project(id: projectId))
    private var project: Project?

    @Shared(ProjectQueries.schemeIds(id: projectId))
    private var schemeIds: [UUID] = []

    @Shared(ProjectQueries.buildVersionStrings(id: projectId))
    private var versionStrings: [String] = []

    @State private var selectedVersion: String? = nil

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if let project = project {
                    ProjectInfoSection(project: project)

                    SchemesSection(schemeIds: schemeIds, projectId: projectId)

                    VersionsSection(
                        versionStrings: versionStrings,
                        selectedVersion: $selectedVersion,
                        projectId: projectId
                    )
                } else {
                    ProgressView("Loading project...")
                }
            }
            .padding()
        }
        .navigationTitle(project?.displayName ?? "Project")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ProjectInfoSection: View {
    let project: Project

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Project Information")
                .font(.headline)

            InfoRow(label: "Display Name", value: project.displayName)
            InfoRow(label: "Bundle ID", value: project.bundleIdentifier)
            InfoRow(label: "Xcode Project", value: project.xcodeprojName)
            InfoRow(label: "Git Repository", value: project.gitRepoURL.absoluteString)
            InfoRow(label: "Working Directory", value: project.workingDirectoryURL.path)
            InfoRow(label: "Created", value: DateFormatter.medium.string(from: project.createdAt))
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct SchemesSection: View {
    let schemeIds: [UUID]
    let projectId: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Schemes (\(schemeIds.count))")
                .font(.headline)

            LazyVStack(spacing: 8) {
                ForEach(schemeIds, id: \.self) { schemeId in
                    SchemeRowView(schemeId: schemeId, projectId: projectId)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct SchemeRowView: View {
    let schemeId: UUID
    let projectId: String

    @Shared(DomainSchemeQueries.scheme(id: schemeId))
    private var scheme: Scheme?

    @Shared(BuildQueries.buildIds(schemeIds: [schemeId], versionString: nil))
    private var buildIds: [UUID] = []

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(scheme?.name ?? "Loading...")
                    .font(.subheadline)
                    .fontWeight(.medium)

                if let scheme = scheme {
                    Text(scheme.platforms.map(\.rawValue).joined(separator: ", "))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Text("\(buildIds.count) builds")
                .font(.caption)
                .foregroundColor(.secondary)

            Button("Build") {
                // Handle build action
            }
            .buttonStyle(.borderless)
            .controlSize(.small)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

struct VersionsSection: View {
    let versionStrings: [String]
    @Binding var selectedVersion: String?
    let projectId: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Version History")
                .font(.headline)

            if versionStrings.isEmpty {
                Text("No builds yet")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(versionStrings, id: \.self) { version in
                        VersionRowView(
                            version: version,
                            projectId: projectId,
                            isSelected: selectedVersion == version
                        ) {
                            selectedVersion = selectedVersion == version ? nil : version
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct VersionRowView: View {
    let version: String
    let projectId: String
    let isSelected: Bool
    let onTap: () -> Void

    @Shared(ProjectQueries.schemeIds(id: projectId))
    private var schemeIds: [UUID] = []

    @Shared(BuildQueries.buildIds(schemeIds: schemeIds, versionString: version))
    private var buildIds: [UUID] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(version)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Spacer()

                Text("\(buildIds.count) builds")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Image(systemName: isSelected ? "chevron.down" : "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if isSelected {
                LazyVStack(spacing: 4) {
                    ForEach(buildIds.prefix(10), id: \.self) { buildId in
                        BuildSummaryRow(buildId: buildId)
                    }

                    if buildIds.count > 10 {
                        NavigationLink("View all \(buildIds.count) builds") {
                            BuildListView(buildIds: buildIds, title: "Builds for \(version)")
                        }
                        .font(.caption)
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .onTapGesture {
            onTap()
        }
    }
}

struct BuildSummaryRow: View {
    let buildId: UUID

    @Shared(DomainBuildQueries.build(id: buildId))
    private var build: Build?

    var body: some View {
        HStack {
            if let build = build {
                Circle()
                    .fill(build.status.color)
                    .frame(width: 8, height: 8)

                Text("#\(build.buildNumber)")
                    .font(.caption)
                    .fontWeight(.medium)

                Text(build.status.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Text(RelativeDateTimeFormatter().localizedString(for: build.createdAt, relativeTo: .now))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }
}

// MARK: - Helper Views and Extensions

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 100, alignment: .leading)

            Text(value)
                .font(.caption)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private extension DateFormatter {
    static let medium: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}
```

### 7.3 Create Backend-Aware View Model Base

**File**: `XcodeBuilder2/Utils/BackendViewModel.swift`

```swift
import Foundation
import SwiftUI
import Sharing
import Core

/// Base view model class that provides backend service access
@MainActor
open class BackendViewModel: ObservableObject {
    @Shared(.currentBackendService)
    protected var backendService: BackendService?

    @Published public private(set) var isLoading: Bool = false
    @Published public private(set) var error: Error?

    public init() {
        // Subclasses can override to perform setup
        setup()
    }

    /// Override in subclasses for initialization
    open func setup() {
        // Default implementation does nothing
    }

    /// Perform an operation with error handling
    protected func withBackend<T>(_ operation: @escaping (BackendService) async throws -> T) async -> T? {
        guard let service = backendService else {
            error = BackendServiceError.notInitialized
            return nil
        }

        isLoading = true
        error = nil

        do {
            let result = try await operation(service)
            isLoading = false
            return result
        } catch {
            self.error = error
            isLoading = false
            return nil
        }
    }

    /// Clear any error state
    public func clearError() {
        error = nil
    }
}
```

### 7.4 Update ProjectDetailViewModel

**File**: `XcodeBuilder2/Screens/ProjectDetail/ProjectDetailViewModel.swift` (update existing file)

```swift
import Foundation
import SwiftUI
import Sharing
import Core

@MainActor
class ProjectDetailViewModel: BackendViewModel {
    let projectId: String

    // Using @Shared for reactive data
    @Shared(DomainProjectQueries.project(id: ""))
    private var _project: Project?

    @Shared(ProjectQueries.schemeIds(id: ""))
    private var _schemeIds: [UUID] = []

    // Computed properties that update the queries when projectId changes
    var project: Project? { _project }
    var schemeIds: [UUID] { _schemeIds }

    @Published var selectedSchemeId: UUID?
    @Published var isBuilding: Bool = false

    init(projectId: String) {
        self.projectId = projectId
        super.init()
    }

    override func setup() {
        // Update the @Shared queries with the correct projectId
        _project = Shared(DomainProjectQueries.project(id: projectId)).wrappedValue
        _schemeIds = Shared(ProjectQueries.schemeIds(id: projectId)).wrappedValue
    }

    func startBuild(schemeId: UUID) async {
        await withBackend { service in
            // Create a new build
            let build = BuildModelValue(
                schemeId: schemeId,
                versionString: "1.0.0", // This should come from project settings
                buildNumber: 1, // This should be incremented
                status: .queued
            )

            try await service.createBuild(build)

            // In a real implementation, you'd trigger the actual build process here
            isBuilding = true
        }
    }

    func deleteProject() async -> Bool {
        guard await withBackend({ service in
            try await service.deleteProject(id: projectId)
        }) != nil else {
            return false
        }

        return true
    }
}
```

### 7.5 Update BuildDetailView

**File**: `XcodeBuilder2/Screens/BuildDetail/BuildDetailView.swift` (update existing file)

```swift
import SwiftUI
import Sharing
import Core

struct BuildDetailView: View {
    let buildId: UUID

    @Shared(DomainBuildQueries.build(id: buildId))
    private var build: Build?

    @Shared(BuildQueries.logIds(buildId: buildId, includeDebug: false))
    private var logIds: [UUID] = []

    @Shared(CrashLogQueries.crashLogIds(buildId: buildId))
    private var crashLogIds: [String] = []

    @State private var selectedTab: Tab = .logs
    @State private var includeDebugLogs: Bool = false

    enum Tab: String, CaseIterable {
        case overview = "Overview"
        case logs = "Logs"
        case crashes = "Crashes"
    }

    var body: some View {
        VStack(spacing: 0) {
            if let build = build {
                // Header
                BuildHeaderView(build: build)

                // Tab picker
                Picker("Tab", selection: $selectedTab) {
                    ForEach(Tab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                // Content
                TabView(selection: $selectedTab) {
                    BuildOverviewView(build: build)
                        .tag(Tab.overview)

                    BuildLogsView(
                        buildId: buildId,
                        includeDebug: $includeDebugLogs
                    )
                    .tag(Tab.logs)

                    CrashLogsView(crashLogIds: crashLogIds)
                        .tag(Tab.crashes)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            } else {
                ProgressView("Loading build...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle("Build #\(build?.buildNumber ?? 0)")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct BuildHeaderView: View {
    let build: Build

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Build #\(build.buildNumber)")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text(build.versionString)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(build.status.displayName)
                        .font(.headline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(build.status.color)
                        .foregroundColor(.white)
                        .cornerRadius(8)

                    if build.status == .running {
                        ProgressView(value: build.progress)
                            .frame(width: 100)
                    }
                }
            }

            if let startDate = build.startDate {
                HStack {
                    Text("Started: \(startDate, formatter: DateFormatter.full)")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    if let endDate = build.endDate {
                        Text("Duration: \(endDate.timeIntervalSince(startDate).formatted(.time(pattern: .minuteSecond)))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
    }
}

struct BuildLogsView: View {
    let buildId: UUID
    @Binding var includeDebug: Bool

    // Dynamic query based on includeDebug setting
    var logIds: [UUID] {
        @Shared(BuildQueries.logIds(buildId: buildId, includeDebug: includeDebug))
        var ids: [UUID] = []
        return ids
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Build Logs (\(logIds.count))")
                    .font(.headline)

                Spacer()

                Toggle("Debug", isOn: $includeDebug)
                    .controlSize(.mini)
            }
            .padding()

            ScrollView {
                LazyVStack(spacing: 1) {
                    ForEach(logIds, id: \.self) { logId in
                        LogEntryView(logId: logId)
                    }
                }
            }
        }
    }
}

struct LogEntryView: View {
    let logId: UUID

    @Shared(DomainBuildLogQueries.buildLog(id: logId))
    private var log: BuildLog?

    var body: some View {
        if let log = log {
            HStack(alignment: .top, spacing: 12) {
                // Level indicator
                Circle()
                    .fill(log.level.color)
                    .frame(width: 8, height: 8)
                    .padding(.top, 6)

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        if let category = log.category {
                            Text(category)
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color(.systemGray5))
                                .cornerRadius(4)
                        }

                        Text(log.level.rawValue.uppercased())
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(log.level.color)

                        Spacer()

                        Text(log.createdAt, formatter: DateFormatter.time)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    Text(log.content)
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                }

                Spacer(minLength: 0)
            }
            .padding()
            .background(Color(.systemBackground))
        }
    }
}

struct CrashLogsView: View {
    let crashLogIds: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Crash Logs (\(crashLogIds.count))")
                .font(.headline)
                .padding()

            if crashLogIds.isEmpty {
                Text("No crash logs")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(crashLogIds, id: \.self) { crashLogId in
                    CrashLogRowView(crashLogId: crashLogId)
                }
                .listStyle(.plain)
            }
        }
    }
}

struct CrashLogRowView: View {
    let crashLogId: String

    @Shared(DomainCrashLogQueries.crashLog(id: crashLogId))
    private var crashLog: CrashLog?

    var body: some View {
        if let crashLog = crashLog {
            NavigationLink(destination: CrashLogDetailView(crashLogId: crashLogId)) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(crashLog.process)
                            .font(.headline)

                        Spacer()

                        Text(crashLog.priority.displayName)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(crashLog.priority.color)
                            .foregroundColor(.white)
                            .cornerRadius(4)
                    }

                    Text("\(crashLog.hardwareModel) • \(crashLog.osVersion)")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(crashLog.dateTime, formatter: DateFormatter.full)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
    }
}

// MARK: - Extensions

private extension BuildLogLevel {
    var color: Color {
        switch self {
        case .debug: return .gray
        case .info: return .blue
        case .warning: return .orange
        case .error: return .red
        }
    }
}

private extension CrashLogPriority {
    var displayName: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        case .critical: return "Critical"
        }
    }

    var color: Color {
        switch self {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        case .critical: return .purple
        }
    }
}

private extension DateFormatter {
    static let full: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter
    }()

    static let time: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        return formatter
    }()
}
```

## Implementation Checklist

- [ ] Update `ProjectList.swift` to use BackendQuery keys
- [ ] Update `ProjectListItemView.swift` with @Shared properties
- [ ] Update `ProjectDetailView.swift` with comprehensive backend integration
- [ ] Create `BackendViewModel.swift` base class
- [ ] Update `ProjectDetailViewModel.swift` to use backend abstraction
- [ ] Update `BuildDetailView.swift` with reactive queries
- [ ] Test all views work with backend abstraction:
  - [ ] Data loads correctly from backend
  - [ ] Updates are reactive (data changes when backend changes)
  - [ ] Error states are handled gracefully
  - [ ] Loading states work properly
- [ ] Verify backend switching works across all views
- [ ] Test performance with large datasets

## Key Changes Made

1. **Replaced Direct GRDB Access**: All views now use `@Shared` properties with `BackendQuery` keys instead of direct database access

2. **Domain Model Integration**: Views use domain model queries (e.g., `DomainProjectQueries.project`) for automatic conversion from backend values

3. **Reactive Updates**: All data is automatically reactive - when the backend changes, views update automatically

4. **Backend Registry**: Added static backend service management through BackendServiceRegistry

5. **Error Handling**: Integrated proper error handling and loading states

6. **Type Safety**: All queries are type-safe with proper generic constraints

## Usage Patterns

- **Simple Data Access**: Use `@Shared(ProjectQueries.allIds)` for backend values
- **Domain Models**: Use `@Shared(DomainProjectQueries.project(id: projectId))` for automatic conversion
- **Dynamic Queries**: Build query keys dynamically based on user input or state changes
- **Error Handling**: Use `BackendViewModel` base class for consistent error handling

## Next Step

After completing this step, proceed to [Step 8: Migration Strategy](./STEP_8_MIGRATION_STRATEGY.md) to plan and execute the migration from your current direct GRDB usage to the new backend abstraction layer.
