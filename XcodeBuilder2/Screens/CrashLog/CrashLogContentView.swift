//
//  CrashLogContentView.swift
//  XcodeBuilder2
//
//  Created by Kai Shao on 2025/7/18.
//

import SwiftUI
import Core
import SharingGRDB

#if canImport(AppKit)
import AppKit
#endif

struct CrashLogContentViewContainer: View {
    let id: String
    
    @FetchOne var fetchedCrashLog: CrashLog?
    @State private var crashLog: CrashLog = .init()
    
    var body: some View {
        CrashLogContentView(crashLog: $crashLog)
            .task(id: id) {
                try! await $fetchedCrashLog.load(
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
                
                guard crashLog.id == id else {
                    return
                }
                
                guard crashLog != .init() else {
                    return
                }
                
                @Dependency(\.defaultDatabase) var db
                
                try! await db.write {
                    try CrashLog
                        .where { $0.incidentIdentifier == id }
                        .update {
                            $0.priority = crashLog.priority
                            $0.note = crashLog.note
                            $0.fixed = crashLog.fixed
                        }
                        .execute($0)
                }
            }
    }
}

struct CrashLogContentView: View {
    @Binding var crashLog: CrashLog
    @State private var selectedThreadNumber: Int?
    @State private var showCopyFeedback = false
    
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
                                        isCrashedFrame: selectedThread.isCrashed && index == 0
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
                    Picker("Priority", selection: $crashLog.priority) {
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
    
    private var isAppFrame: Bool {
        frame.processName.contains(appProcessName) || appProcessName.contains(frame.processName)
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("\(index)")
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.secondary)
                .frame(width: 25, alignment: .trailing)
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Text(frame.processName)
                        .font(.system(.caption, design: .monospaced))
                        .fontWeight(isAppFrame ? .semibold : .regular)
                        .foregroundColor(isAppFrame ? .accentColor : .primary)
                    
                    Spacer()
                }
                
                Text(frame.symbol)
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(
                    isAppFrame ? Color.accentColor.opacity(0.1) :
                        Color.clear
                )
        )
        .padding(.horizontal, 20)
        .padding(.vertical, 4)
    }
}
