import XCTest
@testable import WristQuest_Watch_App

final class QuestProgressCalculatorTests: XCTestCase {
    
    // MARK: - Basic Progress Calculation Tests
    
    func testCalculateProgress_WithValidHealthData() {
        // Arrange
        let healthData = TestDataFactory.createValidHealthData(steps: 1000)
        
        // Act & Assert for each hero class
        for heroClass in HeroClass.allCases {
            let progress = QuestProgressCalculator.calculateProgress(from: healthData, for: heroClass)
            
            XCTAssertGreaterThan(progress, 0.0, "Progress should be positive for \(heroClass)")
            XCTAssertLessThan(progress, 10000.0, "Progress should be reasonable for \(heroClass)")
        }
    }
    
    func testCalculateProgress_WithZeroSteps() {
        // Arrange
        let healthData = TestDataFactory.createZeroHealthData()
        
        // Act & Assert for each hero class
        for heroClass in HeroClass.allCases {
            let progress = QuestProgressCalculator.calculateProgress(from: healthData, for: heroClass)
            XCTAssertEqual(progress, 0.0, "Progress should be zero with no steps for \(heroClass)")
        }
    }
    
    func testCalculateProgress_WithHighSteps() {
        // Arrange
        let healthData = TestDataFactory.createHighActivityHealthData() // 15000 steps
        
        // Act & Assert
        let warriorProgress = QuestProgressCalculator.calculateProgress(from: healthData, for: .warrior)
        let mageProgress = QuestProgressCalculator.calculateProgress(from: healthData, for: .mage)
        
        XCTAssertGreaterThan(warriorProgress, 0.0, "Warrior should have positive progress")
        XCTAssertGreaterThan(mageProgress, 0.0, "Mage should have positive progress")
        XCTAssertNotEqual(warriorProgress, mageProgress, "Different classes should have different progress")
    }
    
    // MARK: - Step to Distance Conversion Tests
    
    func testConvertStepsToDistance_ValidSteps() {
        let testCases = [
            (steps: 0, expectedDistance: 0.0),
            (steps: 100, expectedDistance: 100.0 / WQC.Health.stepsPerDistanceUnit),
            (steps: 1000, expectedDistance: 1000.0 / WQC.Health.stepsPerDistanceUnit),
            (steps: 10000, expectedDistance: 10000.0 / WQC.Health.stepsPerDistanceUnit)
        ]
        
        for (steps, expectedDistance) in testCases {
            let distance = QuestProgressCalculator.convertStepsToDistance(steps)
            XCTAssertEqual(distance, expectedDistance, accuracy: 0.001, 
                          "Distance conversion should be accurate for \(steps) steps")
        }
    }
    
    func testConvertStepsToDistance_EdgeCases() {
        // Test very large numbers
        let largeSteps = 1_000_000
        let largeDistance = QuestProgressCalculator.convertStepsToDistance(largeSteps)
        XCTAssertGreaterThan(largeDistance, 0.0, "Should handle large step counts")
        XCTAssertFinite(largeDistance, "Result should be finite")
        
        // Test maximum reasonable values
        let maxSteps = 100_000 // Extreme daily steps
        let maxDistance = QuestProgressCalculator.convertStepsToDistance(maxSteps)
        XCTAssertGreaterThan(maxDistance, 0.0, "Should handle maximum step counts")
    }
    
    // MARK: - Class Distance Modifier Tests
    
    func testGetClassDistanceModifier_AllClasses() {
        let modifiers = HeroClass.allCases.map { heroClass in
            (heroClass, QuestProgressCalculator.getClassDistanceModifier(for: heroClass))
        }
        
        for (heroClass, modifier) in modifiers {
            XCTAssertGreaterThan(modifier, 0.0, "Distance modifier should be positive for \(heroClass)")
            XCTAssertLessThan(modifier, 5.0, "Distance modifier should be reasonable for \(heroClass)")
        }
    }
    
