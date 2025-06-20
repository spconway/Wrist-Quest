import Foundation
import SwiftUI

// MARK: - Error Handler Protocol

public protocol ErrorHandlerProtocol {
    func handle(_ error: WQError, context: ErrorContext?) async -> ErrorHandlingResult
    func reportError(_ error: WQError, context: ErrorContext?) async
    func getRecoveryOptions(for error: WQError) async -> [RecoveryOption]
    func canRecover(from error: WQError) async -> Bool
}

// MARK: - Error Handling Result

public struct ErrorHandlingResult {
    public let wasHandled: Bool
    public let shouldRetry: Bool
    public let retryDelay: TimeInterval?
    public let fallbackAction: (() -> Void)?
    public let userMessage: String?
    public let recoveryOptions: [RecoveryOption]
    
    public init(
        wasHandled: Bool = true,
        shouldRetry: Bool = false,
        retryDelay: TimeInterval? = nil,
        fallbackAction: (() -> Void)? = nil,
        userMessage: String? = nil,
        recoveryOptions: [RecoveryOption] = []
    ) {
        self.wasHandled = wasHandled
        self.shouldRetry = shouldRetry
        self.retryDelay = retryDelay
        self.fallbackAction = fallbackAction
        self.userMessage = userMessage
        self.recoveryOptions = recoveryOptions
    }
}

// MARK: - Default Error Handler

@MainActor
public class ErrorHandler: ErrorHandlerProtocol, ObservableObject {
    private let logger: LoggingServiceProtocol?
    private let analytics: AnalyticsServiceProtocol?
    
    // Error state management
    @Published public var currentError: WQError?
    @Published public var errorMessage: String?
    @Published public var isShowingError = false
    @Published public var recoveryOptions: [RecoveryOption] = []
    
    // Retry mechanism state
    private var retryAttempts: [String: Int] = [:]
    private var lastErrorTime: [String: Date] = [:]
    
    // Configuration
    private let maxRetryAttempts = 3
    private let retryBackoffMultiplier: TimeInterval = 2.0
    private let baseRetryDelay: TimeInterval = 1.0
    
    init(logger: LoggingServiceProtocol? = nil, analytics: AnalyticsServiceProtocol? = nil) {
        self.logger = logger
        self.analytics = analytics
    }
    
    // MARK: - Main Error Handling
    
    public func handle(_ error: WQError, context: ErrorContext? = nil) async -> ErrorHandlingResult {
        logger?.error("Handling error: \(error.errorDescription ?? "Unknown")", category: .system)
        
        // Report error for tracking
        await reportError(error, context: context)
        
        // Update UI state
        await MainActor.run {
            currentError = error
            errorMessage = error.userMessage
            isShowingError = true
        }
        
        // Get recovery options asynchronously
        let options = await getRecoveryOptions(for: error)
        await MainActor.run {
            recoveryOptions = options
        }
        
        // Handle based on error type and severity
        switch error.severity {
        case .critical:
            return await handleCriticalError(error, context: context)
        case .high:
            return await handleHighSeverityError(error, context: context)
        case .medium:
            return await handleMediumSeverityError(error, context: context)
        case .low:
            return await handleLowSeverityError(error, context: context)
        }
    }
    
    // MARK: - Error Severity Handlers
    
    private func handleCriticalError(_ error: WQError, context: ErrorContext?) async -> ErrorHandlingResult {
        logger?.fault("Critical error occurred: \(error)", category: .system)
        
        switch error {
        case .persistence(.coreDataUnavailable):
            return ErrorHandlingResult(
                wasHandled: true,
                shouldRetry: false,
                userMessage: error.userMessage,
                recoveryOptions: [.restart, .contactSupport]
            )
            
        case .gameState(.playerNotLoaded):
            return ErrorHandlingResult(
                wasHandled: true,
                shouldRetry: false,
                userMessage: error.userMessage,
                recoveryOptions: [.goToOnboarding, .restart]
            )
            
        case .healthKit(.healthDataNotAvailable):
            return ErrorHandlingResult(
                wasHandled: true,
                shouldRetry: false,
                userMessage: error.userMessage,
                recoveryOptions: [.skip, .contactSupport]
            )
            
        default:
            return ErrorHandlingResult(
                wasHandled: true,
                shouldRetry: false,
                userMessage: error.userMessage,
                recoveryOptions: [.restart, .contactSupport]
            )
        }
    }
    
