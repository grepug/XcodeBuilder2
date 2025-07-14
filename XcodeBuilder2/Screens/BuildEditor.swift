//
//  BuildEditor.swift
//  XcodeBuilder2
//
//  Created by Kai Shao on 2025/7/14.
//

import SwiftUI
import Core
import SharingGRDB

struct BuildEditorContainer: View {
    var projectId: String
    
    @State private var buildModel = BuildModel()
    @State private var versions: [Version] = []
    @State private var versionSelection: Version?
    
    @Fetch var fetchedValue: ProjectDetailRequest.Result?
    
    @Environment(BuildManager.self) private var buildManager
    
    var project: Project {
        fetchedValue?.project ?? Project(displayName: "Loading...")
    }
    
    var body: some View {
        BuildEditor(
            project: project,
            build: $buildModel,
            versions: versions,
            versionSelection: $versionSelection,
        ) {
            guard let version = versionSelection else {
                return
            }
            
            guard let schemeName = project.schemes.first(where: { $0.id == buildModel.scheme_id })?.name else {
                return
            }
            
            Task {
                await buildManager.createJob(
                    payload: .init(
                        project: project,
                        schemeName: schemeName,
                        version: version,
                        exportOptions: buildModel.exportOptions,
                    ),
                    buildModel: buildModel,
                )
            }
        }
        .task(id: project) {
            if !project.bundleIdentifier.isEmpty {
                versions = try! await GitCommand.fetchVersions(remoteURL: project.gitRepoURL)
            }
        }
        .task(id: projectId) {
            try! await $fetchedValue.load(ProjectDetailRequest(id: projectId))
        }
    }
}

struct BuildEditor: View {
    var project: Project
    @Binding var build: BuildModel
    var versions: [Version]
    @Binding var versionSelection: Version?
    
    @Dependency(\.xcodeBuildPathManager) var pathManager
    
    var action: (() -> Void)?
    
    var platforms: [Platform]? {
        project.schemes.first(where: { $0.id == build.scheme_id })?.platforms
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
        guard let scheme = project.schemes.first(where: { $0.id == build.scheme_id }) else {
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
            projectPath: pathManager.xcodeprojPath(for: project, version: version),
            archivePath: pathManager.archivePath(for: project, version: version),
            derivedDataPath: pathManager.derivedDataPath(for: project, version: version),
            exportPath: nil
        ).string
    }
    
    var body: some View {
        Form {
            Section {
                Picker("Version:", selection: $versionSelection) {
                    ForEach(sortedVersions, id: \.self) { item in
                        Text("\(item.version) (\(item.buildNumber))")
                            .tag(item)
                    }
                    
                    Text("Select Version")
                        .tag(nil as Version?)
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
            
            if let string = xcodeBuildCommandString {
                Divider()
                    .padding(.vertical)
                
                Section {
                    LabeledContent {
                        Text(string)
                    } label: {
                        Text("Command:")
                    }
                }
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
