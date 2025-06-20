import Foundation

struct Quest: Codable, Identifiable, Hashable {
    let id: UUID
    private var _title: String
    private var _description: String
    private var _totalDistance: Double
    private var _currentProgress: Double
    private var _isCompleted: Bool
    private var _rewardXP: Int
    private var _rewardGold: Int
    var encounters: [Encounter]
    
    // MARK: - Validated Properties
    
    var title: String {
        get { _title }
        set {
            let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                _title = trimmed
            } else {
                ValidationLogger.shared.logValidationErrors(
                    [ValidationError(field: "title", message: "Quest title cannot be empty", severity: .error)],
                    context: .questProgressContext
                )
                // Keep the old value if validation fails
            }
        }
    }
    
    var description: String {
        get { _description }
        set {
            let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                _description = trimmed
            } else {
                ValidationLogger.shared.logValidationErrors(
                    [ValidationError(field: "description", message: "Quest description cannot be empty", severity: .error)],
                    context: .questProgressContext
                )
                // Keep the old value if validation fails
            }
        }
    }
    
    var totalDistance: Double {
        get { _totalDistance }
        set {
            let validationResult = InputValidator.shared.validateQuestDistance(newValue)
            if validationResult.isValid {
                _totalDistance = newValue
            } else {
                ValidationLogger.shared.logValidationErrors(
                    [ValidationError(field: "totalDistance", message: validationResult.message ?? "Invalid total distance", severity: validationResult.severity)],
                    context: .questProgressContext
                )
                // Keep the old value if validation fails
            }
        }
    }
    
    var currentProgress: Double {
        get { _currentProgress }
        set {
            let validationResult = InputValidator.shared.validateQuestProgress(newValue)
            if validationResult.isValid {
                _currentProgress = newValue
                
                // Auto-complete quest if progress reaches total distance
                if !_isCompleted && newValue >= _totalDistance {
                    _isCompleted = true
                    ValidationLogger.shared.logValidationEvent(
                        ValidationEvent(
                            context: .questProgressContext,
                            validationType: .questProgress,
                            input: "Quest completed: \(_title)",
                            result: .valid
                        )
                    )
                }
            } else {
                ValidationLogger.shared.logValidationErrors(
                    [ValidationError(field: "currentProgress", message: validationResult.message ?? "Invalid progress", severity: validationResult.severity)],
                    context: .questProgressContext
                )
                // Keep the old value if validation fails
            }
        }
    }
    
    var isCompleted: Bool {
        get { _isCompleted }
        set {
            // Validate completion state changes
            if _isCompleted && !newValue {
                ValidationLogger.shared.logValidationErrors(
                    [ValidationError(field: "isCompleted", message: "Cannot un-complete a completed quest", severity: .error)],
                    context: .questProgressContext
                )
                // Keep the old value if validation fails
                return
            }
            
            // If completing quest, ensure progress is sufficient
            if !_isCompleted && newValue && _currentProgress < _totalDistance {
                ValidationLogger.shared.logValidationErrors(
                    [ValidationError(field: "isCompleted", message: "Cannot complete quest with insufficient progress", severity: .warning)],
                    context: .questProgressContext
                )
                // Set progress to total distance when completing
                _currentProgress = _totalDistance
            }
            
            _isCompleted = newValue
        }
    }
    
    var rewardXP: Int {
        get { _rewardXP }
        set {
            let validationResult = InputValidator.shared.validateQuestReward(newValue)
            if validationResult.isValid {
                _rewardXP = newValue
            } else {
                ValidationLogger.shared.logValidationErrors(
                    [ValidationError(field: "rewardXP", message: validationResult.message ?? "Invalid XP reward", severity: validationResult.severity)],
                    context: .questProgressContext
                )
                // Keep the old value if validation fails
            }
        }
    }
    
    var rewardGold: Int {
        get { _rewardGold }
        set {
            let validationResult = InputValidator.shared.validateQuestReward(newValue)
            if validationResult.isValid {
                _rewardGold = newValue
            } else {
                ValidationLogger.shared.logValidationErrors(
                    [ValidationError(field: "rewardGold", message: validationResult.message ?? "Invalid gold reward", severity: validationResult.severity)],
                    context: .questProgressContext
                )
                // Keep the old value if validation fails
            }
        }
    }
    
    // MARK: - Initializers
    
    init(title: String, description: String, totalDistance: Double, rewardXP: Int, rewardGold: Int, encounters: [Encounter] = []) throws {
        // Validate input parameters
        var validationErrors: [ValidationError] = []
        
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedTitle.isEmpty {
            validationErrors.append(ValidationError(field: "title", message: "Quest title cannot be empty", severity: .error))
        }
        
        let trimmedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedDescription.isEmpty {
            validationErrors.append(ValidationError(field: "description", message: "Quest description cannot be empty", severity: .error))
        }
        
        let distanceValidation = InputValidator.shared.validateQuestDistance(totalDistance)
        if !distanceValidation.isValid {
            validationErrors.append(ValidationError(field: "totalDistance", message: distanceValidation.message ?? "Invalid distance", severity: distanceValidation.severity))
        }
        
        let xpValidation = InputValidator.shared.validateQuestReward(rewardXP)
        if !xpValidation.isValid {
            validationErrors.append(ValidationError(field: "rewardXP", message: xpValidation.message ?? "Invalid XP reward", severity: xpValidation.severity))
        }
        
        let goldValidation = InputValidator.shared.validateQuestReward(rewardGold)
        if !goldValidation.isValid {
            validationErrors.append(ValidationError(field: "rewardGold", message: goldValidation.message ?? "Invalid gold reward", severity: goldValidation.severity))
        }
        
        // Check for blocking errors
        let blockingErrors = validationErrors.filter { $0.isBlocking }
        if !blockingErrors.isEmpty {
            ValidationLogger.shared.logValidationErrors(validationErrors, context: .questProgressContext)
            let firstBlockingError = blockingErrors.first!
            throw WQError.validation(.invalidQuestData(firstBlockingError.message))
        }
        
        // Set properties with fallbacks for non-blocking errors
        self.id = UUID()
        self._title = trimmedTitle.isEmpty ? WQC.Defaults.defaultQuestTitle : trimmedTitle
        self._description = trimmedDescription.isEmpty ? "A mysterious quest awaits..." : trimmedDescription
        self._totalDistance = distanceValidation.isValid ? totalDistance : WQC.Quest.baseQuestDistance
        self._currentProgress = 0.0
        self._isCompleted = false
        self._rewardXP = xpValidation.isValid ? rewardXP : WQC.Quest.baseQuestXP
        self._rewardGold = goldValidation.isValid ? rewardGold : WQC.Quest.baseQuestGold
        self.encounters = encounters
        
        // Log any non-blocking validation issues
        if !validationErrors.isEmpty {
            ValidationLogger.shared.logValidationErrors(validationErrors, context: .questProgressContext)
        }
    }
    
    // MARK: - Safe Initializer (for existing data)
    
    /// Initializer for loading existing quest data with validation
    init(id: UUID, title: String, description: String, totalDistance: Double, currentProgress: Double, isCompleted: Bool, rewardXP: Int, rewardGold: Int, encounters: [Encounter]) {
        self.id = id
        self.encounters = encounters
        
        // Validate and set properties with fallbacks
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        self._title = trimmedTitle.isEmpty ? WQC.Defaults.defaultQuestTitle : trimmedTitle
        
        let trimmedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
        self._description = trimmedDescription.isEmpty ? "A mysterious quest awaits..." : trimmedDescription
        
        let distanceValidation = InputValidator.shared.validateQuestDistance(totalDistance)
        self._totalDistance = distanceValidation.isValid ? totalDistance : WQC.Quest.baseQuestDistance
        
        let progressValidation = InputValidator.shared.validateQuestProgress(currentProgress)
        self._currentProgress = progressValidation.isValid ? currentProgress : 0.0
        
        // Validate completion consistency
        if isCompleted && currentProgress < totalDistance {
            self._currentProgress = totalDistance // Fix inconsistent completion state
            self._isCompleted = true
        } else {
            self._isCompleted = isCompleted
        }
        
        let xpValidation = InputValidator.shared.validateQuestReward(rewardXP)
        self._rewardXP = xpValidation.isValid ? rewardXP : WQC.Quest.baseQuestXP
        
        let goldValidation = InputValidator.shared.validateQuestReward(rewardGold)
        self._rewardGold = goldValidation.isValid ? rewardGold : WQC.Quest.baseQuestGold
        
        // Log any validation issues
        var errors: [ValidationError] = []
        
        if trimmedTitle.isEmpty {
            errors.append(ValidationError(field: "title", message: "Quest title was empty, using default", severity: .warning))
        }
        if trimmedDescription.isEmpty {
            errors.append(ValidationError(field: "description", message: "Quest description was empty, using default", severity: .warning))
        }
        if !distanceValidation.isValid {
            errors.append(ValidationError(field: "totalDistance", message: distanceValidation.message ?? "Invalid distance", severity: distanceValidation.severity))
        }
        if !progressValidation.isValid {
            errors.append(ValidationError(field: "currentProgress", message: progressValidation.message ?? "Invalid progress", severity: progressValidation.severity))
        }
        if !xpValidation.isValid {
            errors.append(ValidationError(field: "rewardXP", message: xpValidation.message ?? "Invalid XP reward", severity: xpValidation.severity))
        }
        if !goldValidation.isValid {
            errors.append(ValidationError(field: "rewardGold", message: goldValidation.message ?? "Invalid gold reward", severity: goldValidation.severity))
        }
        
        if !errors.isEmpty {
            ValidationLogger.shared.logValidationErrors(errors, context: .persistenceContext)
        }
    }
    
    // MARK: - Validation Methods
    
    /// Validates the current quest state
    func validate() -> ValidationErrorCollection {
        let errors = InputValidator.shared.validateQuest(self)
        return ValidationErrorCollection(errors)
    }
    
    /// Checks if the quest data is in a valid state
    var isValid: Bool {
        return validate().errors.isEmpty
    }
    
    // MARK: - Safe Update Methods
    
    /// Safely updates quest progress with validation
    @discardableResult
    mutating func updateProgress(_ newProgress: Double) -> ValidationResult {
        // Create a copy for state transition validation
        let oldQuest = self
        var newQuest = self
        newQuest._currentProgress = newProgress
        
        // Validate state transition
        let transitionResult = InputValidator.shared.validateQuestStateTransition(from: oldQuest, to: newQuest)
        if transitionResult.isValid {
            let progressResult = InputValidator.shared.validateQuestProgress(newProgress)
            if progressResult.isValid {
                _currentProgress = newProgress
                
                // Auto-complete quest if progress reaches total distance
                if !_isCompleted && newProgress >= _totalDistance {
                    _isCompleted = true
                    ValidationLogger.shared.logValidationEvent(
                        ValidationEvent(
                            context: .questProgressContext,
                            validationType: .questProgress,
                            input: "Quest auto-completed: \(_title)",
                            result: .valid
                        )
                    )
                }
                return progressResult
            } else {
                ValidationLogger.shared.logValidationErrors(
                    [ValidationError(field: "currentProgress", message: progressResult.message ?? "Invalid progress", severity: progressResult.severity)],
                    context: .questProgressContext
                )
                return progressResult
            }
        } else {
            ValidationLogger.shared.logValidationErrors(
                [ValidationError(field: "stateTransition", message: transitionResult.message ?? "Invalid state transition", severity: transitionResult.severity)],
                context: .questProgressContext
            )
            return transitionResult
        }
    }
    
    /// Safely adds progress with validation
    @discardableResult
    mutating func addProgress(_ amount: Double) -> ValidationResult {
        let newProgress = _currentProgress + amount
        return updateProgress(newProgress)
    }
    
    /// Safely completes the quest with validation
    @discardableResult
    mutating func complete() -> ValidationResult {
        if _isCompleted {
            return .invalid(message: "Quest is already completed", severity: .warning)
        }
        
        // Set progress to total distance if not already there
        if _currentProgress < _totalDistance {
            _currentProgress = _totalDistance
        }
        
        _isCompleted = true
        
        ValidationLogger.shared.logValidationEvent(
            ValidationEvent(
                context: .questProgressContext,
                validationType: .questProgress,
                input: "Quest manually completed: \(_title)",
                result: .valid
            )
        )
        
        return .valid
    }
    
    // MARK: - Computed Properties
    
    var progressPercentage: Double {
        guard totalDistance > 0 else { return 0 }
        return min(currentProgress / totalDistance, 1.0)
    }
    
    var remainingDistance: Double {
        max(totalDistance - currentProgress, 0)
    }
    
    /// Provides a quest summary with validation status
    var questSummary: String {
        var summary = "\(title) - \(Int(progressPercentage * 100))% complete"
        
        let validation = validate()
        if validation.hasErrors {
            let errorCount = validation.errorLevelErrors.count + validation.criticalErrors.count
            if errorCount > 0 {
                summary += " (❌ \(errorCount) error\(errorCount == 1 ? "" : "s"))"
            } else if validation.warnings.count > 0 {
                summary += " (⚠️ \(validation.warnings.count) warning\(validation.warnings.count == 1 ? "" : "s"))"
            }
        }
        
        return summary
    }
}

