import XCTest
@testable import WristQuest_Watch_App

final class ValidationTests: XCTestCase {
    
    var inputValidator: InputValidator!
    var businessLogicValidator: BusinessLogicValidator!
    
    override func setUpWithError() throws {
        inputValidator = InputValidator.shared
        businessLogicValidator = BusinessLogicValidator.shared
    }
    
    override func tearDownWithError() throws {
        inputValidator = nil
        businessLogicValidator = nil
    }
    
    // MARK: - Player Name Validation Tests
    
    func testPlayerNameValidation_ValidNames() throws {
        let validNames = ["Hero", "Sir Knight", "Mage123", "A", "ThisIsExactlyTwentyC"]
        
        for name in validNames {
            let result = inputValidator.validatePlayerName(name)
            XCTAssertTrue(result.isValid, "Name '\(name)' should be valid")
        }
    }
    
    func testPlayerNameValidation_InvalidNames() throws {
        let invalidNames = [
            "",                                    // Empty
            "   ",                                // Whitespace only
            "ThisNameIsWayTooLongForValidation",  // Too long
            "Name@WithInvalidChars%",             // Invalid characters
            "Name  WithDoubleSpaces"              // Double spaces
        ]
        
        for name in invalidNames {
            let result = inputValidator.validatePlayerName(name)
            XCTAssertFalse(result.isValid, "Name '\(name)' should be invalid")
        }
    }
    
    // MARK: - Player XP Validation Tests
    
    func testPlayerXPValidation_ValidValues() throws {
        let validXPValues = [0, 100, 1000, 50000, 999999]
        
        for xp in validXPValues {
            let result = inputValidator.validatePlayerXP(xp)
            XCTAssertTrue(result.isValid, "XP \(xp) should be valid")
        }
    }
    
    func testPlayerXPValidation_InvalidValues() throws {
        let invalidXPValues = [-1, -100, 1000001, 9999999]
        
        for xp in invalidXPValues {
            let result = inputValidator.validatePlayerXP(xp)
            XCTAssertFalse(result.isValid, "XP \(xp) should be invalid")
        }
    }
    
    // MARK: - Health Data Validation Tests
    
    func testHealthDataValidation_ValidData() throws {
        let validHealthData = [
            HealthData(steps: 1000, standingHours: 8, heartRate: 75.0, exerciseMinutes: 30, mindfulMinutes: 10),
            HealthData(steps: 0, standingHours: 0, heartRate: 0.0, exerciseMinutes: 0, mindfulMinutes: 0),
            HealthData(steps: 50000, standingHours: 16, heartRate: 180.0, exerciseMinutes: 120, mindfulMinutes: 60)
        ]
        
        for healthData in validHealthData {
            let errors = inputValidator.validateHealthData(healthData)
            XCTAssertTrue(errors.isEmpty, "Health data should be valid: \(healthData)")
        }
    }
    
    func testHealthDataValidation_InvalidData() throws {
        let invalidHealthData = [
            HealthData(steps: -100, standingHours: 8, heartRate: 75.0, exerciseMinutes: 30, mindfulMinutes: 10), // Negative steps
            HealthData(steps: 1000, standingHours: 25, heartRate: 75.0, exerciseMinutes: 30, mindfulMinutes: 10), // Too many stand hours
            HealthData(steps: 1000, standingHours: 8, heartRate: 300.0, exerciseMinutes: 30, mindfulMinutes: 10), // Heart rate too high
            HealthData(steps: 150000, standingHours: 8, heartRate: 75.0, exerciseMinutes: 30, mindfulMinutes: 10) // Too many steps
        ]
        
        for healthData in invalidHealthData {
            let errors = inputValidator.validateHealthData(healthData)
            XCTAssertFalse(errors.isEmpty, "Health data should be invalid: \(healthData)")
        }
    }
    
    // MARK: - Quest Validation Tests
    
    func testQuestValidation_ValidQuest() throws {
        let validQuest = try Quest(
            title: "Test Quest",
            description: "A valid test quest",
            totalDistance: 100.0,
            rewardXP: 50,
            rewardGold: 25
        )
        
        let errors = inputValidator.validateQuest(validQuest)
        XCTAssertTrue(errors.isEmpty, "Valid quest should pass validation")
    }
    
    func testQuestValidation_InvalidQuest() throws {
        // Test quest with invalid distance
        XCTAssertThrowsError(try Quest(
            title: "",
            description: "Test quest",
            totalDistance: -10.0,
            rewardXP: 50,
            rewardGold: 25
        ), "Quest with invalid data should throw error")
    }
    
