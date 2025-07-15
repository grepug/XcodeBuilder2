//
//  BuildDetailView.swift
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

struct BuildDetailView: View {
    var build: BuildModel
    var logIds: [UUID]
    var scheme: Scheme?
    @Binding var showDebugLogs: Bool
    @Binding var selectedTab: DetailTab
    @Binding var selectedCategory: XcodeBuildJobLogCategory?
    
    @State private var position: ScrollPosition = .init(idType: BuildModel.ID.self)
    
    enum DetailTab: String, CaseIterable {
        case info = "Info"
        case logs = "Logs"
        
        var symbol: String {
            switch self {
            case .info: return "info.circle"
            case .logs: return "doc.text"
            }
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header Section
                buildHeader
                
                Divider()
                
                // Segmented Control
                Picker("", selection: $selectedTab) {
                    ForEach(DetailTab.allCases, id: \.self) { tab in
                        Image(systemName: tab.symbol)
                            .tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                // Content based on selected tab
                switch selectedTab {
                case .info:
                    infoContent
                case .logs:
                    logsContent
                }
                
                Spacer()
            }
            .padding()
            .scrollTargetLayout()
        }
        .scrollPosition($position)
        .navigationTitle("Build Details")
        .onAppear {
            // Auto-select logs tab for running builds
            if build.status == .running {
                selectedTab = .logs
            }
        }
    }
    
    private var buildHeader: some View {
        HStack(spacing: 16) {
            // Progress circle
            BuildProgressCircle(build: build, size: 60)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Build \(build.buildNumber)")
                    .font(.title2.bold())
                
                HStack {
                    Text(build.status.title)
                        .font(.subheadline)
                        .foregroundStyle(build.status.color)
                    
                    if build.status == .running {
                        Text("• \(Int(build.progress * 100))%")
                            .font(.subheadline)
                            .foregroundStyle(build.status.color)
                    }
                }
                
                if let scheme = scheme {
                    Text(scheme.name)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
        }
    }
    
    private var buildAndVersionInfo: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Build & Version Information")
                .font(.headline)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), alignment: .leading), count: 2), spacing: 12) {
                CompactInfoRow(label: "Build ID", value: String(build.id.uuidString.prefix(8)))
                CompactInfoRow(label: "Scheme", value: schemeName)
                CompactInfoRow(label: "Status", value: build.status.title)
                CompactInfoRow(label: "Version", value: build.versionString)
                CompactInfoRow(label: "Build Number", value: String(build.buildNumber))
                CompactInfoRow(label: "Full Version", value: "\(build.versionString) (\(build.buildNumber))")
            }
        }
    }
    
    private var schemeName: String {
        if let scheme = scheme {
            scheme.name
        } else {
            "Unknown Scheme"
        }
    }
    
    private var exportOptionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Export Options")
                .font(.headline)
            
            if build.exportOptions.isEmpty {
                Text("No export options configured")
                    .foregroundStyle(.secondary)
                    .italic()
            } else {
                ForEach(build.exportOptions, id: \.self) { option in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: "arrow.up.circle.fill")
                                .foregroundStyle(.blue)
                            Text(option.rawValue)
                                .font(.subheadline.bold())
                        }
                        
                        Text(option.message)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.leading, 24)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }
    
    private var timestampsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Timeline")
                .font(.headline)
            
            InfoRow(label: "Created", value: formatter.string(from: build.createdAt))
            
            if let startDate = build.startDate {
                InfoRow(label: "Started", value: formatter.string(from: startDate))
            } else {
                InfoRow(label: "Started", value: "Not started")
            }
            
            if let endDate = build.endDate {
                InfoRow(label: "Ended", value: formatter.string(from: endDate))
                
                if let startDate = build.startDate {
                    let duration = endDate.timeIntervalSince(startDate)
                    InfoRow(label: "Duration", value: formatDuration(duration))
                }
            } else if build.startDate != nil {
                InfoRow(label: "Ended", value: "In progress")
            } else {
                InfoRow(label: "Ended", value: "Not started")
            }
        }
    }
    
    private var infoContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Build & Version Information (combined and compact)
            buildAndVersionInfo
            
            Divider()
            
            // Export Options
            exportOptionsSection
            
            Divider()
            
            // Timestamps
            timestampsSection
        }
    }
    
    private var logsContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Build Logs")
                    .font(.headline)
                
                Spacer()
                
                // Category filter picker
                Picker("Category", selection: $selectedCategory) {
                    Text("All Categories").tag(nil as XcodeBuildJobLogCategory?)
                    ForEach(XcodeBuildJobLogCategory.allCases, id: \.self) { category in
                        Text(category.rawValue).tag(category as XcodeBuildJobLogCategory?)
                    }
                }
                .pickerStyle(.menu)
                .font(.caption)
                
                // Debug logs toggle
                Toggle("Show debug logs", isOn: $showDebugLogs)
                    .toggleStyle(.switch)
                    .font(.caption)
                
                Text("\(logIds.count) logs")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            if logIds.isEmpty {
                Text("No logs available")
                    .foregroundStyle(.secondary)
                    .italic()
                    .padding()
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(logIds, id: \.self) { id in
                        LogEntryViewContainer(id: id)
                            .tag(id)
                    }
                }
                .padding(.vertical, 8)
                .onChange(of: logIds.count) { _, newCount in
                    // Auto-scroll to bottom when new logs are added
                    withAnimation(.easeInOut(duration: 0.3)) {
                        position.scrollTo(edge: .bottom)
                    }
                }
                .onAppear {
                    // Scroll to bottom when logs appear
                    position.scrollTo(edge: .bottom)
                }
            }
        }
    }
    
    private var formatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        
        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        } else {
            return "\(seconds)s"
        }
    }
}

