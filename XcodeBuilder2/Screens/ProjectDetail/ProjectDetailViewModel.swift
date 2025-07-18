//
//  ProjectDetailViewModel.swift
//  XcodeBuilder2
//
//  Created by Kai Shao on 2025/7/18.
//

import SwiftUI
import Core
import SharingGRDB

struct BuildIdsAndVersionStringRequest: SharingGRDB.FetchKeyRequest {
    typealias Value = [String: [UUID]]
    
    let projectId: String
    var versionString: String?
    
    func fetch(_ db: Database) throws -> Value {
        let schemes = try Scheme
            .where { $0.projectBundleIdentifier == projectId }
            .fetchAll(db)
        
        let schemeIds = schemes.map(\.id)
        
        let builds = try BuildModel
            .where { $0.schemeId.in(schemeIds) }
            .where {
                if let versionString {
                    $0.versionString == versionString
                } else {
                    true
                }
            }
            .order { $0.createdAt.desc() }
            .fetchAll(db)
        
        var result: [String: [UUID]] = [:]
        
        for build in builds {
            let versionString = build.versionString
            result[versionString, default: []].append(build.id)
        }
        
        return result
    }
}

@Observable
@MainActor
class ProjectDetailViewModel {
    @ObservationIgnored @FetchOne var project: Project?
    @ObservationIgnored @FetchAll var schemes: [Scheme] = []
    @ObservationIgnored @FetchAll var builds: [BuildModel] = []
    
    var versionSelection: String?
    
    func loadData(projectId: String) async {
        try! await $project.load(Project.where { $0.bundleIdentifier == projectId }, animation: .default)
        try! await $schemes.load(Scheme.where { $0.projectBundleIdentifier == projectId }, animation: .default)
    }
    
    func loadBuilds(projectId: String) async {
        try! await $builds.load(
            BuildModel
                .where { $0.schemeId.in(schemes.map(\.id)) }
                .where {
                    if let versionSelection {
                        $0.versionString == versionSelection
                    } else {
                        true
                    }
                }
                .order { $0.buildNumber.desc() }
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
                await vm.loadBuilds(projectId: projectId)
            }
    }
}
