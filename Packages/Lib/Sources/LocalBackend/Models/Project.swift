//
//  Project.swift
//  xcode-builder-2
//
//  Created by Kai Shao on 2025/7/11.
//

import Foundation
import SharingGRDB
import Core

@Table
public struct Project: Codable, Sendable, Hashable, Identifiable {
    @Column("bundle_identifier")
    public var bundleIdentifier: String
    
    public var name: String
    
    @Column("display_name")
    public var displayName: String
    
    @Column("git_repo_url")
    public var gitRepoURL: URL
    
    @Column("xcodeproj_name")
    public var xcodeprojName: String

    @Column("working_directory")
    public var workingDirectoryURL: URL
    
    @Column("created_at")
    public var createdAt: Date = .now

    public var id: String {
        bundleIdentifier
    }

    public init(bundleIdentifier: String = "", createdAt: Date = .now, name: String = "", displayName: String = "", gitRepoURL: URL = .init(string: "https://github.com")!, xcodeprojName: String = "", workingDirectoryURL: URL = .init(string: "file:///")!) {
        self.bundleIdentifier = bundleIdentifier
        self.createdAt = createdAt
        self.name = name
        self.displayName = displayName
        self.gitRepoURL = gitRepoURL
        self.xcodeprojName = xcodeprojName
        self.workingDirectoryURL = workingDirectoryURL
    }
}
