import Foundation

// MARK: - Core Error Types

/// Comprehensive error system for WristQuest app
public enum WQError: Error, Equatable {
    case healthKit(HealthKitError)
    case persistence(PersistenceError)
    case quest(QuestError)
    case gameState(GameStateError)
    case network(NetworkError)
    case validation(ValidationError)
    case system(SystemError)
    
    // MARK: - Error Categories
    
    public enum HealthKitError: Error, Equatable {
        case healthDataNotAvailable
        case authorizationDenied
        case permissionRequired
        case queryFailed(String)
        case dataCorrupted
        case rateLimited
        case deviceNotSupported
        case backgroundQueryFailed
        
        var localizedDescription: String {
            switch self {
            case .healthDataNotAvailable:
                return "Health data is not available on this device"
            case .authorizationDenied:
                return "Health data access was denied"
            case .permissionRequired:
                return "Health data permission is required"
            case .queryFailed(let message):
                return "Health query failed: \(message)"
            case .dataCorrupted:
                return "Health data appears to be corrupted"
            case .rateLimited:
                return "Too many health data requests"
            case .deviceNotSupported:
                return "This device doesn't support required health features"
            case .backgroundQueryFailed:
                return "Background health monitoring failed"
            }
        }
        
        var userMessage: String {
            switch self {
            case .healthDataNotAvailable:
                return "Your device doesn't support health tracking for this app."
            case .authorizationDenied:
                return "Please allow health data access in Settings to track your adventures."
            case .permissionRequired:
                return "Health data permission is needed to power your quests with real activity."
            case .queryFailed:
                return "Unable to read your health data right now. Your progress is still saved."
            case .dataCorrupted:
                return "There's an issue with your health data. Try restarting the app."
            case .rateLimited:
                return "Please wait a moment before trying again."
            case .deviceNotSupported:
                return "Some features may not work on this device model."
            case .backgroundQueryFailed:
                return "Background tracking isn't working. Check your privacy settings."
            }
        }
    }
    
    public enum PersistenceError: Error, Equatable {
        case coreDataUnavailable
        case saveFailed(String)
        case loadFailed(String)
        case migrationFailed(String)
        case dataCorrupted
        case storageFullError
        case concurrencyConflict
        case constraintViolation(String)
        case entityNotFound(String)
        
        var localizedDescription: String {
            switch self {
            case .coreDataUnavailable:
                return "Database is unavailable"
            case .saveFailed(let message):
                return "Save operation failed: \(message)"
            case .loadFailed(let message):
                return "Load operation failed: \(message)"
            case .migrationFailed(let message):
                return "Data migration failed: \(message)"
            case .dataCorrupted:
                return "Saved data is corrupted"
            case .storageFullError:
                return "Device storage is full"
            case .concurrencyConflict:
                return "Data conflict occurred"
            case .constraintViolation(let message):
                return "Data constraint violated: \(message)"
            case .entityNotFound(let entityName):
                return "Required data not found: \(entityName)"
            }
        }
        
        var userMessage: String {
            switch self {
            case .coreDataUnavailable:
                return "Unable to access saved game data. Try restarting the app."
            case .saveFailed:
                return "Could not save your progress. Please try again."
            case .loadFailed:
                return "Could not load your saved game. Starting fresh."
            case .migrationFailed:
                return "There was an issue updating your saved data."
            case .dataCorrupted:
                return "Your saved data appears corrupted. You may need to start over."
            case .storageFullError:
                return "Your device is out of storage space."
            case .concurrencyConflict:
                return "Multiple changes detected. Please try again."
            case .constraintViolation:
                return "Invalid data detected. Please check your inputs."
            case .entityNotFound:
                return "Required game data is missing."
            }
        }
    }
    
    public enum QuestError: Error, Equatable {
        case questNotFound(UUID)
        case invalidQuestState(String)
        case progressionFailed(String)
        case completionFailed(String)
        case prerequisiteNotMet(String)
        case rewardCalculationFailed
        case encounterGenerationFailed
        case questDataCorrupted(UUID)
        
        var localizedDescription: String {
            switch self {
            case .questNotFound(let id):
                return "Quest not found: \(id)"
            case .invalidQuestState(let state):
                return "Invalid quest state: \(state)"
            case .progressionFailed(let reason):
                return "Quest progression failed: \(reason)"
            case .completionFailed(let reason):
                return "Quest completion failed: \(reason)"
            case .prerequisiteNotMet(let requirement):
                return "Quest prerequisite not met: \(requirement)"
            case .rewardCalculationFailed:
                return "Failed to calculate quest rewards"
            case .encounterGenerationFailed:
                return "Failed to generate quest encounter"
            case .questDataCorrupted(let id):
                return "Quest data corrupted: \(id)"
            }
        }
        
