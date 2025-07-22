//
//  ProjectListItemViewContainer.swift
//  XcodeBuilder2
//
//  Created by Kai Shao on 2025/7/22.
//

import SwiftUI
import Core
import Sharing

/// Container View Pattern - handles @SharedReader data loading for individual project items
struct ProjectListItemViewContainer: View {
    let projectId: String

    @SharedReader private var project: ProjectValue? = nil
    @SharedReader private var schemeIds: [UUID] = []
    @SharedReader private var recentBuilds: [BuildModelValue] = []

    init(projectId: String) {
        self.projectId = projectId
        _project = .init(wrappedValue: nil, .project(id: projectId))
        _schemeIds = .init(wrappedValue: [], .schemeIds(projectId: projectId))
        _recentBuilds = .init(wrappedValue: [], .latestBuilds(projectId: projectId, limit: 3))
    }

    var body: some View {
        ProjectListItemView(
            project: project,
            schemeIds: schemeIds,
            recentBuilds: recentBuilds
        )
        .task(id: projectId) {
            try? await $project.load(.project(id: projectId))
            try? await $schemeIds.load(.schemeIds(projectId: projectId))
            try? await $recentBuilds.load(.latestBuilds(projectId: projectId, limit: 3))
        }
    }
}

#Preview {
    ProjectListItemViewContainer(projectId: "com.example.app")
}