    func testGetClassDistanceModifier_SpecificClasses() {
        // Test known class-specific modifiers
        let rogueModifier = QuestProgressCalculator.getClassDistanceModifier(for: .rogue)
        let rangerModifier = QuestProgressCalculator.getClassDistanceModifier(for: .ranger)
        let warriorModifier = QuestProgressCalculator.getClassDistanceModifier(for: .warrior)
        let mageModifier = QuestProgressCalculator.getClassDistanceModifier(for: .mage)
        let clericModifier = QuestProgressCalculator.getClassDistanceModifier(for: .cleric)
        
        // Rogue should have reduced distance (easier quests)
        XCTAssertLessThan(rogueModifier, 1.0, "Rogue should have reduced distance requirement")
        
        // Ranger should have bonus distance
        XCTAssertGreaterThan(rangerModifier, 1.0, "Ranger should have distance bonus")
        
        // Mage and Cleric should use default modifier
        XCTAssertEqual(mageModifier, clericModifier, "Mage and Cleric should have same modifier")
        
        // All modifiers should be different (except mage/cleric)
        XCTAssertNotEqual(rogueModifier, warriorModifier, "Rogue and Warrior should have different modifiers")
        XCTAssertNotEqual(rangerModifier, warriorModifier, "Ranger and Warrior should have different modifiers")
    }
    
    // MARK: - Class XP Modifier Tests
    
    func testGetClassXPModifier_Walking() {
        // Test walking activity for all classes
        for heroClass in HeroClass.allCases {
            let modifier = QuestProgressCalculator.getClassXPModifier(for: heroClass, activityType: .walking)
            XCTAssertGreaterThan(modifier, 0.0, "XP modifier should be positive for \(heroClass) walking")
            XCTAssertLessThan(modifier, 3.0, "XP modifier should be reasonable for \(heroClass) walking")
        }
        
        // Warrior should get bonus XP for walking
        let warriorWalkingModifier = QuestProgressCalculator.getClassXPModifier(for: .warrior, activityType: .walking)
        XCTAssertGreaterThan(warriorWalkingModifier, 1.0, "Warrior should get walking XP bonus")
    }
    
    func testGetClassXPModifier_Outdoor() {
        // Test outdoor activity
        let rangerOutdoorModifier = QuestProgressCalculator.getClassXPModifier(for: .ranger, activityType: .outdoor)
        let rangerWalkingModifier = QuestProgressCalculator.getClassXPModifier(for: .ranger, activityType: .walking)
        
        XCTAssertGreaterThan(rangerOutdoorModifier, rangerWalkingModifier, 
                           "Ranger should get higher XP bonus for outdoor activity")
        XCTAssertGreaterThan(rangerOutdoorModifier, 1.0, "Ranger outdoor modifier should be greater than 1")
    }
    
    func testGetClassXPModifier_Mindfulness() {
        // Test mindfulness activity for Cleric
        let clericMindfulnessModifier = QuestProgressCalculator.getClassXPModifier(for: .cleric, activityType: .mindfulness)
        let clericWalkingModifier = QuestProgressCalculator.getClassXPModifier(for: .cleric, activityType: .walking)
        
        XCTAssertGreaterThan(clericMindfulnessModifier, clericWalkingModifier, 
                           "Cleric should get higher XP bonus for mindfulness")
        XCTAssertGreaterThan(clericMindfulnessModifier, 1.0, "Cleric mindfulness modifier should be greater than 1")
    }
    
    func testGetClassXPModifier_DefaultActivity() {
        // Test default activity type (should be walking)
        for heroClass in HeroClass.allCases {
            let defaultModifier = QuestProgressCalculator.getClassXPModifier(for: heroClass)
            let walkingModifier = QuestProgressCalculator.getClassXPModifier(for: heroClass, activityType: .walking)
            
            XCTAssertEqual(defaultModifier, walkingModifier, 
                          "Default activity should be walking for \(heroClass)")
        }
    }
    
    // MARK: - Progress Validation Tests
    