    private func handleHighSeverityError(_ error: WQError, context: ErrorContext?) async -> ErrorHandlingResult {
        logger?.error("High severity error: \(error)", category: .system)
        
        switch error {
        case .persistence(.saveFailed):
            return await handleRetryableError(error, maxRetries: 3, baseDelay: 2.0)
            
        case .quest(.completionFailed):
            return ErrorHandlingResult(
                wasHandled: true,
                shouldRetry: true,
                retryDelay: 1.0,
                userMessage: error.userMessage,
                recoveryOptions: [.retry, .skip]
            )
            
        default:
            return await handleRetryableError(error, maxRetries: 2, baseDelay: 1.0)
        }
    }
    
    private func handleMediumSeverityError(_ error: WQError, context: ErrorContext?) async -> ErrorHandlingResult {
        logger?.warning("Medium severity error: \(error)", category: .system)
        
        switch error {
        case .healthKit(.authorizationDenied):
            return ErrorHandlingResult(
                wasHandled: true,
                shouldRetry: false,
                userMessage: error.userMessage,
                recoveryOptions: [.openSettings("Privacy & Security > Health"), .skip]
            )
            
        case .validation:
            return ErrorHandlingResult(
                wasHandled: true,
                shouldRetry: false,
                userMessage: error.userMessage,
                recoveryOptions: [.custom("Fix Input", "fix_input")]
            )
            
        default:
            return await handleRetryableError(error, maxRetries: 2, baseDelay: 1.0)
        }
    }
    
    private func handleLowSeverityError(_ error: WQError, context: ErrorContext?) async -> ErrorHandlingResult {
        logger?.info("Low severity error: \(error)", category: .system)
        
        // For low severity errors, we often want to handle them silently or with minimal user impact
        switch error {
        case .network(.noConnection):
            return ErrorHandlingResult(
                wasHandled: true,
                shouldRetry: true,
                retryDelay: 5.0,
                userMessage: error.userMessage,
                recoveryOptions: [.retryWithDelay(5.0), .skip]
            )
            
        case .quest(.progressionFailed):
            return ErrorHandlingResult(
                wasHandled: true,
                shouldRetry: true,
                retryDelay: 2.0,
                userMessage: nil, // Handle silently
                recoveryOptions: []
            )
            
        default:
            return await handleRetryableError(error, maxRetries: 1, baseDelay: 1.0)
        }
    }
    
    // MARK: - Retry Logic
    
    private func handleRetryableError(_ error: WQError, maxRetries: Int, baseDelay: TimeInterval) async -> ErrorHandlingResult {
        let errorKey = getErrorKey(for: error)
        let attempts = retryAttempts[errorKey, default: 0]
        
        if attempts < maxRetries && error.isRetryable {
            retryAttempts[errorKey] = attempts + 1
            let delay = calculateRetryDelay(attempt: attempts, baseDelay: baseDelay)
            
            return ErrorHandlingResult(
                wasHandled: true,
                shouldRetry: true,
                retryDelay: delay,
                userMessage: attempts > 0 ? error.userMessage : nil,
                recoveryOptions: attempts > 0 ? [.retry, .skip] : []
            )
        } else {
            // Max retries reached
            retryAttempts.removeValue(forKey: errorKey)
            return ErrorHandlingResult(
                wasHandled: true,
                shouldRetry: false,
                userMessage: error.userMessage,
                recoveryOptions: getRecoveryOptions(for: error)
            )
        }
    }
    
    private func calculateRetryDelay(attempt: Int, baseDelay: TimeInterval) -> TimeInterval {
        return baseDelay * pow(retryBackoffMultiplier, Double(attempt))
    }
    
