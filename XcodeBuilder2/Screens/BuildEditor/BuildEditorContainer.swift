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
    
    enum Tab: String, CaseIterable {
        case branch = "Branch"
        case version = "Version"
    }
    
    @State private var buildModel = BuildModel(exportOptions: [.appStore])
    @State private var versions: [Version] = []
    @State private var branches: [GitBranch] = []
    @State private var versionSelection: Version?
    @State private var branchSelection: GitBranch?
    @State private var showingError: LocalizedError?
    @State private var selectedTab: Tab = .branch
    
    @Fetch var fetchedValue: ProjectDetailRequest.Result?
    
    @Environment(BuildManager.self) private var buildManager
    @Environment(EntryViewModel.self) private var entryVM
    
    var project: Project {
        fetchedValue?.project ?? Project(displayName: "Loading...")
    }
    
    var schemes: [Scheme] {
        fetchedValue?.schemes ?? []
    }

    var loading: Bool {
        versions.isEmpty
    }
    
    var body: some View {
        BuildEditor(
            project: project,
            schemes: schemes,
            build: $buildModel,
            versions: versions,
            branches: branches,
            versionSelection: $versionSelection,
            branchSelection: $branchSelection,
            tabSelection: $selectedTab
        ) {
            Task {
                await handleStartBuild()
            }
        }
        .opacity(loading ? 0 : 1)
        .overlay {
            if loading {
                ProgressView("Loading versions...")
            }
        }
        .task(id: project) {
            if !project.bundleIdentifier.isEmpty {
                versions = try! await GitCommand.fetchVersions(remoteURL: project.gitRepoURL)
                branches = try! await GitCommand.fetchBranches(remoteURL: project.gitRepoURL)
            }
        }
        .task(id: projectId) {
            try! await $fetchedValue.load(ProjectDetailRequest(id: projectId))
        }
        .errorAlert(error: $showingError)
    }
    
    func handleStartBuild() async {
        let version: Version
        
        if selectedTab == .version {
            guard let versionSelection = versionSelection else {
                return
            }
            version = versionSelection
        } else {
            guard let branchSelection else {
                return
            }
            
            // Create a version object from branch selection
            version = Version(
                version: branchSelection.name,
                buildNumber: Int(Date().timeIntervalSince1970),
                commitHash: branchSelection.commitHash,
                branchName: branchSelection.name
            )
        }
        
        guard let scheme = schemes.first(where: { $0.id == buildModel.schemeId }) else {
            return
        }
        
        buildModel.schemeId = scheme.id
        buildModel.versionString = version.version
        buildModel.buildNumber = version.buildNumber
        buildModel.commitHash = version.commitHash
        
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
