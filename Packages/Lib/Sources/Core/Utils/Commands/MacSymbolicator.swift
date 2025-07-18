import Foundation
import Dependencies

struct MacSymbolicatorCLI {
    var translateOnly: Bool = false
    var verbose: Bool = false
    var output: String?
    var reportFilePath: String
    var dsymPaths: [String] = []

    var command: String {
        var components: [String] = []

        if translateOnly {
            components.append("--translate-only")
        }

        if verbose {
            components.append("--verbose")
        }

        if let output = output {
            components.append("--output \(output)")
        }

        components.append(reportFilePath)
        components.append(contentsOf: dsymPaths)

        return components.joined(separator: " ")
    }
}

func recursivelySearchFiles(at url: URL, withExtension ext: String) -> [URL] {
    var result: [URL] = []
    let fileManager = FileManager.default

    if let contents = try? fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil) {
        for fileURL in contents {
            var isDirectory: ObjCBool = false
            if fileManager.fileExists(atPath: fileURL.path, isDirectory: &isDirectory) {
                print("fileURL", fileURL.lastPathComponent)
                if fileURL.lastPathComponent.contains(".\(ext)") {
                    result.append(fileURL)
                } else if isDirectory.boolValue {
                    result.append(contentsOf: recursivelySearchFiles(at: fileURL, withExtension: ext))
                }
            }
        }
    }

    return result
}

public struct MacSymbolicator {
    public static func makeCrashLog(content: String, getBuildId: @escaping (CrashLog) async -> UUID) async throws -> CrashLog {
        let symbolicatedContent = try await symbolicate(content: content)
        let (incidentIdentifier, hardwareModel, process, role, dateTime, launchTime, osVersion, isMainThread, appIdentifier, appVersion, appVariant, reportVersion) = parseCrashReport(content: symbolicatedContent)
        
        var crashLog = CrashLog(
            incidentIdentifier: incidentIdentifier,
            isMainThread: isMainThread,
            createdAt: Date(),
            buildId: UUID(), // In a real implementation, this should come from the context
            content: symbolicatedContent,
            hardwareModel: hardwareModel,
            process: process,
            appIdentifier: appIdentifier,
            appVersion: appVersion,
            appVariant: appVariant,
            role: role,
            dateTime: dateTime,
            launchTime: launchTime,
            osVersion: osVersion,
            reportVersion: reportVersion
        )

        // Fetch the build ID asynchronously
        crashLog.buildId = await getBuildId(crashLog)

        return crashLog
    }
    
