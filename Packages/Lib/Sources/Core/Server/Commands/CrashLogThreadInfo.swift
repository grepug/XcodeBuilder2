import Foundation

public struct CrashLogThread: Sendable, Hashable, Codable {
    public struct Frame: Sendable, Hashable, Codable {
        public let processName: String
        public let symbol: String
        public let lineNumber: Int?
        public let fileName: String?
    }
    
    public let number: Int
    public let isMainThread: Bool
    public let isCrashed: Bool
    public let frames: [Frame]
}

public func parseThreadInfo(content: String) -> [CrashLogThread] {
    var threads: [CrashLogThread] = []
    let lines = content.components(separatedBy: .newlines)
    
    var currentThread: CrashLogThread?
    var currentFrames: [CrashLogThread.Frame] = []
    
    for line in lines {
        let trimmedLine = line.trimmingCharacters(in: .whitespaces)
        
        // Skip empty lines
        if trimmedLine.isEmpty {
            continue
        }
        
        // Check for thread stack start (e.g., "Thread 0:" - the actual start of stack traces)
        if let threadMatch = parseThreadStackStart(trimmedLine) {
            // Save previous thread if exists
            if let thread = currentThread {
                let finalThread = CrashLogThread(
                    number: thread.number,
                    isMainThread: thread.isMainThread,
                    isCrashed: thread.isCrashed,
                    frames: currentFrames
                )
                threads.append(finalThread)
            }
            
            // Start new thread
            currentThread = threadMatch
            currentFrames = []
        }
        // Check for thread name line (e.g., "Thread 0 name:   Dispatch queue: com.apple.main-thread")
        else if let threadInfo = parseThreadNameLine(trimmedLine) {
            // If we have a current thread, update its properties
            if let thread = currentThread, thread.number == threadInfo.number {
                currentThread = CrashLogThread(
                    number: thread.number,
                    isMainThread: threadInfo.isMainThread || thread.isMainThread,
                    isCrashed: threadInfo.isCrashed || thread.isCrashed,
                    frames: []
                )
            } else {
                // This is a new thread info, but we'll wait for the stack start
                // Just store the information for now
            }
        }
        // Check for crashed thread line (e.g., "Thread 4 Crashed:")
        else if let crashedThread = parseCrashedThreadLine(trimmedLine) {
            // Save previous thread if exists
            if let thread = currentThread {
                let finalThread = CrashLogThread(
                    number: thread.number,
                    isMainThread: thread.isMainThread,
                    isCrashed: thread.isCrashed,
                    frames: currentFrames
                )
                threads.append(finalThread)
            }
            
            // Start new crashed thread
            currentThread = crashedThread
            currentFrames = []
        }
        // Check for stack trace line (starts with number and whitespace)
        else if isStackTraceLine(trimmedLine) && currentThread != nil {
            if let frame = parseStackFrame(trimmedLine) {
                currentFrames.append(frame)
            }
        }
        // Check for thread state information (ARM Thread State, etc.)
        else if trimmedLine.contains("Thread State") || trimmedLine.contains("Binary Images") {
            // Save current thread and reset
            if let thread = currentThread {
                let finalThread = CrashLogThread(
                    number: thread.number,
                    isMainThread: thread.isMainThread,
                    isCrashed: thread.isCrashed,
                    frames: currentFrames
                )
                threads.append(finalThread)
                currentThread = nil
                currentFrames = []
            }
        }
    }
    
    // Don't forget the last thread
    if let thread = currentThread {
        let finalThread = CrashLogThread(
            number: thread.number,
            isMainThread: thread.isMainThread,
            isCrashed: thread.isCrashed,
            frames: currentFrames
        )
        threads.append(finalThread)
    }
    
    return threads
}

private func parseThreadStackStart(_ line: String) -> CrashLogThread? {
    // Pattern for "Thread X:" (the start of actual stack traces)
    let threadPattern = #"^Thread\s+(\d+):$"#
    
    guard let regex = try? NSRegularExpression(pattern: threadPattern, options: []),
          let match = regex.firstMatch(in: line, options: [], range: NSRange(line.startIndex..., in: line)) else {
        return nil
    }
    
    // Extract thread number
    let threadNumberRange = Range(match.range(at: 1), in: line)!
    let threadNumber = Int(String(line[threadNumberRange])) ?? 0
    
    // Check if main thread (Thread 0)
    let isMainThread = threadNumber == 0
    
    return CrashLogThread(
        number: threadNumber,
        isMainThread: isMainThread,
        isCrashed: false,
        frames: []
    )
}

private func parseThreadNameLine(_ line: String) -> CrashLogThread? {
    // Pattern for "Thread X name: ..."
    let threadPattern = #"^Thread\s+(\d+)\s+name:\s*(.*)$"#
    
    guard let regex = try? NSRegularExpression(pattern: threadPattern, options: []),
          let match = regex.firstMatch(in: line, options: [], range: NSRange(line.startIndex..., in: line)) else {
        return nil
    }
    
    // Extract thread number
    let threadNumberRange = Range(match.range(at: 1), in: line)!
    let threadNumber = Int(String(line[threadNumberRange])) ?? 0
    
    // Check if main thread (Thread 0 or contains "main-thread")
    let isMainThread = threadNumber == 0 || line.lowercased().contains("main-thread")
    
    return CrashLogThread(
        number: threadNumber,
        isMainThread: isMainThread,
        isCrashed: false,
        frames: []
    )
}

