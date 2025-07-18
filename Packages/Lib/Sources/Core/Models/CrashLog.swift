import Foundation
import SharingGRDB

public enum CrashLogRole: String, Codable, Sendable, Hashable, CaseIterable, QueryBindable {
    case foreground
    case background
}

public enum CrashLogPriority: String, Codable, Sendable, Hashable, CaseIterable, QueryBindable {
    case urgent
    case high
    case medium
    case low
}

@Table("crash_logs")
public struct CrashLog: Identifiable, Sendable, Hashable {
    public var id: String {
        incidentIdentifier 
    }

    @Column("incident_identifier", primaryKey: true)
    public var incidentIdentifier: String

    @Column("is_main_thread")
    public var isMainThread: Bool

    @Column("created_at")
    public var createdAt: Date

    @Column("build_id")
    public var buildId: UUID

    @Column("content")
    public var content: String

    @Column("hardware_model")
    public var hardwareModel: String
    
    @Column("process")
    public var process: String
    
    public var role: CrashLogRole
    
    @Column("date_time")
    public var dateTime: Date
    
    @Column("launch_time")
    public var launchTime: Date
    
    @Column("os_version")
    public var osVersion: String
    
    public var note: String = ""

    public var fixed: Bool = false

    public var priority: CrashLogPriority = .medium

    public init(
        incidentIdentifier: String,
        isMainThread: Bool,
        createdAt: Date = Date(),
        buildId: UUID,
        content: String,
        hardwareModel: String,
        process: String,
        appIdentifier: String,
        appVersion: String,
        appVariant: String,
        role: CrashLogRole,
        dateTime: Date,
        launchTime: Date,
        osVersion: String,
        reportVersion: String,
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