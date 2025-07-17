//
//  ProjectDetailViewModel.swift
//  XcodeBuilder2
//
//  Created by Kai Shao on 2025/7/18.
//

import SwiftUI
import Core
import SharingGRDB

@Observable
@MainActor
class ProjectDetailViewModel {
    @ObservationIgnored @FetchOne var project: Project?
    @ObservationIgnored @FetchAll var buildIds: [UUID] = []
    @ObservationIgnored @FetchAll var schemes: [Scheme] = []
    
    func loadData(projectId: String) async {
        try! await $project.load(Project.where { $0.bundleIdentifier == projectId }, animation: .default)
        try! await $schemes.load(Scheme.where { $0.projectBundleIdentifier == projectId }, animation: .default)
    }
    
    func loadBuildIds(projectId: String, versionString: String? = nil) async {
        try! await $buildIds.load(
            BuildModel
                .where { $0.schemeId.in(schemes.map(\.id)) }
                .where {
                    if let string = versionString {
                        $0.versionString == string
                    } else {
                        true
                    }
                }
                .order { $0.createdAt.desc() }
                .select(\.id)
        )
    }
}

struct ProjectDetailViewModifier: ViewModifier {
    var projectId: String
    var versionString: String?
    
    @State private var vm = ProjectDetailViewModel()
    
    func body(content: Content) -> some View {
        content
            .environment(vm)
            .task(id: projectId) {
                await vm.loadData(projectId: projectId)
            }
            .task(id: vm.schemes) {
                await vm.loadBuildIds(projectId: projectId, versionString: versionString)
            }
    }
}
