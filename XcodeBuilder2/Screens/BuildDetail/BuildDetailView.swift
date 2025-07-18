//
//  BuildDetailView.swift
//  XcodeBuilder2
//
//  Created by Kai Shao on 2025/7/15.
//

import SwiftUI
import Core
import SharingGRDB

struct BuildDetailView: View {
    var build: BuildModel
    var logIds: [UUID]
    var crashLogs: [CrashLog] = []
    var scheme: Scheme?
    @Binding var showDebugLogs: Bool
    @Binding var selectedTab: DetailTab
    @Binding var selectedCategory: XcodeBuildJobLogCategory?
    
    @State private var position: ScrollPosition = .init(idType: BuildModel.ID.self)
    
    enum DetailTab: String, CaseIterable {
        case info = "Info"
        case logs = "Logs"
        case crashLogs = "Crash Logs"
        
        var symbol: String {
            switch self {
            case .info: return "info.circle"
            case .logs: return "doc.text"
            case .crashLogs: return "ladybug"
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
                case .crashLogs:
                    crashLogsContent
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
                CompactInfoRow(label: "Build ID", value: String(build.id.uuidString))
                CompactInfoRow(label: "Scheme", value: schemeName)
                CompactInfoRow(label: "Status", value: build.status.title)
                CompactInfoRow(label: "Version", value: build.versionString)
                CompactInfoRow(label: "Build Number", value: String(build.buildNumber))
                CompactInfoRow(label: "Full Version", value: build.version.displayString)
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
    
    private var crashLogsContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Crash Logs")
                    .font(.headline)
                
                Spacer()
                
                Text("\(crashLogs.count) crash logs")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            if crashLogs.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.green)
                    
                    VStack(spacing: 4) {
                        Text("No Crash Logs")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        
                        Text("This build completed without any crashes")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(32)
                .background {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.regularMaterial)
                }
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(crashLogs, id: \.id) { crashLog in
                        CrashLogRow(crashLog: crashLog)
                    }
                }
                .padding(.vertical, 8)
            }
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

struct CrashLogRow: View {
    let crashLog: CrashLog
    @State private var isExpanded = false
    
    @Environment(\.openWindow) var openWindow
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header row
            Button(action: {
                openWindow(value: CrashLogWindowGroup(id: crashLog.id))
            }) {
                HStack(spacing: 12) {
                    // Priority indicator
                    Circle()
                        .fill(priorityColor)
                        .frame(width: 8, height: 8)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text(crashLog.process)
                                .font(.subheadline.bold())
                                .foregroundStyle(.primary)
                            
                            Text("• \(crashLog.role.rawValue.capitalized)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        
                        HStack {
                            Text(formatter.string(from: crashLog.dateTime))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            if crashLog.fixed {
                                Text("• Fixed")
                                    .font(.caption)
                                    .foregroundStyle(.green)
                                    .lineLimit(1)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Priority badge
                    Text(crashLog.priority.rawValue.uppercased())
                        .font(.caption2.bold())
                        .foregroundStyle(priorityColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(priorityColor.opacity(0.1))
                        .clipShape(Capsule())
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            
            // Expanded content
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    Divider()
                    
                    // Crash details
                    VStack(alignment: .leading, spacing: 8) {
                        DetailRow(label: "Incident ID", value: crashLog.incidentIdentifier)
                        DetailRow(label: "Hardware Model", value: crashLog.hardwareModel)
                        DetailRow(label: "OS Version", value: crashLog.osVersion)
                        DetailRow(label: "Main Thread", value: crashLog.isMainThread ? "Yes" : "No")
                        DetailRow(label: "Launch Time", value: DateFormatter.timeFormatter.string(from: crashLog.launchTime))
                        DetailRow(label: "Created At", value: DateFormatter.timeFormatter.string(from: crashLog.createdAt))
                        DetailRow(label: "Fixed", value: crashLog.fixed ? "Yes" : "No")
                        
                        if !crashLog.note.isEmpty {
                            DetailRow(label: "Note", value: crashLog.note)
                        }
                    }
                    
                    // Crash content (stack trace)
                    if !crashLog.content.isEmpty {
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Crash Report")
                                .font(.subheadline.bold())
                            
                            ScrollView {
                                Text(crashLog.content)
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundStyle(.secondary)
                                    .textSelection(.enabled)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .frame(maxHeight: 200)
                            .background {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(.quaternary)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            }
        }
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(.regularMaterial)
        }
    }
    
    private var priorityColor: Color {
        switch crashLog.priority {
        case .urgent:
            return .red
        case .high:
            return .orange
        case .medium:
            return .yellow
        case .low:
            return .blue
        }
    }
    
    private var formatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .medium
        return formatter
    }
}

extension DateFormatter {
    static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 100, alignment: .leading)
            
            Text(value)
                .font(.caption)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
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




#Preview {
    BuildDetailView(
        build: .init(
            id: UUID(),
            schemeId: UUID(),
            version: .init(version: "1.2.0", buildNumber: 42, commitHash: "xxx"),
            createdAt: Date().addingTimeInterval(-3600),
            startDate: Date().addingTimeInterval(-1800),
            endDate: Date().addingTimeInterval(-300),
            exportOptions: [.appStore, .releaseTesting],
            status: .completed,
            deviceMetadata: .init(),
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
            version: .init(version: "1.2.0", buildNumber: 42, commitHash: "xxx"),
            createdAt: Date().addingTimeInterval(-3600),
            startDate: Date().addingTimeInterval(-1800),
            endDate: nil,
            exportOptions: [.appStore, .releaseTesting],
            status: .running,
            progress: 0.65,
            deviceMetadata: .init(),
        ),
        logIds: [],
        scheme: Scheme(id: schemeId, name: "Beta", platforms: [.iOS, .macOS]),
        showDebugLogs: .constant(true),
        selectedTab: .constant(.logs),
        selectedCategory: .constant(nil)
    )
}
