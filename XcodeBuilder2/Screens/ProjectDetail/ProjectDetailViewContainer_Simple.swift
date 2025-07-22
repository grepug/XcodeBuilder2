//
//  ProjectDetailViewContainer.swift
//  XcodeBuilder2
//
//  Created by Kai Shao on 2025/7/22.
//

import SwiftUI
import Core
import Sharing

/// Container View Pattern for Project Detail - Step 7 UI Integration
/// Backend-agnostic container using @SharedReader with query keys
struct ProjectDetailViewContainer: View {
    let projectId: String
    
    // Step 7: Backend-agnostic data loading with SharedReader
    @SharedReader private var project: ProjectValue?
    @SharedReader private var schemeIds: [String] = []
    @SharedReader private var versionStrings: [String] = []
    
    init(projectId: String) {
        self.projectId = projectId
        // Step 7: Initialize SharedReader with backend query keys
        _project = .init(wrappedValue: nil, .project(id: projectId))
        _schemeIds = .init(wrappedValue: [], .schemeIds(projectId: projectId))
        _versionStrings = .init(wrappedValue: [], .buildVersionStrings(projectId: projectId))
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Project Header
                VStack(alignment: .leading) {
                    Text(project)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("ID: \(projectId)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Schemes Section
                VStack(alignment: .leading) {
                    Text("Schemes")
                        .font(.headline)
                    
                    ForEach(schemeIds, id: \.self) { scheme in
                        HStack {
                            Image(systemName: "gear")
                            Text(scheme)
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                }
                .padding()
                .background(.gray.opacity(0.1))
                .cornerRadius(8)
                
                // Version Strings Section
                VStack(alignment: .leading) {
                    Text("Version History")
                        .font(.headline)
                    
                    ForEach(versionStrings, id: \.self) { version in
                        HStack {
                            Image(systemName: "tag")
                            Text(version)
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                }
                .padding()
                .background(.gray.opacity(0.1))
                .cornerRadius(8)
                
                // TODO: Replace with actual ProjectDetailView when properly imported
                Text("TODO: Add ProjectDetailView presentation component")
                    .font(.caption)
                    .foregroundColor(.orange)
                    .padding()
            }
            .padding()
        }
        .navigationTitle("Project Details")
        // TODO: Add loading tasks when Core module is available
        // .task {
        //     try? await $project.load(.project(id: projectId))
        //     try? await $schemeIds.load(.schemeIds(projectId: projectId))
        //     try? await $versionStrings.load(.buildVersionStrings(projectId: projectId))
        // }
    }
}

#Preview {
    NavigationView {
        ProjectDetailViewContainer_Simple(projectId: "sample-project")
    }
}
