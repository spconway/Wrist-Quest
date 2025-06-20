import Foundation
@testable import WristQuest_Watch_App

/// Mock implementation of LoggingService for testing
class MockLoggingService: LoggingServiceProtocol {
    
    // MARK: - Log Storage
    
    /// Captured log entries for verification
    private(set) var logEntries: [LogEntry] = []
    
    /// Quick access to logs by level
    var debugLogs: [LogEntry] { logEntries.filter { $0.level == .debug } }
    var infoLogs: [LogEntry] { logEntries.filter { $0.level == .info } }
    var warningLogs: [LogEntry] { logEntries.filter { $0.level == .warning } }
    var errorLogs: [LogEntry] { logEntries.filter { $0.level == .error } }
    var criticalLogs: [LogEntry] { logEntries.filter { $0.level == .critical } }
    
    /// Quick access to logs by category
    func logs(for category: LogCategory) -> [LogEntry] {
        return logEntries.filter { $0.category == category }
    }
    
    // MARK: - Mock Control Properties
    
    /// Control whether logging should fail
    var shouldFailLogging = false
    
    /// Track method calls for verification
    var logCallCount = 0
    var debugCallCount = 0
    var infoCallCount = 0
    var warningCallCount = 0
    var errorCallCount = 0
    var criticalCallCount = 0
    
    /// Console output control for debugging tests
    var enableConsoleOutput = false
    
    // MARK: - Protocol Implementation
    
    func log(_ message: String, level: LogLevel, category: LogCategory, file: String, function: String, line: Int) {
        logCallCount += 1
        
        switch level {
        case .debug: debugCallCount += 1
        case .info: infoCallCount += 1
        case .warning: warningCallCount += 1
        case .error: errorCallCount += 1
        case .critical: criticalCallCount += 1
        }
        
        guard !shouldFailLogging else { return }
        
        let entry = LogEntry(
            timestamp: Date(),
            level: level,
            category: category,
            message: message,
            file: file,
            function: function,
            line: line
        )
        
        logEntries.append(entry)
        
        if enableConsoleOutput {
            print("[\(level.rawValue.uppercased())] [\(category.rawValue)] \(message)")
        }
    }
    
    func debug(_ message: String, category: LogCategory, file: String, function: String, line: Int) {
        log(message, level: .debug, category: category, file: file, function: function, line: line)
    }
    
    func info(_ message: String, category: LogCategory, file: String, function: String, line: Int) {
        log(message, level: .info, category: category, file: file, function: function, line: line)
    }
    
    func warning(_ message: String, category: LogCategory, file: String, function: String, line: Int) {
        log(message, level: .warning, category: category, file: file, function: function, line: line)
    }
    
    func error(_ message: String, category: LogCategory, file: String, function: String, line: Int) {
        log(message, level: .error, category: category, file: file, function: function, line: line)
    }
    
    func critical(_ message: String, category: LogCategory, file: String, function: String, line: Int) {
        log(message, level: .critical, category: category, file: file, function: function, line: line)
    }
    
    // MARK: - Mock Control Methods
    
    /// Reset all mock state
    func reset() {
        logEntries.removeAll()
        shouldFailLogging = false
        enableConsoleOutput = false
        
        // Reset call counts
        logCallCount = 0
        debugCallCount = 0
        infoCallCount = 0
        warningCallCount = 0
        errorCallCount = 0
        criticalCallCount = 0
    }
    
    /// Clear only the log entries but keep configuration
    func clearLogs() {
        logEntries.removeAll()
    }
    
    /// Get the most recent log entry
    var lastLog: LogEntry? {
        return logEntries.last
    }
    
    /// Get the most recent log message
    var lastLogMessage: String? {
        return lastLog?.message
    }
    
