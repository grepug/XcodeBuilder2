//
//  Project.swift
//  xcode-builder-2
//
//  Created by Kai Shao on 2025/7/11.
//

import Foundation

public struct Project: Codable, Sendable, Hashable, Identifiable {
    public var bundleIdentifier: String
    public var name: String
    public var path: String
    public var displayName: String
    public var gitRepoURL: URL
    public var xcodeprojName: String
    public var schemes: [Scheme]

    public var id: String {
        bundleIdentifier
    }

    public init(bundleIdentifier: String, path: String, name: String, displayName: String, gitRepoURL: URL, xcodeprojName: String, schemes: [Scheme]) {
        self.bundleIdentifier = bundleIdentifier
        self.name = name
        self.path = path
        self.displayName = displayName
        self.gitRepoURL = gitRepoURL
        self.xcodeprojName = xcodeprojName
        self.schemes = schemes
    }
}
