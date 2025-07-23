//
//  CrashLogValue.swift
//  xcode-builder-2
//
//  Created by Kai Shao on 2025/7/23.
//

import Foundation

public struct CrashLogValue: CrashLogProtocol, Sendable {
    public var incidentIdentifier: String
    public var isMainThread: Bool
    public var createdAt: Date
    public var buildId: UUID
    public var content: String
    public var hardwareModel: String
    public var process: String
    public var role: CrashLogRole
    public var dateTime: Date
    public var launchTime: Date
    public var osVersion: String
    public var note: String
    public var fixed: Bool
    public var priority: CrashLogPriority

    public var id: String { incidentIdentifier }

    public init(
        incidentIdentifier: String = "",
        isMainThread: Bool = false,
        createdAt: Date = .now,
        buildId: UUID = .init(),
        content: String = "",
        hardwareModel: String = "",
        process: String = "",
        role: CrashLogRole = .foreground,
        dateTime: Date = .now,
        launchTime: Date = .now,
        osVersion: String = "",
        note: String = "",
        fixed: Bool = false,
        priority: CrashLogPriority = .medium
    ) {
        self.incidentIdentifier = incidentIdentifier
        self.isMainThread = isMainThread
        self.createdAt = createdAt
        self.buildId = buildId
        self.content = content
        self.hardwareModel = hardwareModel
        self.process = process
        self.role = role
        self.dateTime = dateTime
        self.launchTime = launchTime
        self.osVersion = osVersion
        self.note = note
        self.fixed = fixed
        self.priority = priority
    }
}
