//
//  BuildDetailView.swift
//  XcodeBuilder2
//
//  Created by Kai Shao on 2025/7/15.
//

import SwiftUI
import Core
import SharingGRDB

struct BuildDetailViewContainer: View {
    var buildId: UUID
    
    @FetchOne var fetchedBuild: BuildModel?
    
    var build: BuildModel {
        fetchedBuild ?? .init(id: buildId)
    }
    
    var body: some View {
        BuildDetailView(
            build: build,
        )
        .task(id: buildId) {
            try! await $fetchedBuild.load(BuildModel.where { $0.id == buildId })
        }
    }
}

struct BuildDetailView: View {
    var build: BuildModel
    
    var body: some View {
        VStack {
            
        }
    }
}

#Preview {
    BuildDetailView(
        build: .init(
            
        )
    )
}
