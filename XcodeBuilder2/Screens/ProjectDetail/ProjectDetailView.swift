//
//  ProjectDetailView.swift
//  XcodeBuilder2
//
//  Created by Kai Shao on 2025/7/18.
//

import SwiftUI
import Core
import SharingGRDB

#if os(macOS)
import AppKit
#endif

enum ProjectDetailTab: String, CaseIterable {
    case overview = "Overview"
    case builds = "Builds"
}

struct ProjectDetailViewContainer: View {
    @Environment(ProjectDetailViewModel.self) private var vm
    @Environment(EntryViewModel.self) private var entryVM
    
    @State private var tabSelection = ProjectDetailTab.overview
    
    var body: some View {
        @Bindable var vm = vm
        @Bindable var entryVM = entryVM
        
        ProjectDetailView(
            project: vm.project ?? .init(),
            schemes: vm.schemes,
            builds: vm.builds,
            availableVersions: vm.allVersions,
            versionSelection: $vm.versionSelection,
            tabSelection: $tabSelection,
            buildSelection: $entryVM.buildSelection,
        )
    }
}

struct ProjectDetailView: View {
    var project: Project
    var schemes: [Scheme] = []
    var builds: [BuildModel] = []
    var availableVersions: [String]
    
    @Binding var versionSelection: String?
    @Binding var tabSelection: ProjectDetailTab
    @Binding var buildSelection: UUID?
    
    var buildIds: [UUID] {
        builds.map { $0.id }
    }
    
    var totalBuildTimeInterval: TimeInterval {
        builds.reduce(into: 0) { $0 += $1.duration }
    }
    
    var averageBuildTimeInterval: TimeInterval {
        builds.isEmpty ? 0 : totalBuildTimeInterval / Double(builds.count)
    }
        
    @State private var showingNewBuildSheet = false
    @State private var showingEditProject = false
    @Environment(\.colorScheme) private var colorScheme
    
    private var recentBuilds: [UUID] {
        // Show more builds when a specific version is selected
        let limit = versionSelection == nil ? 5 : 10
        return Array(buildIds.prefix(limit))
    }
    
