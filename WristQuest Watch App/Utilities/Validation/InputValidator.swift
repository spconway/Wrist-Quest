import Foundation

// MARK: - Input Validator

/// Core validation engine that applies validation rules to input data
public class InputValidator {
    
    // MARK: - Singleton
    
    public static let shared = InputValidator()
    
    private init() {}
    
    // MARK: - Player Validation
    
    /// Validates player name input
    public func validatePlayerName(_ name: String) -> ValidationResult {
        let rule = PlayerNameValidationRule()
        return rule.validate(name)
    }
    
    /// Validates player XP value
    public func validatePlayerXP(_ xp: Int) -> ValidationResult {
        let rule = PlayerXPValidationRule()
        return rule.validate(xp)
    }
    
    /// Validates player gold value
    public func validatePlayerGold(_ gold: Int) -> ValidationResult {
        let rule = PlayerGoldValidationRule()
        return rule.validate(gold)
    }
    
    /// Validates player level
    public func validatePlayerLevel(_ level: Int) -> ValidationResult {
        let rule = PlayerLevelValidationRule()
        return rule.validate(level)
    }
    
    /// Validates inventory size
    func validateInventorySize(_ inventory: [Item]) -> ValidationResult {
        let rule = InventorySizeValidationRule()
        return rule.validate(inventory)
    }
    
    /// Validates complete player data
    func validatePlayer(_ player: Player) -> [ValidationError] {
        var errors: [ValidationError] = []
        
        // Validate name
        let nameResult = validatePlayerName(player.name)
        if !nameResult.isValid {
            errors.append(ValidationError(
                field: "name",
                message: nameResult.message ?? "Invalid name",
                severity: nameResult.severity
            ))
        }
        
        // Validate XP
        let xpResult = validatePlayerXP(player.xp)
        if !xpResult.isValid {
            errors.append(ValidationError(
                field: "xp",
                message: xpResult.message ?? "Invalid XP",
                severity: xpResult.severity
            ))
        }
        
        // Validate gold
        let goldResult = validatePlayerGold(player.gold)
        if !goldResult.isValid {
            errors.append(ValidationError(
                field: "gold",
                message: goldResult.message ?? "Invalid gold",
                severity: goldResult.severity
            ))
        }
        
        // Validate level
        let levelResult = validatePlayerLevel(player.level)
        if !levelResult.isValid {
            errors.append(ValidationError(
                field: "level",
                message: levelResult.message ?? "Invalid level",
                severity: levelResult.severity
            ))
        }
        
        // Validate inventory
        let inventoryResult = validateInventorySize(player.inventory)
        if !inventoryResult.isValid {
            errors.append(ValidationError(
                field: "inventory",
                message: inventoryResult.message ?? "Invalid inventory",
                severity: inventoryResult.severity
            ))
        }
        
        // Validate level-XP consistency
        if let levelXPError = validateLevelXPConsistency(level: player.level, xp: player.xp) {
            errors.append(levelXPError)
        }
        
        return errors
    }
    
    // MARK: - Health Data Validation
    
    /// Validates heart rate value
    public func validateHeartRate(_ heartRate: Double) -> ValidationResult {
        let rule = HeartRateValidationRule()
        return rule.validate(heartRate)
    }
    
    /// Validates step count
    public func validateStepCount(_ steps: Int) -> ValidationResult {
        let rule = StepCountValidationRule()
        return rule.validate(steps)
    }
    
    /// Validates exercise minutes
    public func validateExerciseMinutes(_ minutes: Int) -> ValidationResult {
        let rule = ExerciseMinutesValidationRule()
        return rule.validate(minutes)
    }
    
    /// Validates stand hours
    public func validateStandHours(_ hours: Int) -> ValidationResult {
        let rule = StandHoursValidationRule()
        return rule.validate(hours)
    }
    
    /// Validates mindful minutes
    public func validateMindfulMinutes(_ minutes: Int) -> ValidationResult {
        let rule = MindfulMinutesValidationRule()
        return rule.validate(minutes)
    }
    
