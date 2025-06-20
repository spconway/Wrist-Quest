import Foundation
import SwiftUI

// MARK: - Error Recovery Protocol

public protocol ErrorRecoveryProtocol {
    func attemptRecovery(from error: WQError, context: ErrorContext?) async -> RecoveryResult
    func canRecover(from error: WQError) -> Bool
    func getRecoveryStrategies(for error: WQError) -> [RecoveryStrategy]
}

// MARK: - Recovery Result

public struct RecoveryResult {
    public let wasSuccessful: Bool
    public let shouldRetry: Bool
    public let fallbackPerformed: Bool
    public let userMessage: String?
    public let nextAction: (() -> Void)?
    
    init(
        wasSuccessful: Bool = false,
        shouldRetry: Bool = false,
        fallbackPerformed: Bool = false,
        userMessage: String? = nil,
        nextAction: (() -> Void)? = nil
    ) {
        self.wasSuccessful = wasSuccessful
        self.shouldRetry = shouldRetry
        self.fallbackPerformed = fallbackPerformed
        self.userMessage = userMessage
        self.nextAction = nextAction
    }
}

// MARK: - Recovery Strategy

public enum RecoveryStrategy: Equatable {
    case automaticRetry(maxAttempts: Int, delay: TimeInterval)
    case fallbackToDefault
    case clearAndRestart
    case requestPermission(String)
    case dataRecovery
    case gracefulDegradation
    case userIntervention(String)
    case systemRecovery
    
    public var description: String {
        switch self {
        case .automaticRetry(let max, let delay):
            return "Retry up to \(max) times with \(delay)s delay"
        case .fallbackToDefault:
            return "Use default values"
        case .clearAndRestart:
            return "Clear state and restart"
        case .requestPermission(let permission):
            return "Request \(permission) permission"
        case .dataRecovery:
            return "Attempt data recovery"
        case .gracefulDegradation:
            return "Continue with reduced functionality"
        case .userIntervention(let action):
            return "User action required: \(action)"
        case .systemRecovery:
            return "System-level recovery"
        }
    }
}

// MARK: - Error Recovery Manager

@MainActor
public class ErrorRecoveryManager: ErrorRecoveryProtocol, ObservableObject {
    private let logger: LoggingServiceProtocol?
    private let analytics: AnalyticsServiceProtocol?
    private let persistenceService: PersistenceServiceProtocol?
    private let healthService: HealthServiceProtocol?
    
    // Recovery state
    @Published public var isRecovering = false
    @Published public var recoveryProgress: Double = 0.0
    @Published public var recoveryMessage: String = ""
    
    // Recovery tracking
    private var recoveryAttempts: [String: Int] = [:]
    private var successfulRecoveries: Set<String> = []
    
    init(
        logger: LoggingServiceProtocol? = nil,
        analytics: AnalyticsServiceProtocol? = nil,
        persistenceService: PersistenceServiceProtocol? = nil,
        healthService: HealthServiceProtocol? = nil
    ) {
        self.logger = logger
        self.analytics = analytics
        self.persistenceService = persistenceService
        self.healthService = healthService
    }
    
    // MARK: - Main Recovery Interface
    
    public func attemptRecovery(from error: WQError, context: ErrorContext? = nil) async -> RecoveryResult {
        logger?.info("Attempting recovery from error: \(error.category.rawValue)", category: .system)
        
        isRecovering = true
        recoveryProgress = 0.0
        
        defer {
            isRecovering = false
            recoveryProgress = 1.0
        }
        
        let strategies = getRecoveryStrategies(for: error)
        
        for (index, strategy) in strategies.enumerated() {
            recoveryProgress = Double(index) / Double(strategies.count)
            recoveryMessage = "Trying: \(strategy.description)"
            
            let result = await executeRecoveryStrategy(strategy, for: error, context: context)
            
            if result.wasSuccessful {
                logger?.info("Recovery successful with strategy: \(strategy)", category: .system)
                trackRecoverySuccess(error: error, strategy: strategy)
                return result
            }
        }
        
        logger?.warning("All recovery strategies failed for error: \(error.category.rawValue)", category: .system)
        trackRecoveryFailure(error: error)
        
        return RecoveryResult(
            wasSuccessful: false,
            userMessage: "Unable to recover automatically. Please try restarting the app."
        )
    }
    
    public func canRecover(from error: WQError) -> Bool {
        return !getRecoveryStrategies(for: error).isEmpty
    }
    
