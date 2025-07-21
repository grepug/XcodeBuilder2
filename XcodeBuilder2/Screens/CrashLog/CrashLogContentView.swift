//
//  CrashLogContentView.swift
//  XcodeBuilder2
//
//  Created by Kai Shao on 2025/7/18.
//

import SwiftUI
import Core
import SharingGRDB
import Dependencies

#if canImport(AppKit)
import AppKit
#endif

struct CrashLogContentViewContainer: View {
    let id: String
    
    @State @FetchOne var fetchedCrashLog: CrashLog?
    @State private var crashLog: CrashLog
    
    init(id: String) {
        self.id = id
        _fetchedCrashLog = .init(wrappedValue: .init(wrappedValue: nil, CrashLog.where { $0.incidentIdentifier == id }))
        _crashLog = .init(wrappedValue: .init(incidentIdentifier: id))
    }
    
    var body: some View {
        CrashLogContentView(crashLog: $crashLog)
            .task(id: id) {
                try! await $fetchedCrashLog.wrappedValue.load(
                    CrashLog.where { $0.incidentIdentifier == id }
                )
            }
            .task(id: fetchedCrashLog) {
                if let fetchedCrashLog = fetchedCrashLog {
                    crashLog = fetchedCrashLog
                }
            }
            .task(id: [crashLog, id] as [AnyHashable]) {
                let crashLog = crashLog
                let id = id
                
                guard crashLog.id == id else {
                    return
                }
                
                guard crashLog != fetchedCrashLog else {
                    return
                }
                
                @Dependency(\.defaultDatabase) var db
                
                do {
                    try await db.write {
                        try CrashLog
                            .where { $0.incidentIdentifier == id }
                            .update {
                                $0.priority = crashLog.priority
                                $0.note = crashLog.note
                                $0.fixed = crashLog.fixed
                            }
                            .execute($0)
                    }
                } catch is CancellationError {} catch {
                    assertionFailure()
                }
            }
    }
}

struct CrashLogContentView: View {
    @Binding var crashLog: CrashLog
    @State private var selectedThreadNumber: Int?
    @State private var showCopyFeedback = false
    @State private var showFilenameCopyFeedback = false
    @State private var project: Project?
    
    @Dependency(\.xcodeBuildPathManager) var pathManager
    @FetchOne var buildModel: BuildModel?
    @FetchOne var scheme: Scheme?
    @FetchOne var projectFetch: Project?
    
    var selectedThread: CrashLogThread? {
        threads.first(where: { $0.number == selectedThreadNumber })
    }
    
    private var threads: [CrashLogThread] {
        let parsedThreads = crashLog.parsedThreads
        
        // Sort threads: crashed thread first, then by thread number
        return parsedThreads
            .filter { $0.frames.count > 3 }
            .sorted { thread1, thread2 in
                if thread1.isCrashed && !thread2.isCrashed {
                    return true
                } else if !thread1.isCrashed && thread2.isCrashed {
                    return false
                } else {
                    return thread1.number < thread2.number
                }
        }
    }
    
    var body: some View {
        NavigationSplitView(preferredCompactColumn: .constant(.sidebar)) {
            Spacer().navigationSplitViewColumnWidth(0)
        } content: {
            contentColumn
                .navigationSplitViewColumnWidth(min: 500, ideal: 600)
        } detail: {
            // Second column: Settings and Info sections
            settingsAndInfoColumn
                .navigationSplitViewColumnWidth(min: 400, ideal: 500)
        }
        .navigationSplitViewStyle(.balanced)
        .onChange(of: threads, initial: true) { _, _ in
            setInitialSelectedThread()
        }
        .task(id: crashLog.buildId) {
            // Load the build model
            try! await $buildModel.load(
                BuildModel.where { $0.id == crashLog.buildId }
            )
        }
        .task(id: buildModel) {
            // Load the scheme when build model is available
            if let buildModel = buildModel {
                try! await $scheme.load(
                    Scheme.where { $0.id == buildModel.schemeId }
                )
            }
        }
        .task(id: scheme) {
            // Load the project when scheme is available
            if let scheme = scheme {
                try! await $projectFetch.load(
                    Project.where { $0.bundleIdentifier == scheme.projectBundleIdentifier }
                )
            }
        }
        .task(id: projectFetch) {
            // Set the project when it's loaded
            if let projectFetch = projectFetch {
                project = projectFetch
            }
        }
    }
    
    // MARK: - Content Column (First Column)
    private var contentColumn: some View {
        VStack(alignment: .leading, spacing: 0) {
            basicInfoHeader
            threadsSection
        }
    }
    
