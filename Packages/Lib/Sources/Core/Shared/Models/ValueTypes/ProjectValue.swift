//
//  ProjectValue.swift
//  xcode-builder-2
//
//  Created by Kai Shao on 2025/7/23.
//

import Foundation

// MARK: - Value Types for Backend Communication
public struct ProjectValue: ProjectProtocol, Sendable {
    public var bundleIdentifier: String
    public var name: String
    public var displayName: String
    public var gitRepoURL: URL
    public var xcodeprojName: String
    public var workingDirectoryURL: URL
    public var createdAt: Date

    public var id: String { bundleIdentifier }

    public init(
        bundleIdentifier: String = "",
        name: String = "",
        displayName: String = "",
        gitRepoURL: URL = URL(string: "https://github.com")!,
        xcodeprojName: String = "",
        workingDirectoryURL: URL = URL(fileURLWithPath: ""),
        createdAt: Date = .now
    ) {
        self.bundleIdentifier = bundleIdentifier
        self.name = name
        self.displayName = displayName
        self.gitRepoURL = gitRepoURL
        self.xcodeprojName = xcodeprojName
        self.workingDirectoryURL = workingDirectoryURL
        self.createdAt = createdAt
    }
}
