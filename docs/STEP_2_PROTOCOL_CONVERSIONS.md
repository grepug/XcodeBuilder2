# Step 2: Protocol Conversions

**Goal**: Implement the generic conversion system that enables seamless translation between domain models and backend value types.

## Files to Create

### 2.1 Conversion Protocols

**File**: `Packages/Lib/Sources/Core/Services/BackendConversions.swift`

```swift
import Foundation

// MARK: - Core Conversion Protocols

/// Protocol for types that can be converted from backend value types
public protocol ConvertibleFromBackend {
    associatedtype BackendType
    init(from backendValue: BackendType)
}

/// Protocol for types that can be converted to backend value types
public protocol ConvertibleToBackend {
    associatedtype BackendType
    func toBackendValue() -> BackendType
}

/// Protocol for bidirectional conversion
public typealias BackendConvertible = ConvertibleFromBackend & ConvertibleToBackend

// MARK: - Specialized Conversion Protocols

public protocol ProjectConvertible: BackendConvertible where BackendType == ProjectValue {}
public protocol SchemeConvertible: BackendConvertible where BackendType == SchemeValue {}
public protocol BuildModelConvertible: BackendConvertible where BackendType == BuildModelValue {}
public protocol BuildLogConvertible: BackendConvertible where BackendType == BuildLogValue {}
public protocol CrashLogConvertible: BackendConvertible where BackendType == CrashLogValue {}

// MARK: - Generic Conversion Functions

/// Convert any backend value to domain model
public func fromBackend<T: ConvertibleFromBackend>(_ backendValue: T.BackendType, to type: T.Type = T.self) -> T {
    return T(from: backendValue)
}

/// Convert domain model to backend value
public func toBackend<T: ConvertibleToBackend>(_ domainModel: T) -> T.BackendType {
    return domainModel.toBackendValue()
}

/// Convert array of backend values to domain models
public func fromBackendArray<T: ConvertibleFromBackend>(_ backendValues: [T.BackendType], to type: T.Type = T.self) -> [T] {
    return backendValues.map(T.init(from:))
}

/// Convert array of domain models to backend values
public func toBackendArray<T: ConvertibleToBackend>(_ domainModels: [T]) -> [T.BackendType] {
    return domainModels.map(\.toBackendValue())
}

// MARK: - Optional Conversions

public extension ConvertibleFromBackend {
    static func fromOptionalBackend(_ backendValue: BackendType?) -> Self? {
        guard let backendValue = backendValue else { return nil }
        return Self(from: backendValue)
    }
}

public extension ConvertibleToBackend {
    func toOptionalBackend() -> BackendType? {
        return toBackendValue()
    }
}

// MARK: - Array Extensions for easier conversion

public extension Array where Element: ConvertibleFromBackend {
    init(fromBackend backendValues: [Element.BackendType]) {
        self = backendValues.map(Element.init(from:))
    }
}

public extension Array where Element: ConvertibleToBackend {
    func toBackendValues() -> [Element.BackendType] {
        return map(\.toBackendValue())
    }
}
```

### 2.2 Domain Model Extensions

Add these extensions to your existing domain models:

**File**: `Packages/Lib/Sources/Core/Models/Project+BackendConversion.swift`

```swift
import Foundation

extension Project: ProjectConvertible {
    public init(from backendValue: ProjectValue) {
        self.init(
            bundleIdentifier: backendValue.bundleIdentifier,
            name: backendValue.name,
            displayName: backendValue.displayName,
            gitRepoURL: backendValue.gitRepoURL,
            xcodeprojName: backendValue.xcodeprojName,
            workingDirectoryURL: backendValue.workingDirectoryURL,
            createdAt: backendValue.createdAt
        )
    }

    public func toBackendValue() -> ProjectValue {
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
```

**File**: `Packages/Lib/Sources/Core/Models/Scheme+BackendConversion.swift`

```swift
import Foundation

extension Scheme: SchemeConvertible {
    public init(from backendValue: SchemeValue) {
        self.init(
            id: backendValue.id,
            projectBundleIdentifier: backendValue.projectBundleIdentifier,
            name: backendValue.name,
            platforms: backendValue.platforms,
            order: backendValue.order
        )
    }

    public func toBackendValue() -> SchemeValue {
        return SchemeValue(
            id: id,
            projectBundleIdentifier: projectBundleIdentifier,
            name: name,
            platforms: platforms,
            order: order
        )
    }
}
```

**File**: `Packages/Lib/Sources/Core/Models/Build+BackendConversion.swift`

```swift
import Foundation

extension Build: BuildModelConvertible {
    public init(from backendValue: BuildModelValue) {
        self.init(
            id: backendValue.id,
            schemeId: backendValue.schemeId,
            versionString: backendValue.versionString,
            buildNumber: backendValue.buildNumber,
            createdAt: backendValue.createdAt,
            startDate: backendValue.startDate,
            endDate: backendValue.endDate,
            exportOptions: backendValue.exportOptions,
            status: backendValue.status,
            progress: backendValue.progress,
            commitHash: backendValue.commitHash,
            deviceMetadata: backendValue.deviceMetadata,
            osVersion: backendValue.osVersion,
            memory: backendValue.memory,
            processor: backendValue.processor
        )
    }

    public func toBackendValue() -> BuildModelValue {
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
```