    private static func symbolicate(content: String) async throws -> String {
        let tmpFile = try createTemporaryFile(content: content)
        
        defer {
            try? FileManager.default.removeItem(at: tmpFile)
        }
        
        let (cliExe, dsymPaths) = try getSymbolicatorConfiguration()
        let cli = MacSymbolicatorCLI(
            reportFilePath: tmpFile.path,
            dsymPaths: dsymPaths
        )
        
        do {
            return try await runShellCommand2("\(cliExe) \(cli.command)").get()
        } catch {
            print("Failed to symbolicate: \(error)")
            throw NSError(domain: "MacSymbolicator", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to symbolicate"])
        }
    }
    
    private static func createTemporaryFile(content: String) throws -> URL {
        let tmpId = UUID().uuidString
        let tmpDir = URL(fileURLWithPath: NSTemporaryDirectory())
        let tmpFile = tmpDir.appendingPathComponent("\(tmpId).ips")
        
        try content.write(to: tmpFile, atomically: true, encoding: .utf8)
        return tmpFile
    }
    
    private static func getSymbolicatorConfiguration() throws -> (String, [String]) {
        @Dependency(\.xcodeBuildPathManager) var pathManager

        let macSymbolicatorPath = "/Applications/MacSymbolicator.app/Contents/MacOS"
        let dsymPath = pathManager.rootURL

        let macSymbolicatorURL = URL(filePath: macSymbolicatorPath)
            .appending(path: "MacSymbolicatorCLI")
        let cliExe = macSymbolicatorURL.path()
        let dsymPaths = recursivelySearchFiles(at: dsymPath, withExtension: "dSYM")
            .map { "\"\($0.path(percentEncoded: false))\"" }
        
        return (cliExe, dsymPaths)
    }
    
    private static func parseCrashReport(content: String) -> (String, String, String, CrashLogRole, Date, Date, String, Bool, String, String, String, String) {
        let lines = content.components(separatedBy: .newlines)
        
        var incidentIdentifier = ""
        var hardwareModel = ""
        var process = ""
        var role: CrashLogRole = .foreground
        var dateTime = Date()
        var launchTime = Date()
        var osVersion = ""
        var isMainThread = false
        var appIdentifier = ""
        var appVersion = ""
        var appVariant = ""
        var reportVersion = ""
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSS Z"
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            
            parseBasicInfo(from: trimmedLine, incidentIdentifier: &incidentIdentifier, hardwareModel: &hardwareModel, process: &process, role: &role, dateTime: &dateTime, launchTime: &launchTime, osVersion: &osVersion, dateFormatter: dateFormatter)
            parseAppInfo(from: trimmedLine, appIdentifier: &appIdentifier, appVersion: &appVersion, appVariant: &appVariant, reportVersion: &reportVersion)
            
            // Check if this crash is related to main thread
            if trimmedLine.contains("Thread 0") && trimmedLine.contains("Crashed") {
                isMainThread = true
            }
        }
        
        return (incidentIdentifier, hardwareModel, process, role, dateTime, launchTime, osVersion, isMainThread, appIdentifier, appVersion, appVariant, reportVersion)
    }
    
    private static func parseBasicInfo(from line: String, incidentIdentifier: inout String, hardwareModel: inout String, process: inout String, role: inout CrashLogRole, dateTime: inout Date, launchTime: inout Date, osVersion: inout String, dateFormatter: DateFormatter) {
        if line.hasPrefix("Incident Identifier:") {
            incidentIdentifier = extractValue(from: line, prefix: "Incident Identifier:")
        } else if line.hasPrefix("Hardware Model:") {
            hardwareModel = extractValue(from: line, prefix: "Hardware Model:")
        } else if line.hasPrefix("Process:") {
            process = extractValue(from: line, prefix: "Process:")
        } else if line.hasPrefix("Role:") {
            let roleString = extractValue(from: line, prefix: "Role:").lowercased()
            role = CrashLogRole(rawValue: roleString) ?? .foreground
        } else if line.hasPrefix("Date/Time:") {
            let dateString = extractValue(from: line, prefix: "Date/Time:")
            dateTime = dateFormatter.date(from: dateString) ?? Date()
        } else if line.hasPrefix("Launch Time:") {
            let launchString = extractValue(from: line, prefix: "Launch Time:")
            launchTime = dateFormatter.date(from: launchString) ?? Date()
        } else if line.hasPrefix("OS Version:") {
            osVersion = extractValue(from: line, prefix: "OS Version:")
        }
    }
    
    private static func parseAppInfo(from line: String, appIdentifier: inout String, appVersion: inout String, appVariant: inout String, reportVersion: inout String) {
        if line.hasPrefix("Identifier:") {
            appIdentifier = extractValue(from: line, prefix: "Identifier:")
        } else if line.hasPrefix("Version:") {
            appVersion = extractValue(from: line, prefix: "Version:")
        } else if line.hasPrefix("AppVariant:") {
            appVariant = extractValue(from: line, prefix: "AppVariant:")
        } else if line.hasPrefix("Report Version:") {
            reportVersion = extractValue(from: line, prefix: "Report Version:")
        }
    }
    
    private static func extractValue(from line: String, prefix: String) -> String {
        return String(line.dropFirst(prefix.count)).trimmingCharacters(in: .whitespaces)
    }
}