        var userMessage: String {
            switch self {
            case .questNotFound:
                return "This quest is no longer available."
            case .invalidQuestState:
                return "There's an issue with this quest. Try selecting a different one."
            case .progressionFailed:
                return "Unable to update quest progress. Keep adventuring!"
            case .completionFailed:
                return "Quest completion encountered an issue. Your progress is saved."
            case .prerequisiteNotMet(let requirement):
                return "You need to \(requirement) first."
            case .rewardCalculationFailed:
                return "Unable to calculate rewards right now."
            case .encounterGenerationFailed:
                return "Adventure encounter couldn't be created."
            case .questDataCorrupted:
                return "This quest has corrupted data. Try a different quest."
            }
        }
    }
    
    public enum GameStateError: Error, Equatable {
        case invalidTransition(from: String, to: String)
        case missingRequiredData(String)
        case stateCorrupted(String)
        case synchronizationFailed
        case initializationFailed(String)
        case playerNotLoaded
        case concurrentStateChange
        
        var localizedDescription: String {
            switch self {
            case .invalidTransition(let from, let to):
                return "Invalid state transition from \(from) to \(to)"
            case .missingRequiredData(let data):
                return "Missing required data: \(data)"
            case .stateCorrupted(let state):
                return "Game state corrupted: \(state)"
            case .synchronizationFailed:
                return "Game state synchronization failed"
            case .initializationFailed(let reason):
                return "Game initialization failed: \(reason)"
            case .playerNotLoaded:
                return "Player data not loaded"
            case .concurrentStateChange:
                return "Concurrent state change detected"
            }
        }
        
        var userMessage: String {
            switch self {
            case .invalidTransition:
                return "Can't perform that action right now."
            case .missingRequiredData:
                return "Some game data is missing. Try restarting."
            case .stateCorrupted:
                return "Game state issue detected. Restarting may help."
            case .synchronizationFailed:
                return "Game sync failed. Your progress is still saved."
            case .initializationFailed:
                return "Game failed to start properly. Please restart."
            case .playerNotLoaded:
                return "Character data not loaded. Try restarting the app."
            case .concurrentStateChange:
                return "Multiple actions detected. Please wait and try again."
            }
        }
    }
    
    public enum NetworkError: Error, Equatable {
        case noConnection
        case timeout
        case serverError(Int)
        case invalidResponse
        case rateLimited
        case authenticationFailed
        case badRequest(String)
        
        var localizedDescription: String {
            switch self {
            case .noConnection:
                return "No network connection"
            case .timeout:
                return "Request timed out"
            case .serverError(let code):
                return "Server error: \(code)"
            case .invalidResponse:
                return "Invalid server response"
            case .rateLimited:
                return "Too many requests"
            case .authenticationFailed:
                return "Authentication failed"
            case .badRequest(let message):
                return "Bad request: \(message)"
            }
        }
        
        var userMessage: String {
            switch self {
            case .noConnection:
                return "No internet connection. You can still play offline!"
            case .timeout:
                return "Connection timed out. Please try again."
            case .serverError:
                return "Server is having issues. Try again later."
            case .invalidResponse:
                return "Received unexpected response from server."
            case .rateLimited:
                return "Please wait before trying again."
            case .authenticationFailed:
                return "Authentication failed. Please sign in again."
            case .badRequest:
                return "Invalid request. Please check your input."
            }
        }
    }
    
    public enum ValidationError: Error, Equatable {
        case invalidPlayerName(String)
        case invalidHeroClass
        case invalidQuestData(String)
        case constraintViolation(String)
        case dataFormatError(String)
        case rangeError(String)
        
        var localizedDescription: String {
            switch self {
            case .invalidPlayerName(let name):
                return "Invalid player name: \(name)"
            case .invalidHeroClass:
                return "Invalid hero class selected"
            case .invalidQuestData(let issue):
                return "Invalid quest data: \(issue)"
            case .constraintViolation(let constraint):
                return "Constraint violation: \(constraint)"
            case .dataFormatError(let format):
                return "Data format error: \(format)"
            case .rangeError(let range):
                return "Value out of range: \(range)"
            }
        }
        
        var userMessage: String {
            switch self {
            case .invalidPlayerName:
                return "Please choose a valid hero name (3-20 characters)."
            case .invalidHeroClass:
                return "Please select a valid hero class."
            case .invalidQuestData:
                return "Quest data is invalid. Try a different quest."
            case .constraintViolation(let constraint):
                return "Invalid input: \(constraint)"
            case .dataFormatError:
                return "Data format is incorrect."
            case .rangeError(let range):
                return "Value must be \(range)."
            }
        }
    }
    
    public enum SystemError: Error, Equatable {
        case insufficientMemory
        case diskSpaceError
        case permissionDenied(String)
        case deviceCompatibility(String)
        case osVersionNotSupported
        case backgroundProcessingFailed
        case resourceUnavailable(String)
        
        var localizedDescription: String {
            switch self {
            case .insufficientMemory:
                return "Insufficient memory"
            case .diskSpaceError:
                return "Insufficient disk space"
            case .permissionDenied(let permission):
                return "Permission denied: \(permission)"
            case .deviceCompatibility(let issue):
                return "Device compatibility issue: \(issue)"
            case .osVersionNotSupported:
                return "OS version not supported"
            case .backgroundProcessingFailed:
                return "Background processing failed"
            case .resourceUnavailable(let resource):
                return "Resource unavailable: \(resource)"
            }
        }
        
