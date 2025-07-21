# Step 2: Target Setup and Protocol Conversions

**Goal**: Create the LocalBackend target, relocate SharingGRDB-specific files, and implement conversion methods between protocols and value types.

## 2.1 Create LocalBackend Target

### Update Package.swift

Add the LocalBackend target to `Packages/Lib/Package.swift`:

```swift
// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "Lib",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "Core", targets: ["Core"]),
        .library(name: "LocalBackend", targets: ["LocalBackend"])
    ],
    dependencies: [
        .package(url: "https://github.com/groue/GRDB.swift", from: "6.24.2"),
        .package(url: "https://github.com/groue/SharingGRDB", from: "0.12.0"),
        .package(url: "https://github.com/pointfreeco/swift-sharing", from: "1.0.6")
    ],
    targets: [
        .target(
            name: "Core",
            dependencies: [
                .product(name: "Sharing", package: "swift-sharing")
            ]
            // Note: Core has NO SharingGRDB dependency - stays backend-agnostic
        ),
        .target(
            name: "LocalBackend",
            dependencies: [
                "Core",
                .product(name: "GRDB", package: "GRDB.swift"),
                .product(name: "SharingGRDB", package: "SharingGRDB")
            ]
        ),
        .testTarget(
            name: "xcode-builder-2Tests",
            dependencies: [
                "Core",
                "LocalBackend"
            ]
        )
    ]
)
```

### Create Target Directory Structure

Create the LocalBackend target directory structure:

```bash
# Create LocalBackend target directories
mkdir -p Packages/Lib/Sources/LocalBackend/Models
mkdir -p Packages/Lib/Sources/LocalBackend/Database
mkdir -p Packages/Lib/Sources/LocalBackend/Requests
mkdir -p Packages/Lib/Sources/LocalBackend/SharingKeys
```

## 2.2 File Relocations

### Move SharingGRDB Models from Core to LocalBackend

These files contain `@Table` and `@Column` annotations and should be moved:

**Files to move:**

- `Packages/Lib/Sources/Core/Models/Project.swift` → `Packages/Lib/Sources/LocalBackend/Models/Project.swift`
- `Packages/Lib/Sources/Core/Models/Scheme.swift` → `Packages/Lib/Sources/LocalBackend/Models/Scheme.swift`
- `Packages/Lib/Sources/Core/Models/Build.swift` → `Packages/Lib/Sources/LocalBackend/Models/Build.swift`
- `Packages/Lib/Sources/Core/Models/BuildLog.swift` → `Packages/Lib/Sources/LocalBackend/Models/BuildLog.swift`
- `Packages/Lib/Sources/Core/Models/CrashLog.swift` → `Packages/Lib/Sources/LocalBackend/Models/CrashLog.swift`

**Terminal commands:**

```bash
# Move SharingGRDB model files to LocalBackend
mv Packages/Lib/Sources/Core/Models/Project.swift Packages/Lib/Sources/LocalBackend/Models/
mv Packages/Lib/Sources/Core/Models/Scheme.swift Packages/Lib/Sources/LocalBackend/Models/
mv Packages/Lib/Sources/Core/Models/Build.swift Packages/Lib/Sources/LocalBackend/Models/
mv Packages/Lib/Sources/Core/Models/BuildLog.swift Packages/Lib/Sources/LocalBackend/Models/
mv Packages/Lib/Sources/Core/Models/CrashLog.swift Packages/Lib/Sources/LocalBackend/Models/
```

### Move FetchKeyRequest Files from Core to LocalBackend

These files contain `FetchKeyRequest` implementations specific to SharingGRDB:

**Files to move:**

- `Packages/Lib/Sources/Core/Requests/AllProjectRequest.swift` → `Packages/Lib/Sources/LocalBackend/Requests/AllProjectRequest.swift`
- `Packages/Lib/Sources/Core/Requests/ProjectDetailRequest.swift` → `Packages/Lib/Sources/LocalBackend/Requests/ProjectDetailRequest.swift`

**Terminal commands:**

