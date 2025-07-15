//
//  BuildEditor.swift
//  XcodeBuilder2
//
//  Created by Kai Shao on 2025/7/14.
//

import SwiftUI
import Core
import SharingGRDB

struct BuildEditor: View {
    var project: Project
    var schemes: [Scheme]
    @Binding var build: BuildModel
    var versions: [Version]
    @Binding var versionSelection: Version?
    
    @Dependency(\.xcodeBuildPathManager) var pathManager
    
    var action: (() -> Void)?
    
    var platforms: [Platform]? {
        schemes.first(where: { $0.id == build.schemeId })?.platforms
    }
    
    var platformString: String {
        platforms?.map { $0.rawValue }.joined(separator: ", ") ?? "-"
    }
    
    var disabled: Bool {
        xcodeBuildCommandString == nil || build.exportOptions.isEmpty
    }
    
    var sortedVersions: [Version] {
        versions.sorted().reversed()
    }
    
    var xcodeBuildCommandString: String? {
        guard let scheme = schemes.first(where: { $0.id == build.schemeId }) else {
            return nil
        }
        
        guard let version = versionSelection else {
            return nil
        }
        
        guard let platform = scheme.platforms.first else {
            return nil
        }
        
        return XcodeBuildCommand(
            kind: .archive,
            scheme: scheme,
            version: version,
            platform: platform,
            exportOption: nil,
            projectURL: pathManager.xcodeprojURL(for: project, version: version),
            archiveURL: pathManager.archiveURL(for: project, version: version),
            derivedDataURL: pathManager.derivedDataURL(for: project, version: version),
            exportURL: nil
        ).string
    }
    
    var body: some View {
        Form {
            Section {
                Picker("Version:", selection: $versionSelection) {
                    ForEach(sortedVersions, id: \.self) { item in
                        Text(item.tagName)
                            .tag(item)
                    }
                    
                    Text("Select Version")
                        .tag(nil as Version?)
                }
                .pickerStyle(.menu)
                .onChange(of: sortedVersions, initial: true) { oldValue, newValue in
                    versionSelection = newValue.first
                }
                
                Picker("Scheme:", selection: $build.schemeId) {
                    ForEach(schemes) { scheme in
                        Text(scheme.name)
                            .tag(scheme.id)
                    }
                }
                .pickerStyle(.radioGroup)
                .onChange(of: schemes, initial: true) { oldValue, newValue in
                    if let firstScheme = newValue.first {
                        build.schemeId = firstScheme.id
                    }
                }
                
                LabeledContent {
                    Text(platformString)
                } label: {
                    Text("Build Platforms:")
                }
                
                LabeledContent {
                    MultipleSelectionPicker(
                        items: ExportOption.allCases.sorted(),
                        selection: $build.exportOptions.toSet()
                    ) { item in
                        Text(item.rawValue)
                    }
                } label: {
                    Text("Export Options:")
                }
            } header: {
                Text(project.displayName)
                    .font(.title3.bold())
            }
            
            Divider()
                .padding(.vertical)
            
            Button("Start Build") {
                action?()
            }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut(.defaultAction)
            .disabled(disabled)
        }
        .padding()
    }
}

#Preview {
    @Previewable @State var project = Project(
        displayName: "Example Project",
    )
    
    @Previewable @State var schemes: [Scheme] = [
        .init(name: "Beta", platforms: [.iOS, .macOS]),
        .init(name: "Release", platforms: [.iOS]),
    ]
    
    @Previewable @State var build = BuildModel()
    
    @Previewable @State var versionSelection: Version?
    
    BuildEditor(
        project: project,
        schemes: schemes,
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