private func parseCrashedThreadLine(_ line: String) -> CrashLogThread? {
    // Pattern for "Thread X Crashed:"
    let threadPattern = #"^Thread\s+(\d+)\s+Crashed:$"#
    
    guard let regex = try? NSRegularExpression(pattern: threadPattern, options: []),
          let match = regex.firstMatch(in: line, options: [], range: NSRange(line.startIndex..., in: line)) else {
        return nil
    }
    
    // Extract thread number
    let threadNumberRange = Range(match.range(at: 1), in: line)!
    let threadNumber = Int(String(line[threadNumberRange])) ?? 0
    
    return CrashLogThread(
        number: threadNumber,
        isMainThread: threadNumber == 0,
        isCrashed: true,
        frames: []
    )
}

private func isStackTraceLine(_ line: String) -> Bool {
    // Stack trace lines start with a number followed by whitespace and contain memory addresses
    let stackPattern = #"^\d+\s+.*0x[0-9a-fA-F]+"#
    
    guard let regex = try? NSRegularExpression(pattern: stackPattern, options: []) else {
        return false
    }
    
    return regex.firstMatch(in: line, options: [], range: NSRange(line.startIndex..., in: line)) != nil
}

private func parseStackFrame(_ line: String) -> CrashLogThread.Frame? {
    // Stack trace line pattern examples:
    // "0   ContextApp   0x00000001024b7234 0x10248c000 + 176692"
    // "1   ContextApp   0x00000001024b6f10 method_name + 120"
    // "2   ContextApp   0x104bb4d80 closure #1 in BackgroundTaskManager.add(id:operation:mapError:) (in ContextApp) (BackgroundTaskManagerProtocol.swift:76) + 1445248"
    
    let framePattern = #"^\d+\s+([^\s]+)\s+.*$"#
    
    guard let regex = try? NSRegularExpression(pattern: framePattern, options: []),
          let match = regex.firstMatch(in: line, options: [], range: NSRange(line.startIndex..., in: line)) else {
        return nil
    }
    
    // Extract process name
    let processNameRange = Range(match.range(at: 1), in: line)!
    let processName = String(line[processNameRange])
    
    // For symbol, we'll extract everything after the hex address
    // Look for pattern like "0x123456 symbol_name + offset" or "symbol_name + offset"
    let components = line.components(separatedBy: " ").filter { !$0.isEmpty }
    
    // Find the index after the hex address (starts with 0x)
    var symbolStartIndex = 3 // Default fallback
    for (index, component) in components.enumerated() {
        if component.hasPrefix("0x") && index + 1 < components.count {
            symbolStartIndex = index + 1
            break
        }
    }
    
    let symbol = symbolStartIndex < components.count ? 
        components[symbolStartIndex...].joined(separator: " ") : "unknown"
    
    // Extract file name and line number from symbol if present
    // Pattern: "(...) (FileName.swift:123)"
    var fileName: String?
    var lineNumber: Int?
    var cleanSymbol = symbol
    
    // Look for file information in parentheses like "(BackgroundTaskManagerProtocol.swift:76)"
    // Avoid matching compiler-generated files like "(/<compiler-generated>:0)"
    let filePattern = #"\(([^/)][^)]*\.swift):(\d+)\)"#
    if let fileRegex = try? NSRegularExpression(pattern: filePattern, options: []),
       let fileMatch = fileRegex.firstMatch(in: symbol, options: [], range: NSRange(symbol.startIndex..., in: symbol)) {
        
        if let fileRange = Range(fileMatch.range(at: 1), in: symbol) {
            let extractedFileName = String(symbol[fileRange])
            // Only set fileName if it doesn't contain "compiler-generated"
            if !extractedFileName.contains("compiler-generated") {
                fileName = extractedFileName
                
                // Extract line number only if we have a valid file name
                if let lineRange = Range(fileMatch.range(at: 2), in: symbol) {
                    lineNumber = Int(String(symbol[lineRange]))
                }
                
                // Remove the file info from the symbol to create a clean symbol
                let fullMatch = fileMatch.range
                if let fullMatchRange = Range(fullMatch, in: symbol) {
                    cleanSymbol = String(symbol[..<fullMatchRange.lowerBound]) + String(symbol[fullMatchRange.upperBound...])
                    // Clean up any trailing whitespace and trim
                    cleanSymbol = cleanSymbol.trimmingCharacters(in: .whitespaces)
                }
            }
        }
    }
    
    return CrashLogThread.Frame(
        processName: processName,
        symbol: cleanSymbol,
        lineNumber: lineNumber,
        fileName: fileName
    )
}
