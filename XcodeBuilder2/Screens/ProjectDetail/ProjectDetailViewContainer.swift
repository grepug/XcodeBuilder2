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
    @SharedReader private var versionStrings: [String]
    @SharedReader private var builds: [BuildModelValue]
    @SharedReader private var schemes: [SchemeValue]
    
    @Environment(EntryViewModel.self) private var entryVM
    
    @State private var tabSelection = ProjectDetailTab.overview
    @State private var versionSelection: String? = nil
    
    init(id: String) {
        self.id = id
        _project = .init(wrappedValue: nil, .project(id: id))
        _versionStrings = .init(wrappedValue: [], .buildVersionStrings(projectId: id))
        _builds = .init(wrappedValue: [], .latestBuilds(projectId: id, limit: 100))
        _schemes = .init(wrappedValue: [], .schemes(projectId: id))
    }
    
    var body: some View {
        @Bindable var entryVM = entryVM
        
        ProjectDetailView(
            project: project ?? .init(),
            schemes: schemes,
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
