import Foundation

// Note: WQConstants are accessed globally via WQC typealias

/// QuestProgressCalculator handles all quest progress calculations,
/// including class modifiers and distance conversions
struct QuestProgressCalculator {
    
    // MARK: - Progress Calculation
    
    /// Calculate quest progress from health data
    static func calculateProgress(from healthData: HealthData, for heroClass: HeroClass) -> Double {
        let baseDistance = convertStepsToDistance(healthData.steps)
        let classModifier = getClassDistanceModifier(for: heroClass)
        return baseDistance * classModifier
    }
    
    /// Convert steps to distance units
    static func convertStepsToDistance(_ steps: Int) -> Double {
        return Double(steps) / WQC.Health.stepsPerDistanceUnit
    }
    
    // MARK: - Class Modifiers
    
    /// Get distance modifier based on hero class
    static func getClassDistanceModifier(for heroClass: HeroClass) -> Double {
        switch heroClass {
        case .rogue:
            return WQC.Quest.rogueDistanceModifier
        case .ranger:
            return WQC.Quest.rangerDistanceModifier
        case .warrior:
            return WQC.Quest.warriorDistanceModifier
        case .mage:
            return WQC.Quest.defaultDistanceModifier
        case .cleric:
            return WQC.Quest.defaultDistanceModifier
        }
    }
    
    /// Get XP modifier based on hero class and activity type
    static func getClassXPModifier(for heroClass: HeroClass, activityType: ActivityType = .walking) -> Double {
        switch (heroClass, activityType) {
        case (.warrior, .walking):
            return 1.2 // Warriors get bonus XP for steps
        case (.ranger, .outdoor):
            return 1.3 // Rangers get bonus XP when walking outdoors
        case (.cleric, .mindfulness):
            return 1.5 // Clerics heal via mindful minutes
        default:
            return 1.0
        }
    }
    
    // MARK: - Activity Types
    
    enum ActivityType {
        case walking
        case outdoor
        case exercise
        case mindfulness
        case highHeartRate
    }
    
    // MARK: - Advanced Calculations
    
    /// Calculate time-based progress (for time-sensitive quests)
    static func calculateTimeProgress(startTime: Date, duration: TimeInterval) -> Double {
        let elapsed = Date().timeIntervalSince(startTime)
        return min(elapsed / duration, 1.0)
    }
    
    /// Calculate combined progress from multiple metrics
    static func calculateCombinedProgress(steps: Int, 
                                        standHours: Int, 
                                        exerciseMinutes: Int, 
                                        for heroClass: HeroClass) -> Double {
        let stepProgress = convertStepsToDistance(steps)
        // Simple bonuses for stand hours and exercise minutes
        let standBonus = Double(standHours) * 2.0 // Distance units per stand hour
        let exerciseBonus = Double(exerciseMinutes) * 0.5 // Distance units per exercise minute
        
        let totalProgress = (stepProgress + standBonus + exerciseBonus) * getClassDistanceModifier(for: heroClass)
        
        return totalProgress
    }
    
    /// Validate progress update and return result
    static func validateProgressUpdate(_ newProgress: Double, 
                                     currentProgress: Double, 
                                     maxProgress: Double) -> (isValid: Bool, message: String?) {
        guard newProgress >= 0 else {
            return (false, "Progress cannot be negative")
        }
        
        guard newProgress >= currentProgress else {
            return (false, "Progress cannot go backwards")
        }
        
        let progressIncrease = newProgress - currentProgress
        let maxReasonableIncrease = maxProgress * 0.5 // Max 50% increase in one update
        
        guard progressIncrease <= maxReasonableIncrease else {
            return (false, "Progress increase is unreasonably large")
        }
        
        return (true, nil)
    }
    
    // MARK: - Completion Detection
    
    /// Check if quest should be completed based on progress
    static func shouldCompleteQuest(currentProgress: Double, totalDistance: Double) -> Bool {
        return currentProgress >= totalDistance
    }
    
    /// Calculate completion percentage
    static func calculateCompletionPercentage(currentProgress: Double, totalDistance: Double) -> Double {
        guard totalDistance > 0 else { return 0.0 }
        return min(currentProgress / totalDistance, 1.0) * 100.0
    }
}

// Note: WQConstants are accessed globally via WQC typealias