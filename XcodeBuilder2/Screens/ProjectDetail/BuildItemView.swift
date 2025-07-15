//
//  BuildItemView.swift
//  XcodeBuilder2
//
//  Created by Kai Shao on 2025/7/15.
//

import SwiftUI
import Core

struct BuildItemView: View {
    var build: BuildModel
    var schemes: [Scheme]
    
    var body: some View {
        HStack(spacing: 12) {
            // Progress circle
            BuildProgressCircle(build: build, size: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(schemeName(for: build))
                    .font(.headline)
                
                HStack {
                    Text(build.status.title)
                        .font(.subheadline)
                        .foregroundStyle(build.status.color)
                }
                
                Text("\(build.versionString) (\(build.buildNumber))")
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
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }
    
    func status(for build: BuildModel) -> some View {
        HStack {
            VStack {
                if let start = build.startDate {
                    Text("Started at \(formatter.string(from: start))")
                }
                
                if let end = build.endDate {
                    Text("Ended at \(formatter.string(from: end))")
                    
                    let duration = end.timeIntervalSince(build.startDate!)
                    
                    Text("Duration: \(Int(duration)) seconds")
                }
            }
        }
    }
    
    func schemeName(for build: BuildModel) -> String {
        if let scheme = schemes.first(where: { $0.id == build.schemeId }) {
            return scheme.name
        }
        
        return "Unknown Scheme"
    }
}

#Preview {
    @Previewable @State var scheme = Scheme(name: "Beta", platforms: [.iOS, .macOS])
    
    VStack(spacing: 16) {
        BuildItemView(
            build: .init(
                id: UUID(),
                schemeId: scheme.id,
                versionString: "1.0.0",
                buildNumber: 1,
                createdAt: Date(),
                startDate: Date(),
                endDate: Date().addingTimeInterval(60),
                exportOptions: [.appStore],
                status: .completed
            ),
            schemes: [scheme]
        )
        
        BuildItemView(
            build: .init(
                id: UUID(),
                schemeId: scheme.id,
                versionString: "1.2.0",
                buildNumber: 42,
                createdAt: Date(),
                startDate: Date(),
                endDate: nil,
                exportOptions: [.appStore, .releaseTesting],
                status: .running,
                progress: 0.45
            ),
            schemes: [scheme]
        )
        
        BuildItemView(
            build: .init(
                id: UUID(),
                schemeId: scheme.id,
                versionString: "1.1.0",
                buildNumber: 23,
                createdAt: Date(),
                startDate: nil,
                endDate: nil,
                exportOptions: [.appStore],
                status: .queued
            ),
            schemes: [scheme]
        )
    }
    .padding()
}
