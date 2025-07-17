//
//  BuildItemView.swift
//  XcodeBuilder2
//
//  Created by Kai Shao on 2025/7/15.
//

import SwiftUI
import Core
import SharingGRDB

struct BuildItemViewContainer: View {
    var id: UUID
    
    @State @FetchOne var build: BuildModel?
    @State @FetchOne var scheme: Scheme?
    
    @Environment(BuildManager.self) private var buildManager
    
    var body: some View {
        BuildItemView(
            build: build ?? .init(),
            scheme: scheme ?? .init(),
        )
        .task(id: id) {
            try! await $build.wrappedValue.load(BuildModel.where { $0.id == id })
        }
        .task(id: build?.schemeId) {
            guard let schemeId = build?.schemeId else { return }
            try! await $scheme.wrappedValue.load(Scheme.where { $0.id == schemeId })
        }
        .contextMenu {
            if build?.status == .running {
                Button("Cancel", action: {
                    buildManager.cancelBuild(id: id)
                })
            }
            
            if let build, let scheme {
                Button("Delete", role: .destructive) {
                    buildManager.deleteBuild(build, scheme: scheme)
                }
            }
        }
    }
}

struct BuildItemView: View {
    var build: BuildModel
    var scheme: Scheme
    
    var body: some View {
        HStack(spacing: 12) {
            // Progress circle
            BuildProgressCircle(build: build, size: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(scheme.name)
                    .font(.headline)
                
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
                
                Text(build.version.displayString)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            status(for: build)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
    
    var formatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }
    
    func status(for build: BuildModel) -> some View {
        VStack(alignment: .trailing, spacing: 4) {
            // Time info
            if let start = build.startDate {
                if let end = build.endDate {
                    // Completed or Failed build
                    VStack(alignment: .trailing, spacing: 2) {
                        let statusText = build.status == .failed ? "Failed At:" : "Finished At:"
                        Text(statusText)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        
                        Text(formatter.string(from: end))
                            .font(.caption)
                            .foregroundStyle(.primary)
                        
                        Text("Time Used:")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        
                        let duration = end.timeIntervalSince(start)
                        Text(formatDuration(duration))
                            .font(.caption)
                            .foregroundStyle(.primary)
                    }
                } else {
                    // Running build
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Started At:")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        
                        Text(formatter.string(from: start))
                            .font(.caption)
                            .foregroundStyle(.primary)
                        
                        Text("Time Used:")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        
                        Text(timeAgo(from: start))
                            .font(.caption)
                            .foregroundStyle(.primary)
                    }
                }
            } else {
                // Queued build
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Created At:")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    
                    Text(formatter.string(from: build.createdAt))
                        .font(.caption)
                        .foregroundStyle(.primary)
                    
                    Text(timeAgo(from: build.createdAt))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .multilineTextAlignment(.trailing)
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
    
    private func timeAgo(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        let minutes = Int(interval) / 60
        let hours = minutes / 60
        let days = hours / 24
        
        if days > 0 {
            return "\(days)d ago"
        } else if hours > 0 {
            return "\(hours)h ago"
        } else if minutes > 0 {
            return "\(minutes)m ago"
        } else {
            return "now"
        }
    }
}

#Preview {
    @Previewable @State var scheme = Scheme(name: "Beta", platforms: [.iOS, .macOS])
    
    VStack(spacing: 16) {
        BuildItemView(
            build: .init(
                id: UUID(),
                schemeId: scheme.id,
                version: .init(version: "1.2.0", buildNumber: 42, commitHash: "xxx"),
                createdAt: Date().addingTimeInterval(-7200), // 2 hours ago
                startDate: Date().addingTimeInterval(-3600), // 1 hour ago
                endDate: Date().addingTimeInterval(-3540), // 1 hour ago (60s duration)
                exportOptions: [.appStore],
                status: .completed,
                deviceMetadata: .init(),
            ),
            scheme: scheme
        )
        
        BuildItemView(
            build: .init(
                id: UUID(),
                schemeId: scheme.id,
                version: .init(version: "1.2.0", buildNumber: 42, commitHash: "xxx"),
                createdAt: Date().addingTimeInterval(-1800), // 30 minutes ago
                startDate: Date().addingTimeInterval(-900), // 15 minutes ago
                endDate: nil,
                exportOptions: [.appStore, .releaseTesting],
                status: .running,
                progress: 0.45
            ),
            scheme: scheme
        )
        
        BuildItemView(
            build: .init(
                id: UUID(),
                schemeId: scheme.id,
                version: .init(version: "1.2.0", buildNumber: 42, commitHash: "xxx"),
                createdAt: Date().addingTimeInterval(-300), // 5 minutes ago
                startDate: nil,
                endDate: nil,
                exportOptions: [.appStore],
                status: .queued
            ),
            scheme: scheme
        )
        
        BuildItemView(
            build: .init(
                id: UUID(),
                schemeId: scheme.id,
                version: .init(version: "1.2.0", buildNumber: 42, commitHash: "xxx"),
                createdAt: Date().addingTimeInterval(-5400), // 1.5 hours ago
                startDate: Date().addingTimeInterval(-4800), // 1.3 hours ago
                endDate: Date().addingTimeInterval(-4740), // 1.3 hours ago (60s duration)
                exportOptions: [.appStore],
                status: .failed
            ),
            scheme: scheme
        )
    }
    .padding()
}
