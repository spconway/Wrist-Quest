import Foundation

// MARK: - Validation Rule Protocol

/// Protocol defining validation rules for input data
protocol ValidationRule {
    associatedtype T
    func validate(_ value: T) -> ValidationResult
}

// MARK: - Validation Result

/// Result of a validation operation
public enum ValidationResult: Equatable {
    case valid
    case invalid(message: String, severity: ValidationSeverity)
    
    public var isValid: Bool {
        switch self {
        case .valid:
            return true
        case .invalid:
            return false
        }
    }
    
    public var message: String? {
        switch self {
        case .valid:
            return nil
        case .invalid(let message, _):
            return message
        }
    }
    
    public var severity: ValidationSeverity {
        switch self {
        case .valid:
            return .info
        case .invalid(_, let severity):
            return severity
        }
    }
}

// MARK: - Validation Severity

/// Severity levels for validation errors
public enum ValidationSeverity: String, CaseIterable {
    case info = "info"           // Informational, no action needed
    case warning = "warning"     // User can proceed with warning
    case error = "error"         // Must be fixed before proceeding
    case critical = "critical"   // Potential security/data integrity issue
    
    public var canProceed: Bool {
        switch self {
        case .info, .warning:
            return true
        case .error, .critical:
            return false
        }
    }
}

// MARK: - Player Validation Rules

/// Validation rules for player name
struct PlayerNameValidationRule: ValidationRule {
    func validate(_ value: String) -> ValidationResult {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check empty
        guard !trimmed.isEmpty else {
            return .invalid(message: "Hero name cannot be empty", severity: .error)
        }
        
        // Check length
        guard trimmed.count >= WQC.Validation.Player.minNameLength else {
            return .invalid(message: "Hero name must be at least \(WQC.Validation.Player.minNameLength) characters", severity: .error)
        }
        
        guard trimmed.count <= WQC.Validation.Player.maxNameLength else {
            return .invalid(message: "Hero name cannot exceed \(WQC.Validation.Player.maxNameLength) characters", severity: .error)
        }
        
        // Check allowed characters
        let allowedCharacterSet = CharacterSet.letters.union(.whitespaces).union(.punctuationCharacters)
        guard trimmed.unicodeScalars.allSatisfy(allowedCharacterSet.contains) else {
            return .invalid(message: "Hero name contains invalid characters. Use letters, spaces, and basic punctuation only", severity: .error)
        }
        
        // Check for excessive whitespace
        guard !trimmed.contains("  ") else {
            return .invalid(message: "Hero name cannot contain multiple consecutive spaces", severity: .warning)
        }
        
        // Check for profanity (basic implementation)
        if containsProfanity(trimmed.lowercased()) {
            return .invalid(message: "Please choose a more appropriate hero name", severity: .error)
        }
        
        return .valid
    }
    
    private func containsProfanity(_ text: String) -> Bool {
        // Basic profanity filter - extend as needed
        let profanityList = ["badword1", "badword2"] // Add actual profanity list
        return profanityList.contains { text.contains($0) }
    }
}

/// Validation rules for player XP
struct PlayerXPValidationRule: ValidationRule {
    func validate(_ value: Int) -> ValidationResult {
        guard value >= 0 else {
            return .invalid(message: "XP cannot be negative", severity: .error)
        }
        
        guard value <= WQC.Validation.Player.maxXP else {
            return .invalid(message: "XP exceeds maximum allowed value", severity: .critical)
        }
        
        return .valid
    }
}

/// Validation rules for player gold
struct PlayerGoldValidationRule: ValidationRule {
    func validate(_ value: Int) -> ValidationResult {
        guard value >= 0 else {
            return .invalid(message: "Gold cannot be negative", severity: .error)
        }
        
        guard value <= WQC.Validation.Player.maxGold else {
            return .invalid(message: "Gold exceeds maximum allowed value", severity: .critical)
        }
        
        return .valid
    }
}

