import Foundation
import SharingGRDB

public enum BuildStatus: String, Codable, Sendable, Hashable, QueryBindable {
    case queued
    case running
    case completed
    case failed
}

@Table("builds")
public struct BuildModel: Identifiable, Sendable {
    public var id: UUID

    @Column("scheme_id")
    public var schemeId: UUID

    @Column("version_string")
    public var versionString: String

    @Column("build_number")
    public var buildNumber: Int

    @Column("created_at")
    public var createdAt: Date = .now

    @Column("start_date")
    public var startDate: Date?

    @Column("end_date")
    public var endDate: Date?

    public var status: BuildStatus = .queued

    @Column("export_options", as: [ExportOption].JSONRepresentation.self)
    public var exportOptions: [ExportOption]

    public var version: Version {
        get {
            Version(version: versionString, buildNumber: buildNumber)
        }
        
        set {
            versionString = newValue.version
            buildNumber = newValue.buildNumber
        }
    }

    public init(
        id: UUID = .init(), 
        schemeId: UUID = .init(), 
        versionString: String = "1.0.0", 
        buildNumber: Int = 1, 
        createdAt: Date = .now, 
        startDate: Date? = nil, 
        endDate: Date? = nil, 
        exportOptions: [ExportOption] = [], 
        status: BuildStatus = .queued
    ) {
        self.id = id
        self.schemeId = schemeId
        self.versionString = versionString
        self.buildNumber = buildNumber
        self.createdAt = createdAt
        self.startDate = startDate
        self.endDate = endDate
        self.status = status
        self.exportOptions = exportOptions
    }
}
