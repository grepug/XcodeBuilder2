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
        if let start = build.startDate {
            Text("Started at \(formatter.string(from: start))")
        }
        
        if let end = build.endDate {
            Text("Ended at \(formatter.string(from: end))")
            
            let duration = end.timeIntervalSince(build.startDate!)
            
            Text("Duration: \(Int(duration)) seconds")
        }
    }
    
    func schemeName(for build: BuildModel) -> String {
        if let scheme = schemes.first(where: { $0.id == build.schemeId }) {
            return scheme.name
        }
        
        return "Unknown Scheme"
    }
}