```bash
# Move FetchKeyRequest files to LocalBackend
mv Packages/Lib/Sources/Core/Requests/AllProjectRequest.swift Packages/Lib/Sources/LocalBackend/Requests/
mv Packages/Lib/Sources/Core/Requests/ProjectDetailRequest.swift Packages/Lib/Sources/LocalBackend/Requests/
```

### Update Import Statements

After moving files, update import statements in the moved files:

**In LocalBackend model files**, add namespace and update imports:

```swift
// Example: Packages/Lib/Sources/LocalBackend/Models/Project.swift
import Foundation
import SharingGRDB
import Core  // Add this import to access protocols and value types

// Wrap existing structs in LocalBackend namespace
public enum LocalBackend {}

extension LocalBackend {
    @Table("projects")  // or appropriate table name
    public struct Project {  // Make public for access from other modules
        @Column("bundle_identifier") public var bundleIdentifier: String
        @Column("name") public var name: String
        @Column("display_name") public var displayName: String
        @Column("git_repo_url") public var gitRepoURL: URL
        @Column("xcodeprojName") public var xcodeprojName: String
        @Column("working_directory_url") public var workingDirectoryURL: URL
        @Column("created_at") public var createdAt: Date

        // Make public initializer
        public init(
            bundleIdentifier: String,
            name: String,
            displayName: String,
            gitRepoURL: URL,
            xcodeprojName: String,
            workingDirectoryURL: URL,
            createdAt: Date = .now
        ) {
            self.bundleIdentifier = bundleIdentifier
            self.name = name
            self.displayName = displayName
            self.gitRepoURL = gitRepoURL
            self.xcodeprojName = xcodeprojName
            self.workingDirectoryURL = workingDirectoryURL
            self.createdAt = createdAt
        }
    }
}

// Add protocol conformance if needed
extension LocalBackend.Project: ProjectProtocol {
    public var id: String { bundleIdentifier }
}
```

**Similar updates needed for:**

- `LocalBackend.Scheme` (SchemeProtocol)
- `LocalBackend.Build` (BuildModelProtocol)
- `LocalBackend.BuildLog` (BuildLogProtocol)
- `LocalBackend.CrashLog` (CrashLogProtocol)

**In LocalBackend request files**, update imports:

```swift
// Example: Packages/Lib/Sources/LocalBackend/Requests/AllProjectRequest.swift
import Foundation
import SharingGRDB
import Core  // Add this import

// Update any references to model types to use LocalBackend namespace
// e.g., Project -> LocalBackend.Project
public struct AllProjectRequest: FetchKeyRequest {
    public typealias Value = [LocalBackend.Project]  // Updated reference

    // ... rest of implementation
}
```

### Core Target Clean-Up

After moving files, the Core target should only contain backend-agnostic files:

**Remaining in Core/Models/:**

- `Database.swift` (domain model, no SharingGRDB)
- `Destination.swift` (domain model, no SharingGRDB)
- `ExportOption.swift` (domain model, no SharingGRDB)

**Core/Requests/ directory should be empty** (or removed if empty)

## 2.3 Files to Create

## 2.3 Protocol Conversion Implementation

### 2.3.1 Core Protocol Conversion Extensions (Core Target)

**File**: `Packages/Lib/Sources/Core/Services/BackendConversions.swift`

