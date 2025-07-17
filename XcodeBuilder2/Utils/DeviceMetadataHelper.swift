//
//  DeviceMetadataHelper.swift
//  XcodeBuilder2
//
//  Created by Kai Shao on 2025/7/17.
//

import Foundation
import Core
#if canImport(IOKit)
import IOKit
import IOKit.ps
#endif

struct DeviceMetadataHelper {
    static func getCurrentDeviceMetadata() -> DeviceMetadata {
        return DeviceMetadata(
            model: getDeviceModel(),
            osVersion: getOSVersion(),
            memory: getMemoryInGB(),
            processor: getProcessorInfo()
        )
    }
    
    private static func getDeviceModel() -> String {
        var size = 0
        sysctlbyname("hw.model", nil, &size, nil, 0)
        var machine = [CChar](repeating: 0, count: size)
        sysctlbyname("hw.model", &machine, &size, nil, 0)
        return String(cString: machine)
    }
    
    private static func getOSVersion() -> String {
        let version = ProcessInfo.processInfo.operatingSystemVersion
        return "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
    }
    
    private static func getMemoryInGB() -> Int {
        var size: size_t = MemoryLayout<UInt64>.size
        var result: UInt64 = 0
        let ret = sysctlbyname("hw.memsize", &result, &size, nil, 0)
        
        if ret == 0 {
            // Convert bytes to GB and round to nearest GB
            let memoryInGB = Double(result) / (1024 * 1024 * 1024)
            return Int(round(memoryInGB))
        }
        
        return 0
    }
    
    private static func getProcessorInfo() -> String {
        var size = 0
        sysctlbyname("machdep.cpu.brand_string", nil, &size, nil, 0)
        var machine = [CChar](repeating: 0, count: size)
        sysctlbyname("machdep.cpu.brand_string", &machine, &size, nil, 0)
        let brandString = String(cString: machine)
        
        // If brand string is empty or not available, try alternative approach
        if brandString.isEmpty {
            // For Apple Silicon Macs, try to get the CPU name
            size = 0
            sysctlbyname("hw.targettype", nil, &size, nil, 0)
            var targetType = [CChar](repeating: 0, count: size)
            sysctlbyname("hw.targettype", &targetType, &size, nil, 0)
            let target = String(cString: targetType)
            
            if target.contains("Mac") {
                // Try to determine if it's Apple Silicon
                size = 0
                sysctlbyname("hw.optional.arm64", nil, &size, nil, 0)
                if size > 0 {
                    var isArm: UInt32 = 0
                    size = MemoryLayout<UInt32>.size
                    let ret = sysctlbyname("hw.optional.arm64", &isArm, &size, nil, 0)
                    if ret == 0 && isArm == 1 {
                        // Get the specific Apple Silicon chip
                        size = 0
                        sysctlbyname("hw.perflevel0.name", nil, &size, nil, 0)
                        if size > 0 {
                            var chipName = [CChar](repeating: 0, count: size)
                            sysctlbyname("hw.perflevel0.name", &chipName, &size, nil, 0)
                            let chip = String(cString: chipName)
                            return "Apple \(chip)"
                        }
                        return "Apple Silicon"
                    }
                }
            }
            
            return "Unknown Processor"
        }
        
        return brandString
    }
}
