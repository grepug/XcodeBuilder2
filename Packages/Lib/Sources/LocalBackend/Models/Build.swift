import Foundation
import SharingGRDB
import Core

@Table("builds")
public struct BuildModel: Identifiable, Sendable, Hashable, BuildModelProtocol {
    public var id: UUID

    @Column("scheme_id")
    public var schemeId: UUID

    @Column("version_string")
    public var versionString: String

    @Column("build_number")
    public var buildNumber: Int

    @Column("commit_hash")
    public var commitHash: String

    @Column("created_at")
    public var createdAt: Date = .now

    @Column("start_date")
    public var startDate: Date?

    @Column("end_date")
    public var endDate: Date?

    public var status: BuildStatus = .queued

    public var progress: Double = 0

    @Column("device_metadata")
    public var deviceModel: String

    @Column("os_version")
    public var osVersion: String

    public var memory: Int // in GB

    public var processor: String

    @Column("export_options", as: [ExportOption].JSONRepresentation.self)
    public var exportOptions: [ExportOption]
    
    public var projectDirName: String {
        "\(version.displayString)_\(id.uuidString.lowercased().prefix(6))"
    }
    
    public var duration: TimeInterval {
        guard let start = startDate, let end = endDate else { return 0 }
        return end.timeIntervalSince(start)
    }

    public var version: Version {
        get {
            Version(version: versionString, buildNumber: buildNumber, commitHash: commitHash)
        }
        
        set {
            versionString = newValue.version
            buildNumber = newValue.buildNumber
            commitHash = newValue.commitHash
        }
    }

    public var deviceMetadata: DeviceMetadata {
        get {
            .init(model: deviceModel, osVersion: osVersion, memory: memory, processor: processor)
        }

        set {
            deviceModel = newValue.model
            osVersion = newValue.osVersion
            memory = newValue.memory
            processor = newValue.processor
        }
    }

    public init(
        id: UUID = .init(), 
        schemeId: UUID = .init(), 
        version: Version = .init(),
        createdAt: Date = .now, 
        startDate: Date? = nil, 
        endDate: Date? = nil, 
        exportOptions: [ExportOption] = [],
        commitHash: String = "",
        status: BuildStatus = .queued,
        progress: Double = 0,
        deviceMetadata: DeviceMetadata = .init(),
    ) {
        self.id = id
        self.schemeId = schemeId
        self.versionString = version.version
        self.buildNumber = version.buildNumber
        self.commitHash = commitHash
        self.createdAt = createdAt
        self.startDate = startDate
        self.endDate = endDate
        self.status = status
        self.exportOptions = exportOptions
        self.progress = progress
        self.commitHash = commitHash
        self.deviceModel = deviceMetadata.model
        self.osVersion = deviceMetadata.osVersion
        self.memory = deviceMetadata.memory
        self.processor = deviceMetadata.processor
    }
}

extension BuildStatus: QueryBindable {}