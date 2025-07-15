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
        HStack {
            VStack {
                HStack {
                    Image(systemName: "hammer.fill")
                        .foregroundStyle(build.status.color)
                        .imageScale(.large)

                    VStack(alignment: .leading) {
                        Text(schemeName(for: build))
                            .font(.title3.bold())
                        Text(build.status.title)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Spacer()
            
            status(for: build)
                .foregroundStyle(.secondary)
        }
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
            status: .running
        ),
        schemes: [
            scheme,
        ]
    )
    .padding()
}
