//
//  BuildDetailViewContainer.swift
//  XcodeBuilder2
//
//  Created by Kai Shao on 2025/7/15.
//

import SwiftUI
import Core
import SharingGRDB

struct BuildDetailViewContainer: View {
    var buildId: UUID
    
    @FetchOne var fetchedBuild: BuildModel?
    @FetchAll var logIds: [UUID]
    @FetchOne var scheme: Scheme?
    
    @State private var showDebugLogs: Bool = false
    @State private var selectedTab: BuildDetailView.DetailTab = .info
    @State private var selectedCategory: XcodeBuildJobLogCategory?
    
    var build: BuildModel {
        fetchedBuild ?? .init(id: buildId)
    }
    
    var body: some View {
        BuildDetailView(
            build: build,
            logIds: logIds,
            scheme: scheme,
            showDebugLogs: $showDebugLogs,
            selectedTab: $selectedTab,
            selectedCategory: $selectedCategory
        )
        .task(id: buildId) {
            showDebugLogs = false
            selectedTab = .info
            selectedCategory = nil
            
            try! await $fetchedBuild.load(BuildModel.where { $0.id == buildId })
            try! await $scheme.load(Scheme.where { $0.id == build.schemeId })
        }
        .task(id: [buildId, showDebugLogs, selectedCategory] as [AnyHashable]) {
            try! await $logIds.load(
                BuildLog
                    .where { $0.buildId == buildId }
                    .where { showDebugLogs || $0.level != BuildLog.Level.debug }
                    .where { selectedCategory == nil || $0.category == selectedCategory?.rawValue }
                    .order(by: \.createdAt)
                    .select(\.id)
            )
        }
    }
}
