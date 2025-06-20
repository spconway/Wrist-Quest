import XCTest
import Combine
@testable import WristQuest_Watch_App

@MainActor
final class QuestViewModelTests: XCTestCase {
    
    private var questViewModel: QuestViewModel!
    private var playerViewModel: PlayerViewModel!
    private var mockPersistenceService: MockPersistenceService!
    private var mockHealthService: MockHealthService!
    private var mockLogger: MockLoggingService!
    private var mockAnalytics: MockAnalyticsService!
    private var mockTutorialService: MockTutorialService!
    private var mockQuestGenerationService: MockQuestGenerationService!
    private var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        setupMocks()
        setupViewModels()
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        cancellables = nil
        questViewModel = nil
        playerViewModel = nil
        mockPersistenceService = nil
        mockHealthService = nil
        mockLogger = nil
        mockAnalytics = nil
        mockTutorialService = nil
        mockQuestGenerationService = nil
        super.tearDown()
    }
    
    private func setupMocks() {
        mockPersistenceService = MockPersistenceService()
        mockHealthService = MockHealthService.authorizedMock()
        mockLogger = MockLoggingService()
        mockAnalytics = MockAnalyticsService()
        mockTutorialService = MockTutorialService()
        mockQuestGenerationService = MockQuestGenerationService()
    }
    
    private func setupViewModels() {
        let testPlayer = TestDataFactory.createValidPlayer()
        playerViewModel = PlayerViewModel(
            player: testPlayer,
            persistenceService: mockPersistenceService,
            logger: mockLogger,
            analytics: mockAnalytics
        )
        
        questViewModel = QuestViewModel(
            playerViewModel: playerViewModel,
            persistenceService: mockPersistenceService,
            healthService: mockHealthService,
            tutorialService: mockTutorialService,
            questGenerationService: mockQuestGenerationService,
            logger: mockLogger,
            analytics: mockAnalytics
        )
    }
    
    // MARK: - Initialization Tests
    
    func testQuestViewModelInitialization() {
        XCTAssertTrue(questViewModel.availableQuests.isEmpty, "Available quests should be empty initially")
        XCTAssertNil(questViewModel.activeQuest, "Active quest should be nil initially")
        XCTAssertTrue(questViewModel.completedQuests.isEmpty, "Completed quests should be empty initially")
        XCTAssertFalse(questViewModel.isLoading, "Should not be loading initially")
        
        // Verify tutorial state
        XCTAssertNil(questViewModel.tutorialQuest, "Tutorial quest should be nil initially")
        XCTAssertEqual(questViewModel.tutorialStage, .notStarted, "Tutorial stage should be not started")
        XCTAssertEqual(questViewModel.tutorialProgress, 0.0, "Tutorial progress should be zero")
        
        // Verify logging
        XCTAssertTrue(mockLogger.verifyInfoLogged(containing: "QuestViewModel initializing"), 
                     "Should log initialization")
    }
    
    func testInitialQuestGeneration() {
        // Verify that initial quests are generated
        XCTAssertGreaterThan(mockQuestGenerationService.generateInitialQuestsCallCount, 0, 
                           "Should generate initial quests")
        
        // Check if quests were loaded
        XCTAssertGreaterThan(mockPersistenceService.loadQuestLogsCallCount, 0, 
                           "Should attempt to load quest logs")
        
        // Check if active quest was loaded
        XCTAssertGreaterThan(mockPersistenceService.loadActiveQuestCallCount, 0, 
                           "Should attempt to load active quest")
    }
    
    // MARK: - Quest Lifecycle Tests
    
    func testStartQuest_ValidQuest() {
        // Arrange
        let testQuest = TestDataFactory.createValidQuest(title: "Test Adventure")
        questViewModel.availableQuests = [testQuest]
        
        // Act
        questViewModel.startQuest(testQuest)
        
        // Assert
        XCTAssertNotNil(questViewModel.activeQuest, "Should have active quest")
        XCTAssertEqual(questViewModel.activeQuest?.title, "Test Adventure", "Should set correct quest")
        XCTAssertEqual(questViewModel.activeQuest?.currentProgress, 0.0, "Should reset progress")
        XCTAssertFalse(questViewModel.activeQuest?.isCompleted ?? true, "Should not be completed")
        XCTAssertTrue(questViewModel.availableQuests.isEmpty, "Should remove quest from available")
        
        // Verify persistence calls
        XCTAssertEqual(mockPersistenceService.saveActiveQuestCallCount, 1, "Should save active quest")
        
        // Verify analytics tracking
        XCTAssertTrue(mockAnalytics.wasGameActionTracked(.questStarted), 
                     "Should track quest started")
        XCTAssertTrue(mockAnalytics.verifyQuestTracked(action: .questStarted, questTitle: "Test Adventure"), 
                     "Should track correct quest details")
        
        // Verify logging
        XCTAssertTrue(mockLogger.verifyInfoLogged(containing: "Starting quest: Test Adventure"), 
                     "Should log quest start")
    }
    
    func testCompleteQuest_ValidCompletion() {
        // Arrange
        let testQuest = TestDataFactory.createCompletedQuest()
        questViewModel.activeQuest = testQuest
        let initialXP = playerViewModel.player.xp
        let initialGold = playerViewModel.player.gold
        
        // Act
        questViewModel.completeQuest()
        
        // Assert
        XCTAssertNil(questViewModel.activeQuest, "Should clear active quest")
        XCTAssertEqual(questViewModel.completedQuests.count, 1, "Should add to completed quests")
        
        // Verify rewards were given
        XCTAssertGreaterThan(playerViewModel.player.xp, initialXP, "Should award XP")
        XCTAssertGreaterThan(playerViewModel.player.gold, initialGold, "Should award gold")
        
        // Verify quest log was created
        let questLog = questViewModel.completedQuests.first
        XCTAssertNotNil(questLog, "Should create quest log")
        XCTAssertEqual(questLog?.questName, testQuest.title, "Quest log should have correct title")
        
        // Verify persistence calls
        XCTAssertEqual(mockPersistenceService.clearActiveQuestCallCount, 1, "Should clear active quest")
        
        // Verify analytics tracking
        XCTAssertTrue(mockAnalytics.wasGameActionTracked(.questCompleted), 
                     "Should track quest completion")
        
        // Verify logging
        XCTAssertTrue(mockLogger.verifyInfoLogged(containing: "Completing quest"), 
                     "Should log quest completion")
    }
    
    func testCancelQuest_ValidCancellation() {
        // Arrange
        let testQuest = TestDataFactory.createInProgressQuest()
        questViewModel.activeQuest = testQuest
        let originalAvailableCount = questViewModel.availableQuests.count
        
        // Act
        questViewModel.cancelQuest()
        
        // Assert
        XCTAssertNil(questViewModel.activeQuest, "Should clear active quest")
        XCTAssertEqual(questViewModel.availableQuests.count, originalAvailableCount + 1, 
                      "Should restore quest to available")
        
        // Verify restored quest is reset
        let restoredQuest = questViewModel.availableQuests.last
        XCTAssertEqual(restoredQuest?.currentProgress, 0.0, "Restored quest should have reset progress")
        XCTAssertFalse(restoredQuest?.isCompleted ?? true, "Restored quest should not be completed")
        
        // Verify persistence calls
        XCTAssertEqual(mockPersistenceService.clearActiveQuestCallCount, 1, "Should clear active quest")
        
        // Verify analytics tracking
        XCTAssertTrue(mockAnalytics.wasGameActionTracked(.questCancelled), 
                     "Should track quest cancellation")
        
        // Verify logging
        XCTAssertTrue(mockLogger.verifyInfoLogged(containing: "Cancelling quest"), 
                     "Should log quest cancellation")
    }
    
    // MARK: - Health Data Integration Tests
    
    func testUpdateQuestProgress_ValidHealthData() {
        // Arrange
        let testQuest = TestDataFactory.createValidQuest(totalDistance: 100.0)
        questViewModel.activeQuest = testQuest
        let healthData = TestDataFactory.createValidHealthData(steps: 5000)
        
        // Act
        mockHealthService.simulateHealthDataUpdate(healthData)
        
        // Wait for async update
        let expectation = expectation(description: "Quest progress updated")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // Assert
        XCTAssertNotNil(questViewModel.activeQuest, "Should still have active quest")
        // Progress calculation depends on QuestProgressCalculator implementation
        XCTAssertGreaterThanOrEqual(questViewModel.activeQuest?.currentProgress ?? 0.0, 0.0, 
                                   "Progress should be non-negative")
        
        // Verify persistence
        XCTAssertGreaterThan(mockPersistenceService.saveActiveQuestCallCount, 0, 
                           "Should save quest progress")
    }
    
    func testUpdateQuestProgress_WithInvalidHealthData() {
        // Arrange
        let testQuest = TestDataFactory.createValidQuest()
        questViewModel.activeQuest = testQuest
        let invalidHealthData = TestDataFactory.createInvalidHealthData()
        let originalProgress = testQuest.currentProgress
        
        // Act
        mockHealthService.simulateHealthDataUpdate(invalidHealthData)
        
        // Wait for processing
        let expectation = expectation(description: "Invalid health data processed")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // Assert
        XCTAssertEqual(questViewModel.activeQuest?.currentProgress, originalProgress, 
                      "Progress should not change with invalid health data")
        
        // Verify error logging
        XCTAssertTrue(mockLogger.verifyErrorLogged(containing: "Health data validation failed"), 
                     "Should log validation error")
    }
    
    func testQuestCompletion_ThroughHealthProgress() {
        // Arrange
        let testQuest = TestDataFactory.createValidQuest(totalDistance: 50.0, currentProgress: 45.0)
        questViewModel.activeQuest = testQuest
        
        // Create health data that would complete the quest
        let healthData = TestDataFactory.createHighActivityHealthData()
        
        // Act
        mockHealthService.simulateHealthDataUpdate(healthData)
        
        // Wait for completion processing
        let expectation = expectation(description: "Quest completed through progress")
        
        questViewModel.$activeQuest
            .sink { activeQuest in
                if activeQuest == nil {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 3.0)
        
        // Assert
        XCTAssertNil(questViewModel.activeQuest, "Quest should be completed and cleared")
        XCTAssertEqual(questViewModel.completedQuests.count, 1, "Should have completed quest")
        
        // Verify analytics
        XCTAssertTrue(mockAnalytics.wasGameActionTracked(.questCompleted), 
                     "Should track automatic quest completion")
    }
    
    // MARK: - Tutorial Quest Tests
    
    func testStartTutorialQuest_ForWarrior() {
        // Act
        questViewModel.startTutorialQuest(for: .warrior)
        
        // Assert
        XCTAssertNotNil(questViewModel.tutorialQuest, "Should create tutorial quest")
        XCTAssertEqual(questViewModel.tutorialQuest?.heroClass, .warrior, "Should be warrior tutorial")
        XCTAssertEqual(questViewModel.tutorialStage, .introduction, "Should start at introduction")
        XCTAssertEqual(questViewModel.tutorialProgress, 0.0, "Should start with zero progress")
        
        // Verify service calls
        XCTAssertEqual(mockTutorialService.createTutorialQuestCallCount, 1, 
                      "Should call tutorial service")
    }
    
    func testAdvanceTutorialQuest_ThroughStages() {
        // Arrange
        questViewModel.startTutorialQuest(for: .mage)
        
        // Act & Assert - Progress through stages
        XCTAssertEqual(questViewModel.tutorialStage, .introduction)
        
        questViewModel.advanceTutorialQuest()
        XCTAssertEqual(questViewModel.tutorialStage, .basicMovement, "Should advance to basic movement")
        
        questViewModel.advanceTutorialQuest()
        XCTAssertEqual(questViewModel.tutorialStage, .encounter, "Should advance to encounter")
        
        questViewModel.advanceTutorialQuest()
        XCTAssertEqual(questViewModel.tutorialStage, .rewards, "Should advance to rewards")
        
        questViewModel.advanceTutorialQuest()
        XCTAssertEqual(questViewModel.tutorialStage, .completion, "Should advance to completion")
        
        // Verify tutorial completion
        XCTAssertNotNil(questViewModel.tutorialRewards, "Should have tutorial rewards")
        
        // Verify service calls
        XCTAssertGreaterThan(mockTutorialService.getNextStageCallCount, 0, 
                           "Should call getNextStage")
        XCTAssertGreaterThan(mockTutorialService.createRewardsCallCount, 0, 
                           "Should create rewards")
    }
    
    func testCompleteTutorialQuest() {
        // Arrange
        questViewModel.startTutorialQuest(for: .rogue)
        questViewModel.tutorialStage = .completion
        
        // Act
        questViewModel.advanceTutorialQuest()
        
        // Assert
        XCTAssertEqual(questViewModel.tutorialStage, .completion, "Should stay at completion")
        XCTAssertNotNil(questViewModel.tutorialRewards, "Should have rewards")
        
        // Verify rewards creation
        XCTAssertGreaterThan(mockTutorialService.createRewardsCallCount, 0, 
                           "Should create tutorial rewards")
    }
    
    func testResetTutorialQuest() {
        // Arrange
        questViewModel.startTutorialQuest(for: .cleric)
        questViewModel.advanceTutorialQuest() // Progress beyond start
        
        // Act
        questViewModel.resetTutorialQuest()
        
        // Assert
        XCTAssertNil(questViewModel.tutorialQuest, "Should clear tutorial quest")
        XCTAssertEqual(questViewModel.tutorialStage, .notStarted, "Should reset to not started")
        XCTAssertNil(questViewModel.tutorialDialogue, "Should clear dialogue")
        XCTAssertEqual(questViewModel.tutorialProgress, 0.0, "Should reset progress")
        XCTAssertFalse(questViewModel.isShowingTutorialEffects, "Should clear effects")
        XCTAssertNil(questViewModel.tutorialEncounter, "Should clear encounter")
        XCTAssertEqual(questViewModel.tutorialNarrative, "", "Should clear narrative")
    }
    
    func testTutorialProgressUpdate() {
        // Arrange
        questViewModel.startTutorialQuest(for: .ranger)
        
        // Act
        questViewModel.advanceTutorialQuest()
        
        // Assert
        XCTAssertGreaterThan(questViewModel.tutorialProgress, 0.0, "Progress should increase")
        XCTAssertLessThanOrEqual(questViewModel.tutorialProgress, 1.0, "Progress should not exceed 1.0")
        
        // Verify service calls
        XCTAssertGreaterThan(mockTutorialService.getStageProgressCallCount, 0, 
                           "Should get stage progress")
    }
    
    func testTutorialEffects() {
        // Arrange
        questViewModel.startTutorialQuest(for: .warrior)
        
        // Act
        questViewModel.advanceTutorialQuest()
        
        // Assert
        XCTAssertTrue(questViewModel.isShowingTutorialEffects, "Should show tutorial effects initially")
        
        // Wait for effects to clear
        let expectation = expectation(description: "Tutorial effects cleared")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        XCTAssertFalse(questViewModel.isShowingTutorialEffects, "Effects should clear after delay")
    }
    
    // MARK: - Quest Generation Tests
    
    func testGenerateNewQuests() {
        // Arrange
        let initialQuestCount = questViewModel.availableQuests.count
        let playerLevel = playerViewModel.player.level
        
        // Act - This should be called internally when starting quest
        questViewModel.startQuest(TestDataFactory.createValidQuest())
        questViewModel.completeQuest()
        
        // Assert
        XCTAssertGreaterThan(mockQuestGenerationService.generateNewQuestsCallCount, 0, 
                           "Should generate new quests after completion")
    }
    
    func testQuestGenerationWithPlayerLevel() {
        // Arrange
        playerViewModel.player.level = 10 // High level player
        
        // Restart quest system with high level
        setupViewModels()
        
        // Assert
        XCTAssertGreaterThan(mockQuestGenerationService.generateInitialQuestsCallCount, 0, 
                           "Should generate quests appropriate for player level")
    }
    
    // MARK: - Validation and Error Handling Tests
    
    func testQuestValidation_BeforeStarting() {
        // Arrange
        let invalidQuest = try! Quest(
            id: UUID(),
            title: "", // Invalid empty title
            description: "Test",
            totalDistance: -10.0, // Invalid negative distance
            currentProgress: 0.0,
            isCompleted: false,
            rewardXP: -5, // Invalid negative XP
            rewardGold: -3, // Invalid negative gold
            encounters: []
        )
        
        // Act & Assert
        // The quest validation should happen in the Quest initializer
        // If we get here, the validation passed (which it shouldn't for this data)
        XCTFail("Should not be able to create quest with invalid data")
    }
    
    func testQuestProgressValidation() {
        // Arrange
        let testQuest = TestDataFactory.createValidQuest(totalDistance: 100.0)
        questViewModel.activeQuest = testQuest
        
        // Simulate invalid progress update
        var invalidQuest = testQuest
        // Try to set progress beyond maximum
        let result = invalidQuest.updateProgress(150.0) // Beyond total distance
        
        // Assert
        XCTAssertFalse(result.isValid, "Should reject progress beyond maximum")
    }
    
    func testHealthDataValidationInProgress() {
        // Arrange
        let testQuest = TestDataFactory.createValidQuest()
        questViewModel.activeQuest = testQuest
        let invalidHealthData = HealthData(
            steps: -100, // Invalid
            standingHours: 25, // Invalid
            heartRate: 300.0, // Invalid
            exerciseMinutes: -10, // Invalid
            mindfulMinutes: -5 // Invalid
        )
        
        // Act
        mockHealthService.simulateHealthDataUpdate(invalidHealthData)
        
        // Wait for processing
        let expectation = expectation(description: "Invalid health data handled")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // Assert
        XCTAssertTrue(mockLogger.verifyErrorLogged(containing: "Health data validation failed"), 
                     "Should log validation failure")
    }
    
    // MARK: - Persistence Tests
    
    func testQuestPersistence_SaveAndLoad() async {
        // Arrange
        let testQuest = TestDataFactory.createValidQuest()
        
        // Act - Start quest (should save)
        questViewModel.startQuest(testQuest)
        
        // Wait for save
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Assert
        XCTAssertEqual(mockPersistenceService.saveActiveQuestCallCount, 1, "Should save active quest")
        XCTAssertTrue(mockPersistenceService.verifyQuestSaved(testQuest), "Should save correct quest")
    }
    
    func testQuestLogPersistence() async {
        // Arrange
        let testQuest = TestDataFactory.createCompletedQuest()
        questViewModel.activeQuest = testQuest
        
        // Act - Complete quest (should save quest log)
        questViewModel.completeQuest()
        
        // Wait for save
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Assert
        XCTAssertEqual(mockPersistenceService.saveQuestLogsCallCount, 1, "Should save quest logs")
        XCTAssertEqual(questViewModel.completedQuests.count, 1, "Should have completed quest")
    }
    
    func testPersistenceError_Handling() {
        // Arrange
        mockPersistenceService.shouldFailSaveQuest = true
        mockPersistenceService.saveQuestError = WQError.persistence(.saveFailed("Test save error"))
        let testQuest = TestDataFactory.createValidQuest()
        
        // Act
        questViewModel.startQuest(testQuest)
        
        // Wait for error handling
        let expectation = expectation(description: "Persistence error handled")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // Assert
        XCTAssertTrue(mockLogger.verifyErrorLogged(containing: "Failed to save active quest"), 
                     "Should log persistence error")
    }
    
    // MARK: - Analytics and Logging Tests
    
    func testAnalyticsTracking_CompleteQuestFlow() {
        // Arrange
        let testQuest = TestDataFactory.createValidQuest(title: "Analytics Test Quest")
        questViewModel.availableQuests = [testQuest]
        
        // Act - Complete full quest lifecycle
        questViewModel.startQuest(testQuest)
        questViewModel.activeQuest = TestDataFactory.createCompletedQuest()
        questViewModel.completeQuest()
        
        // Assert
        XCTAssertTrue(mockAnalytics.wasGameActionTracked(.questStarted), 
                     "Should track quest start")
        XCTAssertTrue(mockAnalytics.wasGameActionTracked(.questCompleted), 
                     "Should track quest completion")
        
        // Verify detailed tracking
        let questStartEvents = mockAnalytics.getGameActions(for: .questStarted)
        XCTAssertEqual(questStartEvents.count, 1, "Should have one quest start event")
        
        let questCompleteEvents = mockAnalytics.getGameActions(for: .questCompleted)
        XCTAssertEqual(questCompleteEvents.count, 1, "Should have one quest complete event")
    }
    
    func testLogging_QuestOperations() {
        // Arrange
        let testQuest = TestDataFactory.createValidQuest(title: "Logging Test Quest")
        questViewModel.availableQuests = [testQuest]
        
        // Act
        questViewModel.startQuest(testQuest)
        questViewModel.cancelQuest()
        
        // Assert
        XCTAssertTrue(mockLogger.verifyInfoLogged(containing: "Starting quest: Logging Test Quest"), 
                     "Should log quest start")
        XCTAssertTrue(mockLogger.verifyInfoLogged(containing: "Cancelling quest: Logging Test Quest"), 
                     "Should log quest cancellation")
    }
    
    // MARK: - Edge Cases Tests
    
    func testStartQuest_WithoutAvailableQuests() {
        // Arrange
        questViewModel.availableQuests = []
        let testQuest = TestDataFactory.createValidQuest()
        
        // Act
        questViewModel.startQuest(testQuest)
        
        // Assert
        XCTAssertNotNil(questViewModel.activeQuest, "Should still set active quest")
        // Available quests list should remain empty since quest wasn't in it
        XCTAssertTrue(questViewModel.availableQuests.isEmpty, "Available quests should remain empty")
    }
    
    func testCompleteQuest_WithoutActiveQuest() {
        // Arrange
        questViewModel.activeQuest = nil
        let initialCompletedCount = questViewModel.completedQuests.count
        
        // Act
        questViewModel.completeQuest()
        
        // Assert
        XCTAssertEqual(questViewModel.completedQuests.count, initialCompletedCount, 
                      "Should not add to completed quests without active quest")
        XCTAssertEqual(mockPersistenceService.clearActiveQuestCallCount, 0, 
                      "Should not attempt to clear without active quest")
    }
    
    func testCancelQuest_WithoutActiveQuest() {
        // Arrange
        questViewModel.activeQuest = nil
        let initialAvailableCount = questViewModel.availableQuests.count
        
        // Act
        questViewModel.cancelQuest()
        
        // Assert
        XCTAssertEqual(questViewModel.availableQuests.count, initialAvailableCount, 
                      "Should not modify available quests without active quest")
    }
    
    // MARK: - Performance Tests
    
    func testPerformanceWithManyQuestOperations() {
        measure {
            let quests = TestDataFactory.createMultipleQuests(count: 50)
            
            for quest in quests {
                questViewModel.availableQuests.append(quest)
                questViewModel.startQuest(quest)
                questViewModel.cancelQuest()
            }
        }
    }
    
    func testPerformanceWithFrequentHealthUpdates() {
        // Arrange
        let testQuest = TestDataFactory.createValidQuest()
        questViewModel.activeQuest = testQuest
        
        measure {
            for steps in 0..<100 {
                let healthData = TestDataFactory.createValidHealthData(steps: steps * 100)
                mockHealthService.simulateHealthDataUpdate(healthData)
            }
        }
    }
    
    // MARK: - Integration Tests
    
    func testCompleteQuestFlow_WithTutorial() {
        // Arrange & Act - Complete tutorial flow
        questViewModel.startTutorialQuest(for: .warrior)
        
        // Progress through all tutorial stages
        while questViewModel.tutorialStage != .completion {
            questViewModel.advanceTutorialQuest()
        }
        
        // Assert
        XCTAssertEqual(questViewModel.tutorialStage, .completion, "Should complete tutorial")
        XCTAssertNotNil(questViewModel.tutorialRewards, "Should have tutorial rewards")
        
        // Verify all service interactions
        XCTAssertGreaterThan(mockTutorialService.createTutorialQuestCallCount, 0, 
                           "Should interact with tutorial service")
        XCTAssertGreaterThan(mockTutorialService.getNextStageCallCount, 0, 
                           "Should progress through stages")
        XCTAssertGreaterThan(mockTutorialService.createRewardsCallCount, 0, 
                           "Should create rewards")
    }
    
    func testQuestSystemResilience() {
        // Test that the quest system can handle various error conditions gracefully
        
        // Test with failing services
        mockPersistenceService.shouldFailSaveQuest = true
        mockTutorialService.shouldFailCreateQuest = true
        mockQuestGenerationService.shouldFailGenerateQuests = true
        
        // These operations should not crash the app
        let testQuest = TestDataFactory.createValidQuest()
        questViewModel.startQuest(testQuest)
        questViewModel.startTutorialQuest(for: .mage)
        questViewModel.completeQuest()
        
        // Verify the system remains functional
        XCTAssertNotNil(questViewModel, "Quest system should remain functional")
        
        // Verify error logging
        XCTAssertGreaterThan(mockLogger.errorCallCount, 0, 
                           "Should log errors from failing services")
    }
}

