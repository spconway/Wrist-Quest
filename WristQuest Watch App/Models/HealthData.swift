import Foundation

// Note: WQConstants are accessed globally via WQC typealias

struct HealthData: Codable {
    private var _steps: Int
    private var _standingHours: Int
    private var _heartRate: Double
    private var _exerciseMinutes: Int
    private var _mindfulMinutes: Int
    
    // MARK: - Validated Properties
    
    var steps: Int {
        get { _steps }
        set {
            let validationResult = InputValidator.shared.validateStepCount(newValue)
            if validationResult.isValid {
                _steps = newValue
            } else {
                ValidationLogger.shared.logValidationErrors(
                    [ValidationError(field: "steps", message: validationResult.message ?? "Invalid step count", severity: validationResult.severity)],
                    context: .healthDataContext
                )
                // Keep the old value if validation fails
            }
        }
    }
    
    var standingHours: Int {
        get { _standingHours }
        set {
            let validationResult = InputValidator.shared.validateStandHours(newValue)
            if validationResult.isValid {
                _standingHours = newValue
            } else {
                ValidationLogger.shared.logValidationErrors(
                    [ValidationError(field: "standingHours", message: validationResult.message ?? "Invalid standing hours", severity: validationResult.severity)],
                    context: .healthDataContext
                )
                // Keep the old value if validation fails
            }
        }
    }
    
    var heartRate: Double {
        get { _heartRate }
        set {
            let validationResult = InputValidator.shared.validateHeartRate(newValue)
            if validationResult.isValid {
                _heartRate = newValue
            } else {
                ValidationLogger.shared.logValidationErrors(
                    [ValidationError(field: "heartRate", message: validationResult.message ?? "Invalid heart rate", severity: validationResult.severity)],
                    context: .healthDataContext
                )
                // Keep the old value if validation fails
            }
        }
    }
    
    var exerciseMinutes: Int {
        get { _exerciseMinutes }
        set {
            let validationResult = InputValidator.shared.validateExerciseMinutes(newValue)
            if validationResult.isValid {
                _exerciseMinutes = newValue
            } else {
                ValidationLogger.shared.logValidationErrors(
                    [ValidationError(field: "exerciseMinutes", message: validationResult.message ?? "Invalid exercise minutes", severity: validationResult.severity)],
                    context: .healthDataContext
                )
                // Keep the old value if validation fails
            }
        }
    }
    
    var mindfulMinutes: Int {
        get { _mindfulMinutes }
        set {
            let validationResult = InputValidator.shared.validateMindfulMinutes(newValue)
            if validationResult.isValid {
                _mindfulMinutes = newValue
            } else {
                ValidationLogger.shared.logValidationErrors(
                    [ValidationError(field: "mindfulMinutes", message: validationResult.message ?? "Invalid mindful minutes", severity: validationResult.severity)],
                    context: .healthDataContext
                )
                // Keep the old value if validation fails
            }
        }
    }
    
    // MARK: - Initializers
    
    init(steps: Int = 0, standingHours: Int = 0, heartRate: Double = 0.0, exerciseMinutes: Int = 0, mindfulMinutes: Int = 0) {
        // Validate inputs and use fallbacks if needed
        let stepsValidation = InputValidator.shared.validateStepCount(steps)
        self._steps = stepsValidation.isValid ? steps : 0
        
        let standingValidation = InputValidator.shared.validateStandHours(standingHours)
        self._standingHours = standingValidation.isValid ? standingHours : 0
        
        let heartRateValidation = InputValidator.shared.validateHeartRate(heartRate)
        self._heartRate = heartRateValidation.isValid ? heartRate : 0.0
        
        let exerciseValidation = InputValidator.shared.validateExerciseMinutes(exerciseMinutes)
        self._exerciseMinutes = exerciseValidation.isValid ? exerciseMinutes : 0
        
        let mindfulValidation = InputValidator.shared.validateMindfulMinutes(mindfulMinutes)
        self._mindfulMinutes = mindfulValidation.isValid ? mindfulMinutes : 0
        
        // Log any validation issues
        var errors: [ValidationError] = []
        
        if !stepsValidation.isValid {
            errors.append(ValidationError(field: "steps", message: stepsValidation.message ?? "Invalid steps", severity: stepsValidation.severity))
        }
        if !standingValidation.isValid {
            errors.append(ValidationError(field: "standingHours", message: standingValidation.message ?? "Invalid standing hours", severity: standingValidation.severity))
        }
        if !heartRateValidation.isValid {
            errors.append(ValidationError(field: "heartRate", message: heartRateValidation.message ?? "Invalid heart rate", severity: heartRateValidation.severity))
        }
        if !exerciseValidation.isValid {
            errors.append(ValidationError(field: "exerciseMinutes", message: exerciseValidation.message ?? "Invalid exercise minutes", severity: exerciseValidation.severity))
        }
        if !mindfulValidation.isValid {
            errors.append(ValidationError(field: "mindfulMinutes", message: mindfulValidation.message ?? "Invalid mindful minutes", severity: mindfulValidation.severity))
        }
        
        if !errors.isEmpty {
            ValidationLogger.shared.logValidationErrors(errors, context: .healthDataContext)
        }
    }
    
    // MARK: - Validation Methods
    
    /// Validates the current health data state
    func validate() -> ValidationErrorCollection {
        let errors = InputValidator.shared.validateHealthData(self)
        return ValidationErrorCollection(errors)
    }
    