    private func getErrorKey(for error: WQError) -> String {
        return "\(error.category.rawValue)_\(error.errorDescription?.hash ?? 0)"
    }
    
    // MARK: - Recovery Options
    
    public func getRecoveryOptions(for error: WQError) -> [RecoveryOption] {
        switch error {
        case .healthKit(.authorizationDenied), .healthKit(.permissionRequired):
            return [.openSettings("Privacy & Security > Health"), .skip]
            
        case .persistence(.saveFailed), .persistence(.loadFailed):
            return [.retry, .restart]
            
        case .quest(.questNotFound), .quest(.questDataCorrupted):
            return [.fallback("Choose Different Quest"), .goToOnboarding]
            
        case .gameState(.playerNotLoaded), .gameState(.initializationFailed):
            return [.goToOnboarding, .restart]
            
        case .network(.noConnection):
            return [.retryWithDelay(5.0), .skip]
            
        case .validation:
            return [.custom("Fix Input", "fix_input")]
            
        case .system(.permissionDenied):
            return [.openSettings("Privacy & Security"), .contactSupport]
            
        default:
            if error.isRetryable {
                return [.retry, .skip]
            } else {
                return [.restart, .contactSupport]
            }
        }
    }
    
    public func canRecover(from error: WQError) -> Bool {
        return !getRecoveryOptions(for: error).isEmpty
    }
    
    // MARK: - Error Reporting
    
    public func reportError(_ error: WQError, context: ErrorContext? = nil) async {
        let errorContext = context ?? ErrorContext()
        
        // Log to logging service
        logger?.error(
            "WQError reported: \(error.errorDescription ?? "Unknown") [Category: \(error.category.rawValue), Severity: \(error.severity.rawValue), Retryable: \(error.isRetryable)]",
            category: .system
        )
        
        // Track with analytics
        analytics?.trackError(
            NSError(domain: "WQError", code: error.errorDescription?.hash ?? 0, userInfo: [
                NSLocalizedDescriptionKey: error.errorDescription ?? "Unknown error"
            ]),
            context: "ErrorHandler.reportError",
        )
    }
    
    // MARK: - Public Interface
    
    public func clearError() {
        currentError = nil
        errorMessage = nil
        isShowingError = false
        recoveryOptions = []
    }
    
    public func executeRecoveryOption(_ option: RecoveryOption) {
        switch option {
        case .retry:
            // Handled by caller
            break
            
        case .retryWithDelay(let delay):
            Task {
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                // Handled by caller
            }
            
        case .openSettings(let path):
            openSystemSettings(path: path)
            
        case .restart:
            // This would typically be handled by the app coordinator
            break
            
        case .skip:
            clearError()
            
        case .goToOnboarding:
            // This would be handled by the navigation system
            break
            
        case .contactSupport:
            openSupportContact()
            
        case .custom(_, let action):
            // Custom actions handled by caller
            break
            
        default:
            break
        }
    }
    
    // MARK: - System Integration
    
    private func openSystemSettings(path: String) {
        #if os(iOS)
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
        #else
        // For watchOS, we can't directly open settings
        logger?.info("Settings path requested: \(path)", category: .system)
        #endif
    }
    
    private func openSupportContact() {
        // This would open support contact method
        logger?.info("Support contact requested", category: .system)
    }
    
    // MARK: - Error Prevention
    
    public func resetRetryCount(for error: WQError) {
        let errorKey = getErrorKey(for: error)
        retryAttempts.removeValue(forKey: errorKey)
    }
    
    public func shouldThrottle(error: WQError, throttleWindow: TimeInterval = 60.0) -> Bool {
        let errorKey = getErrorKey(for: error)
        
        if let lastTime = lastErrorTime[errorKey] {
            return Date().timeIntervalSince(lastTime) < throttleWindow
        }
        
        lastErrorTime[errorKey] = Date()
        return false
    }
}

// MARK: - Convenience Extensions

extension WQError {
    public func handle(with handler: ErrorHandlerProtocol, context: ErrorContext? = nil) async -> ErrorHandlingResult {
        return await handler.handle(self, context: context)
    }
}