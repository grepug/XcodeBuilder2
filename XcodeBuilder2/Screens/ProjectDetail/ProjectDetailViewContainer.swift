//
//  ProjectDetailViewContainer.swift
//  XcodeBuilder2
//
//  Created by Kai Shao on 2025/7/22.
//

import SwiftUI
import Core
import Sharing

struct ProjectDetailViewContainer: View {
    var id: String
    
    @SharedReader private var project: ProjectValue?
    @SharedReader private var schemeIds: [UUID]
    @SharedReader private var versionStrings: [String]
    @SharedReader private var builds: [BuildModelValue]
    
    @Environment(EntryViewModel.self) private var entryVM
    @Environment(BuildManager.self) private var buildManager
    
    @State private var tabSelection = ProjectDetailTab.overview
    @State private var versionSelection: String? = nil
    
    init(id: String) {
        self.id = id
        _project = .init(wrappedValue: nil, .project(id: id))
        _schemeIds = .init(wrappedValue: [], .schemeIds(projectId: id))
        _versionStrings = .init(wrappedValue: [], .buildVersionStrings(projectId: id))
        _builds = .init(wrappedValue: [], .latestBuilds(projectId: id, limit: 100))
    }
    
    var body: some View {
        @Bindable var entryVM = entryVM
        
        ProjectDetailView(
            project: project ?? .init(),
            // TODO: Fetch schemes from the database
            schemes: [],
            builds: builds,
            availableVersions: versionStrings,
            versionSelection: $versionSelection,
            tabSelection: $tabSelection,
            buildSelection: $entryVM.buildSelection,
        )
        .onChange(of: tabSelection) { oldValue, newValue in
            if newValue != .overview {
                entryVM.buildSelection = builds.first?.id
            }
        }
    }
}