    /// Checks if the health data is in a valid state
    var isValid: Bool {
        return validate().errors.isEmpty
    }
    
    // MARK: - Safe Update Methods
    
    /// Safely updates step count with validation
    @discardableResult
    mutating func updateSteps(_ newSteps: Int) -> ValidationResult {
        let validationResult = InputValidator.shared.validateStepCount(newSteps)
        if validationResult.isValid {
            _steps = newSteps
        } else {
            ValidationLogger.shared.logValidationErrors(
                [ValidationError(field: "steps", message: validationResult.message ?? "Invalid step count", severity: validationResult.severity)],
                context: .healthDataContext
            )
        }
        return validationResult
    }
    
    /// Safely updates heart rate with validation
    @discardableResult
    mutating func updateHeartRate(_ newHeartRate: Double) -> ValidationResult {
        let validationResult = InputValidator.shared.validateHeartRate(newHeartRate)
        if validationResult.isValid {
            _heartRate = newHeartRate
        } else {
            ValidationLogger.shared.logValidationErrors(
                [ValidationError(field: "heartRate", message: validationResult.message ?? "Invalid heart rate", severity: validationResult.severity)],
                context: .healthDataContext
            )
        }
        return validationResult
    }
    
    /// Safely updates exercise minutes with validation
    @discardableResult
    mutating func updateExerciseMinutes(_ newExerciseMinutes: Int) -> ValidationResult {
        let validationResult = InputValidator.shared.validateExerciseMinutes(newExerciseMinutes)
        if validationResult.isValid {
            _exerciseMinutes = newExerciseMinutes
        } else {
            ValidationLogger.shared.logValidationErrors(
                [ValidationError(field: "exerciseMinutes", message: validationResult.message ?? "Invalid exercise minutes", severity: validationResult.severity)],
                context: .healthDataContext
            )
        }
        return validationResult
    }
    
    /// Safely updates standing hours with validation
    @discardableResult
    mutating func updateStandingHours(_ newStandingHours: Int) -> ValidationResult {
        let validationResult = InputValidator.shared.validateStandHours(newStandingHours)
        if validationResult.isValid {
            _standingHours = newStandingHours
        } else {
            ValidationLogger.shared.logValidationErrors(
                [ValidationError(field: "standingHours", message: validationResult.message ?? "Invalid standing hours", severity: validationResult.severity)],
                context: .healthDataContext
            )
        }
        return validationResult
    }
    
    /// Safely updates mindful minutes with validation
    @discardableResult
    mutating func updateMindfulMinutes(_ newMindfulMinutes: Int) -> ValidationResult {
        let validationResult = InputValidator.shared.validateMindfulMinutes(newMindfulMinutes)
        if validationResult.isValid {
            _mindfulMinutes = newMindfulMinutes
        } else {
            ValidationLogger.shared.logValidationErrors(
                [ValidationError(field: "mindfulMinutes", message: validationResult.message ?? "Invalid mindful minutes", severity: validationResult.severity)],
                context: .healthDataContext
            )
        }
        return validationResult
    }
    
    // MARK: - Computed Properties
    
    var isInCombatMode: Bool {
        heartRate > WQC.Health.combatHeartRateThreshold
    }
    
    var dailyActivityScore: Int {
        let stepScore = min(steps / WQC.Health.stepScoreMultiplier, WQC.Health.stepScoreMultiplier)
        let standScore = standingHours * WQC.Health.standHourScoreMultiplier
        let exerciseScore = exerciseMinutes * WQC.Health.exerciseMinuteScoreMultiplier
        let mindfulScore = mindfulMinutes * WQC.Health.mindfulMinuteScoreMultiplier
        
        return stepScore + standScore + exerciseScore + mindfulScore
    }
    
    /// Provides a health data summary with validation warnings
    var healthSummary: String {
        var summary = "Activity Score: \(dailyActivityScore)"
        
        let validation = validate()
        if validation.hasErrors {
            let warningCount = validation.warnings.count
            if warningCount > 0 {
                summary += " (⚠️ \(warningCount) warning\(warningCount == 1 ? "" : "s"))"
            }
        }
        
        return summary
    }
}

// MARK: - Codable Implementation

extension HealthData {
    enum CodingKeys: String, CodingKey {
        case steps = "_steps"
        case standingHours = "_standingHours"
        case heartRate = "_heartRate"
        case exerciseMinutes = "_exerciseMinutes"
        case mindfulMinutes = "_mindfulMinutes"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let steps = try container.decode(Int.self, forKey: .steps)
        let standingHours = try container.decode(Int.self, forKey: .standingHours)
        let heartRate = try container.decode(Double.self, forKey: .heartRate)
        let exerciseMinutes = try container.decode(Int.self, forKey: .exerciseMinutes)
        let mindfulMinutes = try container.decode(Int.self, forKey: .mindfulMinutes)
        
        // Use the validated initializer
        self.init(
            steps: steps,
            standingHours: standingHours,
            heartRate: heartRate,
            exerciseMinutes: exerciseMinutes,
            mindfulMinutes: mindfulMinutes
        )
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(_steps, forKey: .steps)
        try container.encode(_standingHours, forKey: .standingHours)
        try container.encode(_heartRate, forKey: .heartRate)
        try container.encode(_exerciseMinutes, forKey: .exerciseMinutes)
        try container.encode(_mindfulMinutes, forKey: .mindfulMinutes)
    }
}