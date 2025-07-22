//
//  BuildDetailViewContainer.swift
//  XcodeBuilder2
//
//  Created by Kai Shao on 2025/7/22.
//

import SwiftUI
import Core
import Sharing
import Dependencies

/// Container View Pattern - handles @SharedReader data loading for build detail
struct BuildDetailViewContainer: View {
    let buildId: UUID

    @SharedReader private var build: BuildModelValue? = nil

    @State private var selectedTab: BuildDetailView.Tab = .logs
    @State private var includeDebugLogs: Bool = false

    init(buildId: UUID) {
        self.buildId = buildId
        _build = .init(wrappedValue: nil, .build(id: buildId))
    }

    var body: some View {
        BuildDetailView(
            build: build,
            buildId: buildId,
            selectedTab: $selectedTab,
            includeDebugLogs: $includeDebugLogs
        )
        .task(id: buildId) {
            try? await $build.load(.build(id: buildId))
        }
        .navigationTitle("Build #\(build?.buildNumber ?? 0)")
    }
}

/// Presentation View Pattern - accepts backend value types as parameters
struct BuildDetailView: View {
    let build: BuildModelValue?
    let buildId: UUID
    @Binding var selectedTab: Tab
    @Binding var includeDebugLogs: Bool

    @Dependency(\.backendService) private var backendService
    @State private var isLoading = false
    @State private var error: Error?

    enum Tab: String, CaseIterable {
        case overview = "Overview"
        case logs = "Logs"
        case crashes = "Crashes"
    }

    var body: some View {
        VStack {
            if let build = build {
                // Build Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Build #\(build.buildNumber)")
                            .font(.title2)
                            .bold()
                        
                        Spacer()
                        
                        Text(build.status.rawValue.capitalized)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(colorForStatus(build.status))
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                    }
                    
                    Text("Version: \(build.versionString)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if build.progress > 0 {
                        ProgressView(value: build.progress)
                    }
                }
                .padding()
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Tab View
                TabView(selection: $selectedTab) {
                    buildOverviewTab(build: build)
                        .tabItem { Label("Overview", systemImage: "info.circle") }
                        .tag(Tab.overview)
                    
                    buildLogsTab()
                        .tabItem { Label("Logs", systemImage: "doc.text") }
                        .tag(Tab.logs)
                    
                    buildCrashesTab()
                        .tabItem { Label("Crashes", systemImage: "exclamationmark.triangle") }
                        .tag(Tab.crashes)
                }
            } else {
                ProgressView("Loading build...")
            }
        }
        .padding()
    }
    
    private func colorForStatus(_ status: BuildStatus) -> Color {
        switch status {
        case .completed: return .green
        case .running: return .blue
        case .failed: return .red
        case .queued: return .orange
        case .cancelled: return .gray
        }
    }
    
    private func buildOverviewTab(build: BuildModelValue) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Build Information")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 8) {
                    InfoRow(title: "Created", value: build.createdAt.formatted())
                    if let startDate = build.startDate {
                        InfoRow(title: "Started", value: startDate.formatted())
                    }
                    if let endDate = build.endDate {
                        InfoRow(title: "Completed", value: endDate.formatted())
                    }
                    InfoRow(title: "Commit", value: build.commitHash)
                    InfoRow(title: "Device", value: build.deviceMetadata)
                    InfoRow(title: "OS Version", value: build.osVersion)
                }
                
                Spacer()
            }
            .padding()
        }
    }
    
    private func buildLogsTab() -> some View {
        Text("Build logs would be loaded here with BuildLogsViewContainer")
            .padding()
    }
    
    private func buildCrashesTab() -> some View {
        Text("Crash logs would be loaded here with CrashLogsViewContainer")
            .padding()
    }
}

struct InfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .fontWeight(.medium)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    BuildDetailViewContainer(buildId: UUID())
}
