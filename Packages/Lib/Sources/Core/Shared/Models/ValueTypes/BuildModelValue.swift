//
//  BuildModelValue.swift
//  xcode-builder-2
//
//  Created by Kai Shao on 2025/7/23.
//

import Foundation

public struct BuildModelValue: BuildModelProtocol, Sendable {
    public let id: UUID
    public var schemeId: UUID
    public var versionString: String
    public var buildNumber: Int
    public var createdAt: Date
    public var startDate: Date?
    public var endDate: Date?
    public var exportOptions: [ExportOption]
    public var status: BuildStatus
    public var progress: Double
    public var commitHash: String
    public var deviceMetadata: DeviceMetadata
    public var osVersion: String
    public var memory: Int
    public var processor: String
    
    // Computed properties
    public var version: Version {
        Version(version: versionString, buildNumber: buildNumber)
    }
    
    public var projectDirName: String {
        "\(versionString)_\(buildNumber)"
    }

    public init(
        id: UUID = UUID(),
        schemeId: UUID = .init(),
        version: Version = .init(),
        createdAt: Date = .now,
        startDate: Date? = nil,
        endDate: Date? = nil,
        exportOptions: [ExportOption] = [],
        status: BuildStatus = .queued,
        progress: Double = 0,
        deviceMetadata: DeviceMetadata = .init(),
        osVersion: String = "",
        memory: Int = 0,
        processor: String = ""
    ) {
        self.id = id
        self.schemeId = schemeId
        self.versionString = version.version
        self.buildNumber = version.buildNumber
        self.commitHash = version.commitHash
        self.createdAt = createdAt
        self.startDate = startDate
        self.endDate = endDate
        self.exportOptions = exportOptions
        self.status = status
        self.progress = progress
        self.deviceMetadata = deviceMetadata
        self.osVersion = osVersion
        self.memory = memory
        self.processor = processor
    }
}