```swift
import Foundation

// MARK: - Protocol to Value Conversions
// These work with ANY type conforming to the protocols

/// Extension on ProjectProtocol to convert to ProjectValue
public extension ProjectProtocol {
    func toProjectValue() -> ProjectValue {
        return ProjectValue(
            bundleIdentifier: bundleIdentifier,
            name: name,
            displayName: displayName,
            gitRepoURL: gitRepoURL,
            xcodeprojName: xcodeprojName,
            workingDirectoryURL: workingDirectoryURL,
            createdAt: createdAt
        )
    }
}

/// Extension on SchemeProtocol to convert to SchemeValue
public extension SchemeProtocol {
    func toSchemeValue() -> SchemeValue {
        return SchemeValue(
            id: id,
            projectBundleIdentifier: projectBundleIdentifier,
            name: name,
            platforms: platforms,
            order: order
        )
    }
}

/// Extension on BuildModelProtocol to convert to BuildModelValue
public extension BuildModelProtocol {
    func toBuildModelValue() -> BuildModelValue {
        return BuildModelValue(
            id: id,
            schemeId: schemeId,
            versionString: versionString,
            buildNumber: buildNumber,
            createdAt: createdAt,
            startDate: startDate,
            endDate: endDate,
            exportOptions: exportOptions,
            status: status,
            progress: progress,
            commitHash: commitHash,
            deviceMetadata: deviceMetadata,
            osVersion: osVersion,
            memory: memory,
            processor: processor
        )
    }
}

/// Extension on BuildLogProtocol to convert to BuildLogValue
public extension BuildLogProtocol {
    func toBuildLogValue() -> BuildLogValue {
        return BuildLogValue(
            id: id,
            buildId: buildId,
            category: category,
            level: level,
            content: content,
            createdAt: createdAt
        )
    }
}

/// Extension on CrashLogProtocol to convert to CrashLogValue
public extension CrashLogProtocol {
    func toCrashLogValue() -> CrashLogValue {
        return CrashLogValue(
            incidentIdentifier: incidentIdentifier,
            isMainThread: isMainThread,
            createdAt: createdAt,
            buildId: buildId,
            content: content,
            hardwareModel: hardwareModel,
            process: process,
            role: role,
            dateTime: dateTime,
            launchTime: launchTime,
            osVersion: osVersion,
            note: note,
            fixed: fixed,
            priority: priority
        )
    }
}

// MARK: - Array Conversion Extensions

/// Extension on Array of ProjectProtocol conforming types
public extension Array where Element: ProjectProtocol {
    func toProjectValues() -> [ProjectValue] {
        return map { $0.toProjectValue() }
    }
}

/// Extension on Array of SchemeProtocol conforming types
public extension Array where Element: SchemeProtocol {
    func toSchemeValues() -> [SchemeValue] {
        return map { $0.toSchemeValue() }
    }
}

/// Extension on Array of BuildModelProtocol conforming types
public extension Array where Element: BuildModelProtocol {
    func toBuildModelValues() -> [BuildModelValue] {
        return map { $0.toBuildModelValue() }
    }
}

/// Extension on Array of BuildLogProtocol conforming types
public extension Array where Element: BuildLogProtocol {
    func toBuildLogValues() -> [BuildLogValue] {
        return map { $0.toBuildLogValue() }
    }
}

/// Extension on Array of CrashLogProtocol conforming types
public extension Array where Element: CrashLogProtocol {
    func toCrashLogValues() -> [CrashLogValue] {
        return map { $0.toCrashLogValue() }
    }
}

// MARK: - Optional Conversion Extensions

public extension Optional where Wrapped: ProjectProtocol {
    func toProjectValue() -> ProjectValue? {
        return self?.toProjectValue()
    }
}

public extension Optional where Wrapped: SchemeProtocol {
    func toSchemeValue() -> SchemeValue? {
        return self?.toSchemeValue()
    }
}

public extension Optional where Wrapped: BuildModelProtocol {
    func toBuildModelValue() -> BuildModelValue? {
        return self?.toBuildModelValue()
    }
}

public extension Optional where Wrapped: BuildLogProtocol {
    func toBuildLogValue() -> BuildLogValue? {
        return self?.toBuildLogValue()
    }
}

public extension Optional where Wrapped: CrashLogProtocol {
    func toCrashLogValue() -> CrashLogValue? {
        return self?.toCrashLogValue()
    }
}

// MARK: - AsyncSequence Conversion Extensions

public extension AsyncSequence where Element: ProjectProtocol {
    func toProjectValues() -> AsyncMapSequence<Self, ProjectValue> {
        return self.map { $0.toProjectValue() }
    }
}

public extension AsyncSequence where Element: SchemeProtocol {
    func toSchemeValues() -> AsyncMapSequence<Self, SchemeValue> {
        return self.map { $0.toSchemeValue() }
    }
}

public extension AsyncSequence where Element: BuildModelProtocol {
    func toBuildModelValues() -> AsyncMapSequence<Self, BuildModelValue> {
        return self.map { $0.toBuildModelValue() }
    }
}

public extension AsyncSequence where Element: BuildLogProtocol {
    func toBuildLogValues() -> AsyncMapSequence<Self, BuildLogValue> {
        return self.map { $0.toBuildLogValue() }
    }
}

public extension AsyncSequence where Element: CrashLogProtocol {
    func toCrashLogValues() -> AsyncMapSequence<Self, CrashLogValue> {
        return self.map { $0.toCrashLogValue() }
    }
}
```

