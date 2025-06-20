import Foundation

// MARK: - Validation Error

/// Represents a validation error with context and severity
public struct ValidationError: Error, Equatable, Identifiable {
    public let id = UUID()
    public let field: String
    public let message: String
    public let severity: ValidationSeverity
    public let timestamp: Date
    public let context: [String: Any]?
    
    public init(field: String, message: String, severity: ValidationSeverity, context: [String: Any]? = nil) {
        self.field = field
        self.message = message
        self.severity = severity
        self.timestamp = Date()
        self.context = context
    }
    
    // MARK: - Equatable
    
    public static func == (lhs: ValidationError, rhs: ValidationError) -> Bool {
        return lhs.field == rhs.field &&
               lhs.message == rhs.message &&
               lhs.severity == rhs.severity
    }
    
    // MARK: - Error Properties
    
    /// Whether this error blocks further processing
    public var isBlocking: Bool {
        return !severity.canProceed
    }
    
    /// User-friendly message for display
    public var userMessage: String {
        return message
    }
    
    /// Technical message for logging
    public var technicalMessage: String {
        return "Validation error in field '\(field)': \(message) (severity: \(severity.rawValue))"
    }
}

// MARK: - Validation Error Collection

/// Collection of validation errors with utility methods
public struct ValidationErrorCollection {
    public let errors: [ValidationError]
    
    public init(_ errors: [ValidationError]) {
        self.errors = errors
    }
    
    // MARK: - Properties
    
    /// Whether the collection contains any errors
    public var hasErrors: Bool {
        return !errors.isEmpty
    }
    
    /// Whether the collection contains any blocking errors
    public var hasBlockingErrors: Bool {
        return errors.contains { $0.isBlocking }
    }
    
    /// Whether the collection contains only warnings
    public var hasOnlyWarnings: Bool {
        return hasErrors && !hasBlockingErrors
    }
    
    /// Errors grouped by severity
    public var errorsBySeverity: [ValidationSeverity: [ValidationError]] {
        return Dictionary(grouping: errors, by: { $0.severity })
    }
    
    /// Critical errors only
    public var criticalErrors: [ValidationError] {
        return errors.filter { $0.severity == .critical }
    }
    
    /// Error-level errors only
    public var errorLevelErrors: [ValidationError] {
        return errors.filter { $0.severity == .error }
    }
    
    /// Warning-level errors only
    public var warnings: [ValidationError] {
        return errors.filter { $0.severity == .warning }
    }
    
    /// Info-level errors only
    public var infoMessages: [ValidationError] {
        return errors.filter { $0.severity == .info }
    }
    
    // MARK: - Methods
    
    /// Get errors for a specific field
    public func errorsForField(_ field: String) -> [ValidationError] {
        return errors.filter { $0.field == field }
    }
    
    /// Get the most severe error for a field
    public func mostSevereErrorForField(_ field: String) -> ValidationError? {
        let fieldErrors = errorsForField(field)
        return fieldErrors.max { error1, error2 in
            error1.severity.rawValue < error2.severity.rawValue
        }
    }
    
    /// Convert to WQError for integration with existing error system
    public func toWQErrors() -> [WQError] {
        return errors.map { error in
            let validationError = WQError.ValidationError.constraintViolation("\(error.field): \(error.message)")
            return WQError.validation(validationError)
        }
    }
    
    /// Get a summary message for all errors
    public func summaryMessage() -> String {
        guard hasErrors else { return "No validation errors" }
        
        if errors.count == 1 {
            return errors.first!.message
        }
        
        let criticalCount = criticalErrors.count
        let errorCount = errorLevelErrors.count
        let warningCount = warnings.count
        
        var parts: [String] = []
        
        if criticalCount > 0 {
            parts.append("\(criticalCount) critical error\(criticalCount == 1 ? "" : "s")")
        }
        
        if errorCount > 0 {
            parts.append("\(errorCount) error\(errorCount == 1 ? "" : "s")")
        }
        
        if warningCount > 0 {
            parts.append("\(warningCount) warning\(warningCount == 1 ? "" : "s")")
        }
        
        return parts.joined(separator: ", ")
    }
}

// MARK: - Validation Context

/// Context information for validation operations
public struct ValidationContext {
    public let operation: String
    public let source: String
    public let userInitiated: Bool
    public let metadata: [String: Any]
    
    public init(operation: String, source: String, userInitiated: Bool = true, metadata: [String: Any] = [:]) {
        self.operation = operation
        self.source = source
        self.userInitiated = userInitiated
        self.metadata = metadata
    }
    
    // MARK: - Predefined Contexts
    
    static let onboardingContext = ValidationContext(
        operation: "onboarding",
        source: "OnboardingView",
        userInitiated: true
    )
    
    static let gameplayContext = ValidationContext(
        operation: "gameplay",
        source: "GameViewModel",
        userInitiated: false
    )
    
    static let questProgressContext = ValidationContext(
        operation: "quest_progress",
        source: "QuestViewModel",
        userInitiated: false
    )
    
    static let healthDataContext = ValidationContext(
        operation: "health_data",
        source: "HealthService",
        userInitiated: false
    )
    
    static let settingsContext = ValidationContext(
        operation: "settings",
        source: "SettingsView",
        userInitiated: true
    )
    
    static let persistenceContext = ValidationContext(
        operation: "persistence",
        source: "PersistenceService",
        userInitiated: false
    )
}

// MARK: - Validation Event