**File**: `Packages/Lib/Sources/Core/Models/BuildLog+BackendConversion.swift`

```swift
import Foundation

extension BuildLog: BuildLogConvertible {
    public init(from backendValue: BuildLogValue) {
        self.init(
            id: backendValue.id,
            buildId: backendValue.buildId,
            category: backendValue.category,
            level: backendValue.level,
            content: backendValue.content,
            createdAt: backendValue.createdAt
        )
    }

    public func toBackendValue() -> BuildLogValue {
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
```

**File**: `Packages/Lib/Sources/Core/Models/CrashLog+BackendConversion.swift`

```swift
import Foundation

extension CrashLog: CrashLogConvertible {
    public init(from backendValue: CrashLogValue) {
        self.init(
            incidentIdentifier: backendValue.incidentIdentifier,
            isMainThread: backendValue.isMainThread,
            createdAt: backendValue.createdAt,
            buildId: backendValue.buildId,
            content: backendValue.content,
            hardwareModel: backendValue.hardwareModel,
            process: backendValue.process,
            role: backendValue.role,
            dateTime: backendValue.dateTime,
            launchTime: backendValue.launchTime,
            osVersion: backendValue.osVersion,
            note: backendValue.note,
            fixed: backendValue.fixed,
            priority: backendValue.priority
        )
    }

    public func toBackendValue() -> CrashLogValue {
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
```

### 2.3 Conversion Utilities

**File**: `Packages/Lib/Sources/Core/Services/BackendConversionUtilities.swift`

```swift
import Foundation

// MARK: - Batch Conversion Utilities

public struct BackendConversionUtils {

    /// Convert optional backend values with error handling
    public static func safeConvert<T: ConvertibleFromBackend>(
        _ backendValue: T.BackendType?,
        to type: T.Type = T.self
    ) -> T? {
        guard let backendValue = backendValue else { return nil }
        return T(from: backendValue)
    }

    /// Convert array with individual error handling
    public static func safeConvertArray<T: ConvertibleFromBackend>(
        _ backendValues: [T.BackendType],
        to type: T.Type = T.self
    ) -> [T] {
        return backendValues.compactMap { backendValue in
            return T(from: backendValue)
        }
    }

    /// Convert dictionary values
    public static func convertDictionary<Key: Hashable, T: ConvertibleFromBackend>(
        _ backendDict: [Key: T.BackendType],
        to type: T.Type = T.self
    ) -> [Key: T] {
        return backendDict.compactMapValues { backendValue in
            return T(from: backendValue)
        }
    }

    /// Convert async sequence elements
    public static func convertAsyncSequence<S: AsyncSequence, T: ConvertibleFromBackend>(
        _ sequence: S,
        to type: T.Type = T.self
    ) -> AsyncMapSequence<S, T?> where S.Element == T.BackendType {
        return sequence.map { backendValue in
            return T(from: backendValue)
        }
    }
}

// MARK: - ProjectDetailData Conversion

public extension ProjectDetailData {
    /// Convert to domain models
    func toDomainModels() -> (project: Project, schemeIds: [UUID], recentBuildIds: [UUID]) {
        return (
            project: fromBackend(project),
            schemeIds: schemeIds,
            recentBuildIds: recentBuildIds
        )
    }
}

// MARK: - AsyncSequence Extensions

public extension AsyncSequence where Element: ConvertibleFromBackend {
    /// Convert async sequence of backend values to domain models
    func convertToDomainModels<T: ConvertibleFromBackend>(
        _ type: T.Type = T.self
    ) -> AsyncMapSequence<Self, T> where Element == T.BackendType {
        return self.map(T.init(from:))
    }
}
```

## Implementation Checklist

- [ ] Create `BackendConversions.swift` with core conversion protocols
- [ ] Create domain model conversion extensions for each model type:
  - [ ] `Project+BackendConversion.swift`
  - [ ] `Scheme+BackendConversion.swift`
  - [ ] `Build+BackendConversion.swift`
  - [ ] `BuildLog+BackendConversion.swift`
  - [ ] `CrashLog+BackendConversion.swift`
- [ ] Create `BackendConversionUtilities.swift` with helper functions
- [ ] Test conversions work correctly:
  - [ ] Domain model → Backend value → Domain model (round trip)
  - [ ] Array conversions
  - [ ] Optional conversions
  - [ ] Dictionary conversions
- [ ] Verify all conversion extensions compile

## Usage Examples

```swift
// Convert single values
let project: Project = // ... existing project
let backendValue: ProjectValue = project.toBackendValue()
let convertedBack: Project = fromBackend(backendValue)

// Convert arrays
let projects: [Project] = // ... existing projects
let backendValues: [ProjectValue] = toBackendArray(projects)
let convertedProjects: [Project] = fromBackendArray(backendValues)

// Using specialized protocols
let projectConvertible: any ProjectConvertible = project
let backendProject = projectConvertible.toBackendValue()
```

## Next Step

After completing this step, proceed to [Step 3: SharingKey System](./STEP_3_SHARING_KEY_SYSTEM.md) to implement the universal BackendQuery system.