### 2.3.2 LocalBackend-Specific Conversions (LocalBackend Target)

These files handle conversions between SharingGRDB @Table structs and backend value types.

**File**: `Packages/Lib/Sources/LocalBackend/Models/Project+LocalBackend.swift`

```swift
import Foundation
import SharingGRDB
import Core

// GRDB Project struct (defined elsewhere in GRDBModels.swift)
/*
@Table("projects")
struct Project {
    @Column("bundle_identifier") var bundleIdentifier: String
    @Column("name") var name: String
    @Column("display_name") var displayName: String
    // ... other @Column properties
}
*/

// MARK: - SharingGRDB Project to ProjectValue Conversion

extension LocalBackend.Project {
    func toProjectValue() -> ProjectValue {
        return ProjectValue(
            bundleIdentifier: bundleIdentifier,
            name: name,
            displayName: displayName,
            gitRepoURL: gitRepoURL,
            xcodeprojName: xcodeprojName,
            workingDirectoryURL: workingDirectoryURL,
            createdAt: createdAt
        )
    }
}

// MARK: - ProjectValue to SharingGRDB Project Conversion

extension ProjectValue {
    func toGRDBProject() -> LocalBackend.Project {
        return LocalBackend.Project(
            bundleIdentifier: bundleIdentifier,
            name: name,
            displayName: displayName,
            gitRepoURL: gitRepoURL,
            xcodeprojName: xcodeprojName,
            workingDirectoryURL: workingDirectoryURL,
            createdAt: createdAt
        )
    }
}

// MARK: - Array Conversions

extension Array where Element == LocalBackend.Project {
    func toProjectValues() -> [ProjectValue] {
        return map { $0.toProjectValue() }
    }
}

extension Array where Element == ProjectValue {
    func toGRDBProjects() -> [LocalBackend.Project] {
        return map { $0.toGRDBProject() }
    }
}
```

**File**: `Packages/Lib/Sources/LocalBackend/Models/Scheme+LocalBackend.swift`

```swift
import Foundation
import SharingGRDB
import Core

extension LocalBackend.Scheme {
    func toSchemeValue() -> SchemeValue {
        return SchemeValue(
            id: id,
            projectBundleIdentifier: projectBundleIdentifier,
            name: name,
            platforms: platforms,
            order: order
        )
    }
}

extension SchemeValue {
    func toGRDBScheme() -> LocalBackend.Scheme {
        return LocalBackend.Scheme(
            id: id,
            projectBundleIdentifier: projectBundleIdentifier,
            name: name,
            platforms: platforms,
            order: order
        )
    }
}

extension Array where Element == LocalBackend.Scheme {
    func toSchemeValues() -> [SchemeValue] {
        return map { $0.toSchemeValue() }
    }
}
```

**File**: `Packages/Lib/Sources/LocalBackend/Models/Build+LocalBackend.swift`