    // Helper function to format duration
    private func formatDuration(_ duration: TimeInterval) -> String {
        if duration == 0 {
            return "0s"
        }
        
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        let seconds = Int(duration) % 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        } else {
            return "\(seconds)s"
        }
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 24) {
                // Header Section
                projectHeader
                
                // Tab Picker Section
                tabPickerSection
                
                // Content based on tab selection
                if tabSelection == .overview {
                    // Statistics Overview
                    statisticsSection
                    
                    // Schemes Section
                    schemesSection
                    
                    // Repository Info Section
                    repositorySection
                } else {
                    // Full Builds List
                    fullBuildsSection
                }
            }
            .padding()
        }
        .navigationTitle(project.displayName.isEmpty ? "Project Details" : project.displayName)
        .background(.background)
        .sheet(isPresented: $showingNewBuildSheet) {
            // TODO: Present build editor
            Text("New Build Sheet")
        }
        .sheet(isPresented: $showingEditProject) {
            // TODO: Present project editor
            Text("Edit Project Sheet")
        }
    }
    
    // MARK: - Header Section
    private var projectHeader: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                // Project Icon
                RoundedRectangle(cornerRadius: 16)
                    .fill(LinearGradient(
                        colors: [.blue.opacity(0.8), .purple.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 80, height: 80)
                    .overlay {
                        Image(systemName: "app.dashed")
                            .font(.system(size: 36, weight: .light))
                            .foregroundColor(.white)
                    }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(project.displayName)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .lineLimit(2)
                    
                    if !project.bundleIdentifier.isEmpty {
                        Text(project.bundleIdentifier)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .textSelection(.enabled)
                    }
                    
                    Label {
                        Text("Created \(project.createdAt, style: .date)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } icon: {
                        Image(systemName: "calendar")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Version Filter
                VStack(alignment: .trailing, spacing: 8) {
                    HStack(spacing: 8) {
                        Picker("Version:", selection: $versionSelection) {
                            Text("All Versions")
                                .tag(nil as String?)
                            
                            Divider()
                            
                            ForEach(availableVersions, id: \.self) { version in
                                Text(version)
                                    .tag(version as String?)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 200)
                    }
                    
                    // Action Buttons
                    HStack(spacing: 8) {
                        Button(action: { showingNewBuildSheet = true }) {
                            Label("New Build", systemImage: "plus.circle.fill")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .buttonStyle(.borderedProminent)
                        
                        Button(action: { showingEditProject = true }) {
                            Label("Edit", systemImage: "pencil")
                                .font(.caption)
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)
        }
    }
    
    // MARK: - Tab Picker Section
    private var tabPickerSection: some View {
        Picker("", selection: $tabSelection) {
            ForEach(ProjectDetailTab.allCases, id: \.self) { tab in
                Text(tab.rawValue)
                    .tag(tab)
            }
        }
        .pickerStyle(.segmented)
        .frame(width: 300)
    }
    
    // MARK: - Statistics Section
    private var statisticsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Statistics")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                if versionSelection != nil {
                    Text("for \(versionSelection!)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .clipShape(Capsule())
                }
                
                Spacer()
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                StatCard(
                    title: "Total Builds",
                    value: "\(buildIds.count)",
                    icon: "hammer.fill",
                    color: .blue
                )
                
                StatCard(
                    title: "Schemes",
                    value: "\(schemes.count)",
                    icon: "list.bullet.rectangle",
                    color: .green
                )
                
                StatCard(
                    title: "Success Rate",
                    value: "85%", // TODO: Calculate from actual data
                    icon: "chart.line.uptrend.xyaxis",
                    color: .orange
                )
                
                StatCard(
                    title: "Total Build Time",
                    value: formatDuration(totalBuildTimeInterval),
                    icon: "clock.fill",
                    color: .purple
                )
                
                StatCard(
                    title: "Avg Build Time",
                    value: formatDuration(averageBuildTimeInterval),
                    icon: "stopwatch.fill",
                    color: .teal
                )
                
                StatCard(
                    title: "Recent Activity",
                    value: buildIds.isEmpty ? "None" : "Active",
                    icon: "chart.line.uptrend.xyaxis.circle.fill",
                    color: .indigo
                )
            }
        }
    }
    
    // MARK: - Schemes Section
    private var schemesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Build Schemes")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                if !schemes.isEmpty {
                    Text("\(schemes.count)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .clipShape(Capsule())
                }
                
                Spacer()
            }
            
            if schemes.isEmpty {
                EmptyStateView(
                    icon: "list.bullet.rectangle",
                    title: "No Schemes Yet",
                    subtitle: "Add build schemes to get started",
                    actionTitle: "Add Scheme",
                    action: { showingEditProject = true }
                )
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ForEach(schemes) { scheme in
                        SchemeCard(scheme: scheme) {
                            showingNewBuildSheet = true
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Recent Builds Section
    private var recentBuildsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(versionSelection == nil ? "Recent Builds" : "Builds")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                if versionSelection != nil {
                    Text(versionSelection!)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.green.opacity(0.1))
                        .foregroundColor(.green)
                        .clipShape(Capsule())
                }
                
                Spacer()
                
                if buildIds.count > (versionSelection == nil ? 5 : 10) {
                    Button("View All") {
                        // TODO: Navigate to full builds list
                    }
                    .font(.subheadline)
                    .foregroundColor(.blue)
                }
            }
            
            if recentBuilds.isEmpty {
                EmptyStateView(
                    icon: "hammer",
                    title: "No Builds Yet",
                    subtitle: "Create your first build to get started",
                    actionTitle: "Create First Build",
                    action: { showingNewBuildSheet = true }
                )
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(recentBuilds, id: \.self) { buildId in
                        BuildItemViewContainer(id: buildId)
                            .background {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.regularMaterial)
                            }
                    }
                }
            }
        }
    }
    
    // MARK: - Repository Section
    private var repositorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Repository")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                InfoRowItem(
                    label: "Git URL",
                    value: project.gitRepoURL.absoluteString,
                    action: {
                        #if os(macOS)
                        NSWorkspace.shared.open(project.gitRepoURL)
                        #endif
                    }
                )
                
                if !project.xcodeprojName.isEmpty {
                    InfoRowItem(
                        label: "Xcode Project",
                        value: project.xcodeprojName
                    )
                }
            }
            .padding(16)
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.regularMaterial)
            }
        }
    }
    
    // MARK: - Full Builds Section
    private var fullBuildsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("All Builds")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                if versionSelection != nil {
                    Text(versionSelection!)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.green.opacity(0.1))
                        .foregroundColor(.green)
                        .clipShape(Capsule())
                }
                
                Spacer()
                
                Text("\(buildIds.count) builds")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if buildIds.isEmpty {
                EmptyStateView(
                    icon: "hammer",
                    title: "No Builds Yet",
                    subtitle: "Create your first build to get started",
                    actionTitle: "Create First Build",
                    action: { showingNewBuildSheet = true }
                )
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(buildIds, id: \.self) { buildId in
                        BuildItemViewContainer(id: buildId)
                            .background {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.regularMaterial)
                                    .overlay {
                                        if buildSelection == buildId {
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(.blue, lineWidth: 2)
                                        }
                                    }
                            }
                            .scaleEffect(buildSelection == buildId ? 1.02 : 1.0)
                            .shadow(
                                color: buildSelection == buildId ? .blue.opacity(0.3) : .clear,
                                radius: buildSelection == buildId ? 8 : 0,
                                x: 0,
                                y: buildSelection == buildId ? 4 : 0
                            )
                            .animation(.easeInOut(duration: 0.2), value: buildSelection)
                            .onTapGesture {
                                buildSelection = buildId
                            }
                    }
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(.regularMaterial)
        }
    }
}

