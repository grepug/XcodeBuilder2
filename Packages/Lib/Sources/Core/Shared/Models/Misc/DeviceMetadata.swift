import Foundation

public struct DeviceMetadata: Codable, Sendable, Hashable {
    public let model: String
    public let osVersion: String
    public let memory: Int // in GB
    public let processor: String

    public init(model: String = "", osVersion: String = "", memory: Int = 0, processor: String = "") {
        self.model = model
        self.osVersion = osVersion
        self.memory = memory
        self.processor = processor
    }
}