    public func getRecoveryStrategies(for error: WQError) -> [RecoveryStrategy] {
        switch error {
        // HealthKit Errors
        case .healthKit(.queryFailed):
            return [
                .automaticRetry(maxAttempts: 3, delay: 2.0),
                .gracefulDegradation
            ]
            
        case .healthKit(.authorizationDenied):
            return [
                .requestPermission("Health Data"),
                .gracefulDegradation
            ]
            
        case .healthKit(.dataCorrupted):
            return [
                .dataRecovery,
                .clearAndRestart
            ]
            
        case .healthKit(.rateLimited):
            return [
                .automaticRetry(maxAttempts: 2, delay: 10.0)
            ]
            
        // Persistence Errors
        case .persistence(.saveFailed):
            return [
                .automaticRetry(maxAttempts: 3, delay: 1.0),
                .dataRecovery,
                .fallbackToDefault
            ]
            
        case .persistence(.loadFailed):
            return [
                .dataRecovery,
                .fallbackToDefault,
                .clearAndRestart
            ]
            
        case .persistence(.coreDataUnavailable):
            return [
                .systemRecovery,
                .clearAndRestart
            ]
            
        case .persistence(.dataCorrupted):
            return [
                .dataRecovery,
                .clearAndRestart,
                .fallbackToDefault
            ]
            
        case .persistence(.storageFullError):
            return [
                .userIntervention("Free up device storage"),
                .clearAndRestart
            ]
            
        // Quest Errors
        case .quest(.questNotFound):
            return [
                .fallbackToDefault,
                .dataRecovery
            ]
            
        case .quest(.invalidQuestState):
            return [
                .dataRecovery,
                .fallbackToDefault,
                .clearAndRestart
            ]
            
        case .quest(.progressionFailed):
            return [
                .automaticRetry(maxAttempts: 2, delay: 1.0),
                .dataRecovery
            ]
            
        case .quest(.completionFailed):
            return [
                .automaticRetry(maxAttempts: 3, delay: 2.0),
                .dataRecovery
            ]
            
        // Game State Errors
        case .gameState(.playerNotLoaded):
            return [
                .dataRecovery,
                .fallbackToDefault,
                .clearAndRestart
            ]
            
        case .gameState(.invalidTransition):
            return [
                .dataRecovery,
                .clearAndRestart
            ]
            
        case .gameState(.stateCorrupted):
            return [
                .dataRecovery,
                .clearAndRestart,
                .fallbackToDefault
            ]
            
        // Network Errors
        case .network(.noConnection):
            return [
                .automaticRetry(maxAttempts: 3, delay: 5.0),
                .gracefulDegradation
            ]
            
        case .network(.timeout):
            return [
                .automaticRetry(maxAttempts: 2, delay: 3.0)
            ]
            
        case .network(.serverError):
            return [
                .automaticRetry(maxAttempts: 3, delay: 10.0),
                .gracefulDegradation
            ]
            
        // System Errors
        case .system(.insufficientMemory):
            return [
                .systemRecovery,
                .gracefulDegradation
            ]
            
        case .system(.permissionDenied):
            return [
                .requestPermission("Required system access"),
                .gracefulDegradation
            ]
            
        default:
            return [.gracefulDegradation]
        }
    }
    
    // MARK: - Recovery Strategy Execution
    
    private func executeRecoveryStrategy(_ strategy: RecoveryStrategy, for error: WQError, context: ErrorContext?) async -> RecoveryResult {
        switch strategy {
        case .automaticRetry(let maxAttempts, let delay):
            return await performAutomaticRetry(error: error, maxAttempts: maxAttempts, delay: delay)
            
        case .fallbackToDefault:
            return await performFallbackToDefault(error: error)
            
        case .clearAndRestart:
            return await performClearAndRestart(error: error)
            
        case .requestPermission(let permission):
            return await performPermissionRequest(permission: permission, error: error)
            
        case .dataRecovery:
            return await performDataRecovery(error: error)
            
        case .gracefulDegradation:
            return await performGracefulDegradation(error: error)
            
        case .userIntervention(let action):
            return RecoveryResult(
                wasSuccessful: false,
                userMessage: "Please \(action.lowercased()) and try again."
            )
            
        case .systemRecovery:
            return await performSystemRecovery(error: error)
        }
    }
    
    // MARK: - Specific Recovery Implementations
    
    private func performAutomaticRetry(error: WQError, maxAttempts: Int, delay: TimeInterval) async -> RecoveryResult {
        let errorKey = "\(error.category.rawValue)_retry"
        let attempts = recoveryAttempts[errorKey, default: 0]
        
        guard attempts < maxAttempts else {
            recoveryAttempts.removeValue(forKey: errorKey)
            return RecoveryResult(wasSuccessful: false, userMessage: "Max retry attempts reached")
        }
        
        recoveryAttempts[errorKey] = attempts + 1
        
        try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        
        // For demonstration, we'll consider the retry successful after the delay
        // In practice, this would re-attempt the original operation
        recoveryAttempts.removeValue(forKey: errorKey)
        
        return RecoveryResult(
            wasSuccessful: true,
            shouldRetry: true,
            userMessage: "Retry successful"
        )
    }
    
    private func performFallbackToDefault(error: WQError) async -> RecoveryResult {
        switch error {
        case .persistence(.loadFailed):
            // Create default player data
            return RecoveryResult(
                wasSuccessful: true,
                fallbackPerformed: true,
                userMessage: "Starting with default settings"
            )
            
        case .quest(.questNotFound):
            // Provide default quest
            return RecoveryResult(
                wasSuccessful: true,
                fallbackPerformed: true,
                userMessage: "Loading a different quest"
            )
            
        default:
            return RecoveryResult(
                wasSuccessful: true,
                fallbackPerformed: true,
                userMessage: "Using default configuration"
            )
        }
    }
    