    // MARK: - Basic Info Header
    private var basicInfoHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "doc.text")
                    .foregroundColor(.blue)
                Text("Crash Log Content")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                
                Button(action: {
                    #if canImport(AppKit)
                    let pasteboard = NSPasteboard.general
                    pasteboard.clearContents()
                    let success = pasteboard.setString(crashLog.content, forType: .string)
                    if success {
                        showCopyFeedback = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            showCopyFeedback = false
                        }
                    }
                    #endif
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: showCopyFeedback ? "checkmark" : "doc.on.doc")
                        Text(showCopyFeedback ? "Copied!" : "Copy")
                            .font(.caption)
                    }
                    .foregroundColor(showCopyFeedback ? .green : .blue)
                }
                .buttonStyle(.bordered)
                
                // Filename copy feedback overlay
                if showFilenameCopyFeedback {
                    Text("Filename copied!")
                        .font(.caption)
                        .foregroundColor(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(4)
                }
            }
            
            // Basic crash info in compact cards
            if !threads.isEmpty {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 8) {
                    CompactInfoCard(
                        icon: "exclamationmark.triangle",
                        title: "Crashed Thread",
                        value: "Thread \(crashedThreadNumber)",
                        color: .red
                    )
                    
                    CompactInfoCard(
                        icon: "gear",
                        title: "Total Threads",
                        value: "\(threads.count)",
                        color: .blue
                    )
                    
                    CompactInfoCard(
                        icon: "app.badge",
                        title: "Process",
                        value: crashLog.process,
                        color: .purple
                    )
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color(NSColor.textBackgroundColor))
        .overlay(
            Rectangle()
                .fill(Color(NSColor.separatorColor))
                .frame(height: 0.5),
            alignment: .bottom
        )
    }
    
    // MARK: - Threads Section
    private var threadsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            if !threads.isEmpty {
                // Thread Picker
                VStack(alignment: .leading, spacing: 8) {
                    Picker("", selection: $selectedThreadNumber) {
                        ForEach(threads, id: \.number) { thread in
                            Text(threadDisplayName(for: thread))
                                .tag(thread.number)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color(NSColor.controlBackgroundColor))
                
                // Thread Stack Content
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        // Thread header info
                        if let selectedThread {
                            HStack {
                                Text(threadDisplayName(for: selectedThread))
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                
                                Spacer()
                                
                                Text("\(selectedThread.frames.count) frames")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 16)
                            
                            // Stack trace
                            VStack(alignment: .leading, spacing: 2) {
                                ForEach(Array(selectedThread.frames.enumerated()), id: \.offset) { index, frame in
                                    StackFrameView(
                                        index: index,
                                        frame: frame,
                                        appProcessName: crashLog.process,
                                        isCrashedFrame: selectedThread.isCrashed && index == 0,
                                        isFileFound: isFileFoundInProject(frame.fileName),
                                        onFileClick: openFileInXcode
                                    )
                                }
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // Fallback to original content view
                ScrollView {
                    Text(crashLog.content)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                }
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(NSColor.separatorColor), lineWidth: 0.5)
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }
        }
    }
    
    // MARK: - Settings and Info Column (Second Column)
    private var settingsAndInfoColumn: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Section 1: User Input
                userInputSection
                
                // Section 2: Structured Info
                structuredInfoSection
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
//        .background(Color(NSColor.controlBackgroundColor))
        .navigationTitle("Details")
    }
    
    // MARK: - User Input Section
    private var userInputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "slider.horizontal.3")
                    .foregroundColor(.blue)
                    .font(.caption)
                Text("Settings")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            HStack(spacing: 20) {
                // Priority Picker
                HStack(spacing: 8) {
                    Text("Priority")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Picker("", selection: $crashLog.priority) {
                        ForEach(CrashLogPriority.allCases, id: \.self) { priority in
                            HStack {
                                Circle()
                                    .fill(priorityColor(for: priority))
                                    .frame(width: 6, height: 6)
                                Text(priority.rawValue.capitalized)
                            }
                            .tag(priority)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 100)
                }
                
                // Fixed Toggle
                HStack(spacing: 8) {
                    Text("Fixed")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Toggle("", isOn: $crashLog.fixed)
                        .toggleStyle(SwitchToggleStyle(tint: .green))
                        .scaleEffect(0.8)
                }
            }
            
            // Note TextEditor - compact version
            if !crashLog.note.isEmpty || crashLog.note.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Notes")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    TextEditor(text: $crashLog.note)
                        .frame(height: 50)
                        .padding(6)
                        .background(Color(NSColor.textBackgroundColor))
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                            .stroke(Color(NSColor.separatorColor), lineWidth: 0.5)
                        )
                }
            }
        }
        .padding(12)
        .background(Color(NSColor.textBackgroundColor))
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.03), radius: 1, x: 0, y: 1)
    }
    
    // MARK: - Structured Info Section
    private var structuredInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "info.circle")
                    .foregroundColor(.blue)
                    .font(.caption)
                Text("Crash Information")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            // Compact grid with smaller cards
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                CompactInfoCard(
                    icon: "exclamationmark.triangle",
                    title: "Incident",
                    value: String(crashLog.incidentIdentifier.prefix(8)),
                    color: .orange
                )
                
                CompactInfoCard(
                    icon: "gear",
                    title: "Process",
                    value: crashLog.process,
                    color: .blue
                )
                
                CompactInfoCard(
                    icon: "square.stack",
                    title: "Main Thread",
                    value: crashLog.isMainThread ? "Yes" : "No",
                    color: crashLog.isMainThread ? .red : .green
                )
                
                CompactInfoCard(
                    icon: "desktopcomputer",
                    title: "Hardware",
                    value: crashLog.hardwareModel,
                    color: .purple
                )
                
                CompactInfoCard(
                    icon: "app.badge",
                    title: "Role",
                    value: crashLog.role.rawValue.capitalized,
                    color: crashLog.role == .foreground ? .blue : .gray
                )
                
                CompactInfoCard(
                    icon: "gear.circle",
                    title: "OS Version",
                    value: crashLog.osVersion,
                    color: .indigo
                )
            }
            
            // Time information in a more compact format
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                CompactTimeInfo(
                    icon: "clock",
                    title: "Crashed",
                    date: crashLog.dateTime,
                    color: .red
                )
                
                CompactTimeInfo(
                    icon: "play.circle",
                    title: "Launched",
                    date: crashLog.launchTime,
                    color: .green
                )
                
                CompactTimeInfo(
                    icon: "calendar.badge.plus",
                    title: "Created",
                    date: crashLog.createdAt,
                    color: .blue
                )
            }
        }
        .padding(12)
        .background(Color(NSColor.textBackgroundColor))
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.03), radius: 1, x: 0, y: 1)
    }
    
    // MARK: - Helper Functions
    private func priorityColor(for priority: CrashLogPriority) -> Color {
        switch priority {
        case .urgent:
            return .red
        case .high:
            return .orange
        case .medium:
            return .yellow
        case .low:
            return .green
        }
    }
    
    private var crashedThreadNumber: Int {
        return threads.first(where: { $0.isCrashed })?.number ?? 0
    }
    
    private func threadDisplayName(for thread: CrashLogThread) -> String {
        if thread.isMainThread {
            "Main Thread \(thread.number)"
        } else if thread.isCrashed {
            "🔥 Thread \(thread.number)"
        } else {
            "Thread \(thread.number)"
        }
    }
    
    private func setInitialSelectedThread() {
        // Set initial selection to crashed thread
        if let thread = threads.first(where: { $0.isCrashed }) {
            selectedThreadNumber = thread.number
        }
    }
    
    private func openFileInXcode(fileName: String, lineNumber: Int?) {
        guard let project = project else { 
            // No project available, copy filename to clipboard
            copyFilenameToClipboard(fileName)
            return 
        }
        
        // Search for the file in the project's working directory
        if let fileURL = pathManager.findFile(named: fileName, in: project.workingDirectoryURL) {
            // Try to open the file
            #if canImport(AppKit)
            let success = NSWorkspace.shared.open(fileURL)
            if !success {
                // File couldn't be opened, copy filename to clipboard
                copyFilenameToClipboard(fileName)
            }
            #endif
        } else {
            // File not found, copy filename to clipboard
            copyFilenameToClipboard(fileName)
        }
    }
    
    private func isFileFound(_ fileName: String) -> Bool {
        guard let project = project else { return false }
        return pathManager.findFile(named: fileName, in: project.workingDirectoryURL) != nil
    }
    
    private func isFileFoundInProject(_ fileName: String?) -> Bool {
        guard let fileName = fileName, !fileName.isEmpty else { return false }
        return isFileFound(fileName)
    }
    
    private func copyFilenameToClipboard(_ fileName: String) {
        #if canImport(AppKit)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        let success = pasteboard.setString(fileName, forType: .string)
        if success {
            showFilenameCopyFeedback = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                showFilenameCopyFeedback = false
            }
        }
        #endif
    }
}

