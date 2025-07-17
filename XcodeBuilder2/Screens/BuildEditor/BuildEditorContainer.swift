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
        buildModel.deviceMetadata = getCurrentDeviceMetadata()
        
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
    
    func getCurrentDeviceMetadata() -> DeviceMetadata {
        return DeviceMetadata(
            model: getDeviceModel(),
            osVersion: getOSVersion(),
            memory: getMemoryInGB(),
            processor: getProcessorInfo()
        )
    }
    
    private func getDeviceModel() -> String {
        var size = 0
        sysctlbyname("hw.model", nil, &size, nil, 0)
        var machine = [CChar](repeating: 0, count: size)
        sysctlbyname("hw.model", &machine, &size, nil, 0)
        return String(cString: machine)
    }
    
    private func getOSVersion() -> String {
        let version = ProcessInfo.processInfo.operatingSystemVersion
        return "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
    }
    
    private func getMemoryInGB() -> Int {
        var size: size_t = MemoryLayout<UInt64>.size
        var result: UInt64 = 0
        let ret = sysctlbyname("hw.memsize", &result, &size, nil, 0)
        
        if ret == 0 {
            // Convert bytes to GB and round to nearest GB
            let memoryInGB = Double(result) / (1024 * 1024 * 1024)
            return Int(round(memoryInGB))
        }
        
        return 0
    }
    
    private func getProcessorInfo() -> String {
        var size = 0
        sysctlbyname("machdep.cpu.brand_string", nil, &size, nil, 0)
        var machine = [CChar](repeating: 0, count: size)
        sysctlbyname("machdep.cpu.brand_string", &machine, &size, nil, 0)
        let brandString = String(cString: machine)
        
        // If brand string is empty or not available, try alternative approach
        if brandString.isEmpty {
            // For Apple Silicon Macs, try to get the CPU name
            size = 0
            sysctlbyname("hw.targettype", nil, &size, nil, 0)
            var targetType = [CChar](repeating: 0, count: size)
            sysctlbyname("hw.targettype", &targetType, &size, nil, 0)
            let target = String(cString: targetType)
            
            if target.contains("Mac") {
                // Try to determine if it's Apple Silicon
                size = 0
                sysctlbyname("hw.optional.arm64", nil, &size, nil, 0)
                if size > 0 {
                    var isArm: UInt32 = 0
                    size = MemoryLayout<UInt32>.size
                    let ret = sysctlbyname("hw.optional.arm64", &isArm, &size, nil, 0)
                    if ret == 0 && isArm == 1 {
                        // Get the specific Apple Silicon chip
                        size = 0
                        sysctlbyname("hw.perflevel0.name", nil, &size, nil, 0)
                        if size > 0 {
                            var chipName = [CChar](repeating: 0, count: size)
                            sysctlbyname("hw.perflevel0.name", &chipName, &size, nil, 0)
                            let chip = String(cString: chipName)
                            return "Apple \(chip)"
                        }
                        return "Apple Silicon"
                    }
                }
            }
            
            return "Unknown Processor"
        }
        
        return brandString
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
