//
//  ProjectDetailView.swift
//  XcodeBuilder2
//
//  Created by Kai Shao on 2025/7/14.
//

import SwiftUI
import Core
import SharingGRDB

struct ProjectDetailViewContainer: View {
    var id: String
    
    @Fetch var fetchedValue: ProjectDetailRequest.Result?
    
    var item: Project {
        fetchedValue?.project ?? Project(displayName: "Loading...")
    }
    
    var builds: [BuildModel] {
        fetchedValue?.builds ?? []
    }
    
    init(id: String) {
        self.id = id
    }
    
    var body: some View {
        ProjectDetailView(
            project: item,
            builds: builds,
            schemes: fetchedValue?.schemes ?? []
        )
        .task(id: id) {
            try! await $fetchedValue.load(ProjectDetailRequest(id: id))
        }
    }
}

struct ProjectDetailView: View {
    var project: Project
    var builds: [BuildModel]
    var schemes: [Scheme] = []
    
    var body: some View {
        List {
            ForEach(builds) { build in
                buildItemView(for: build)
            }
        }
    }
    
    func buildItemView(for build: BuildModel) -> some View {
        HStack {
            Image(systemName: "hammer")
                .foregroundStyle(.secondary)
                .imageScale(.large)
            
            Text(schemeName(for: build))
                .font(.headline)
            
            Spacer()
            
            status(for: build)
                .foregroundStyle(.secondary)
        }
    }
    
    var formatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }
    
    @ViewBuilder
    func status(for build: BuildModel) -> some View {
        if let start = build.start_date {
            Text("Started at \(formatter.string(from: start))")
        }
        
        if let end = build.end_date {
            Text("Ended at \(formatter.string(from: end))")
            
            let duration = end.timeIntervalSince(build.start_date!)
            
            Text("Duration: \(Int(duration)) seconds")
        }
    }
    
    func schemeName(for build: BuildModel) -> String {
        if let scheme = schemes.first(where: { $0.id == build.scheme_id }) {
            return scheme.name
        }
        
        return "Unknown Scheme"
    }
}

struct ProjectDetailRequest: SharingGRDB.FetchKeyRequest {
    var id: String
    
    struct Result {
        let project: Project
        let builds: [BuildModel]
        let schemes: [Scheme]
    }
    
    func fetch(_ db: Database) throws -> Result? {
        guard var project = (try ProjectModel.where { $0.bundle_identifier == id }
            .fetchOne(db)?
            .toProject()) else {
                return nil
            }
        
        let builds = try BuildModel
            .join(SchemeModel.where { $0.project_bundle_identifier == id }, on: { $0.0.scheme_id == $0.1.id })
            .where { a, b in b.project_bundle_identifier == id }
            .fetchAll(db)
            .map { $0.0 }
        
        let schemes = try SchemeModel
            .where { $0.project_bundle_identifier == id }
            .fetchAll(db)
            .map { $0.toScheme() }
            .sorted()
        
        project.schemes = schemes
        
        return .init(project: project, builds: builds, schemes: schemes)
    }
}
