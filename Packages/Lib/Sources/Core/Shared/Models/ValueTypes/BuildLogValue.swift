//
//  BuildLogValue.swift
//  xcode-builder-2
//
//  Created by Kai Shao on 2025/7/23.
//

import Foundation

public struct BuildLogValue: BuildLogProtocol, Sendable {
    public let id: UUID
    public let buildId: UUID
    public let category: String?
    public let level: BuildLogLevel
    public let content: String
    public let createdAt: Date

    public init(
        id: UUID = UUID(),
        buildId: UUID,
        category: String? = nil,
        level: BuildLogLevel = .info,
        content: String,
        createdAt: Date = .now
    ) {
        self.id = id
        self.buildId = buildId
        self.category = category
        self.level = level
        self.content = content
        self.createdAt = createdAt
    }
}
