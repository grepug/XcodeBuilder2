import Testing
import Sharing
import Dependencies
@testable import LocalBackend

@Suite("SharedReaderKey Backend Integration Tests")
struct SharedReaderKeyIntegrationTests {
  
  @Test("All project IDs can be loaded via SharedReader")
  func allProjectIdsSharedReader() async throws {
    // Setup test database
    let service = LocalBackendService()
    
    await withDependencies {
      $0.defaultDatabase = try DatabaseManager.setupInMemoryDatabase()
      $0.backendService = service
    } operation: {
      // Create a SharedReader for all project IDs
      let projectIdsReader = SharedReader(.allProjectIds)
      
      // Load the project IDs
      try await projectIdsReader.load()
      
      // Verify the result (should be empty initially)
      #expect(projectIdsReader.wrappedValue.isEmpty)
    }
  }
  
  @Test("Project can be loaded via SharedReader")
  func projectSharedReader() async throws {
    let service = LocalBackendService()
    
    await withDependencies {
      $0.defaultDatabase = try DatabaseManager.setupInMemoryDatabase()
      $0.backendService = service
    } operation: {
      // First create a test project
      let testProject = ProjectValue(
        bundleIdentifier: "com.example.test",
        name: "Test Project",
        displayName: "Test Application", 
        gitRepoURL: URL(string: "https://github.com/test/repo")!,
        xcodeprojName: "TestApp.xcodeproj",
        workingDirectoryURL: URL(fileURLWithPath: "/tmp/test"),
        createdAt: Date()
      )
      try await service.createProject(testProject)
      
      // Create a SharedReader for the project
      let projectReader = SharedReader(.project(id: "com.example.test"))
      
      // Load the project
      try await projectReader.load()
      
      // Verify the result
      #expect(projectReader.wrappedValue != nil)
      #expect(projectReader.wrappedValue?.name == "Test Project")
    }
  }
  
  @Test("Project version strings can be loaded via SharedReader")
  func projectVersionStringsSharedReader() async throws {
    let service = LocalBackendService()
    
    await withDependencies {
      $0.defaultDatabase = try DatabaseManager.setupInMemoryDatabase()
      $0.backendService = service
    } operation: {
      // Create a SharedReader for project version strings
      let versionStringsReader = SharedReader(.projectVersionStrings)
      
      // Load the version strings
      try await versionStringsReader.load()
      
      // Verify the result (should be empty initially)
      #expect(versionStringsReader.wrappedValue.isEmpty)
    }
  }
}