    func testValidateProgressUpdate_ValidUpdates() {
        let testCases = [
            (newProgress: 0.0, currentProgress: 0.0, maxProgress: 100.0, shouldBeValid: true),
            (newProgress: 50.0, currentProgress: 30.0, maxProgress: 100.0, shouldBeValid: true),
            (newProgress: 100.0, currentProgress: 90.0, maxProgress: 100.0, shouldBeValid: true),
            (newProgress: 100.0, currentProgress: 100.0, maxProgress: 100.0, shouldBeValid: true) // Completing quest
        ]
        
        for (newProgress, currentProgress, maxProgress, shouldBeValid) in testCases {
            let result = QuestProgressCalculator.validateProgressUpdate(
                newProgress,
                currentProgress: currentProgress,
                maxProgress: maxProgress
            )
            
            XCTAssertEqual(result.isValid, shouldBeValid, 
                          "Progress update (\(currentProgress) → \(newProgress)) should be \(shouldBeValid ? "valid" : "invalid")")
        }
    }
    
    func testValidateProgressUpdate_InvalidUpdates() {
        let invalidTestCases = [
            (newProgress: -10.0, currentProgress: 0.0, maxProgress: 100.0, reason: "negative progress"),
            (newProgress: 150.0, currentProgress: 90.0, maxProgress: 100.0, reason: "exceeds maximum"),
            (newProgress: 50.0, currentProgress: 80.0, maxProgress: 100.0, reason: "goes backward"),
            (newProgress: 75.0, currentProgress: 75.0, maxProgress: 50.0, reason: "exceeds max from start")
        ]
        
        for (newProgress, currentProgress, maxProgress, reason) in invalidTestCases {
            let result = QuestProgressCalculator.validateProgressUpdate(
                newProgress,
                currentProgress: currentProgress,
                maxProgress: maxProgress
            )
            
            XCTAssertFalse(result.isValid, "Progress update should be invalid: \(reason)")
            XCTAssertNotNil(result.message, "Should have error message for invalid update: \(reason)")
        }
    }
    
    // MARK: - Complex Activity Score Calculation Tests
    
    func testCalculateActivityScore_ComprehensiveHealthData() {
        // Test activity score calculation with comprehensive health data
        let testCases = [
            (steps: 0, standingHours: 0, exerciseMinutes: 0, expectedScore: 0),
            (steps: 5000, standingHours: 6, exerciseMinutes: 30, expectedScore: 50...80),
            (steps: 10000, standingHours: 12, exerciseMinutes: 60, expectedScore: 80...100),
            (steps: 15000, standingHours: 16, exerciseMinutes: 90, expectedScore: 100...100)
        ]
        
        for (steps, standingHours, exerciseMinutes, expectedRange) in testCases {
            let healthData = TestDataFactory.createValidHealthData(
                steps: steps,
                standingHours: standingHours,
                exerciseMinutes: exerciseMinutes
            )
            
            let activityScore = QuestProgressCalculator.calculateActivityScore(from: healthData)
            
            XCTAssertTrue(expectedRange.contains(activityScore), 
                         "Activity score \(activityScore) should be in range \(expectedRange) for \(steps) steps")
            XCTAssertGreaterThanOrEqual(activityScore, 0, "Activity score should be non-negative")
            XCTAssertLessThanOrEqual(activityScore, 100, "Activity score should not exceed 100")
        }
    }
    
    func testCalculateActivityScore_WeightedComponents() {
        // Test that different health components are weighted appropriately
        
        // High steps, low other metrics
        let highStepsData = TestDataFactory.createValidHealthData(steps: 15000, standingHours: 2, exerciseMinutes: 10)
        let highStepsScore = QuestProgressCalculator.calculateActivityScore(from: highStepsData)
        
        // Low steps, high other metrics
        let lowStepsData = TestDataFactory.createValidHealthData(steps: 2000, standingHours: 14, exerciseMinutes: 80)
        let lowStepsScore = QuestProgressCalculator.calculateActivityScore(from: lowStepsData)
        
        // Balanced metrics
        let balancedData = TestDataFactory.createValidHealthData(steps: 8000, standingHours: 8, exerciseMinutes: 45)
        let balancedScore = QuestProgressCalculator.calculateActivityScore(from: balancedData)
        
        XCTAssertGreaterThan(highStepsScore, 0, "High steps should contribute to activity score")
        XCTAssertGreaterThan(lowStepsScore, 0, "Other metrics should contribute to activity score")
        XCTAssertGreaterThan(balancedScore, 0, "Balanced metrics should give good activity score")
        
        // Steps should be weighted heavily
        XCTAssertGreaterThan(highStepsScore, lowStepsScore, "Steps should be weighted more heavily than other metrics")
    }
    
