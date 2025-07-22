//
//  CrashLogRow.swift
//  XcodeBuilder2
//
//  Created by Kai Shao on 2025/7/22.
//

import SwiftUI
import Core
import Sharing

struct CrashLogRowContainer: View {
    var id: String
    @SharedReader var crashLog: CrashLogValue?
    
    init(id: String) {
        self.id = id
        _crashLog = .init(wrappedValue: nil, .crashLog(id: id))
    }
    
    
    var body: some View {
        Group {
            if let crashLog {
                CrashLogRow(crashLog: crashLog)
            }
        }
        .task(id: id) {
            try! await $crashLog.load(.crashLog(id: id))
        }
    }
}

struct CrashLogRow: View {
    let crashLog: CrashLogValue
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

private struct DetailRow: View {
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