    /// Validates complete health data
    func validateHealthData(_ healthData: HealthData) -> [ValidationError] {
        var errors: [ValidationError] = []
        
        // Validate heart rate
        let heartRateResult = validateHeartRate(healthData.heartRate)
        if !heartRateResult.isValid {
            errors.append(ValidationError(
                field: "heartRate",
                message: heartRateResult.message ?? "Invalid heart rate",
                severity: heartRateResult.severity
            ))
        }
        
        // Validate steps
        let stepsResult = validateStepCount(healthData.steps)
        if !stepsResult.isValid {
            errors.append(ValidationError(
                field: "steps",
                message: stepsResult.message ?? "Invalid step count",
                severity: stepsResult.severity
            ))
        }
        
        // Validate exercise minutes
        let exerciseResult = validateExerciseMinutes(healthData.exerciseMinutes)
        if !exerciseResult.isValid {
            errors.append(ValidationError(
                field: "exerciseMinutes",
                message: exerciseResult.message ?? "Invalid exercise minutes",
                severity: exerciseResult.severity
            ))
        }
        
        // Validate stand hours
        let standResult = validateStandHours(healthData.standingHours)
        if !standResult.isValid {
            errors.append(ValidationError(
                field: "standingHours",
                message: standResult.message ?? "Invalid stand hours",
                severity: standResult.severity
            ))
        }
        
        // Validate mindful minutes
        let mindfulResult = validateMindfulMinutes(healthData.mindfulMinutes)
        if !mindfulResult.isValid {
            errors.append(ValidationError(
                field: "mindfulMinutes",
                message: mindfulResult.message ?? "Invalid mindful minutes",
                severity: mindfulResult.severity
            ))
        }
        
        return errors
    }
    
    // MARK: - Quest Validation
    
    /// Validates quest progress
    public func validateQuestProgress(_ progress: Double) -> ValidationResult {
        let rule = QuestProgressValidationRule()
        return rule.validate(progress)
    }
    
    /// Validates quest distance
    public func validateQuestDistance(_ distance: Double) -> ValidationResult {
        let rule = QuestDistanceValidationRule()
        return rule.validate(distance)
    }
    
    /// Validates quest reward
    public func validateQuestReward(_ reward: Int) -> ValidationResult {
        let rule = QuestRewardValidationRule()
        return rule.validate(reward)
    }
    
    /// Validates complete quest data
    func validateQuest(_ quest: Quest) -> [ValidationError] {
        var errors: [ValidationError] = []
        
        // Validate title
        if quest.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append(ValidationError(
                field: "title",
                message: "Quest title cannot be empty",
                severity: .error
            ))
        }
        
