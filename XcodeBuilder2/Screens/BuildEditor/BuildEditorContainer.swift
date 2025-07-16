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
    @State private var version: Version = .init()
    @State private var branchSelection: GitBranch?
    @State private var showingError: LocalizedError?
    @State private var selectedTab: Tab = .branch
    
    @Shared(.appStorage("saved_branch_name")) private var savedBranchName: String?
    
    @State private var errorMessage: String?
    
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
        versions.isEmpty || branches.isEmpty
    }
    
    var body: some View {
        BuildEditor(
            project: project,
            schemes: schemes,
            build: $buildModel,
            versions: versions,
            version: $version,
            branches: branches,
            versionSelection: $versionSelection,
            branchSelection: $branchSelection,
            tabSelection: $selectedTab,
            errorMessage: errorMessage,
        ) {
            Task {
                await handleStartBuild()
            }
        }
        .opacity(loading ? 0 : 1)
        .overlay {
            if loading {
                ProgressView("Loading...")
            }
        }
        .task(id: project) {
            if !project.bundleIdentifier.isEmpty {
                async let a = try! GitCommand.fetchVersions(remoteURL: project.gitRepoURL)
                async let b = try! GitCommand.fetchBranches(remoteURL: project.gitRepoURL)
                
                (versions, branches) = await (a, b)
                
                let maxVersion = versions.max() ?? .init()
                version.version = maxVersion.version
                version.buildNumber = maxVersion.buildNumber + 1
                branchSelection = branches.first { $0.name == savedBranchName }
            }
        }
        .onChange(of: branchSelection) { _, newValue in
            if let newValue {
                version.commitHash = newValue.commitHash
                $savedBranchName.withLock { $0 = newValue.name }
            }
        }
        .onChange(of: version) { _, newValue in
            do {
                try newValue.validate()
                errorMessage = nil
            } catch {
                errorMessage = error.localizedDescription
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
            assert(versionSelection != nil, "Version selection should not be nil")
            version = versionSelection!
        } else {
            assert(branchSelection != nil, "Branch selection should not be nil")
            version = self.version
        }
        
        do {
            try version.validate()
        } catch {
            errorMessage = error.localizedDescription
            return
        }
        
        guard let scheme = schemes.first(where: { $0.id == buildModel.schemeId }) else {
            return
        }
        
        buildModel.schemeId = scheme.id
        buildModel.version = version
        
        let gitCloneKind: XcodeBuildPayload.GitCloneKind = if selectedTab == .branch {
            .branch(branchSelection!.name)
        } else {
            .tag
        }
        
        do {
            try await buildManager.createJob(
                payload: .init(
                    project: project,
                    scheme: scheme,
                    build: buildModel,
                    gitCloneKind: gitCloneKind,
                    exportOptions: buildModel.exportOptions,
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