```swift
import Foundation
import SharingGRDB
import Core

extension LocalBackend.Build {
    func toBuildModelValue() -> BuildModelValue {
        return BuildModelValue(
            id: id,
            schemeId: schemeId,
            versionString: versionString,
            buildNumber: buildNumber,
            createdAt: createdAt,
            startDate: startDate,
            endDate: endDate,
            exportOptions: exportOptions,
            status: status,
            progress: progress,
            commitHash: commitHash,
            deviceMetadata: deviceMetadata,
            osVersion: osVersion,
            memory: memory,
            processor: processor
        )
    }
}

extension BuildModelValue {
    func toGRDBBuild() -> LocalBackend.Build {
        return LocalBackend.Build(
            id: id,
            schemeId: schemeId,
            versionString: versionString,
            buildNumber: buildNumber,
            createdAt: createdAt,
            startDate: startDate,
            endDate: endDate,
            exportOptions: exportOptions,
            status: status,
            progress: progress,
            commitHash: commitHash,
            deviceMetadata: deviceMetadata,
            osVersion: osVersion,
            memory: memory,
            processor: processor
        )
    }
}
```

**File**: `Packages/Lib/Sources/LocalBackend/Models/BuildLog+LocalBackend.swift`

```swift
import Foundation
import SharingGRDB
import Core

extension LocalBackend.BuildLog {
    func toBuildLogValue() -> BuildLogValue {
        return BuildLogValue(
            id: id,
            buildId: buildId,
            category: category,
            level: level,
            content: content,
            createdAt: createdAt
        )
    }
}

extension BuildLogValue {
    func toGRDBBuildLog() -> LocalBackend.BuildLog {
        return LocalBackend.BuildLog(
            id: id,
            buildId: buildId,
            category: category,
            level: level,
            content: content,
            createdAt: createdAt
        )
    }
}
```

**File**: `Packages/Lib/Sources/LocalBackend/Models/CrashLog+LocalBackend.swift`

```swift
import Foundation
import SharingGRDB
import Core

extension LocalBackend.CrashLog {
    func toCrashLogValue() -> CrashLogValue {
        return CrashLogValue(
            incidentIdentifier: incidentIdentifier,
            isMainThread: isMainThread,
            createdAt: createdAt,
            buildId: buildId,
            content: content,
            hardwareModel: hardwareModel,
            process: process,
            role: role,
            dateTime: dateTime,
            launchTime: launchTime,
            osVersion: osVersion,
            note: note,
            fixed: fixed,
            priority: priority
        )
    }
}

extension CrashLogValue {
    func toGRDBCrashLog() -> LocalBackend.CrashLog {
        return LocalBackend.CrashLog(
            incidentIdentifier: incidentIdentifier,
            isMainThread: isMainThread,
            createdAt: createdAt,
            buildId: buildId,
            content: content,
            hardwareModel: hardwareModel,
            process: process,
            role: role,
            dateTime: dateTime,
            launchTime: launchTime,
            osVersion: osVersion,
            note: note,
            fixed: fixed,
            priority: priority
        )
    }
}
```

## Implementation Checklist

### Target Setup & File Relocation

- [ ] Update `Package.swift` to add LocalBackend target
- [ ] Create LocalBackend directory structure
- [ ] Move SharingGRDB model files from Core to LocalBackend:
  - [ ] `Project.swift`
  - [ ] `Scheme.swift`
  - [ ] `Build.swift`
  - [ ] `BuildLog.swift`
  - [ ] `CrashLog.swift`
- [ ] Move FetchKeyRequest files from Core to LocalBackend:
  - [ ] `AllProjectRequest.swift`
  - [ ] `ProjectDetailRequest.swift`
- [ ] Update import statements in moved files
- [ ] Add LocalBackend namespace to moved model files
- [ ] Verify Core target contains only backend-agnostic files

### Core Target (Protocol Extensions)

- [ ] Create `BackendConversions.swift` with protocol conversion extensions
- [ ] Test protocol conversions work with any conforming type:
  - [ ] `ProjectProtocol` → `ProjectValue`
  - [ ] `SchemeProtocol` → `SchemeValue`
  - [ ] Array/Optional/AsyncSequence conversions

### LocalBackend Target (GRDB-Specific Conversions)

- [ ] Create GRDB model conversion files:
  - [ ] `Project+LocalBackend.swift`
  - [ ] `Scheme+LocalBackend.swift`
  - [ ] `Build+LocalBackend.swift`
  - [ ] `BuildLog+LocalBackend.swift`
  - [ ] `CrashLog+LocalBackend.swift`
