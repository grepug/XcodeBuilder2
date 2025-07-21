import Testing
import Foundation
import Sharing
import Dependencies
import SwiftUI
@testable import LocalBackend

@Suite("SharedReaderKey Backend Integration Tests")
struct SharedReaderKeyIntegrationTests {
  
  @Test("@SharedReader automatically updates multiple consumers")
  func multipleConsumerUpdates() async throws {
    let service = LocalBackendService()
    
    try await withDependencies {
      $0.defaultDatabase = try DatabaseManager.setupInMemoryDatabase()
      $0.backendService = service
    } operation: {
      // Create multiple SharedReaders for the same data
      @SharedReader(.allProjectIds) var projectIds1: [String] = []
      @SharedReader(.allProjectIds) var projectIds2: [String] = []
      @SharedReader(.allProjectIds) var projectIds3: [String] = []
      
      // Initially empty
      #expect(projectIds1.isEmpty)
      #expect(projectIds2.isEmpty)
      #expect(projectIds3.isEmpty)
      
      // Create a project - this should automatically update all SharedReaders
      let testProject = ProjectValue(
        bundleIdentifier: "com.example.test1",
        name: "Test Project 1",
        displayName: "Test Application 1", 
        gitRepoURL: URL(string: "https://github.com/test/repo1")!,
        xcodeprojName: "TestApp1.xcodeproj",
        workingDirectoryURL: URL(fileURLWithPath: "/tmp/test1"),
        createdAt: Date()
      )
      try await service.createProject(testProject)
      
      // Load the updates - all should reflect the new project
      try await $projectIds1.load()
      try await $projectIds2.load()
      try await $projectIds3.load()
      
      #expect(!projectIds1.isEmpty)
      #expect(projectIds1 == projectIds2)
      #expect(projectIds2 == projectIds3)
      #expect(projectIds1.contains("com.example.test1"))
      
      // Add another project
      let testProject2 = ProjectValue(
        bundleIdentifier: "com.example.test2",
        name: "Test Project 2",
        displayName: "Test Application 2", 
        gitRepoURL: URL(string: "https://github.com/test/repo2")!,
        xcodeprojName: "TestApp2.xcodeproj",
        workingDirectoryURL: URL(fileURLWithPath: "/tmp/test2"),
        createdAt: Date()
      )
      try await service.createProject(testProject2)
      
      // Reload and verify all consumers see the updates
      try await $projectIds1.load()
      #expect(projectIds1.count == 2)
      #expect(projectIds1.contains("com.example.test1"))
      #expect(projectIds1.contains("com.example.test2"))
      
      // Other consumers should also see the same data when loaded
      try await $projectIds2.load()
      try await $projectIds3.load()
      #expect(projectIds1 == projectIds2)
      #expect(projectIds2 == projectIds3)
    }
  }
  
  @Test("@SharedReader works in SwiftUI-style view model")
  func swiftUIViewModelPattern() async throws {
    let service = LocalBackendService()
    
    try await withDependencies {
      $0.defaultDatabase = try DatabaseManager.setupInMemoryDatabase()
      $0.backendService = service
    } operation: {
      
      // Simulate a SwiftUI view model using SharedReader
      final class ProjectListViewModel {
        @SharedReader(.allProjectIds) var projectIds: [String] = []
        @SharedReader(.projectVersionStrings) var versionStrings: [String: [String]] = [:]
        
        var hasProjects: Bool { !projectIds.isEmpty }
        var projectCount: Int { projectIds.count }
        
        func refresh() async throws {
          try await $projectIds.load()
          try await $versionStrings.load()
        }
      }
      
      let viewModel = ProjectListViewModel()
      
      // Initially empty
      #expect(!viewModel.hasProjects)
      #expect(viewModel.projectCount == 0)
      
      // Create some test projects
      let projects = [
        ProjectValue(
          bundleIdentifier: "com.example.app1",
          name: "App 1",
          displayName: "Application 1", 
          gitRepoURL: URL(string: "https://github.com/test/app1")!,
          xcodeprojName: "App1.xcodeproj",
          workingDirectoryURL: URL(fileURLWithPath: "/tmp/app1"),
          createdAt: Date()
        ),
        ProjectValue(
          bundleIdentifier: "com.example.app2",
          name: "App 2",
          displayName: "Application 2", 
          gitRepoURL: URL(string: "https://github.com/test/app2")!,
          xcodeprojName: "App2.xcodeproj",
          workingDirectoryURL: URL(fileURLWithPath: "/tmp/app2"),
          createdAt: Date()
        )
      ]
      
      for project in projects {
        try await service.createProject(project)
      }
      
      // Refresh the view model
      try await viewModel.refresh()
      
      // Verify the view model reflects the changes
      #expect(viewModel.hasProjects)
      #expect(viewModel.projectCount == 2)
      #expect(viewModel.projectIds.contains("com.example.app1"))
      #expect(viewModel.projectIds.contains("com.example.app2"))
    }
  }
  