        var userMessage: String {
            switch self {
            case .insufficientMemory:
                return "Device is low on memory. Close other apps and try again."
            case .diskSpaceError:
                return "Device is out of storage space."
            case .permissionDenied(let permission):
                return "Permission required: \(permission). Check Settings."
            case .deviceCompatibility:
                return "Your device may not support all features."
            case .osVersionNotSupported:
                return "Please update your device's software."
            case .backgroundProcessingFailed:
                return "Background updates aren't working properly."
            case .resourceUnavailable:
                return "Required system resource is unavailable."
            }
        }
    }
}

// MARK: - Error Properties and Helpers

extension WQError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .healthKit(let error):
            return error.localizedDescription
        case .persistence(let error):
            return error.localizedDescription
        case .quest(let error):
            return error.localizedDescription
        case .gameState(let error):
            return error.localizedDescription
        case .network(let error):
            return error.localizedDescription
        case .validation(let error):
            return error.localizedDescription
        case .system(let error):
            return error.localizedDescription
        }
    }
    
    /// User-friendly error message
    public var userMessage: String {
        switch self {
        case .healthKit(let error):
            return error.userMessage
        case .persistence(let error):
            return error.userMessage
        case .quest(let error):
            return error.userMessage
        case .gameState(let error):
            return error.userMessage
        case .network(let error):
            return error.userMessage
        case .validation(let error):
            return error.userMessage
        case .system(let error):
            return error.userMessage
        }
    }
    
    /// Error category for analytics and logging
    public var category: ErrorCategory {
        switch self {
        case .healthKit:
            return .healthKit
        case .persistence:
            return .persistence
        case .quest:
            return .quest
        case .gameState:
            return .gameState
        case .network:
            return .network
        case .validation:
            return .validation
        case .system:
            return .system
        }
    }
    
    /// Error severity level
    public var severity: ErrorSeverity {
        switch self {
        case .healthKit(.healthDataNotAvailable), .healthKit(.deviceNotSupported):
            return .critical
        case .persistence(.coreDataUnavailable), .persistence(.dataCorrupted):
            return .critical
        case .gameState(.playerNotLoaded), .gameState(.initializationFailed):
            return .critical
        case .system(.insufficientMemory), .system(.osVersionNotSupported):
            return .critical
        case .persistence(.saveFailed), .quest(.completionFailed):
            return .high
        case .healthKit(.authorizationDenied), .healthKit(.permissionRequired):
            return .medium
        case .network(.noConnection), .quest(.progressionFailed):
            return .low
        default:
            return .medium
        }
    }
    
    /// Whether this error should be retryable
    public var isRetryable: Bool {
        switch self {
        case .healthKit(.rateLimited), .healthKit(.queryFailed):
            return true
        case .persistence(.saveFailed), .persistence(.loadFailed):
            return true
        case .network(.timeout), .network(.serverError):
            return true
        case .quest(.progressionFailed), .quest(.rewardCalculationFailed):
            return true
        case .system(.backgroundProcessingFailed):
            return true
        default:
            return false
        }
    }
}

// MARK: - Supporting Types

public enum ErrorCategory: String, CaseIterable {
    case healthKit = "health_kit"
    case persistence = "persistence"
    case quest = "quest"
    case gameState = "game_state" 
    case network = "network"
    case validation = "validation"
    case system = "system"
}

public enum ErrorSeverity: String, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
}

// MARK: - Error Context

public struct ErrorContext {
    public let timestamp: Date
    public let userAction: String?
    public let gameState: String?
    public let additionalInfo: [String: Any]
    
    public init(userAction: String? = nil, gameState: String? = nil, additionalInfo: [String: Any] = [:]) {
        self.timestamp = Date()
        self.userAction = userAction
        self.gameState = gameState
        self.additionalInfo = additionalInfo
    }
}

// MARK: - Recovery Option

public enum RecoveryOption: Equatable {
    case retry
    case retryWithDelay(TimeInterval)
    case fallback(String)
    case openSettings(String)
    case restart
    case skip
    case goToOnboarding
    case contactSupport
    case custom(String, String) // title, action
    
    public var title: String {
        switch self {
        case .retry:
            return "Try Again"
        case .retryWithDelay(let delay):
            return "Retry in \(Int(delay))s"
        case .fallback(let title):
            return title
        case .openSettings:
            return "Open Settings"
        case .restart:
            return "Restart App"
        case .skip:
            return "Skip"
        case .goToOnboarding:
            return "Start Over"
        case .contactSupport:
            return "Get Help"
        case .custom(let title, _):
            return title
        }
    }
    
    public var actionDescription: String {
        switch self {
        case .retry:
            return "retry_action"
        case .retryWithDelay:
            return "retry_with_delay"
        case .fallback(let action):
            return action
        case .openSettings(let setting):
            return "open_settings_\(setting)"
        case .restart:
            return "restart_app"
        case .skip:
            return "skip_action"
        case .goToOnboarding:
            return "go_to_onboarding"
        case .contactSupport:
            return "contact_support"
        case .custom(_, let action):
            return action
        }
    }
}

