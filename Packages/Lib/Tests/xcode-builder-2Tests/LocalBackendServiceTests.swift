import XCTest
import GRDB
import SharingGRDB
import Dependencies
@testable import LocalBackend
@testable import Core

final class LocalBackendServiceTests: XCTestCase {
    private var testDatabase: DatabaseQueue!
    private var service: LocalBackendService!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Create in-memory database for testing
        testDatabase = DatabaseQueue()
        
        // Setup test dependencies
        withDependencies {
            $0.defaultDatabase = .testValue(testDatabase)
        } operation: {
            service = LocalBackendService()
        }
        
        // Run migrations
        let databaseManager = DatabaseManager()
        try await databaseManager.runMigrations(using: testDatabase)
    }
    
    override func tearDown() async throws {
        testDatabase = nil
        service = nil
        try await super.tearDown()
    }
    
    // MARK: - Project Tests
    
    func testCreateAndReadProject() async throws {
        // Given
        let project = ProjectValue(
            bundleIdentifier: "com.test.app",
            name: "TestApp",
            displayName: "Test Application",
            gitRepoURL: "https://github.com/test/app.git",
            xcodeprojName: "TestApp.xcodeproj",
            workingDirectoryURL: "/path/to/project",
            createdAt: Date()
        )
        
        // When
        try await service.createProject(project)
        
        // Then
        let projectStream = service.streamProject(id: project.bundleIdentifier)
        for await retrievedProject in projectStream {
            XCTAssertNotNil(retrievedProject)
            XCTAssertEqual(retrievedProject?.bundleIdentifier, project.bundleIdentifier)
            XCTAssertEqual(retrievedProject?.name, project.name)
            break
        }
    }
    
    func testUpdateProject() async throws {
        // Given
        let originalProject = ProjectValue(
            bundleIdentifier: "com.test.app",
            name: "TestApp",
            displayName: "Test Application",
            gitRepoURL: "https://github.com/test/app.git",
            xcodeprojName: "TestApp.xcodeproj",
            workingDirectoryURL: "/path/to/project",
            createdAt: Date()
        )
        
        let updatedProject = ProjectValue(
            bundleIdentifier: "com.test.app",
            name: "TestApp Updated",
            displayName: "Updated Test Application",
            gitRepoURL: "https://github.com/test/app.git",
            xcodeprojName: "TestApp.xcodeproj",
            workingDirectoryURL: "/path/to/project",
            createdAt: originalProject.createdAt
        )
        
        // When
        try await service.createProject(originalProject)
        try await service.updateProject(updatedProject)
        
        // Then
        let projectStream = service.streamProject(id: originalProject.bundleIdentifier)
        for await retrievedProject in projectStream {
            XCTAssertEqual(retrievedProject?.name, "TestApp Updated")
            XCTAssertEqual(retrievedProject?.displayName, "Updated Test Application")
            break
        }
    }
    
    func testDeleteProject() async throws {
        // Given
        let project = ProjectValue(
            bundleIdentifier: "com.test.app",
            name: "TestApp",
            displayName: "Test Application",
            gitRepoURL: "https://github.com/test/app.git",
            xcodeprojName: "TestApp.xcodeproj",
            workingDirectoryURL: "/path/to/project",
            createdAt: Date()
        )
        
        // When
        try await service.createProject(project)
        try await service.deleteProject(id: project.bundleIdentifier)
        
        // Then
        let projectStream = service.streamProject(id: project.bundleIdentifier)
        for await retrievedProject in projectStream {
            XCTAssertNil(retrievedProject)
            break
        }
    }
    
    // MARK: - Scheme Tests
    
    func testCreateAndReadScheme() async throws {
        // Given
        let project = ProjectValue(
            bundleIdentifier: "com.test.app",
            name: "TestApp",
            displayName: "Test Application",
            gitRepoURL: "https://github.com/test/app.git",
            xcodeprojName: "TestApp.xcodeproj",
            workingDirectoryURL: "/path/to/project",
            createdAt: Date()
        )
        
        let scheme = SchemeValue(
            id: UUID(),
            projectBundleIdentifier: project.bundleIdentifier,
            name: "TestScheme",
            platforms: "iOS",
            order: 1
        )
        
        // When
        try await service.createProject(project)
        try await service.createScheme(scheme)
        
        // Then
        let schemeStream = service.streamScheme(id: scheme.id)
        for await retrievedScheme in schemeStream {
            XCTAssertNotNil(retrievedScheme)
            XCTAssertEqual(retrievedScheme?.name, scheme.name)
            XCTAssertEqual(retrievedScheme?.projectBundleIdentifier, project.bundleIdentifier)
            break
        }
    }
    
    // MARK: - Build Tests
    
    func testCreateAndReadBuild() async throws {
        // Given
        let project = ProjectValue(
            bundleIdentifier: "com.test.app",
            name: "TestApp",
            displayName: "Test Application",
            gitRepoURL: "https://github.com/test/app.git",
            xcodeprojName: "TestApp.xcodeproj",
            workingDirectoryURL: "/path/to/project",
            createdAt: Date()
        )
        
        let scheme = SchemeValue(
            id: UUID(),
            projectBundleIdentifier: project.bundleIdentifier,
            name: "TestScheme",
            platforms: "iOS",
            order: 1
        )
        
        let build = BuildModelValue(
            id: UUID(),
            schemeId: scheme.id,
            versionString: "1.0.0",
            buildNumber: "1",
            createdAt: Date(),
            startDate: Date(),
            endDate: Date().addingTimeInterval(60),
            exportOptions: ExportOption.appStore,
            status: .completed,
            progress: 100,
            commitHash: "abc123",
            deviceMetadata: "MacBook Pro",
            osVersion: "macOS 15.0",
            memory: "16 GB",
            processor: "Apple M1"
        )
        
        // When
        try await service.createProject(project)
        try await service.createScheme(scheme)
        try await service.createBuild(build)
        
        // Then
        let buildStream = service.streamBuild(id: build.id)
        for await retrievedBuild in buildStream {
            XCTAssertNotNil(retrievedBuild)
            XCTAssertEqual(retrievedBuild?.versionString, build.versionString)
            XCTAssertEqual(retrievedBuild?.status, build.status)
            break
        }
    }
    
    // MARK: - Build Log Tests
    
    func testCreateAndReadBuildLog() async throws {
        // Given
        let buildId = UUID()
        let buildLog = BuildLogValue(
            id: UUID(),
            buildId: buildId,
            category: "Build",
            level: "info",
            content: "Build started",
            createdAt: Date()
        )
        
        // When
        try await service.createBuildLog(buildLog)
        
        // Then
        let logStream = service.streamBuildLog(id: buildLog.id)
        for await retrievedLog in logStream {
            XCTAssertNotNil(retrievedLog)
            XCTAssertEqual(retrievedLog?.content, buildLog.content)
            XCTAssertEqual(retrievedLog?.level, buildLog.level)
            break
        }
    }
    
    // MARK: - Crash Log Tests
    
    func testCreateAndReadCrashLog() async throws {
        // Given
        let buildId = UUID()
        let crashLog = CrashLogValue(
            incidentIdentifier: "test-crash-001",
            isMainThread: true,
            createdAt: Date(),
            buildId: buildId,
            content: "Test crash log content",
            hardwareModel: "MacBook Pro",
            process: "TestApp",
            role: "Foreground",
            dateTime: Date(),
            launchTime: Date().addingTimeInterval(-10),
            osVersion: "macOS 15.0",
            note: "Test crash",
            fixed: false,
            priority: "high"
        )
        
        // When
        try await service.createCrashLog(crashLog)
        
        // Then
        let crashLogStream = service.streamCrashLog(id: crashLog.incidentIdentifier)
        for await retrievedCrashLog in crashLogStream {
            XCTAssertNotNil(retrievedCrashLog)
            XCTAssertEqual(retrievedCrashLog?.content, crashLog.content)
            XCTAssertEqual(retrievedCrashLog?.process, crashLog.process)
            break
        }
    }
    
    // MARK: - Complex Query Tests
    
    func testProjectDetailStream() async throws {
        // Given
        let project = ProjectValue(
            bundleIdentifier: "com.test.app",
            name: "TestApp",
            displayName: "Test Application",
            gitRepoURL: "https://github.com/test/app.git",
            xcodeprojName: "TestApp.xcodeproj",
            workingDirectoryURL: "/path/to/project",
            createdAt: Date()
        )
        
        let scheme = SchemeValue(
            id: UUID(),
            projectBundleIdentifier: project.bundleIdentifier,
            name: "TestScheme",
            platforms: "iOS",
            order: 1
        )
        
        // When
        try await service.createProject(project)
        try await service.createScheme(scheme)
        
        // Then
        let detailStream = service.streamProjectDetail(id: project.bundleIdentifier)
        for await projectDetail in detailStream {
            XCTAssertEqual(projectDetail.project.bundleIdentifier, project.bundleIdentifier)
            XCTAssertEqual(projectDetail.schemeIds.count, 1)
            XCTAssertEqual(projectDetail.schemeIds.first, scheme.id)
            break
        }
    }
    
    func testLatestBuildsStream() async throws {
        // Given
        let project = ProjectValue(
            bundleIdentifier: "com.test.app",
            name: "TestApp",
            displayName: "Test Application",
            gitRepoURL: "https://github.com/test/app.git",
            xcodeprojName: "TestApp.xcodeproj",
            workingDirectoryURL: "/path/to/project",
            createdAt: Date()
        )
        
        let scheme = SchemeValue(
            id: UUID(),
            projectBundleIdentifier: project.bundleIdentifier,
            name: "TestScheme",
            platforms: "iOS",
            order: 1
        )
        
        let build1 = BuildModelValue(
            id: UUID(),
            schemeId: scheme.id,
            versionString: "1.0.0",
            buildNumber: "1",
            createdAt: Date().addingTimeInterval(-60),
            startDate: Date().addingTimeInterval(-60),
            endDate: Date().addingTimeInterval(-30),
            exportOptions: ExportOption.appStore,
            status: .completed,
            progress: 100,
            commitHash: "abc123",
            deviceMetadata: "MacBook Pro",
            osVersion: "macOS 15.0",
            memory: "16 GB",
            processor: "Apple M1"
        )
        
        let build2 = BuildModelValue(
            id: UUID(),
            schemeId: scheme.id,
            versionString: "1.0.1",
            buildNumber: "2",
            createdAt: Date(),
            startDate: Date(),
            endDate: Date().addingTimeInterval(30),
            exportOptions: ExportOption.appStore,
            status: .completed,
            progress: 100,
            commitHash: "def456",
            deviceMetadata: "MacBook Pro",
            osVersion: "macOS 15.0",
            memory: "16 GB",
            processor: "Apple M1"
        )
        
        // When
        try await service.createProject(project)
        try await service.createScheme(scheme)
        try await service.createBuild(build1)
        try await service.createBuild(build2)
        
        // Then
        let buildsStream = service.streamLatestBuilds(projectId: project.bundleIdentifier, limit: 5)
        for await builds in buildsStream {
            XCTAssertEqual(builds.count, 2)
            // Should be sorted by createdAt desc, so build2 should be first
            XCTAssertEqual(builds.first?.versionString, "1.0.1")
            break
        }
    }
    
    // MARK: - Factory Tests
    
    func testLocalBackendFactoryConfiguration() async throws {
        // Given
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test.sqlite")
        
        // When & Then
        XCTAssertNoThrow(
            try await LocalBackendFactory.configureDependencies(databaseURL: tempURL)
        )
        
        // Cleanup
        try? FileManager.default.removeItem(at: tempURL)
    }
    
    func testCreateBackendService() {
        // When
        let service = LocalBackendFactory.createBackendService()
        
        // Then
        XCTAssertNotNil(service)
        XCTAssert(service is LocalBackendService)
    }
}
