//
//  ProjectListContainer.swift
//  XcodeBuilder2
//
//  Created by Kai Shao on 2025/7/22.
//

import SwiftUI
import Core
import Sharing

/// Container View Pattern - handles @SharedReader data loading for backend-agnostic UI
struct ProjectListContainer: View {
    @SharedReader private var projectIds: [String] = []

    init() {
        _projectIds = .init(wrappedValue: [], .allProjectIds)
    }
    // }

    var body: some View {
        NavigationView {
            VStack {
                Text("Project List Container (Step 7 Pattern)")
                    .font(.title)
                    .padding()
                
                ForEach(projectIds, id: \.self) { projectId in
                    ProjectListItemViewContainer(projectId: projectId)
                }
                
                Spacer()
            }
            .navigationTitle("Projects")
        }
        .task {
            try? await $projectIds.load(.allProjectIds)
        }
    }
}

/// Simple project item view to demonstrate the pattern
struct ProjectItemView: View {
    let projectId: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Project: \(projectId)")
                    .font(.headline)
                Text("Schemes: 2, Builds: 3")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

#Preview {
    ProjectListContainer()
}