struct SchemeCard: View {
    let scheme: Scheme
    let buildAction: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(scheme.name)
                    .font(.headline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Button(action: buildAction) {
                    Image(systemName: "play.circle.fill")
                        .font(.title3)
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
            }
            
            HStack(spacing: 8) {
                ForEach(scheme.platforms, id: \.self) { platform in
                    PlatformBadge(platform: platform)
                }
                
                Spacer()
            }
            
            // TODO: Add recent build status indicator
            HStack {
                Circle()
                    .fill(.green)
                    .frame(width: 8, height: 8)
                
                Text("Last build successful")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(.regularMaterial)
        }
    }
}

struct PlatformBadge: View {
    let platform: Platform
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: platformIcon)
                .font(.caption)
            
            Text(platform.rawValue)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(platformColor.opacity(0.1))
        .foregroundColor(platformColor)
        .clipShape(Capsule())
    }
    
    private var platformIcon: String {
        switch platform {
        case .iOS: return "iphone"
        case .macOS: return "laptopcomputer"
        case .macCatalyst: return "ipad.and.iphone"
        }
    }
    
    private var platformColor: Color {
        switch platform {
        case .iOS: return .blue
        case .macOS: return .purple
        case .macCatalyst: return .orange
        }
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    let actionTitle: String
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            VStack(spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(actionTitle, action: action)
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
        }
        .frame(maxWidth: .infinity)
        .padding(32)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(.regularMaterial)
        }
    }
}

struct InfoRowItem: View {
    let label: String
    let value: String
    var action: (() -> Void)? = nil
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(width: 100, alignment: .leading)
            
            if let action = action {
                Button(action: action) {
                    Text(value)
                        .font(.subheadline)
                        .foregroundColor(.blue)
                        .textSelection(.enabled)
                }
                .buttonStyle(.plain)
            } else {
                Text(value)
                    .font(.subheadline)
                    .textSelection(.enabled)
            }
            
            Spacer()
            
            if action != nil {
                Image(systemName: "arrow.up.right.square")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Preview

#Preview("With Data") {
    NavigationView {
        ProjectDetailView(
            project: Project(
                bundleIdentifier: "com.example.myapp",
                name: "MyApp",
                displayName: "My Awesome App",
                gitRepoURL: URL(string: "https://github.com/user/myapp")!,
                xcodeprojName: "MyApp.xcodeproj"
            ),
            schemes: [
                Scheme(
                    id: UUID(),
                    name: "Debug",
                    platforms: [.iOS, .macOS]
                ),
                Scheme(
                    id: UUID(),
                    name: "Release",
                    platforms: [.iOS]
                ),
                Scheme(
                    id: UUID(),
                    name: "Beta",
                    platforms: [.iOS, .macCatalyst]
                )
            ],
            availableVersions: [
                "1.0.0",
                "1.1.0",
                "1.2.0",
            ],
            versionSelection: .constant(nil),
            tabSelection: .constant(.overview),
            buildSelection: .constant(nil),
        )
    }
}

#Preview("Empty State") {
    NavigationView {
        ProjectDetailView(
            project: Project(
                bundleIdentifier: "com.example.empty",
                displayName: "Empty Project"
            ),
            schemes: [],
            availableVersions: [
                "1.0.0",
                "1.1.0",
                "1.2.0",
            ],
            versionSelection: .constant(nil),
            tabSelection: .constant(.overview),
            buildSelection: .constant(nil),
        )
    }
}