    // MARK: - Combat Mode Detection Tests
    
    func testDetectCombatMode_HighHeartRate() {
        let combatHealthData = TestDataFactory.createCombatModeHealthData()
        let isCombatMode = QuestProgressCalculator.detectCombatMode(from: combatHealthData)
        
        XCTAssertTrue(isCombatMode, "Should detect combat mode with high heart rate")
    }
    
    func testDetectCombatMode_NormalHeartRate() {
        let normalHealthData = TestDataFactory.createValidHealthData(heartRate: 75.0)
        let isCombatMode = QuestProgressCalculator.detectCombatMode(from: normalHealthData)
        
        XCTAssertFalse(isCombatMode, "Should not detect combat mode with normal heart rate")
    }
    
    func testDetectCombatMode_Thresholds() {
        let testCases = [
            (heartRate: 60.0, expectedCombat: false),
            (heartRate: 120.0, expectedCombat: false),
            (heartRate: 140.0, expectedCombat: true),
            (heartRate: 160.0, expectedCombat: true),
            (heartRate: 180.0, expectedCombat: true)
        ]
        
        for (heartRate, expectedCombat) in testCases {
            let healthData = TestDataFactory.createValidHealthData(heartRate: heartRate)
            let isCombatMode = QuestProgressCalculator.detectCombatMode(from: healthData)
            
            XCTAssertEqual(isCombatMode, expectedCombat, 
                          "Heart rate \(heartRate) should \(expectedCombat ? "" : "not ")trigger combat mode")
        }
    }
    
    // MARK: - Integration Tests
    
    func testEndToEndCalculation_WarriorQuest() {
        // Test complete calculation flow for a warrior
        let warriorHealthData = TestDataFactory.createValidHealthData(steps: 5000, heartRate: 85.0)
        
        // Calculate progress
        let progress = QuestProgressCalculator.calculateProgress(from: warriorHealthData, for: .warrior)
        
        // Validate progress
        let validationResult = QuestProgressCalculator.validateProgressUpdate(
            progress,
            currentProgress: 0.0,
            maxProgress: 100.0
        )
        
        // Calculate activity score
        let activityScore = QuestProgressCalculator.calculateActivityScore(from: warriorHealthData)
        
        // Detect combat mode
        let isCombatMode = QuestProgressCalculator.detectCombatMode(from: warriorHealthData)
        
        // Assert results
        XCTAssertTrue(validationResult.isValid, "Warrior progress calculation should be valid")
        XCTAssertGreaterThan(progress, 0.0, "Warrior should make quest progress")
        XCTAssertGreaterThan(activityScore, 0, "Warrior should have activity score")
        XCTAssertFalse(isCombatMode, "Normal heart rate should not trigger combat mode")
    }
    
    func testEndToEndCalculation_RogueQuest() {
        // Test complete calculation flow for a rogue with reduced distance
        let rogueHealthData = TestDataFactory.createValidHealthData(steps: 3000)
        
        let rogueProgress = QuestProgressCalculator.calculateProgress(from: rogueHealthData, for: .rogue)
        let warriorProgress = QuestProgressCalculator.calculateProgress(from: rogueHealthData, for: .warrior)
        
        // Rogue should make more progress with same steps due to distance modifier
        XCTAssertGreaterThan(rogueProgress, warriorProgress, 
                           "Rogue should make more progress than warrior with same steps")
    }
    