struct CompactInfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Text(value)
                .font(.subheadline)
                .textSelection(.enabled)
        }
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(width: 100, alignment: .leading)
            
            Text(value)
                .font(.subheadline)
                .textSelection(.enabled)
            
            Spacer()
        }
    }
}

struct LogEntryViewContainer: View {
    var id: UUID
    
    @State @FetchOne var fetchedLog: BuildLog?
    
    var body: some View {
        LazyVStack {
            LogEntryView(log: fetchedLog ?? .init(buildId: id, content: ""))
                .task(id: id) {
                    try! await $fetchedLog.wrappedValue.load(BuildLog.where { $0.id == id })
                }
        }
    }
}

struct LogEntryView: View {
    let log: BuildLog
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            // Level indicator
            Image(systemName: levelIcon)
                .foregroundStyle(levelColor)
                .font(.caption)
                .frame(width: 16)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(log.level.rawValue.uppercased())
                        .font(.caption2.bold())
                        .foregroundStyle(levelColor)
                    
                    // Category badge
                    if let category = log.category {
                        Text(category.uppercased())
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(categoryColor(category).opacity(0.2))
                            )
                            .foregroundStyle(categoryColor(category))
                    }
                    
                    Spacer()
                    
                    Text(timeFormatter.string(from: log.createdAt))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                
                Text(log.content)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.primary)
                    .textSelection(.enabled)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(levelBackgroundColor)
        )
    }
    
    private var levelIcon: String {
        switch log.level {
        case .info: return "info.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .error: return "xmark.circle.fill"
        case .debug: return "ladybug.fill"
        }
    }
    
    private var levelColor: Color {
        switch log.level {
        case .info: return .blue
        case .warning: return .orange
        case .error: return .red
        case .debug: return .purple
        }
    }
    
    private var levelBackgroundColor: Color {
        switch log.level {
        case .info: return .blue.opacity(0.1)
        case .warning: return .orange.opacity(0.1)
        case .error: return .red.opacity(0.1)
        case .debug: return .purple.opacity(0.1)
        }
    }
    
    private func categoryColor(_ category: String) -> Color {
        guard let enumCategory = XcodeBuildJobLogCategory(rawValue: category) else {
            return .primary
        }
        
        switch enumCategory {
        case .clone: return .green
        case .resolveDependencies: return .blue
        case .archive: return .orange
        case .export: return .purple
        case .cleanup: return .gray
        }
    }
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .none
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }
}


#Preview {
    BuildDetailView(
        build: .init(
            id: UUID(),
            schemeId: UUID(),
            versionString: "1.2.0",
            buildNumber: 42,
            createdAt: Date().addingTimeInterval(-3600),
            startDate: Date().addingTimeInterval(-1800),
            endDate: Date().addingTimeInterval(-300),
            exportOptions: [.appStore, .releaseTesting],
            status: .completed
        ),
        logIds: [],
        scheme: Scheme(id: UUID(), name: "Release", platforms: [.iOS]),
        showDebugLogs: .constant(false),
        selectedTab: .constant(.info),
        selectedCategory: .constant(nil)
    )
}

#Preview("Running Build") {
    let schemeId = UUID()
    
    BuildDetailView(
        build: .init(
            id: UUID(),
            schemeId: schemeId,
            versionString: "1.2.0",
            buildNumber: 42,
            createdAt: Date().addingTimeInterval(-3600),
            startDate: Date().addingTimeInterval(-1800),
            endDate: nil,
            exportOptions: [.appStore, .releaseTesting],
            status: .running,
            progress: 0.65
        ),
        logIds: [],
        scheme: Scheme(id: schemeId, name: "Beta", platforms: [.iOS, .macOS]),
        showDebugLogs: .constant(true),
        selectedTab: .constant(.logs),
        selectedCategory: .constant(nil)
    )
}
