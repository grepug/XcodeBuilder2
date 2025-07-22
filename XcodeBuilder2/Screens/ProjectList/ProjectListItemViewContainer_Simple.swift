//
//  ProjectListItemViewContainer.swift
//  XcodeBuilder2
//
//  Created by Kai Shao on 2025/7/22.
//

import SwiftUI
import Core
import Sharing

/// Container View Pattern - Step 7 UI Integration with multiple data sources
/// Backend-agnostic container using @SharedReader with query keys
struct ProjectListItemViewContainer: View {
    let projectId: String

    // Step 7: Backend-agnostic data loading with SharedReader
    @SharedReader private var project: ProjectValue?
    @SharedReader private var schemeIds: [String] = []
    @SharedReader private var recentBuilds: [BuildModelValue] = []

    init(projectId: String) {
        self.projectId = projectId
        // Step 7: Initialize SharedReader with backend query keys
        _project = .init(wrappedValue: nil, .project(id: projectId))
        _schemeIds = .init(wrappedValue: [], .schemeIds(projectId: projectId))
        _recentBuilds = .init(wrappedValue: [], .latestBuilds(projectId: projectId, limit: 3))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Project: \(project?.name ?? "Loading...")")
                .font(.headline)
            
            HStack {
                Text("Schemes: \(schemeIds.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("Recent: \(recentBuilds.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text("ID: \(projectId)")
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .padding()
        .background(.gray.opacity(0.1))
        .cornerRadius(8)
        .task(id: projectId) {
            // Step 7: Load data using SharedReader with query keys
            try? await $project.load(.project(id: projectId))
            try? await $schemeIds.load(.schemeIds(projectId: projectId))
            try? await $recentBuilds.load(.latestBuilds(projectId: projectId, limit: 3))
        }
    }
}

#Preview {
    VStack {
        ProjectListItemViewContainer_Simple(projectId: "sample-project-1")
        ProjectListItemViewContainer_Simple(projectId: "sample-project-2")
        ProjectListItemViewContainer_Simple(projectId: "sample-project-3")
    }
    .padding()
}