// MARK: - Codable Implementation

extension Quest {
    enum CodingKeys: String, CodingKey {
        case id
        case title = "_title"
        case description = "_description"
        case totalDistance = "_totalDistance"
        case currentProgress = "_currentProgress"
        case isCompleted = "_isCompleted"
        case rewardXP = "_rewardXP"
        case rewardGold = "_rewardGold"
        case encounters
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let id = try container.decode(UUID.self, forKey: .id)
        let title = try container.decode(String.self, forKey: .title)
        let description = try container.decode(String.self, forKey: .description)
        let totalDistance = try container.decode(Double.self, forKey: .totalDistance)
        let currentProgress = try container.decode(Double.self, forKey: .currentProgress)
        let isCompleted = try container.decode(Bool.self, forKey: .isCompleted)
        let rewardXP = try container.decode(Int.self, forKey: .rewardXP)
        let rewardGold = try container.decode(Int.self, forKey: .rewardGold)
        let encounters = try container.decode([Encounter].self, forKey: .encounters)
        
        // Use safe initializer for loaded data
        self.init(
            id: id,
            title: title,
            description: description,
            totalDistance: totalDistance,
            currentProgress: currentProgress,
            isCompleted: isCompleted,
            rewardXP: rewardXP,
            rewardGold: rewardGold,
            encounters: encounters
        )
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(_title, forKey: .title)
        try container.encode(_description, forKey: .description)
        try container.encode(_totalDistance, forKey: .totalDistance)
        try container.encode(_currentProgress, forKey: .currentProgress)
        try container.encode(_isCompleted, forKey: .isCompleted)
        try container.encode(_rewardXP, forKey: .rewardXP)
        try container.encode(_rewardGold, forKey: .rewardGold)
        try container.encode(encounters, forKey: .encounters)
    }
}