    func testEndToEndCalculation_ClericMindfulness() {
        // Test cleric's mindfulness bonus
        let mindfulHealthData = TestDataFactory.createValidHealthData(
            steps: 2000, // Low steps
            mindfulMinutes: 20 // High mindfulness
        )
        
        let clericXPModifier = QuestProgressCalculator.getClassXPModifier(for: .cleric, activityType: .mindfulness)
        let clericWalkingModifier = QuestProgressCalculator.getClassXPModifier(for: .cleric, activityType: .walking)
        
        XCTAssertGreaterThan(clericXPModifier, clericWalkingModifier, 
                           "Cleric should get higher XP bonus for mindfulness than walking")
    }
    
    // MARK: - Performance Tests
    
    func testCalculationPerformance() {
        measure {
            let healthData = TestDataFactory.createValidHealthData(steps: 10000)
            
            for _ in 0..<1000 {
                let _ = QuestProgressCalculator.calculateProgress(from: healthData, for: .warrior)
                let _ = QuestProgressCalculator.calculateActivityScore(from: healthData)
                let _ = QuestProgressCalculator.detectCombatMode(from: healthData)
            }
        }
    }
    
    func testClassModifierPerformance() {
        measure {
            for _ in 0..<10000 {
                for heroClass in HeroClass.allCases {
                    let _ = QuestProgressCalculator.getClassDistanceModifier(for: heroClass)
                    let _ = QuestProgressCalculator.getClassXPModifier(for: heroClass)
                }
            }
        }
    }
    
    // MARK: - Edge Cases and Error Handling
    
    func testCalculationWithExtremeValues() {
        // Test with extreme but valid values
        let extremeHealthData = HealthData(
            steps: 100000, // Very high steps
            standingHours: 24, // Maximum possible
            heartRate: 200.0, // Very high heart rate
            exerciseMinutes: 1440, // Maximum possible (24 hours)
            mindfulMinutes: 1440 // Maximum possible
        )
        
        let progress = QuestProgressCalculator.calculateProgress(from: extremeHealthData, for: .warrior)
        let activityScore = QuestProgressCalculator.calculateActivityScore(from: extremeHealthData)
        
        XCTAssertFinite(progress, "Progress calculation should handle extreme values")
        XCTAssertLessThanOrEqual(activityScore, 100, "Activity score should be capped at 100")
        XCTAssertGreaterThanOrEqual(activityScore, 0, "Activity score should be non-negative")
    }
    
    func testCalculationConsistency() {
        // Test that calculations are consistent across multiple calls
        let healthData = TestDataFactory.createValidHealthData(steps: 7500)
        
        let results = (0..<10).map { _ in
            QuestProgressCalculator.calculateProgress(from: healthData, for: .mage)
        }
        
        // All results should be identical
        let firstResult = results[0]
        for result in results {
            XCTAssertEqual(result, firstResult, accuracy: 0.0001, 
                          "Progress calculation should be consistent")
        }
    }
}

// MARK: - Test Helpers

extension QuestProgressCalculatorTests {
    
    /// Helper to test all hero classes with given health data
    private func testAllHeroClasses(
        with healthData: HealthData,
        expectation: (HeroClass, Double) -> Void
    ) {
        for heroClass in HeroClass.allCases {
            let progress = QuestProgressCalculator.calculateProgress(from: healthData, for: heroClass)
            expectation(heroClass, progress)
        }
    }
    
    /// Helper to verify progress is within reasonable bounds
    private func verifyProgressBounds(_ progress: Double, for heroClass: HeroClass, with steps: Int) {
        XCTAssertGreaterThanOrEqual(progress, 0.0, 
                                   "Progress should be non-negative for \(heroClass) with \(steps) steps")
        
        // Progress should be proportional to steps
        let expectedMaxProgress = Double(steps) * 2.0 // Generous upper bound
        XCTAssertLessThan(progress, expectedMaxProgress, 
                         "Progress should be reasonable for \(heroClass) with \(steps) steps")
    }
}