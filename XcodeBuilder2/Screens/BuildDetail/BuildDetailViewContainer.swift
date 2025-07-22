//
//  BuildDetailViewContainer.swift
//  XcodeBuilder2
//
//  Created by Kai Shao on 2025/7/15.
//

import SwiftUI
import Core
import Sharing

/// Container View Pattern - Step 7 UI Integration for Build Detail
/// Backend-agnostic container using @SharedReader with query keys
struct BuildDetailViewContainer: View {
    var buildId: UUID
    
    // Step 7: Backend-agnostic data loading with SharedReader
    @SharedReader private var build: BuildModelValue?
    @SharedReader private var logIds: [UUID]
    @SharedReader private var crashLogIds: [String]
    
    @State private var showDebugLogs: Bool = false
    @State private var selectedTab: BuildDetailView.DetailTab = .info
    @State private var selectedCategory: XcodeBuildJobLogCategory?

    init(buildId: UUID) {
        self.buildId = buildId
        // Step 7: Initialize SharedReader with backend query keys
        _build = .init(wrappedValue: nil, .build(id: buildId))
        _logIds = .init(wrappedValue: [], .buildLogIds(buildId: buildId, includeDebug: false, category: nil))
        _crashLogIds = .init(wrappedValue: [], .crashLogIds(buildId: buildId))
    }
    
    var body: some View {
        Group {
            if let build = build {
                BuildDetailView(
                    build: build,
                    logIds: logIds,
                    crashLogIds: crashLogIds,
                    showDebugLogs: $showDebugLogs,
                    selectedTab: $selectedTab,
                    selectedCategory: $selectedCategory
                )
            } else {
                ProgressView("Loading build details...")
            }
        }
        .task(id: buildId) {
            try? await $build.load(.build(id: buildId))
            try? await $crashLogIds.load(.crashLogIds(buildId: buildId))
        }
        .task(id: [buildId, showDebugLogs, selectedCategory] as [AnyHashable]) {
            try? await $logIds.load(.buildLogIds(buildId: buildId, includeDebug: showDebugLogs, category: selectedCategory?.rawValue))
        }
    }
}
