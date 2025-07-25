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
    @Binding var version: Version
    var branches: [GitBranch]
    @Binding var versionSelection: Version?
    @Binding var branchSelection: GitBranch?
    @Binding var tabSelection: BuildEditorContainer.Tab
    var errorMessage: String? = nil
    
    @Dependency(\.xcodeBuildPathManager) var pathManager
    
    var action: (() -> Void)?
    
    var platforms: [Platform]? {
        schemes.first(where: { $0.id == build.schemeId })?.platforms
    }
    
    var platformString: String {
        platforms?.map { $0.rawValue }.joined(separator: ", ") ?? "-"
    }
    
    var disabled: Bool {
        let hasValidSelection = (tabSelection == .version && versionSelection != nil) || 
                               (tabSelection == .branch && branchSelection != nil)
        return !hasValidSelection || build.exportOptions.isEmpty || errorMessage != nil
    }
    
    var sortedVersions: [Version] {
        versions.sorted().reversed()
    }
    
    var body: some View {
        Form {
            Section {
                // Segment picker for Branch/Version selection
                Picker("Selection Mode:", selection: $tabSelection) {
                    ForEach(BuildEditorContainer.Tab.allCases, id: \.self) { tab in
                        Text(tab.rawValue)
                            .tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.bottom, 8)
                
                // Branch or Version picker based on selection
                if tabSelection == .branch {
                    Picker("Branch:", selection: $branchSelection) {
                        ForEach(branches, id: \.name) { branch in
                            Text("\(branch.name) (\(String(branch.commitHash.prefix(8))))")
                                .tag(branch as GitBranch?)
                        }
                        
                        Text("Select Branch")
                            .tag(nil as GitBranch?)
                    }
                    .pickerStyle(.menu)
                    .onChange(of: branches, initial: true) { oldValue, newValue in
                        if branchSelection == nil {
                            branchSelection = newValue.first
                        }
                    }
                    
                    TextField("Version:", text: $version.version)
                    TextField("Build Number:", value: $version.buildNumber, format: .number)
                    LabeledContent("Commit Hash:", value: version.commitHash.prefix(6))
                } else {
                    Picker("Version:", selection: $versionSelection) {
                        ForEach(sortedVersions, id: \.self) { item in
                            Text(item.displayString)
                                .tag(item)
                        }
                        
                        Text("Select Version")
                            .tag(nil as Version?)
                    }
                    .pickerStyle(.menu)
                    .onChange(of: sortedVersions, initial: true) { oldValue, newValue in
                        if versionSelection == nil {
                            versionSelection = newValue.first
                        }
                    }
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
            
            if let errorMessage {
                Section {
                    LabeledContent("Error:", value: errorMessage)
                }
            }
            
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
    
    @Previewable @State var branchSelection: GitBranch?
    
    @Previewable @State var tabSelection: BuildEditorContainer.Tab = .version
    
    BuildEditor(
        project: project,
        schemes: schemes,
        build: $build,
        versions: [
            .init(version: "1.0.0", buildNumber: 0),
            .init(version: "1.1.0", buildNumber: 1),
            .init(version: "1.2.0", buildNumber: 2),
        ],
        version: .constant(.init()),
        branches: [
            .init(name: "main", commitHash: "abc123"),
            .init(name: "develop", commitHash: "def456"),
        ],
        versionSelection: $versionSelection,
        branchSelection: $branchSelection,
        tabSelection: $tabSelection
    )
    .frame(width: 500, height: 400)
}