- [ ] Test GRDB conversions work correctly:
  - [ ] SharingGRDB struct → Value type → SharingGRDB struct (round trip)
  - [ ] Array conversions for batch operations

## Usage Examples

```swift
// Core Protocol Conversions (works with ANY conforming type)
let project: any ProjectProtocol = // ... could be domain model, GRDB model, API model
let projectValue: ProjectValue = project.toProjectValue()

let projects: [any ProjectProtocol] = // ... mixed types all conforming to ProjectProtocol
let projectValues: [ProjectValue] = projects.toProjectValues()

// LocalBackend GRDB Conversions (specific to SharingGRDB types)
let grdbProject: LocalBackend.Project = // ... from database
let projectValue: ProjectValue = grdbProject.toProjectValue()
let backToGRDB: LocalBackend.Project = projectValue.toGRDBProject()

// Used in LocalBackendService
let grdbProjects: [LocalBackend.Project] = try await fetch(...)
let projectValues: [ProjectValue] = grdbProjects.toProjectValues()
return AsyncStream { projectValues.toProjectValues() }
```

## 2.4 Missing Type Definitions (Prerequisites)

**⚠️ CRITICAL**: Before implementing Step 2, ensure Step 1 is complete. The protocol conversions require these types to exist:

### Required Types in Core Target

Verify these types exist in `Packages/Lib/Sources/Core/Services/BackendModels.swift`:

**Protocols:**

- `ProjectProtocol`
- `SchemeProtocol`
- `BuildModelProtocol`
- `BuildLogProtocol`
- `CrashLogProtocol`

**Value Types:**

- `ProjectValue`
- `SchemeValue`
- `BuildModelValue`
- `BuildLogValue`
- `CrashLogValue`

**Supporting Types:**

- `Platform` (enum)
- `ExportOption` (struct)
- `BuildStatus` (enum)
- `BuildLogLevel` (enum)
- `CrashLogRole` (enum)
- `CrashLogPriority` (enum)

### Quick Verification Command

```bash
# Check if Step 1 types are available
cd Packages/Lib
swift build --target Core

# If this fails, complete Step 1 first
```

**If Step 1 is incomplete:**

1. Complete [Step 1: Backend Protocols](./STEP_1_BACKEND_PROTOCOLS.md) first
2. Ensure all types compile in Core target
3. Then return to Step 2

## 2.5 Compilation Strategy

To ensure Step 2 compiles at each stage, follow this order:

### Stage 1: Target Setup (Must compile)

1. Update `Package.swift`
2. Create directory structure
3. Build to verify targets exist:
   ```bash
   swift build  # Should succeed, no moved files yet
   ```

### Stage 2: File Relocation (Expect temporary failures)

1. Move files from Core to LocalBackend
2. **Expected**: Build will fail due to missing imports
3. **Do not panic** - this is temporary

### Stage 3: Import Updates (Must compile)

1. Update import statements in moved files
2. Add LocalBackend namespace
3. Build should succeed:
   ```bash
   swift build --target Core      # Should succeed (no SharingGRDB)
   swift build --target LocalBackend  # Should succeed (with moved files)
   ```

### Stage 4: Conversion Extensions (Must compile)

1. Create Core protocol conversion extensions
2. Create LocalBackend-specific conversions
3. Build should succeed:
   ```bash
   swift build  # Full project should compile
   ```

## Verification Steps

### 2.6 Build Verification

After completing the target setup and file moves, verify everything builds correctly:

```bash
# Build all targets to ensure no missing imports or dependencies
cd Packages/Lib
swift build

# Specifically test each target
swift build --target Core
swift build --target LocalBackend
```

### 2.5 Import Verification

Verify the import structure is correct:

**Core Target** should be able to import:

- `Foundation`
- `Sharing` (from swift-sharing)
- **Should NOT import**: `SharingGRDB`, `GRDB`

