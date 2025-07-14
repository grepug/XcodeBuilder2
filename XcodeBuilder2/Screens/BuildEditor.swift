//
//  BuildEditor.swift
//  XcodeBuilder2
//
//  Created by Kai Shao on 2025/7/14.
//

import SwiftUI
import Core

struct BuildEditor: View {
    var project: Project
    @Binding var build: BuildModel
    var versions: [Version]
    @Binding var versionSelection: Version?
    
    var action: (() -> Void)?
    
    var platforms: [Platform]? {
        project.schemes.first(where: { $0.id == build.scheme_id })?.platforms
    }
    
    var platformString: String {
        platforms?.map { $0.rawValue }.joined(separator: ", ") ?? "-"
    }
    
    var disabled: Bool {
        platforms == nil ||
        platforms!.isEmpty ||
        versionSelection == nil
    }
    
    var sortedVersions: [Version] {
        versions.sorted().reversed()
    }
    
    var body: some View {
        Form {
            Section {
                Picker("Version:", selection: $versionSelection) {
                    ForEach(sortedVersions, id: \.self) { item in
                        Text("\(item.version) (\(item.buildNumber))")
                            .tag(item)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: sortedVersions, initial: true) { oldValue, newValue in
                    versionSelection = newValue.first
                }
                
                Picker("Scheme:", selection: $build.scheme_id) {
                    ForEach(project.schemes) { scheme in
                        Text(scheme.name)
                            .tag(scheme.id)
                    }
                }
                .pickerStyle(.radioGroup)
                .onChange(of: project.schemes, initial: true) { oldValue, newValue in
                    if let firstScheme = newValue.first {
                        build.scheme_id = firstScheme.id
                    }
                }
                
                LabeledContent {
                    Text(platformString)
                } label: {
                    Text("Build Platforms:")
                }
            } header: {
                Text(project.displayName)
                    .font(.headline)
            }
            
            Divider()
                .padding(.vertical)
            
            Button("Start Build") {
                action?()
            }
            .disabled(disabled)
        }
        .padding()
    }
}

#Preview {
    @Previewable @State var project = Project(
        displayName: "Example Project",
        schemes: [
            .init(name: "Beta", platforms: [.iOS, .macOS]),
            .init(name: "Release", platforms: [.iOS]),
        ]
    )
    @Previewable @State var build = BuildModel()
    
    @Previewable @State var versionSelection: Version?
    
    BuildEditor(
        project: project,
        build: $build,
        versions: [
            .init(version: "1.0.0", buildNumber: 0),
            .init(version: "1.1.0", buildNumber: 1),
            .init(version: "1.2.0", buildNumber: 2),
        ],
        versionSelection: $versionSelection,
    )
    .frame(width: 500, height: 400)
}