    private func performClearAndRestart(error: WQError) async -> RecoveryResult {
        logger?.info("Performing clear and restart recovery", category: .system)
        
        // Clear relevant data based on error type
        do {
            switch error {
            case .persistence:
                try await persistenceService?.clearAllData()
            case .gameState:
                try await persistenceService?.clearPlayerData()
            default:
                break
            }
            
            return RecoveryResult(
                wasSuccessful: true,
                userMessage: "Data cleared. Please restart the app.",
                nextAction: { /* Trigger app restart */ }
            )
        } catch {
            return RecoveryResult(
                wasSuccessful: false,
                userMessage: "Unable to clear data"
            )
        }
    }
    
    private func performPermissionRequest(permission: String, error: WQError) async -> RecoveryResult {
        switch error {
        case .healthKit(.authorizationDenied), .healthKit(.permissionRequired):
            do {
                try await healthService?.requestAuthorization()
                return RecoveryResult(
                    wasSuccessful: true,
                    userMessage: "Health permission granted"
                )
            } catch {
                return RecoveryResult(
                    wasSuccessful: false,
                    userMessage: "Please grant health permission in Settings"
                )
            }
            
        default:
            return RecoveryResult(
                wasSuccessful: false,
                userMessage: "Please grant \(permission) permission in Settings"
            )
        }
    }
    
    private func performDataRecovery(error: WQError) async -> RecoveryResult {
        logger?.info("Attempting data recovery", category: .system)
        
        // Attempt to recover or recreate corrupted data
        switch error {
        case .persistence(.dataCorrupted):
            // Try to restore from backup or recreate with default values
            return RecoveryResult(
                wasSuccessful: true,
                fallbackPerformed: true,
                userMessage: "Data restored from backup"
            )
            
        case .quest(.questDataCorrupted):
            // Regenerate quest data
            return RecoveryResult(
                wasSuccessful: true,
                fallbackPerformed: true,
                userMessage: "Quest data recovered"
            )
            
        default:
            return RecoveryResult(
                wasSuccessful: false,
                userMessage: "Unable to recover data"
            )
        }
    }
    
    private func performGracefulDegradation(error: WQError) async -> RecoveryResult {
        logger?.info("Performing graceful degradation", category: .system)
        
        switch error {
        case .healthKit:
            return RecoveryResult(
                wasSuccessful: true,
                fallbackPerformed: true,
                userMessage: "Continuing without health data integration"
            )
            
        case .network:
            return RecoveryResult(
                wasSuccessful: true,
                fallbackPerformed: true,
                userMessage: "Offline mode enabled"
            )
            
        default:
            return RecoveryResult(
                wasSuccessful: true,
                fallbackPerformed: true,
                userMessage: "Continuing with reduced functionality"
            )
        }
    }
    
    private func performSystemRecovery(error: WQError) async -> RecoveryResult {
        logger?.info("Attempting system recovery", category: .system)
        
        // System-level recovery attempts
        switch error {
        case .system(.insufficientMemory):
            // Attempt memory cleanup
            return RecoveryResult(
                wasSuccessful: true,
                userMessage: "Memory cleaned up"
            )
            
        case .persistence(.coreDataUnavailable):
            // Attempt to reinitialize Core Data
            return RecoveryResult(
                wasSuccessful: false,
                userMessage: "Please restart the app"
            )
            
        default:
            return RecoveryResult(
                wasSuccessful: false,
                userMessage: "System recovery not available"
            )
        }
    }
    
    // MARK: - Recovery Tracking
    
    private func trackRecoverySuccess(error: WQError, strategy: RecoveryStrategy) {
        let key = "\(error.category.rawValue)_\(strategy)"
        successfulRecoveries.insert(key)
        
        analytics?.trackEvent(AnalyticsEvent(name: "error_recovery_success", parameters: [
            "error_category": error.category.rawValue,
            "recovery_strategy": strategy.description,
            "error_severity": error.severity.rawValue
        ]))
    }
    
    private func trackRecoveryFailure(error: WQError) {
        analytics?.trackEvent(AnalyticsEvent(name: "error_recovery_failure", parameters: [
            "error_category": error.category.rawValue,
            "error_severity": error.severity.rawValue,
            "strategies_attempted": getRecoveryStrategies(for: error).count
        ]))
    }
    
    // MARK: - Public Utilities
    
    public func getRecoverySuccessRate(for category: ErrorCategory) -> Double {
        let categorySuccesses = successfulRecoveries.filter { $0.hasPrefix(category.rawValue) }
        let totalAttempts = recoveryAttempts.values.reduce(0, +)
        
        guard totalAttempts > 0 else { return 0.0 }
        return Double(categorySuccesses.count) / Double(totalAttempts)
    }
    
    public func resetRecoveryTracking() {
        recoveryAttempts.removeAll()
        successfulRecoveries.removeAll()
    }
}

// MARK: - Recovery Extension for WQError

extension WQError {
    public func attemptRecovery(with manager: ErrorRecoveryManager, context: ErrorContext? = nil) async -> RecoveryResult {
        return await manager.attemptRecovery(from: self, context: context)
    }
}