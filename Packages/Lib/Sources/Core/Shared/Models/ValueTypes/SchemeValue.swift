//
//  SchemeValue.swift
//  xcode-builder-2
//
//  Created by Kai Shao on 2025/7/23.
//

import Foundation

public struct SchemeValue: SchemeProtocol, Sendable {
    public let id: UUID
    public var projectBundleIdentifier: String
    public var name: String
    public var platforms: [Platform]
    public var order: Int

    public init(
        id: UUID = UUID(),
        projectBundleIdentifier: String = "",
        name: String = "",
        platforms: [Platform] = [],
        order: Int = 0,
    ) {
        self.id = id
        self.projectBundleIdentifier = projectBundleIdentifier
        self.name = name
        self.platforms = platforms
        self.order = order
    }
}