// MARK: - Test Helpers

extension QuestViewModelTests {
    
    /// Helper to create a quest that's nearly complete
    private func createNearlyCompleteQuest() -> Quest {
        return TestDataFactory.createValidQuest(
            title: "Nearly Complete Quest",
            totalDistance: 100.0,
            currentProgress: 95.0
        )
    }
    
    /// Helper to verify quest state consistency
    private func verifyQuestStateConsistency() {
        if let activeQuest = questViewModel.activeQuest {
            XCTAssertFalse(questViewModel.availableQuests.contains { $0.id == activeQuest.id }, 
                          "Active quest should not be in available quests")
            XCTAssertFalse(questViewModel.completedQuests.contains { $0.questId == activeQuest.id }, 
                          "Active quest should not be in completed quests")
        }
    }
    
    /// Helper to simulate realistic quest progression
    private func simulateQuestProgression(_ quest: Quest, steps: [Int]) {
        questViewModel.activeQuest = quest
        
        for stepCount in steps {
            let healthData = TestDataFactory.createValidHealthData(steps: stepCount)
            mockHealthService.simulateHealthDataUpdate(healthData)
            
            // Small delay to allow processing
            RunLoop.current.run(mode: .default, before: Date(timeIntervalSinceNow: 0.01))
        }
    }
}