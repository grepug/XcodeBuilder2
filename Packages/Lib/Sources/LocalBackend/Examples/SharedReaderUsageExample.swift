import SwiftUI
import Sharing
import Dependencies
import Core

// Example SwiftUI View using the new SharedReaderKey implementation
struct ProjectListView: View {
  // Use SharedReader to load all project IDs
  @SharedReader(.allProjectIds) var projectIds: [String] = []
  
  // Use SharedReader to load project version strings
  @SharedReader(.projectVersionStrings) var versionStrings: [String: [String]] = [:]
  
  var body: some View {
    NavigationView {
      List(projectIds, id: \.self) { projectId in
        ProjectRowView(projectId: projectId)
      }
      .navigationTitle("Projects")
      .task {
        do {
          // Load the data
          try await $projectIds.load()
          try await $versionStrings.load()
        } catch {
          print("Failed to load projects: \(error)")
        }
      }
    }
  }
}

struct ProjectRowView: View {
  let projectId: String
  
  // Use SharedReader to load specific project details
  @SharedReader(.project(id: "")) var project: ProjectValue?
  
  var body: some View {
    VStack(alignment: .leading) {
      Text(project?.name ?? "Unknown Project")
        .font(.headline)
      Text(project?.displayName ?? "")
        .font(.subheadline)
        .foregroundColor(.secondary)
    }
    .task {
      // Load project details when view appears
      $project = SharedReader(wrappedValue: nil, .project(id: projectId))
      try! await $project.load()
    }
  }
}

// Example of using SharedReaderKey in a view model
@MainActor
class ProjectDetailViewModel: ObservableObject {
  @Published var isLoading = false
  
  // Use SharedReader for latest builds
  @SharedReader(.latestBuilds(projectId: "", limit: 10)) 
  var latestBuilds: [BuildModelValue] = []
  
  func loadProjectDetail(projectId: String) async {
    isLoading = true
    defer { isLoading = false }
    
    do {
      // Update the SharedReader key dynamically
      $latestBuilds = SharedReader(
        wrappedValue: [],
        .latestBuilds(projectId: projectId, limit: 10)
      )
      
      // Load the latest builds
      try await $latestBuilds.load()
    } catch {
      print("Failed to load project details: \(error)")
    }
  }
}

#if DEBUG
// Preview with dependency injection
struct ProjectListView_Previews: PreviewProvider {
  static var previews: some View {
    withDependencies {
      $0.defaultDatabase = try! DatabaseManager.setupInMemoryDatabase()
      $0.backendService = LocalBackendService()
    } operation: {
      ProjectListView()
    }
  }
}
#endif