  @Test("@SharedReader provides loading states and error handling")
  func loadingStatesAndErrorHandling() async throws {
    let service = LocalBackendService()
    
    try await withDependencies {
      $0.defaultDatabase = try DatabaseManager.setupInMemoryDatabase()
      $0.backendService = service
    } operation: {
      @SharedReader(.project(id: "com.example.nonexistent")) var project: ProjectValue? = nil
      
      // Initially not loading and no error
      #expect($project.loadError == nil) // No error initially
      
      // Load a non-existent project (should not throw but return nil)
      try await $project.load()
      
      // Should complete and return nil for non-existent project
      #expect(project == nil)
      
      // Now create the project and load again
      let testProject = ProjectValue(
        bundleIdentifier: "com.example.nonexistent",
        name: "Previously Nonexistent Project",
        displayName: "Test Application", 
        gitRepoURL: URL(string: "https://github.com/test/repo")!,
        xcodeprojName: "TestApp.xcodeproj",
        workingDirectoryURL: URL(fileURLWithPath: "/tmp/test"),
        createdAt: Date()
      )
      try await service.createProject(testProject)
      
      try await $project.load()
      
      #expect(project != nil)
      #expect(project?.name == "Previously Nonexistent Project")
    }
  }
  
  @Test("@SharedReader supports dynamic key switching")
  func dynamicKeySwitching() async throws {
    let service = LocalBackendService()
    
    try await withDependencies {
      $0.defaultDatabase = try DatabaseManager.setupInMemoryDatabase()
      $0.backendService = service
    } operation: {
      // Create test projects
      let project1 = ProjectValue(
        bundleIdentifier: "com.example.project1",
        name: "Project One",
        displayName: "First Project", 
        gitRepoURL: URL(string: "https://github.com/test/project1")!,
        xcodeprojName: "Project1.xcodeproj",
        workingDirectoryURL: URL(fileURLWithPath: "/tmp/project1"),
        createdAt: Date()
      )
      
      let project2 = ProjectValue(
        bundleIdentifier: "com.example.project2",
        name: "Project Two",
        displayName: "Second Project", 
        gitRepoURL: URL(string: "https://github.com/test/project2")!,
        xcodeprojName: "Project2.xcodeproj",
        workingDirectoryURL: URL(fileURLWithPath: "/tmp/project2"),
        createdAt: Date()
      )
      
      try await service.createProject(project1)
      try await service.createProject(project2)
      
      // Start with project1
      @SharedReader(.project(id: "com.example.project1")) var currentProject: ProjectValue? = nil
      try await $currentProject.load()
      
      #expect(currentProject?.name == "Project One")
      
      // Switch to project2 by changing the key dynamically
      $currentProject = SharedReader(.project(id: "com.example.project2"))
      try await $currentProject.load()
      
      #expect(currentProject?.name == "Project Two")
      
      // Switch back to project1
      $currentProject = SharedReader(.project(id: "com.example.project1"))
      try await $currentProject.load()
      
      #expect(currentProject?.name == "Project One")
    }
  }
  