/// Validation rules for player level
struct PlayerLevelValidationRule: ValidationRule {
    func validate(_ value: Int) -> ValidationResult {
        guard value >= WQC.Validation.Player.minLevel else {
            return .invalid(message: "Level cannot be less than \(WQC.Validation.Player.minLevel)", severity: .error)
        }
        
        guard value <= WQC.Validation.Player.maxLevel else {
            return .invalid(message: "Level cannot exceed \(WQC.Validation.Player.maxLevel)", severity: .error)
        }
        
        return .valid
    }
}

/// Validation rules for inventory size
struct InventorySizeValidationRule: ValidationRule {
    func validate(_ value: [Item]) -> ValidationResult {
        guard value.count <= WQC.maxInventorySize else {
            return .invalid(message: "Inventory is full. Maximum \(WQC.maxInventorySize) items allowed", severity: .error)
        }
        
        return .valid
    }
}

// MARK: - Health Data Validation Rules

/// Validation rules for heart rate
struct HeartRateValidationRule: ValidationRule {
    func validate(_ value: Double) -> ValidationResult {
        guard value >= 0 else {
            return .invalid(message: "Heart rate cannot be negative", severity: .error)
        }
        
        guard value <= WQC.Validation.Health.maxHeartRate else {
            return .invalid(message: "Heart rate exceeds maximum safe value", severity: .critical)
        }
        
        // Optional: Check for realistic ranges
        if value > 0 && value < WQC.Validation.Health.minRealisticHeartRate {
            return .invalid(message: "Heart rate seems unusually low", severity: .warning)
        }
        
        if value > WQC.Validation.Health.maxRealisticHeartRate {
            return .invalid(message: "Heart rate seems unusually high", severity: .warning)
        }
        
        return .valid
    }
}

/// Validation rules for step count
struct StepCountValidationRule: ValidationRule {
    func validate(_ value: Int) -> ValidationResult {
        guard value >= 0 else {
            return .invalid(message: "Step count cannot be negative", severity: .error)
        }
        
        guard value <= WQC.Validation.Health.maxDailySteps else {
            return .invalid(message: "Step count exceeds reasonable daily maximum", severity: .warning)
        }
        
        return .valid
    }
}

/// Validation rules for exercise minutes
struct ExerciseMinutesValidationRule: ValidationRule {
    func validate(_ value: Int) -> ValidationResult {
        guard value >= 0 else {
            return .invalid(message: "Exercise minutes cannot be negative", severity: .error)
        }
        
        guard value <= WQC.Validation.Health.maxDailyExerciseMinutes else {
            return .invalid(message: "Exercise minutes exceed daily maximum (24 hours)", severity: .error)
        }
        
        return .valid
    }
}

/// Validation rules for stand hours
struct StandHoursValidationRule: ValidationRule {
    func validate(_ value: Int) -> ValidationResult {
        guard value >= 0 else {
            return .invalid(message: "Stand hours cannot be negative", severity: .error)
        }
        
        guard value <= WQC.Validation.Health.maxDailyStandHours else {
            return .invalid(message: "Stand hours exceed daily maximum (24 hours)", severity: .error)
        }
        
        return .valid
    }
}

/// Validation rules for mindful minutes
struct MindfulMinutesValidationRule: ValidationRule {
    func validate(_ value: Int) -> ValidationResult {
        guard value >= 0 else {
            return .invalid(message: "Mindful minutes cannot be negative", severity: .error)
        }
        
        guard value <= WQC.Validation.Health.maxDailyMindfulMinutes else {
            return .invalid(message: "Mindful minutes exceed daily maximum", severity: .warning)
        }
        
        return .valid
    }
}

// MARK: - Quest Validation Rules

/// Validation rules for quest progress
struct QuestProgressValidationRule: ValidationRule {
    func validate(_ value: Double) -> ValidationResult {
        guard value >= 0.0 else {
            return .invalid(message: "Quest progress cannot be negative", severity: .error)
        }
        
        guard value.isFinite else {
            return .invalid(message: "Quest progress must be a valid number", severity: .error)
        }
        
        // Note: Progress can exceed total distance temporarily during calculation
        return .valid
    }
}

