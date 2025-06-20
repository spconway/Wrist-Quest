import Foundation
import os.log

// MARK: - Logging Service Protocol

protocol LoggingServiceProtocol {
    func debug(_ message: String, category: LogCategory)
    func info(_ message: String, category: LogCategory)
    func warning(_ message: String, category: LogCategory)
    func error(_ message: String, category: LogCategory)
    func fault(_ message: String, category: LogCategory)
}

// MARK: - Log Categories

enum LogCategory: String, CaseIterable {
    case game = "Game"
    case health = "Health"
    case persistence = "Persistence"
    case quest = "Quest"
    case player = "Player"
    case ui = "UI"
    case system = "System"
    case analytics = "Analytics"
    case background = "Background"
    case validation = "Validation"
    
    var subsystem: String {
        return "com.wristquest.app"
    }
}

// MARK: - Logging Service Implementation

class LoggingService: LoggingServiceProtocol {
    private var loggers: [LogCategory: Logger] = [:]
    
    init() {
        setupLoggers()
    }
    
    private func setupLoggers() {
        for category in LogCategory.allCases {
            loggers[category] = Logger(subsystem: category.subsystem, category: category.rawValue)
        }
    }
    
    func debug(_ message: String, category: LogCategory = .system) {
        loggers[category]?.debug("\(message)")
    }
    
    func info(_ message: String, category: LogCategory = .system) {
        loggers[category]?.info("\(message)")
    }
    
    func warning(_ message: String, category: LogCategory = .system) {
        loggers[category]?.warning("\(message)")
    }
    
    func error(_ message: String, category: LogCategory = .system) {
        loggers[category]?.error("\(message)")
    }
    
    func fault(_ message: String, category: LogCategory = .system) {
        loggers[category]?.fault("\(message)")
    }
}

// MARK: - Mock Logging Service for Testing

class MockLoggingService: LoggingServiceProtocol {
    var logs: [(level: String, message: String, category: LogCategory)] = []
    
    func debug(_ message: String, category: LogCategory = .system) {
        logs.append((level: "DEBUG", message: message, category: category))
    }
    
    func info(_ message: String, category: LogCategory = .system) {
        logs.append((level: "INFO", message: message, category: category))
    }
    
    func warning(_ message: String, category: LogCategory = .system) {
        logs.append((level: "WARNING", message: message, category: category))
    }
    
    func error(_ message: String, category: LogCategory = .system) {
        logs.append((level: "ERROR", message: message, category: category))
    }
    
    func fault(_ message: String, category: LogCategory = .system) {
        logs.append((level: "FAULT", message: message, category: category))
    }
    
    func clearLogs() {
        logs.removeAll()
    }
    
    func getLogsForCategory(_ category: LogCategory) -> [(level: String, message: String, category: LogCategory)] {
        return logs.filter { $0.category == category }
    }
}