// MARK: - Array Extension for Safe Access
extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Supporting Views
struct CompactInfoCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.caption2)
                Spacer()
            }
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(1)
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(6)
    }
}

struct CompactTimeInfo: View {
    let icon: String
    let title: String
    let date: Date
    let color: Color
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .medium // This shows seconds
        return formatter
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.caption2)
                Spacer()
            }
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(1)
            
            VStack(alignment: .leading, spacing: 1) {
                Text(dateFormatter.string(from: date))
                    .font(.caption2)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Text(timeFormatter.string(from: date))
                    .font(.caption2)
                    .fontWeight(.medium)
                    .lineLimit(1)
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(6)
    }
}

struct InfoCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.caption)
                Spacer()
            }
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(1)
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}

struct TimeInfoRow: View {
    let icon: String
    let title: String
    let date: Date
    let color: Color
    
    private var formatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter
    }
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 16)
            
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(formatter.string(from: date))
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .padding(.vertical, 4)
    }
}

struct StackFrameView: View {
    let index: Int
    let frame: CrashLogThread.Frame
    let appProcessName: String
    let isCrashedFrame: Bool
    let isFileFound: Bool
    let onFileClick: (String, Int?) -> Void
    
    private var isAppFrame: Bool {
        frame.processName.contains(appProcessName) || appProcessName.contains(frame.processName)
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Frame index with background
            Text("\(index)")
                .font(.system(.caption, design: .monospaced))
                .fontWeight(.medium)
                .foregroundColor(.white)
                .frame(width: 20, height: 20)
                .background(
                    Circle()
                        .fill(isAppFrame ? Color.accentColor : Color.secondary.opacity(0.6))
                )
                .padding(.top, 2)
            
            VStack(alignment: .leading, spacing: 6) {
                // Process name and file info
                HStack(spacing: 8) {
                    Text(frame.processName)
                        .font(.system(.caption, design: .monospaced))
                        .fontWeight(isAppFrame ? .bold : .semibold)
                        .foregroundColor(isAppFrame ? .accentColor : .primary)
                    
                    Spacer()
                    
                    // Combined filename and line number
                    if let fileName = frame.fileName, !fileName.isEmpty {
                        Button(action: {
                            onFileClick(fileName, frame.lineNumber)
                        }) {
                            HStack(spacing: 4) {
                                // Show copy icon if file is not found, otherwise show document icon
                                Image(systemName: isFileFound ? "doc.text" : "doc.on.doc.fill")
                                    .font(.system(.caption2))
                                    .foregroundColor(isFileFound ? .secondary : .orange)
                                
                                HStack(spacing: 2) {
                                    Text(fileName)
                                        .font(.system(.caption2, design: .monospaced))
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                    
                                    if let lineNumber = frame.lineNumber {
                                        Text(":\(lineNumber)")
                                            .font(.system(.caption2, design: .monospaced))
                                            .fontWeight(.medium)
                                            .foregroundColor(.orange)
                                    }
                                }
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(isFileFound ? Color.secondary.opacity(0.1) : Color.orange.opacity(0.1))
                            )
                        }
                        .buttonStyle(.plain)
                        .onHover { isHovering in
                            // Optional: Add hover effect
                        }
                    } else if let lineNumber = frame.lineNumber {
                        // Show just line number if no filename
                        HStack(spacing: 2) {
                            Image(systemName: "number")
                                .font(.system(.caption2))
                                .foregroundColor(.orange)
                            
                            Text("\(lineNumber)")
                                .font(.system(.caption2, design: .monospaced))
                                .fontWeight(.medium)
                                .foregroundColor(.orange)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.orange.opacity(0.1))
                        )
                    }
                }
                
                // Function symbol
                Text(frame.symbol)
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundColor(isAppFrame ? .primary : .secondary)
                
                // Additional context line if it's a crashed frame
                if isCrashedFrame {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption2)
                            .foregroundColor(.red)
                        
                        Text("Crash point")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.red)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.red.opacity(0.1))
                            .stroke(Color.red.opacity(0.3), lineWidth: 0.5)
                    )
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    isAppFrame ? Color.accentColor.opacity(0.08) :
                        isCrashedFrame ? Color.red.opacity(0.05) :
                        Color.clear
                )
                .stroke(
                    isAppFrame ? Color.accentColor.opacity(0.2) :
                        isCrashedFrame ? Color.red.opacity(0.2) :
                        Color.clear,
                    lineWidth: isAppFrame || isCrashedFrame ? 1 : 0
                )
        )
        .padding(.horizontal, 16)
        .padding(.vertical, 2)
    }
}