    func testQuestStateTransition_ValidTransitions() throws {
        var oldQuest = try Quest(
            title: "Test Quest",
            description: "A test quest",
            totalDistance: 100.0,
            rewardXP: 50,
            rewardGold: 25
        )
        
        var newQuest = oldQuest
        let progressResult = newQuest.updateProgress(50.0)
        
        XCTAssertTrue(progressResult.isValid, "Progress update should be valid")
        XCTAssertEqual(newQuest.currentProgress, 50.0, "Progress should be updated")
        
        let transitionResult = inputValidator.validateQuestStateTransition(from: oldQuest, to: newQuest)
        XCTAssertTrue(transitionResult.isValid, "Quest state transition should be valid")
    }
    
    func testQuestStateTransition_InvalidTransitions() throws {
        let oldQuest = try Quest(
            title: "Test Quest",
            description: "A test quest",
            totalDistance: 100.0,
            rewardXP: 50,
            rewardGold: 25
        )
        
        var newQuest = oldQuest
        newQuest._currentProgress = -10.0 // Invalid progress
        
        let transitionResult = inputValidator.validateQuestStateTransition(from: oldQuest, to: newQuest)
        XCTAssertFalse(transitionResult.isValid, "Invalid quest state transition should fail")
    }
    
    // MARK: - Player Model Validation Tests
    
    func testPlayerCreation_ValidData() throws {
        let player = try Player(name: "TestHero", activeClass: .warrior)
        
        XCTAssertEqual(player.name, "TestHero")
        XCTAssertEqual(player.level, 1)
        XCTAssertEqual(player.xp, 0)
        XCTAssertEqual(player.gold, 0)
        XCTAssertEqual(player.activeClass, .warrior)
        XCTAssertTrue(player.inventory.isEmpty)
    }
    
    func testPlayerCreation_InvalidData() throws {
        XCTAssertThrowsError(try Player(name: "", activeClass: .warrior), "Empty name should throw error")
        XCTAssertThrowsError(try Player(name: "ThisNameIsWayTooLongForValidationAndShouldFail", activeClass: .warrior), "Long name should throw error")
    }
    
    func testPlayerXPAddition_ValidAmount() throws {
        var player = try Player(name: "TestHero", activeClass: .warrior)
        
        let result = player.addXP(100)
        XCTAssertTrue(result.isValid, "Adding valid XP should succeed")
        XCTAssertEqual(player.xp, 100, "XP should be updated")
    }
    
    func testPlayerXPAddition_InvalidAmount() throws {
        var player = try Player(name: "TestHero", activeClass: .warrior)
        player._xp = 999999 // Set to near maximum
        
        let result = player.addXP(10000) // This should exceed maximum
        XCTAssertFalse(result.isValid, "Adding excessive XP should fail")
    }
    
    func testPlayerInventoryManagement() throws {
        var player = try Player(name: "TestHero", activeClass: .warrior)
        
        let testItem = Item(
            name: "Test Sword",
            type: .weapon,
            level: 1,
            rarity: .common,
            effects: []
        )
        
        let result = player.addItem(testItem)
        XCTAssertTrue(result.isValid, "Adding valid item should succeed")
        XCTAssertEqual(player.inventory.count, 1, "Inventory should contain one item")
    }
    
    // MARK: - Business Logic Validation Tests
    
    func testLevelUpValidation_ValidLevelUp() throws {
        let player = try Player(name: "TestHero", activeClass: .warrior)
        // Manually set XP to level 2 requirement
        player._xp = 200 // Assuming this is enough for level 2
        
        let result = businessLogicValidator.validateLevelUp(player: player, targetLevel: 2)
        XCTAssertTrue(result.isValid, "Valid level up should succeed")
    }
    
    func testLevelUpValidation_InsufficientXP() throws {
        let player = try Player(name: "TestHero", activeClass: .warrior)
        
        let result = businessLogicValidator.validateLevelUp(player: player, targetLevel: 2)
        XCTAssertFalse(result.isValid, "Level up without sufficient XP should fail")
    }
    
    func testQuestCompletionValidation() throws {
        var quest = try Quest(
            title: "Test Quest",
            description: "A test quest",
            totalDistance: 100.0,
            rewardXP: 50,
            rewardGold: 25
        )
        
        let player = try Player(name: "TestHero", activeClass: .warrior)
        
        // Quest not completed yet
        let incompleteResult = businessLogicValidator.validateQuestCompletion(quest: quest, player: player)
        XCTAssertFalse(incompleteResult.isValid, "Incomplete quest should not validate for completion")
        
        // Complete the quest
        let _ = quest.updateProgress(100.0)
        
        let completeResult = businessLogicValidator.validateQuestCompletion(quest: quest, player: player)
        XCTAssertTrue(completeResult.isValid, "Completed quest should validate for completion")
    }
    
    func testGoldTransactionValidation() throws {
        var player = try Player(name: "TestHero", activeClass: .warrior)
        let _ = player.addGold(1000) // Give player some gold
        
        // Valid purchase
        let validPurchase = businessLogicValidator.validateGoldTransaction(player: player, amount: -100, transactionType: "item_purchase")
        XCTAssertTrue(validPurchase.isValid, "Valid gold transaction should succeed")
        
        // Invalid purchase (insufficient funds)
        let invalidPurchase = businessLogicValidator.validateGoldTransaction(player: player, amount: -2000, transactionType: "expensive_item")
        XCTAssertFalse(invalidPurchase.isValid, "Transaction with insufficient funds should fail")
    }
    