    /// Check if a specific message was logged
    func wasLogged(_ message: String, level: LogLevel? = nil, category: LogCategory? = nil) -> Bool {
        return logEntries.contains { entry in
            let messageMatches = entry.message.contains(message)
            let levelMatches = level == nil || entry.level == level
            let categoryMatches = category == nil || entry.category == category
            return messageMatches && levelMatches && categoryMatches
        }
    }
    
    /// Check if any log entry contains the specified text
    func containsLog(containing text: String) -> Bool {
        return logEntries.contains { $0.message.contains(text) }
    }
    
    /// Get count of logs for specific level
    func logCount(for level: LogLevel) -> Int {
        return logEntries.filter { $0.level == level }.count
    }
    
    /// Get count of logs for specific category
    func logCount(for category: LogCategory) -> Int {
        return logEntries.filter { $0.category == category }.count
    }
    
    /// Verify logging pattern (useful for testing proper logging practices)
    func verifyLoggingPattern(expectedMinLogs: Int = 1, requiredCategories: [LogCategory] = []) -> Bool {
        guard logEntries.count >= expectedMinLogs else { return false }
        
        for category in requiredCategories {
            if !logEntries.contains(where: { $0.category == category }) {
                return false
            }
        }
        
        return true
    }
    
    /// Get summary of logging activity
    func getLoggingSummary() -> LoggingSummary {
        return LoggingSummary(
            totalLogs: logEntries.count,
            debugCount: debugLogs.count,
            infoCount: infoLogs.count,
            warningCount: warningLogs.count,
            errorCount: errorLogs.count,
            criticalCount: criticalLogs.count,
            categoryCounts: LogCategory.allCases.reduce(into: [:]) { result, category in
                result[category] = logCount(for: category)
            }
        )
    }
}

// MARK: - Supporting Types

struct LogEntry {
    let timestamp: Date
    let level: LogLevel
    let category: LogCategory
    let message: String
    let file: String
    let function: String
    let line: Int
}

struct LoggingSummary {
    let totalLogs: Int
    let debugCount: Int
    let infoCount: Int
    let warningCount: Int
    let errorCount: Int
    let criticalCount: Int
    let categoryCounts: [LogCategory: Int]
    
    var hasErrors: Bool {
        return errorCount > 0 || criticalCount > 0
    }
    
    var hasWarnings: Bool {
        return warningCount > 0
    }
}

// MARK: - Test Helper Extensions

extension MockLoggingService {
    /// Create pre-configured mock with console output enabled for debugging
    static func withConsoleOutput() -> MockLoggingService {
        let mock = MockLoggingService()
        mock.enableConsoleOutput = true
        return mock
    }
    
    /// Create pre-configured mock that fails logging operations
    static func failingMock() -> MockLoggingService {
        let mock = MockLoggingService()
        mock.shouldFailLogging = true
        return mock
    }
    
    /// Convenience method to verify error logging
    func verifyErrorLogged(containing text: String) -> Bool {
        return errorLogs.contains { $0.message.contains(text) } || 
               criticalLogs.contains { $0.message.contains(text) }
    }
    
    /// Convenience method to verify info logging
    func verifyInfoLogged(containing text: String) -> Bool {
        return infoLogs.contains { $0.message.contains(text) }
    }
    
    /// Convenience method to verify warning logging
    func verifyWarningLogged(containing text: String) -> Bool {
        return warningLogs.contains { $0.message.contains(text) }
    }
    
    /// Get all log messages as a single string for debugging
    func getAllLogsAsString() -> String {
        return logEntries.map { entry in
            "[\(entry.level.rawValue.uppercased())] [\(entry.category.rawValue)] \(entry.message)"
        }.joined(separator: "\n")
    }
}

// MARK: - LogLevel and LogCategory Extensions for Testing

extension LogLevel: CaseIterable {
    public static var allCases: [LogLevel] {
        return [.debug, .info, .warning, .error, .critical]
    }
}

extension LogCategory: CaseIterable {
    public static var allCases: [LogCategory] {
        return [.game, .quest, .health, .persistence, .analytics, .ui, .network, .validation]
    }
}