        // Validate description
        if quest.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append(ValidationError(
                field: "description",
                message: "Quest description cannot be empty",
                severity: .error
            ))
        }
        
        // Validate total distance
        let distanceResult = validateQuestDistance(quest.totalDistance)
        if !distanceResult.isValid {
            errors.append(ValidationError(
                field: "totalDistance",
                message: distanceResult.message ?? "Invalid total distance",
                severity: distanceResult.severity
            ))
        }
        
        // Validate current progress
        let progressResult = validateQuestProgress(quest.currentProgress)
        if !progressResult.isValid {
            errors.append(ValidationError(
                field: "currentProgress",
                message: progressResult.message ?? "Invalid progress",
                severity: progressResult.severity
            ))
        }
        
        // Validate XP reward
        let xpRewardResult = validateQuestReward(quest.rewardXP)
        if !xpRewardResult.isValid {
            errors.append(ValidationError(
                field: "rewardXP",
                message: xpRewardResult.message ?? "Invalid XP reward",
                severity: xpRewardResult.severity
            ))
        }
        
        // Validate gold reward
        let goldRewardResult = validateQuestReward(quest.rewardGold)
        if !goldRewardResult.isValid {
            errors.append(ValidationError(
                field: "rewardGold",
                message: goldRewardResult.message ?? "Invalid gold reward",
                severity: goldRewardResult.severity
            ))
        }
        
        // Validate progress consistency
        if quest.currentProgress > quest.totalDistance * 1.1 { // Allow 10% buffer for calculations
            errors.append(ValidationError(
                field: "progress",
                message: "Current progress significantly exceeds total distance",
                severity: .warning
            ))
        }
        
        // Validate completion consistency
        if quest.isCompleted && quest.currentProgress < quest.totalDistance {
            errors.append(ValidationError(
                field: "completion",
                message: "Quest marked as completed but progress is insufficient",
                severity: .error
            ))
        }
        
        return errors
    }
    
    // MARK: - Quest State Transition Validation
    
    /// Validates quest state transitions
    func validateQuestStateTransition(from oldQuest: Quest, to newQuest: Quest) -> ValidationResult {
        // Ensure quest IDs match
        guard oldQuest.id == newQuest.id else {
            return .invalid(message: "Cannot transition between different quests", severity: .error)
        }
        
        // Validate progress only increases
        guard newQuest.currentProgress >= oldQuest.currentProgress else {
            return .invalid(message: "Quest progress cannot decrease", severity: .error)
        }
        
        // Validate completion state changes
        if oldQuest.isCompleted && !newQuest.isCompleted {
            return .invalid(message: "Cannot un-complete a completed quest", severity: .error)
        }
        
        // Validate immutable fields
        if oldQuest.totalDistance != newQuest.totalDistance {
            return .invalid(message: "Quest total distance cannot be changed after creation", severity: .warning)
        }
        
        return .valid
    }
    
    // MARK: - Generic Validation
    
    /// Validates date values
    public func validateDate(_ date: Date) -> ValidationResult {
        let rule = DateValidationRule()
        return rule.validate(date)
    }
    
    /// Validates UUID strings
    public func validateUUID(_ uuid: String) -> ValidationResult {
        let rule = UUIDValidationRule()
        return rule.validate(uuid)
    }
    
    /// Validates JSON data
    public func validateJSON(_ data: Data) -> ValidationResult {
        let rule = JSONValidationRule()
        return rule.validate(data)
    }
    
    /// Validates enum values
    public func validateEnum<T: RawRepresentable>(_ value: String, as enumType: T.Type) -> ValidationResult where T.RawValue == String {
        let rule = EnumValidationRule(enumType: enumType)
        return rule.validate(value)
    }
    
    // MARK: - Business Logic Validation
    
    /// Validates level-XP consistency for character progression
    private func validateLevelXPConsistency(level: Int, xp: Int) -> ValidationError? {
        let expectedMinXP = calculateMinXPForLevel(level)
        let expectedMaxXP = calculateMinXPForLevel(level + 1) - 1
        
        if xp < expectedMinXP {
            return ValidationError(
                field: "levelXP",
                message: "XP is too low for level \(level). Expected at least \(expectedMinXP)",
                severity: .error
            )
        }
        
        if level < WQC.Validation.Player.maxLevel && xp > expectedMaxXP {
            return ValidationError(
                field: "levelXP",
                message: "XP is too high for level \(level). Player should be level \(level + 1)",
                severity: .warning
            )
        }
        
        return nil
    }
    
    /// Calculates minimum XP required for a given level
    private func calculateMinXPForLevel(_ level: Int) -> Int {
        guard level > 1 else { return 0 }
        
        // Using the game's XP progression formula
        var totalXP = 0
        for currentLevel in 1..<level {
            let xpForLevel = Int(WQC.XP.baseXPMultiplier * pow(Double(currentLevel), WQC.XP.xpCurveExponent))
            totalXP += xpForLevel
        }
        
        return totalXP
    }
    
    // MARK: - Batch Validation
    
    // Note: Complex generic validation method removed to avoid compilation issues
    
    // Note: Complex generic validation method removed to avoid compilation issues
}

// MARK: - Validation Extensions

extension InputValidator {
    
    /// Convenience method for validating player creation data
    func validatePlayerCreation(name: String, heroClass: HeroClass) -> [ValidationError] {
        var errors: [ValidationError] = []
        
        // Validate name
        let nameResult = validatePlayerName(name)
        if !nameResult.isValid {
            errors.append(ValidationError(
                field: "name",
                message: nameResult.message ?? "Invalid name",
                severity: nameResult.severity
            ))
        }
        
        // HeroClass is an enum, so it's inherently valid if it exists
        // Additional validation could be added here if needed
        
        return errors
    }
    
    /// Convenience method for validating form input during gameplay
    public func validateGameplayInput(stepCount: Int?, heartRate: Double?, exerciseMinutes: Int?) -> [ValidationError] {
        var errors: [ValidationError] = []
        
        if let steps = stepCount {
            let stepsResult = validateStepCount(steps)
            if !stepsResult.isValid {
                errors.append(ValidationError(
                    field: "steps",
                    message: stepsResult.message ?? "Invalid step count",
                    severity: stepsResult.severity
                ))
            }
        }
        
        if let heartRate = heartRate {
            let heartRateResult = validateHeartRate(heartRate)
            if !heartRateResult.isValid {
                errors.append(ValidationError(
                    field: "heartRate",
                    message: heartRateResult.message ?? "Invalid heart rate",
                    severity: heartRateResult.severity
                ))
            }
        }
        
        if let minutes = exerciseMinutes {
            let exerciseResult = validateExerciseMinutes(minutes)
            if !exerciseResult.isValid {
                errors.append(ValidationError(
                    field: "exerciseMinutes",
                    message: exerciseResult.message ?? "Invalid exercise minutes",
                    severity: exerciseResult.severity
                ))
            }
        }
        
        return errors
    }
}