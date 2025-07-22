import Foundation
import SharingGRDB
import Core

@Table
public struct CrashLog: Identifiable, Sendable, Hashable, CrashLogProtocol {
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

    public var parsedThreads: [CrashLogThread] {
        parseThreadInfo(content: content)
    }

    public init(
        incidentIdentifier: String = "",
        isMainThread: Bool = false,
        createdAt: Date = Date(),
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
