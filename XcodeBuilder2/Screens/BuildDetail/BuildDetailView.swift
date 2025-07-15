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
    
    var build: BuildModel {
        fetchedBuild ?? .init(id: buildId)
    }
    
    var body: some View {
        BuildDetailView(
            build: build,
        )
        .task(id: buildId) {
            try! await $fetchedBuild.load(BuildModel.where { $0.id == buildId })
        }
    }
}

struct BuildDetailView: View {
    var build: BuildModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header Section
                buildHeader
                
                Divider()
                
                // Build Information
                buildInfo
                
                Divider()
                
                // Version Information
                versionInfo
                
                Divider()
                
                // Export Options
                exportOptionsSection
                
                Divider()
                
                // Timestamps
                timestampsSection
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("Build Details")
//        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var buildHeader: some View {
        HStack {
            Image(systemName: "hammer.fill")
                .foregroundStyle(build.status.color)
                .imageScale(.large)
                .font(.title)
            
            VStack(alignment: .leading) {
                Text("Build \(build.buildNumber)")
                    .font(.title2.bold())
                
                HStack {
                    Text(build.status.title)
                        .font(.subheadline)
                        .foregroundStyle(build.status.color)
                    
                    Circle()
                        .fill(build.status.color)
                        .frame(width: 8, height: 8)
                }
            }
            
            Spacer()
        }
    }
    
    private var buildInfo: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Build Information")
                .font(.headline)
            
            InfoRow(label: "Build ID", value: build.id.uuidString)
            InfoRow(label: "Scheme ID", value: build.schemeId.uuidString)
            InfoRow(label: "Status", value: build.status.title)
        }
    }
    
    private var versionInfo: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Version Information")
                .font(.headline)
            
            InfoRow(label: "Version", value: build.versionString)
            InfoRow(label: "Build Number", value: String(build.buildNumber))
            InfoRow(label: "Full Version", value: "\(build.versionString) (\(build.buildNumber))")
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
            versionString: "1.2.0",
            buildNumber: 42,
            createdAt: Date().addingTimeInterval(-3600),
            startDate: Date().addingTimeInterval(-1800),
            endDate: Date().addingTimeInterval(-300),
            exportOptions: [.appStore, .releaseTesting],
            status: .completed
        )
    )
}