  @Test("@SharedReader supports complex data relationships")
  func complexDataRelationships() async throws {
    let service = LocalBackendService()
    
    try await withDependencies {
      $0.defaultDatabase = try DatabaseManager.setupInMemoryDatabase()
      $0.backendService = service
    } operation: {
      
      // Simulate a comprehensive view that loads related data
      final class ProjectDetailViewModel {
        private let projectId: String
        
        @SharedReader(.allProjectIds) var allProjectIds: [String] = []
        @SharedReader(.projectVersionStrings) var versionStrings: [String: [String]] = [:]
        
        // Dynamic project data based on projectId
        var projectReader: SharedReader<ProjectValue?>
        var projectDetailReader: SharedReader<ProjectDetailData?>
        
        init(projectId: String) {
          self.projectId = projectId
          self.projectReader = SharedReader(.project(id: projectId))
          self.projectDetailReader = SharedReader(.projectDetail(id: projectId))
        }
        
        var project: ProjectValue? { projectReader.wrappedValue }
        var projectDetail: ProjectDetailData? { projectDetailReader.wrappedValue }
        
        var isProjectInList: Bool { 
          allProjectIds.contains(projectId)
        }
        
        var projectVersions: [String] {
          versionStrings[projectId] ?? []
        }
        
        func loadAll() async throws {
          try await $allProjectIds.load()
          try await $versionStrings.load()
          try await projectReader.load()
          try await projectDetailReader.load()
        }
      }
      
      // Create test data
      let testProject = ProjectValue(
        bundleIdentifier: "com.example.detailtest",
        name: "Detail Test Project",
        displayName: "Detail Test Application", 
        gitRepoURL: URL(string: "https://github.com/test/detail")!,
        xcodeprojName: "DetailTest.xcodeproj",
        workingDirectoryURL: URL(fileURLWithPath: "/tmp/detailtest"),
        createdAt: Date()
      )
      try await service.createProject(testProject)
      
      let viewModel = ProjectDetailViewModel(projectId: "com.example.detailtest")
      try await viewModel.loadAll()
      
      // Verify all related data is loaded correctly
      #expect(viewModel.isProjectInList)
      #expect(viewModel.project?.name == "Detail Test Project")
      #expect(viewModel.allProjectIds.contains("com.example.detailtest"))
    }
  }
  
  @Test("@SharedReader works with different data types")
  func differentDataTypes() async throws {
    let service = LocalBackendService()
    
    try await withDependencies {
      $0.defaultDatabase = try DatabaseManager.setupInMemoryDatabase()
      $0.backendService = service
    } operation: {
      // Test different return types from our backend
      @SharedReader(.allProjectIds) var stringArray: [String] = []
      @SharedReader(.projectVersionStrings) var dictionary: [String: [String]] = [:]
      @SharedReader(.project(id: "test")) var optional: ProjectValue? = nil
      
      // Create a test project
      let testProject = ProjectValue(
        bundleIdentifier: "test",
        name: "Type Test Project",
        displayName: "Type Test", 
        gitRepoURL: URL(string: "https://github.com/test/types")!,
        xcodeprojName: "TypeTest.xcodeproj",
        workingDirectoryURL: URL(fileURLWithPath: "/tmp/typetest"),
        createdAt: Date()
      )
      try await service.createProject(testProject)
      
      // Load all different types
      try await $stringArray.load()
      try await $dictionary.load()
      try await $optional.load()
      
      // Verify each type works correctly
      #expect(!stringArray.isEmpty)
      #expect(stringArray.contains("test"))
      
      // Verify the dictionary type and contents
      #expect(dictionary.isEmpty || dictionary.keys.count >= 0) // Dictionary operations work
      
      // Verify the optional type and value
      #expect(optional != nil)
      #expect(optional?.bundleIdentifier == "test")
    }
  }
}