/// Event that captures validation attempts and results
public struct ValidationEvent {
    public let id = UUID()
    public let timestamp = Date()
    public let context: ValidationContext
    public let validationType: ValidationType
    public let input: String
    public let result: ValidationResult
    public let errors: [ValidationError]
    
    public init(context: ValidationContext, validationType: ValidationType, input: String, result: ValidationResult, errors: [ValidationError] = []) {
        self.context = context
        self.validationType = validationType
        self.input = input
        self.result = result
        self.errors = errors
    }
}

// MARK: - Validation Type

/// Types of validation operations
public enum ValidationType: String, CaseIterable {
    case playerName = "player_name"
    case playerStats = "player_stats"
    case healthData = "health_data"
    case questData = "quest_data"
    case questProgress = "quest_progress"
    case inventory = "inventory"
    case gameState = "game_state"
    case formInput = "form_input"
    case dataImport = "data_import"
    case levelProgression = "level_progression"
    
    public var displayName: String {
        switch self {
        case .playerName:
            return "Player Name"
        case .playerStats:
            return "Player Statistics"
        case .healthData:
            return "Health Data"
        case .questData:
            return "Quest Data"
        case .questProgress:
            return "Quest Progress"
        case .inventory:
            return "Inventory"
        case .gameState:
            return "Game State"
        case .formInput:
            return "Form Input"
        case .dataImport:
            return "Data Import"
        case .levelProgression:
            return "Level Progression"
        }
    }
}

// MARK: - Validation Logger

/// Logger for validation events and errors
public class ValidationLogger {
    public static let shared = ValidationLogger()
    
    private let loggingService: LoggingService
    private var validationEvents: [ValidationEvent] = []
    private let maxEvents = 1000
    
    private init() {
        self.loggingService = LoggingService()
    }
    
    // MARK: - Logging Methods
    
    /// Log a validation event
    public func logValidationEvent(_ event: ValidationEvent) {
        validationEvents.append(event)
        
        // Keep only recent events
        if validationEvents.count > maxEvents {
            validationEvents.removeFirst(validationEvents.count - maxEvents)
        }
        
        // Log to system
        let logMessage = "Validation [\(event.validationType.displayName)]: \(event.result.isValid ? "PASSED" : "FAILED") - \(event.input)"
        
        if event.result.isValid {
            loggingService.debug(logMessage, category: .validation)
        } else {
            let errorDetails = event.errors.map { "\($0.field): \($0.message)" }.joined(separator: ", ")
            loggingService.warning("\(logMessage) - Errors: \(errorDetails)", category: .validation)
        }
    }
    
    /// Log validation errors
    public func logValidationErrors(_ errors: [ValidationError], context: ValidationContext) {
        for error in errors {
            let logMessage = "Validation Error [\(context.operation)]: \(error.technicalMessage)"
            
            switch error.severity {
            case .critical:
                loggingService.error(logMessage, category: .validation)
            case .error:
                loggingService.warning(logMessage, category: .validation)
            case .warning:
                loggingService.info(logMessage, category: .validation)
            case .info:
                loggingService.debug(logMessage, category: .validation)
            }
        }
    }
    
    /// Get validation statistics
    public func getValidationStatistics() -> ValidationStatistics {
        let totalEvents = validationEvents.count
        let passedEvents = validationEvents.filter { $0.result.isValid }.count
        let failedEvents = totalEvents - passedEvents
        
        let errorsByType = Dictionary(grouping: validationEvents) { $0.validationType }
        let errorRatesByType = errorsByType.mapValues { events in
            let failed = events.filter { !$0.result.isValid }.count
            return events.isEmpty ? 0.0 : Double(failed) / Double(events.count)
        }
        
        return ValidationStatistics(
            totalValidations: totalEvents,
            passedValidations: passedEvents,
            failedValidations: failedEvents,
            errorRatesByType: errorRatesByType
        )
    }
}

// MARK: - Validation Statistics

/// Statistics about validation performance
public struct ValidationStatistics {
    public let totalValidations: Int
    public let passedValidations: Int
    public let failedValidations: Int
    public let errorRatesByType: [ValidationType: Double]
    
    public var overallSuccessRate: Double {
        guard totalValidations > 0 else { return 1.0 }
        return Double(passedValidations) / Double(totalValidations)
    }
    
    public var overallErrorRate: Double {
        return 1.0 - overallSuccessRate
    }
}

// MARK: - Extensions


// MARK: - Validation Error Extensions

extension ValidationError {
    
    /// Create a validation error for a specific validation type
    static func forValidationType(_ type: ValidationType, field: String, message: String, severity: ValidationSeverity) -> ValidationError {
        return ValidationError(
            field: field,
            message: message,
            severity: severity,
            context: ["validationType": type.rawValue]
        )
    }
    
    /// Create a critical validation error
    static func critical(field: String, message: String) -> ValidationError {
        return ValidationError(field: field, message: message, severity: .critical)
    }
    
    /// Create an error-level validation error
    static func error(field: String, message: String) -> ValidationError {
        return ValidationError(field: field, message: message, severity: .error)
    }
    
    /// Create a warning-level validation error
    static func warning(field: String, message: String) -> ValidationError {
        return ValidationError(field: field, message: message, severity: .warning)
    }
    
    /// Create an info-level validation error
    static func info(field: String, message: String) -> ValidationError {
        return ValidationError(field: field, message: message, severity: .info)
    }
}