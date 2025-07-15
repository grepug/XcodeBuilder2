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
    @State private var showingError: LocalizedError?
    
    @Fetch var fetchedValue: ProjectDetailRequest.Result?
    
    @Environment(BuildManager.self) private var buildManager
    @Environment(EntryViewModel.self) private var entryVM
    
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
        .errorAlert(error: $showingError)
    }
    
    func handleStartBuild() async {
        guard let version = versionSelection else {
            return
        }
        
        guard let scheme = schemes.first(where: { $0.id == buildModel.schemeId }) else {
            return
        }
        
        buildModel.schemeId = scheme.id
        buildModel.versionString = version.version
        buildModel.buildNumber = version.buildNumber
        
        do {
            try await buildManager.createJob(
                payload: .init(
                    project: project,
                    scheme: scheme,
                    version: version,
                    exportOptions: buildModel.exportOptions,
                    buildId: buildModel.id,
                ),
                buildModel: buildModel,
            )
            
            dismiss!()
            entryVM.buildSelection = buildModel.id
        } catch {
            showingError = error
        }
    }
}

struct ErrorAlertModifier: ViewModifier {
    @Binding var error: LocalizedError?
    
    func body(content: Content) -> some View {
        content
            .alert(
                "Error",
                isPresented: .init(
                    get: { error != nil },
                    set: { if !$0 { error = nil } }
                ),
            ) {
                Button("OK", role: .cancel) {
                    error = nil
                }
            } message: {
                Text(error?.localizedDescription ?? "An unknown error occurred.")
            }
    }
}

extension View {
    func errorAlert(error: Binding<LocalizedError?>) -> some View {
        self.modifier(ErrorAlertModifier(error: error))
    }
}
