//
//  ProjectDetailView.swift
//  XcodeBuilder2
//
//  Created by Kai Shao on 2025/7/18.
//

import SwiftUI
import Charts
import Core
import Sharing

#if os(macOS)
import AppKit
#endif

enum ProjectDetailTab: String, CaseIterable {
    case overview = "Overview"
    case builds = "Builds"
}



struct ProjectDetailView: View {
    var project: ProjectValue
    var schemes: [SchemeValue] = []
    var builds: [BuildModelValue] = []
    var availableVersions: [String]
    
    @Binding var versionSelection: String?
    @Binding var tabSelection: ProjectDetailTab
    @Binding var buildSelection: UUID?
    
    var cancelBuild: ((UUID) -> Void)?
    var deleteBuild: ((BuildModel) -> Void)?
    
    var buildIds: [UUID] {
        builds.map { $0.id }
    }
    
    var totalBuildTimeInterval: TimeInterval {
        builds
            .filter { $0.status == .completed }
            .reduce(into: 0) { $0 += $1.duration }
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
                    
                    // Build Time Chart Section
                    buildTimeChartSection
                    
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
            ViewThatFits {
                // Regular horizontal layout for larger containers
                regularHeaderLayout
                
                // Compact vertical layout for smaller containers
                compactHeaderLayout
            }
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)
        }
    }
    
    // MARK: - Header Layout Variants
    private var regularHeaderLayout: some View {
        HStack(spacing: 16) {
            // Project Icon
            projectIcon
            
            // Project Info
            projectInfo
            
            Spacer()
            
            // Version Filter and Actions
            headerActions
        }
    }
    
    private var compactHeaderLayout: some View {
        VStack(spacing: 16) {
            // Top row: Icon and basic info
            HStack(spacing: 16) {
                projectIcon
                    .scaleEffect(0.8) // Slightly smaller icon for compact view
                
                projectInfo
                
                Spacer()
            }
            
            // Bottom row: Version filter and actions
            HStack {
                // Version Filter (more compact)
                HStack(spacing: 8) {
                    Text("Version:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Picker("Version:", selection: $versionSelection) {
                        Text("All")
                            .tag(nil as String?)
                        
                        Divider()
                        
                        ForEach(availableVersions, id: \.self) { version in
                            Text(version)
                                .tag(version as String?)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: 120)
                }
                
                Spacer()
                
                // Compact Action Buttons
                HStack(spacing: 6) {
                    Button(action: { showingNewBuildSheet = true }) {
                        Label("Build", systemImage: "plus.circle.fill")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    
                    Button(action: { showingEditProject = true }) {
                        Image(systemName: "pencil")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
        }
    }
    
    private var projectIcon: some View {
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
    }
    
    private var projectInfo: some View {
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
    }
    
    private var headerActions: some View {
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
    
    // MARK: - Build Time Chart Section
    private var buildTimeChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Build Time Trends")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                if versionSelection != nil {
                    Text("for \(versionSelection!)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.green.opacity(0.1))
                        .foregroundColor(.green)
                        .clipShape(Capsule())
                }
                
                Spacer()
                
                if !buildTimeChartData.isEmpty {
                    Text("\(buildTimeChartData.count) builds")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if buildTimeChartData.isEmpty {
                EmptyStateView(
                    icon: "chart.bar",
                    title: "No Build Data",
                    subtitle: "Create some builds to see time trends",
                    actionTitle: "Create First Build",
                    action: { showingNewBuildSheet = true }
                )
            } else {
                VStack(spacing: 16) {
                    // Chart
                    BuildTimeBarChart(data: buildTimeChartData)
                        .frame(height: 220)
                    
                    // Legend
                    HStack(spacing: 16) {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(.green)
                                .frame(width: 8, height: 8)
                            Text("Successful")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack(spacing: 4) {
                            Circle()
                                .fill(.red)
                                .frame(width: 8, height: 8)
                            Text("Failed")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack(spacing: 4) {
                            Circle()
                                .fill(.orange)
                                .frame(width: 8, height: 8)
                            Text("Cancelled")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack(spacing: 4) {
                            Circle()
                                .fill(.blue)
                                .frame(width: 8, height: 8)
                            Text("Running/Queued")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                }
                .padding(16)
                .background {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.regularMaterial)
                }
            }
        }
    }
    
    // Chart data for the last 10 builds
    private var buildTimeChartData: [BuildTimeChartItem] {
        let recentBuilds = Array(builds.prefix(10))
        let validBuilds = recentBuilds.compactMap { build -> BuildTimeChartItem? in
            guard build.duration > 0 else { return nil }
            return BuildTimeChartItem(
                id: build.id,
                duration: build.duration,
                status: build.status,
                createdAt: build.createdAt,
                buildNumber: build.buildNumber
            )
        }
        
        // Group by build number and keep only the most recent one for each build number
        let groupedByBuildNumber = Dictionary(grouping: validBuilds) { $0.buildNumber }
        let uniqueBuilds = groupedByBuildNumber.compactMap { (buildNumber, builds) in
            builds.max { $0.createdAt < $1.createdAt } // Get the most recent build for this build number
        }
        
        return uniqueBuilds.sorted { $0.createdAt < $1.createdAt } // Show oldest to newest (left to right)
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

// MARK: - Chart Data and Views

struct BuildTimeChartItem: Identifiable {
    let id: UUID
    let duration: TimeInterval
    let status: BuildStatus
    let createdAt: Date
    let buildNumber: Int
    
    var color: Color {
        switch status {
        case .completed: return .green
        case .failed: return .red
        case .cancelled: return .orange
        case .running, .queued: return .blue
        }
    }
    
    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        
        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        } else {
            return "\(seconds)s"
        }
    }
}

struct BuildTimeBarChart: View {
    let data: [BuildTimeChartItem]
    
    var body: some View {
        Chart(data, id: \.id) { item in
            BarMark(
                x: .value("Build", "Build \(item.buildNumber)"),
                y: .value("Duration", item.duration)
            )
            .foregroundStyle(item.color)
            .cornerRadius(4)
        }
        .chartXAxis {
            AxisMarks { value in
                AxisGridLine()
                AxisTick()
                AxisValueLabel {
                    if let buildLabel = value.as(String.self) {
                        Text(buildLabel)
                            .font(.caption2)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisGridLine()
                AxisTick()
                AxisValueLabel {
                    if let duration = value.as(TimeInterval.self) {
                        Text(formatDuration(duration))
                    }
                }
            }
        }
        .chartPlotStyle { plotArea in
            plotArea
                .background(.regularMaterial.opacity(0.1))
                .cornerRadius(8)
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        
        if minutes > 0 {
            return "\(minutes)m"
        } else {
            return "\(seconds)s"
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
