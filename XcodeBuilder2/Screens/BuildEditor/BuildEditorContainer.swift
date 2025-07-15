//
//  BuildEditorContainer.swift
//  XcodeBuilder2
//
//  Created by Kai Shao on 2025/7/15.
//

import SwiftUI
import Core
import SharingGRDB

struct BuildEditorContainer: View {
    var projectId: String
    var dismiss: (() -> Void)?
    
    @State private var buildModel = BuildModel()
    @State private var versions: [Version] = []
    @State private var versionSelection: Version?
    
    @Fetch var fetchedValue: ProjectDetailRequest.Result?
    
    @Environment(BuildManager.self) private var buildManager
    
    var project: Project {
        fetchedValue?.project ?? Project(displayName: "Loading...")
    }
    
    var schemes: [Scheme] {
        fetchedValue?.schemes ?? []
    }
    
    var body: some View {
        BuildEditor(
            project: project,
            schemes: schemes,
            build: $buildModel,
            versions: versions,
            versionSelection: $versionSelection,
        ) {
            Task {
                await handleStartBuild()
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
    
    func handleStartBuild() async {
        guard let version = versionSelection else {
            return
        }
        
        guard let scheme = schemes.first(where: { $0.id == buildModel.schemeId }) else {
            return
        }
        
        await buildManager.createJob(
            payload: .init(
                project: project,
                scheme: scheme,
                version: version,
                exportOptions: buildModel.exportOptions,
            ),
            buildModel: buildModel,
        )
        
        dismiss!()
    }
}