/// Validation rules for quest distance
struct QuestDistanceValidationRule: ValidationRule {
    func validate(_ value: Double) -> ValidationResult {
        guard value > 0 else {
            return .invalid(message: "Quest distance must be positive", severity: .error)
        }
        
        guard value.isFinite else {
            return .invalid(message: "Quest distance must be a valid number", severity: .error)
        }
        
        guard value <= WQC.Validation.Quest.maxDistance else {
            return .invalid(message: "Quest distance exceeds maximum allowed", severity: .error)
        }
        
        return .valid
    }
}

/// Validation rules for quest rewards
struct QuestRewardValidationRule: ValidationRule {
    func validate(_ value: Int) -> ValidationResult {
        guard value >= 0 else {
            return .invalid(message: "Quest reward cannot be negative", severity: .error)
        }
        
        guard value <= WQC.Validation.Quest.maxReward else {
            return .invalid(message: "Quest reward exceeds maximum allowed", severity: .warning)
        }
        
        return .valid
    }
}

// MARK: - Date Validation Rules

/// Validation rules for dates
struct DateValidationRule: ValidationRule {
    func validate(_ value: Date) -> ValidationResult {
        let now = Date()
        
        // Check for future dates in historical data
        if value > now {
            return .invalid(message: "Date cannot be in the future", severity: .error)
        }
        
        // Check for unreasonably old dates
        let calendar = Calendar.current
        if let oneYearAgo = calendar.date(byAdding: .year, value: -1, to: now),
           value < oneYearAgo {
            return .invalid(message: "Date is too far in the past", severity: .warning)
        }
        
        return .valid
    }
}

// MARK: - UUID Validation Rules

/// Validation rules for UUID values
struct UUIDValidationRule: ValidationRule {
    func validate(_ value: String) -> ValidationResult {
        guard UUID(uuidString: value) != nil else {
            return .invalid(message: "Invalid UUID format", severity: .error)
        }
        
        return .valid
    }
}

// MARK: - JSON Validation Rules

/// Validation rules for JSON data
struct JSONValidationRule: ValidationRule {
    func validate(_ value: Data) -> ValidationResult {
        do {
            _ = try JSONSerialization.jsonObject(with: value, options: [])
            return .valid
        } catch {
            return .invalid(message: "Invalid JSON format: \(error.localizedDescription)", severity: .error)
        }
    }
}

// MARK: - Enum Validation Rules

/// Generic validation rule for enum values
struct EnumValidationRule<T: RawRepresentable>: ValidationRule where T.RawValue == String {
    private let enumType: T.Type
    
    init(enumType: T.Type) {
        self.enumType = enumType
    }
    
    func validate(_ value: String) -> ValidationResult {
        guard T(rawValue: value) != nil else {
            return .invalid(message: "Invalid \(String(describing: T.self)) value: \(value)", severity: .error)
        }
        
        return .valid
    }
}

// MARK: - Combined Validation Rules
// Note: Complex generic validation rules removed to avoid compilation issues

// MARK: - Validation Constants Extension

extension WQConstants {
    struct Validation {
        struct Player {
            static let minNameLength = 1
            static let maxNameLength = 20
            static let minLevel = 1
            static let maxLevel = 100
            static let maxXP = 1_000_000
            static let maxGold = 100_000
        }
        
        struct Health {
            static let minHeartRate: Double = 30.0
            static let maxHeartRate: Double = 250.0
            static let minRealisticHeartRate: Double = 40.0
            static let maxRealisticHeartRate: Double = 220.0
            static let maxDailySteps = 100_000
            static let maxDailyExerciseMinutes = 24 * 60  // 24 hours
            static let maxDailyStandHours = 24
            static let maxDailyMindfulMinutes = 24 * 60   // 24 hours
        }
        
        struct Quest {
            static let maxDistance: Double = 10_000.0
            static let maxReward = 10_000
        }
    }
}