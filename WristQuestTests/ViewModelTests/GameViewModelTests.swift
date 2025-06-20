import XCTest
import Combine
@testable import WristQuest_Watch_App

@MainActor
final class GameViewModelTests: XCTestCase {
    
    private var viewModel: GameViewModel!
    private var mockPersistenceService: MockPersistenceService!
    private var mockHealthService: MockHealthService!
    private var mockLogger: MockLoggingService!
    private var mockAnalytics: MockAnalyticsService!
    private var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        setupMocks()
        setupViewModel()
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        cancellables = nil
        viewModel = nil
        mockPersistenceService = nil
        mockHealthService = nil
        mockLogger = nil
        mockAnalytics = nil
        super.tearDown()
    }
    
    private func setupMocks() {
        mockPersistenceService = MockPersistenceService()
        mockHealthService = MockHealthService.authorizedMock()
        mockLogger = MockLoggingService()
        mockAnalytics = MockAnalyticsService()
    }
    
    private func setupViewModel() {
        viewModel = GameViewModel(
            persistenceService: mockPersistenceService,
            healthService: mockHealthService,
            logger: mockLogger,
            analytics: mockAnalytics
        )
    }
    
    // MARK: - Initialization Tests
    
    func testGameViewModelInitialization() {
        XCTAssertEqual(viewModel.gameState, .onboarding, "Initial game state should be onboarding")
        XCTAssertNil(viewModel.currentPlayer, "Current player should be nil initially")
        XCTAssertTrue(viewModel.isLoading, "Should be loading initially")
        XCTAssertNil(viewModel.errorMessage, "Error message should be nil initially")
        
        // Verify logging
        XCTAssertTrue(mockLogger.verifyInfoLogged(containing: "GameViewModel initializing"), 
                     "Should log initialization")
    }
    
    // MARK: - Game State Loading Tests
    
    func testLoadGameState_WithExistingPlayer() async {
        // Arrange
        let testPlayer = TestDataFactory.createValidPlayer()
        mockPersistenceService.populateWithTestData()
        
        // Wait for async loading to complete
        let expectation = expectation(description: "Game state loaded")
        
        viewModel.$isLoading
            .dropFirst() // Skip initial true value
            .sink { isLoading in
                if !isLoading {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        await fulfillment(of: [expectation], timeout: 5.0)
        
        // Assert
        XCTAssertEqual(viewModel.gameState, .mainMenu, "Should transition to main menu with existing player")
        XCTAssertNotNil(viewModel.currentPlayer, "Should load existing player")
        XCTAssertFalse(viewModel.isLoading, "Should finish loading")
        XCTAssertEqual(mockPersistenceService.loadPlayerCallCount, 1, "Should call load player once")
        
        // Verify analytics tracking
        XCTAssertTrue(mockAnalytics.wasEventTracked("game_action_appLaunched"), 
                     "Should track app launch")
    }
    
    func testLoadGameState_WithoutExistingPlayer() async {
        // Arrange - MockPersistenceService returns nil by default for new player scenario
        
        // Wait for async loading to complete
        let expectation = expectation(description: "Game state loaded")
        
        viewModel.$isLoading
            .dropFirst() // Skip initial true value
            .sink { isLoading in
                if !isLoading {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        await fulfillment(of: [expectation], timeout: 5.0)
        
        // Assert
        XCTAssertEqual(viewModel.gameState, .onboarding, "Should stay in onboarding for new player")
        XCTAssertNil(viewModel.currentPlayer, "Should not have a player")
        XCTAssertFalse(viewModel.isLoading, "Should finish loading")
        
        // Verify logging
        XCTAssertTrue(mockLogger.verifyInfoLogged(containing: "No saved player found"), 
                     "Should log new player scenario")
    }
    
    func testLoadGameState_WithPersistenceError() async {
        // Arrange
        mockPersistenceService.shouldFailLoadPlayer = true
        mockPersistenceService.loadPlayerError = WQError.persistence(.loadFailed("Test load error"))
        
        // Wait for async loading to complete
        let expectation = expectation(description: "Game state loaded with error")
        
        viewModel.$isLoading
            .dropFirst() // Skip initial true value
            .sink { isLoading in
                if !isLoading {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        await fulfillment(of: [expectation], timeout: 5.0)
        
        // Assert
        XCTAssertEqual(viewModel.gameState, .onboarding, "Should go to onboarding on load error")
        XCTAssertNil(viewModel.currentPlayer, "Should not have a player")
        XCTAssertFalse(viewModel.isLoading, "Should finish loading")
        
        // Verify error handling
        XCTAssertTrue(mockLogger.verifyErrorLogged(containing: "Error loading player"), 
                     "Should log load error")
    }
    
    func testLoadGameState_WithTimeout() async {
        // Arrange - Simulate extremely slow loading
        mockPersistenceService.simulateNetworkDelay = true
        mockPersistenceService.networkDelayDuration = 5.0 // Longer than timeout
        
        // Wait for timeout to trigger
        let expectation = expectation(description: "Loading timeout reached")
        
        viewModel.$gameState
            .dropFirst() // Skip initial onboarding
            .sink { gameState in
                if gameState == .onboarding && !self.viewModel.isLoading {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        await fulfillment(of: [expectation], timeout: 5.0)
        
        // Assert
        XCTAssertEqual(viewModel.gameState, .onboarding, "Should reset to onboarding on timeout")
        XCTAssertFalse(viewModel.isLoading, "Should stop loading")
        XCTAssertNotNil(viewModel.errorMessage, "Should have error message about timeout")
        
        // Verify logging
        XCTAssertTrue(mockLogger.verifyWarningLogged(containing: "Loading timeout reached"), 
                     "Should log timeout warning")
    }
    
    // MARK: - Player Creation and Game Start Tests
    
    func testStartGame_WithValidPlayer() {
        // Arrange
        let testPlayer = TestDataFactory.createValidPlayer(name: "TestHero", heroClass: .warrior)
        
        // Act
        viewModel.startGame(with: testPlayer)
        
        // Assert
        XCTAssertEqual(viewModel.currentPlayer?.name, "TestHero", "Should set current player")
        XCTAssertEqual(viewModel.gameState, .mysticalTransition, "Should start mystical transition")
        XCTAssertTrue(viewModel.isPlayingIntroSequence, "Should be playing intro sequence")
        XCTAssertTrue(viewModel.legendBeginning, "Legend should be beginning")
        XCTAssertFalse(viewModel.realmWelcomeMessage.isEmpty, "Should have welcome message")
        
        // Verify analytics tracking
        XCTAssertTrue(mockAnalytics.wasGameActionTracked(.onboardingCompleted), 
                     "Should track onboarding completion")
        XCTAssertTrue(mockAnalytics.verifyOnboardingTracked(heroClass: "warrior", playerName: "TestHero"), 
                     "Should track correct player details")
        
        // Verify logging
        XCTAssertTrue(mockLogger.verifyInfoLogged(containing: "Starting game with player: TestHero"), 
                     "Should log game start")
    }
    
    func testStartGame_WithInvalidPlayer() {
        // Arrange
        let invalidPlayer = try! Player(
            id: UUID(),
            name: "", // Invalid empty name
            level: 1,
            xp: 0,
            gold: 0,
            stepsToday: 0,
            activeClass: .warrior,
            inventory: [],
            journal: []
        )
        
        // Act
        viewModel.startGame(with: invalidPlayer)
        
        // Assert
        // Should handle validation error and not start the game
        XCTAssertNotEqual(viewModel.gameState, .mysticalTransition, "Should not start transition with invalid player")
        XCTAssertNotNil(viewModel.currentError, "Should have validation error")
        
        // Verify error logging
        XCTAssertTrue(mockLogger.verifyWarningLogged(containing: "validation"), 
                     "Should log validation issues")
    }
    
    func testGenerateRealmWelcome_ForDifferentClasses() {
        // Test warrior welcome
        let warrior = TestDataFactory.createValidPlayer(name: "WarriorHero", heroClass: .warrior)
        viewModel.startGame(with: warrior)
        XCTAssertTrue(viewModel.realmWelcomeMessage.contains("warrior"), 
                     "Warrior welcome should mention warrior")
        XCTAssertTrue(viewModel.realmWelcomeMessage.contains("WarriorHero"), 
                     "Welcome should include player name")
        
        // Reset and test mage
        setupViewModel()
        let mage = TestDataFactory.createValidPlayer(name: "MageHero", heroClass: .mage)
        viewModel.startGame(with: mage)
        XCTAssertTrue(viewModel.realmWelcomeMessage.contains("magic"), 
                     "Mage welcome should mention magic")
        
        // Reset and test rogue
        setupViewModel()
        let rogue = TestDataFactory.createValidPlayer(name: "RogueHero", heroClass: .rogue)
        viewModel.startGame(with: rogue)
        XCTAssertTrue(viewModel.realmWelcomeMessage.contains("shadow"), 
                     "Rogue welcome should mention shadows")
    }
    
    // MARK: - Game State Transition Tests
    
    func testTransitionTo_ValidStates() {
        // Arrange
        let testPlayer = TestDataFactory.createValidPlayer()
        viewModel.startGame(with: testPlayer)
        
        // Test transition to main menu
        viewModel.transitionTo(.mainMenu)
        XCTAssertEqual(viewModel.gameState, .mainMenu, "Should transition to main menu")
        
        // Test transition to inventory
        viewModel.transitionTo(.inventory)
        XCTAssertEqual(viewModel.gameState, .inventory, "Should transition to inventory")
        
        // Test transition to settings
        viewModel.transitionTo(.settings)
        XCTAssertEqual(viewModel.gameState, .settings, "Should transition to settings")
        
        // Test transition to journal
        viewModel.transitionTo(.journal)
        XCTAssertEqual(viewModel.gameState, .journal, "Should transition to journal")
    }
    
    func testTransitionTo_QuestState() {
        // Arrange
        let testPlayer = TestDataFactory.createValidPlayer()
        let testQuest = TestDataFactory.createValidQuest()
        viewModel.startGame(with: testPlayer)
        
        // Act
        viewModel.transitionTo(.activeQuest(testQuest))
        
        // Assert
        XCTAssertEqual(viewModel.gameState, .activeQuest(testQuest), "Should transition to active quest")
    }
    
    func testTransitionTo_EncounterState() {
        // Arrange
        let testPlayer = TestDataFactory.createValidPlayer()
        let testEncounter = TestDataFactory.createCombatEncounter()
        viewModel.startGame(with: testPlayer)
        
        // Act
        viewModel.transitionTo(.encounter(testEncounter))
        
        // Assert
        XCTAssertEqual(viewModel.gameState, .encounter(testEncounter), "Should transition to encounter")
    }
    
    // MARK: - Health Data Integration Tests
    
    func testHealthDataUpdate() {
        // Arrange
        let testPlayer = TestDataFactory.createValidPlayer()
        viewModel.currentPlayer = testPlayer
        let healthData = TestDataFactory.createValidHealthData(steps: 5000)
        
        // Act
        mockHealthService.simulateHealthDataUpdate(healthData)
        
        // Wait for async update
        let expectation = expectation(description: "Health data updated")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // Assert
        XCTAssertEqual(viewModel.currentPlayer?.stepsToday, 5000, "Should update player steps")
        XCTAssertEqual(mockPersistenceService.savePlayerCallCount, 1, "Should save updated player")
    }
    
    func testHealthDataUpdate_WithStepMilestone() {
        // Arrange
        let testPlayer = TestDataFactory.createValidPlayer()
        viewModel.currentPlayer = testPlayer
        let healthData = TestDataFactory.createValidHealthData(steps: 10000) // Milestone
        
        // Act
        mockHealthService.simulateHealthDataUpdate(healthData)
        
        // Wait for async update
        let expectation = expectation(description: "Milestone tracked")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // Assert
        XCTAssertTrue(mockAnalytics.verifyEventParameters(
            "game_action_healthPermissionGranted", 
            expectedParameters: ["steps_milestone": 10000]
        ), "Should track step milestone")
    }
    
    // MARK: - Error Handling Tests
    
    func testHandleError_WQError() {
        // Arrange
        let testError = WQError.gameState(.stateCorrupted("Test error"))
        
        // Act
        viewModel.handleError(testError)
        
        // Assert
        XCTAssertNotNil(viewModel.currentError, "Should set current error")
        XCTAssertTrue(mockLogger.verifyErrorLogged(containing: "GameViewModel error"), 
                     "Should log error")
    }
    
    func testHandleError_GenericError() {
        // Arrange
        struct TestError: Error {
            let message = "Generic test error"
        }
        let testError = TestError()
        
        // Act
        viewModel.handleError(testError)
        
        // Assert
        XCTAssertNotNil(viewModel.currentError, "Should set current error")
        XCTAssertTrue(mockLogger.verifyErrorLogged(containing: "GameViewModel error"), 
                     "Should log error")
    }
    
    func testErrorThrottling() {
        // Arrange
        let testError = WQError.gameState(.stateCorrupted("Test error"))
        
        // Act - Send same error multiple times quickly
        viewModel.handleError(testError)
        viewModel.handleError(testError)
        viewModel.handleError(testError)
        
        // Assert
        XCTAssertEqual(mockLogger.errorCallCount, 1, "Should throttle similar errors")
        XCTAssertTrue(mockLogger.verifyDebugLogged(containing: "Error throttled"), 
                     "Should log throttling")
    }
    
    func testClearError() {
        // Arrange
        let testError = WQError.gameState(.stateCorrupted("Test error"))
        viewModel.handleError(testError)
        
        // Act
        viewModel.clearError()
        
        // Assert
        XCTAssertNil(viewModel.errorMessage, "Should clear error message")
        XCTAssertNil(viewModel.currentError, "Should clear current error")
        XCTAssertFalse(viewModel.isShowingError, "Should not be showing error")
        XCTAssertTrue(viewModel.errorRecoveryOptions.isEmpty, "Should clear recovery options")
    }
    
    // MARK: - Game State Validation Tests
    
    func testValidateGameState_ValidStates() {
        // Test onboarding state (should always be valid)
        viewModel.gameState = .onboarding
        XCTAssertTrue(viewModel.validateGameState(), "Onboarding state should be valid")
        
        // Test mystical transition state
        viewModel.gameState = .mysticalTransition
        XCTAssertTrue(viewModel.validateGameState(), "Mystical transition should be valid")
        
        // Test states that require a player
        let testPlayer = TestDataFactory.createValidPlayer()
        viewModel.currentPlayer = testPlayer
        
        viewModel.gameState = .mainMenu
        XCTAssertTrue(viewModel.validateGameState(), "Main menu with player should be valid")
        
        viewModel.gameState = .inventory
        XCTAssertTrue(viewModel.validateGameState(), "Inventory with player should be valid")
        
        viewModel.gameState = .settings
        XCTAssertTrue(viewModel.validateGameState(), "Settings with player should be valid")
    }
    
    func testValidateGameState_InvalidStates() {
        // Test states that require a player without one
        viewModel.currentPlayer = nil
        
        viewModel.gameState = .mainMenu
        XCTAssertFalse(viewModel.validateGameState(), "Main menu without player should be invalid")
        
        viewModel.gameState = .inventory
        XCTAssertFalse(viewModel.validateGameState(), "Inventory without player should be invalid")
        
        viewModel.gameState = .settings
        XCTAssertFalse(viewModel.validateGameState(), "Settings without player should be invalid")
    }
    
    func testValidateGameState_QuestState() {
        let testPlayer = TestDataFactory.createValidPlayer()
        viewModel.currentPlayer = testPlayer
        
        // Valid quest state
        let validQuest = TestDataFactory.createValidQuest()
        viewModel.gameState = .activeQuest(validQuest)
        XCTAssertTrue(viewModel.validateGameState(), "Active quest with valid quest should be valid")
        
        // Invalid quest state (empty title)
        let invalidQuest = try! Quest(
            id: UUID(),
            title: "", // Empty title
            description: "Test",
            totalDistance: 100.0,
            currentProgress: 0.0,
            isCompleted: false,
            rewardXP: 50,
            rewardGold: 25,
            encounters: []
        )
        viewModel.gameState = .activeQuest(invalidQuest)
        XCTAssertFalse(viewModel.validateGameState(), "Active quest with invalid quest should be invalid")
    }
    
    // MARK: - Debug Methods Tests
    
    func testAddDebugXP() {
        // Arrange
        let testPlayer = TestDataFactory.createValidPlayer(xp: 50)
        viewModel.currentPlayer = testPlayer
        
        // Act
        viewModel.addDebugXP(100)
        
        // Assert
        XCTAssertEqual(viewModel.currentPlayer?.xp, 150, "Should add debug XP")
        XCTAssertEqual(mockPersistenceService.savePlayerCallCount, 1, "Should save updated player")
    }
    
    func testAddDebugXP_WithLevelUp() {
        // Arrange
        let testPlayer = TestDataFactory.createValidPlayer(level: 1, xp: 90)
        viewModel.currentPlayer = testPlayer
        
        // Act
        viewModel.addDebugXP(50) // Should trigger level up (90 + 50 = 140, level 2)
        
        // Assert
        XCTAssertEqual(viewModel.currentPlayer?.xp, 140, "Should add debug XP")
        XCTAssertEqual(viewModel.currentPlayer?.level, 2, "Should level up")
    }
    
    func testResetOnboarding() {
        // Arrange
        let testPlayer = TestDataFactory.createValidPlayer()
        viewModel.currentPlayer = testPlayer
        viewModel.gameState = .mainMenu
        
        // Act
        viewModel.resetOnboarding()
        
        // Assert
        XCTAssertNil(viewModel.currentPlayer, "Should clear current player")
        XCTAssertEqual(viewModel.gameState, .onboarding, "Should return to onboarding")
        XCTAssertFalse(viewModel.isPlayingIntroSequence, "Should reset intro sequence")
        XCTAssertEqual(viewModel.heroAscensionProgress, 0.0, "Should reset ascension progress")
        XCTAssertEqual(mockPersistenceService.clearPlayerDataCallCount, 1, "Should clear player data")
        
        // Verify analytics tracking
        XCTAssertTrue(mockAnalytics.wasGameActionTracked(.settingsChanged), 
                     "Should track settings change")
        
        // Verify logging
        XCTAssertTrue(mockLogger.verifyInfoLogged(containing: "Resetting onboarding"), 
                     "Should log reset action")
    }
    
    // MARK: - Fantasy State Management Tests
    
    func testHeroAscensionAnimation() {
        // Arrange
        let testPlayer = TestDataFactory.createValidPlayer()
        
        // Act
        viewModel.startGame(with: testPlayer)
        
        // Assert initial state
        XCTAssertEqual(viewModel.heroAscensionProgress, 0.0, "Should start with zero progress")
        XCTAssertTrue(viewModel.isPlayingIntroSequence, "Should be playing intro")
        
        // Wait for animation to progress
        let expectation = expectation(description: "Animation progressed")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
        
        // Progress should have increased
        XCTAssertGreaterThan(viewModel.heroAscensionProgress, 0.0, "Animation should have progressed")
    }
    
    func testCompleteGameStart() {
        // Arrange
        let testPlayer = TestDataFactory.createValidPlayer()
        viewModel.startGame(with: testPlayer)
        
        // Wait for game start completion
        let expectation = expectation(description: "Game start completed")
        
        viewModel.$gameState
            .dropFirst() // Skip mystical transition
            .sink { gameState in
                if gameState == .mainMenu {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 5.0)
        
        // Assert
        XCTAssertEqual(viewModel.gameState, .mainMenu, "Should transition to main menu")
        XCTAssertFalse(viewModel.isPlayingIntroSequence, "Should finish intro sequence")
        XCTAssertGreaterThan(mockPersistenceService.savePlayerCallCount, 0, "Should save player")
    }
    
    // MARK: - Epic Moments Tests
    
    func testTriggerEpicGameMoment() {
        // Test doesn't crash and handles all moment types
        viewModel.triggerEpicGameMoment(.firstQuestBegin)
        viewModel.triggerEpicGameMoment(.levelUp(5))
        viewModel.triggerEpicGameMoment(.rareLootFound("Legendary Sword"))
        viewModel.triggerEpicGameMoment(.questComplete("Epic Adventure"))
        
        // No specific assertions - just verify no crashes occur
        XCTAssertTrue(true, "Epic moments should be handled without crashing")
    }
    
    // MARK: - Service Integration Tests
    
    func testHealthServiceErrorHandling() {
        // Arrange
        let healthError = WQError.health(.queryFailed("Test health error"))
        
        // Act
        mockHealthService.triggerError(healthError)
        
        // Wait for error handling
        let expectation = expectation(description: "Health error handled")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // Assert
        XCTAssertTrue(mockLogger.verifyErrorLogged(containing: "GameViewModel error"), 
                     "Should handle health service errors")
    }
    
    func testPersistenceServiceErrorHandling() {
        // Arrange
        let persistenceError = WQError.persistence(.saveFailed("Test persistence error"))
        
        // Act
        mockPersistenceService.triggerError(persistenceError)
        
        // Wait for error handling
        let expectation = expectation(description: "Persistence error handled")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // Assert
        XCTAssertTrue(mockLogger.verifyErrorLogged(containing: "GameViewModel error"), 
                     "Should handle persistence service errors")
    }
    
    // MARK: - Performance Tests
    
    func testMemoryUsageWithManyStateTransitions() {
        measure {
            let testPlayer = TestDataFactory.createValidPlayer()
            viewModel.currentPlayer = testPlayer
            
            // Perform many state transitions
            for _ in 0..<100 {
                viewModel.transitionTo(.mainMenu)
                viewModel.transitionTo(.inventory)
                viewModel.transitionTo(.settings)
                viewModel.transitionTo(.journal)
            }
        }
    }
    
    func testPerformanceWithManyHealthUpdates() {
        measure {
            let testPlayer = TestDataFactory.createValidPlayer()
            viewModel.currentPlayer = testPlayer
            
            // Simulate many health updates
            for steps in 0..<100 {
                let healthData = TestDataFactory.createValidHealthData(steps: steps * 100)
                mockHealthService.simulateHealthDataUpdate(healthData)
            }
        }
    }
}

// MARK: - Test Helpers

extension GameViewModelTests {
    
    /// Helper to wait for game state changes
    private func waitForGameStateChange(to expectedState: GameState, timeout: TimeInterval = 5.0) async {
        let expectation = expectation(description: "Game state changed to \(expectedState)")
        
        viewModel.$gameState
            .sink { gameState in
                if gameState == expectedState {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        await fulfillment(of: [expectation], timeout: timeout)
    }
    
    /// Helper to verify complete game initialization flow
    private func verifyCompleteGameFlow(with player: Player) async {
        viewModel.startGame(with: player)
        
        // Verify mystical transition
        XCTAssertEqual(viewModel.gameState, .mysticalTransition)
        
        // Wait for completion
        await waitForGameStateChange(to: .mainMenu)
        
        // Verify final state
        XCTAssertEqual(viewModel.gameState, .mainMenu)
        XCTAssertNotNil(viewModel.currentPlayer)
        XCTAssertFalse(viewModel.isPlayingIntroSequence)
    }
}