**LocalBackend Target** should be able to import:

- `Foundation`
- `Core` (the core target)
- `SharingGRDB`
- `GRDB`

**XcodeBuilder2 App** should import:

- `Core` for protocols and value types
- `LocalBackend` for the concrete backend service
- Both targets should be available

### 2.6 File Structure Verification

Verify the final file structure matches the expected layout:

```bash
# Check Core contains only backend-agnostic files
ls -la Packages/Lib/Sources/Core/Models/
# Should show: Database.swift, Destination.swift, ExportOption.swift

# Check LocalBackend contains moved SharingGRDB files
ls -la Packages/Lib/Sources/LocalBackend/Models/
# Should show: Project.swift, Scheme.swift, Build.swift, BuildLog.swift, CrashLog.swift

# Check LocalBackend requests
ls -la Packages/Lib/Sources/LocalBackend/Requests/
# Should show: AllProjectRequest.swift, ProjectDetailRequest.swift

# Verify Core/Requests is empty or removed
ls -la Packages/Lib/Sources/Core/Requests/ 2>/dev/null || echo "Core/Requests directory removed (expected)"
```

### 2.7 Troubleshooting Common Compilation Issues

**Issue 1: "Cannot find type 'ProjectProtocol' in scope"**

```
Solution: Ensure Step 1 is complete. Check that BackendModels.swift exists in Core target.
Verification: swift build --target Core should succeed.
```

**Issue 2: "No such module 'Core'" in LocalBackend files**

```
Solution: Ensure Package.swift includes Core as dependency for LocalBackend target.
Verification: Check dependencies array in Package.swift.
```

**Issue 3: "Cannot find 'LocalBackend' in scope" in conversion files**

```
Solution: Ensure LocalBackend namespace is declared:
public enum LocalBackend {}
extension LocalBackend { /* models here */ }
```

**Issue 4: Build fails after moving files**

```
Expected during Stage 2. Follow Stage 3 to fix imports:
1. Add import Core to moved files
2. Add LocalBackend namespace
3. Make types and initializers public
4. Update type references (Project -> LocalBackend.Project)
```

**Issue 5: "Cannot find type 'Platform'" or other supporting types**

```
Solution: Ensure all supporting types are defined in Core/BackendModels.swift:
- Platform, ExportOption, BuildStatus, BuildLogLevel, CrashLogRole, CrashLogPriority
```

**Issue 6: Protocol conformance errors**

```
Solution: Ensure moved GRDB structs still conform to protocols:
extension LocalBackend.Project: ProjectProtocol {
    public var id: String { bundleIdentifier }
}
```

### 2.8 Compilation Success Checklist

- [ ] **Stage 1**: `swift build` succeeds after Package.swift update
- [ ] **Stage 2**: Expected failures after file moves (temporary)
- [ ] **Stage 3**: `swift build --target Core` succeeds (no SharingGRDB dependency)
- [ ] **Stage 3**: `swift build --target LocalBackend` succeeds (with moved files)
- [ ] **Stage 4**: `swift build` succeeds (full project with conversions)
- [ ] **Integration**: XcodeBuilder2 app builds with both targets imported

## Architecture Benefits

### ✅ **Clean Separation**

- **Core**: Protocol extensions work with any conforming type
- **LocalBackend**: Specific conversions for SharingGRDB types
- **Future Backends**: Can add their own conversion extensions

### ✅ **Type Safety**

- Protocol extensions ensure any conforming type can convert
- Backend-specific extensions handle implementation details
- Clear naming prevents confusion (`toProjectValue()` vs `toGRDBProject()`)

### ✅ **Extensibility**

- New backends add their own conversion files
- Core protocol extensions remain unchanged
- No shared code between backend implementations

### ✅ **Maintainability**

- Conversions live close to the types they convert
- Backend implementations are isolated
- Easy to add new backends without touching existing code

## Next Step

After completing this step, proceed to [Step 3: SharingKey System](./STEP_3_SHARING_KEY_SYSTEM.md) to implement the universal BackendQuery system.