    func testGameStateValidation() throws {
        let player = try Player(name: "TestHero", activeClass: .warrior)
        let quest = try Quest(
            title: "Test Quest",
            description: "A test quest",
            totalDistance: 100.0,
            rewardXP: 50,
            rewardGold: 25
        )
        
        let errors = businessLogicValidator.validateGameState(player: player, activeQuest: quest)
        
        // Should have minimal errors for a fresh game state
        let blockingErrors = errors.filter { $0.isBlocking }
        XCTAssertTrue(blockingErrors.isEmpty, "Fresh game state should not have blocking errors")
    }
    
    // MARK: - Validation Error Collection Tests
    
    func testValidationErrorCollection() throws {
        let errors = [
            ValidationError(field: "test1", message: "Error 1", severity: .error),
            ValidationError(field: "test2", message: "Warning 1", severity: .warning),
            ValidationError(field: "test3", message: "Critical 1", severity: .critical)
        ]
        
        let collection = ValidationErrorCollection(errors)
        
        XCTAssertTrue(collection.hasErrors, "Collection should have errors")
        XCTAssertTrue(collection.hasBlockingErrors, "Collection should have blocking errors")
        XCTAssertFalse(collection.hasOnlyWarnings, "Collection should not have only warnings")
        
        XCTAssertEqual(collection.criticalErrors.count, 1, "Should have 1 critical error")
        XCTAssertEqual(collection.errorLevelErrors.count, 1, "Should have 1 error-level error")
        XCTAssertEqual(collection.warnings.count, 1, "Should have 1 warning")
    }
    
    // MARK: - Integration Tests
    
    func testValidationIntegration_CompleteGameFlow() throws {
        // Create a player
        var player = try Player(name: "IntegrationHero", activeClass: .warrior)
        
        // Create and start a quest
        var quest = try Quest(
            title: "Integration Quest",
            description: "Testing complete flow",
            totalDistance: 100.0,
            rewardXP: 50,
            rewardGold: 25
        )
        
        // Validate initial state
        let initialErrors = businessLogicValidator.validateGameState(player: player, activeQuest: quest)
        let initialBlockingErrors = initialErrors.filter { $0.isBlocking }
        XCTAssertTrue(initialBlockingErrors.isEmpty, "Initial game state should be valid")
        
        // Progress the quest
        let progressResult = quest.updateProgress(50.0)
        XCTAssertTrue(progressResult.isValid, "Quest progress should be valid")
        
        // Complete the quest
        let _ = quest.updateProgress(100.0)
        XCTAssertTrue(quest.isCompleted, "Quest should be completed")
        
        // Validate quest completion
        let completionResult = businessLogicValidator.validateQuestCompletion(quest: quest, player: player)
        XCTAssertTrue(completionResult.isValid, "Quest completion should be valid")
        
        // Award rewards
        let xpResult = player.addXP(quest.rewardXP)
        let goldResult = player.addGold(quest.rewardGold)
        
        XCTAssertTrue(xpResult.isValid, "XP reward should be valid")
        XCTAssertTrue(goldResult.isValid, "Gold reward should be valid")
        
        // Validate final state
        let finalErrors = businessLogicValidator.validateGameState(player: player, activeQuest: nil)
        let finalBlockingErrors = finalErrors.filter { $0.isBlocking }
        XCTAssertTrue(finalBlockingErrors.isEmpty, "Final game state should be valid")
    }
    
    // MARK: - Performance Tests
    
    func testValidationPerformance() throws {
        measure {
            let player = try! Player(name: "PerformanceHero", activeClass: .warrior)
            
            for _ in 0..<1000 {
                let _ = inputValidator.validatePlayer(player)
                let _ = businessLogicValidator.validateGameState(player: player, activeQuest: nil)
            }
        }
    }
}

// MARK: - Mock Extensions for Testing

extension Player {
    // Expose private properties for testing
    var _xp: Int {
        get { xp }
        set { 
            // Direct assignment for testing - bypasses validation
            self = Player(
                id: id,
                name: name,
                level: level,
                xp: newValue,
                gold: gold,
                stepsToday: stepsToday,
                activeClass: activeClass,
                inventory: inventory,
                journal: journal
            )
        }
    }
}

extension Quest {
    // Expose private properties for testing
    var _currentProgress: Double {
        get { currentProgress }
        set {
            // Direct assignment for testing - bypasses validation
            self = Quest(
                id: id,
                title: title,
                description: description,
                totalDistance: totalDistance,
                currentProgress: newValue,
                isCompleted: isCompleted,
                rewardXP: rewardXP,
                rewardGold: rewardGold,
                encounters: encounters
            )
        }
    }
}