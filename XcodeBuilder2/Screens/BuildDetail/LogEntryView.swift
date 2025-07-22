//
//  LogEntryView.swift
//  XcodeBuilder2
//
//  Created by Kai Shao on 2025/7/15.
//

import SwiftUI
import Core

struct LogEntryView: View {
    let log: BuildLogValue
    
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
