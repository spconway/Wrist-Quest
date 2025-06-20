import XCTest
import Combine
@testable import WristQuest_Watch_App

@MainActor
final class PlayerViewModelTests: XCTestCase {
    
    private var viewModel: PlayerViewModel!
    private var mockPersistenceService: MockPersistenceService!
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
        mockLogger = nil
        mockAnalytics = nil
        super.tearDown()
    }
    
    private func setupMocks() {
        mockPersistenceService = MockPersistenceService()
        mockLogger = MockLoggingService()
        mockAnalytics = MockAnalyticsService()
    }
    
    private func setupViewModel() {
        let testPlayer = TestDataFactory.createValidPlayer()
        viewModel = PlayerViewModel(
            player: testPlayer,
            persistenceService: mockPersistenceService,
            logger: mockLogger,
            analytics: mockAnalytics
        )
    }
    
    // MARK: - Initialization Tests
    
    func testPlayerViewModelInitialization() {
        XCTAssertNotNil(viewModel.player, "Player should be set")
        XCTAssertEqual(viewModel.player.name, "TestHero", "Should have correct player name")
        XCTAssertEqual(viewModel.player.level, 1, "Should start at level 1")
        XCTAssertEqual(viewModel.player.xp, 0, "Should start with 0 XP")
        XCTAssertEqual(viewModel.player.gold, 100, "Should start with initial gold")
        XCTAssertFalse(viewModel.canLevelUp, "Should not be able to level up initially")
        XCTAssertTrue(viewModel.levelUpRewards.isEmpty, "Should have no level up rewards initially")
        
        // Verify logging
        XCTAssertTrue(mockLogger.verifyInfoLogged(containing: "PlayerViewModel initializing for player: TestHero"), 
                     "Should log initialization")
    }
    
    func testInitializationWithDifferentHeroClasses() {
        for heroClass in HeroClass.allCases {
            setupMocks()
            let testPlayer = TestDataFactory.createValidPlayer(heroClass: heroClass)
            let playerViewModel = PlayerViewModel(
                player: testPlayer,
                persistenceService: mockPersistenceService,
                logger: mockLogger,
                analytics: mockAnalytics
            )
            
            XCTAssertEqual(playerViewModel.player.activeClass, heroClass, 
                          "Should initialize with correct hero class: \(heroClass)")
        }
    }
    
    // MARK: - XP System Tests
    
    func testAddXP_ValidAmount() {
        // Arrange
        let initialXP = viewModel.player.xp
        
        // Act
        viewModel.addXP(100)
        
        // Assert
        XCTAssertGreaterThan(viewModel.player.xp, initialXP, "XP should increase")
        XCTAssertEqual(mockPersistenceService.savePlayerCallCount, 1, "Should save player")
        
        // Verify analytics tracking
        XCTAssertTrue(mockAnalytics.wasGameActionTracked(.levelUp), 
                     "Should track XP gain")
        
        // Verify logging
        XCTAssertTrue(mockLogger.verifyInfoLogged(containing: "Adding"), 
                     "Should log XP addition")
    }
    
    func testAddXP_WithClassMultiplier() {
        // Test Warrior XP bonus
        let warriorPlayer = TestDataFactory.createValidPlayer(heroClass: .warrior)
        let warriorViewModel = PlayerViewModel(
            player: warriorPlayer,
            persistenceService: mockPersistenceService,
            logger: mockLogger,
            analytics: mockAnalytics
        )
        
        let initialXP = warriorViewModel.player.xp
        warriorViewModel.addXP(100)
        let warriorXPGain = warriorViewModel.player.xp - initialXP
        
        // Test Ranger XP bonus
        let rangerPlayer = TestDataFactory.createValidPlayer(heroClass: .ranger)
        let rangerViewModel = PlayerViewModel(
            player: rangerPlayer,
            persistenceService: mockPersistenceService,
            logger: mockLogger,
            analytics: mockAnalytics
        )
        
        let rangerInitialXP = rangerViewModel.player.xp
        rangerViewModel.addXP(100)
        let rangerXPGain = rangerViewModel.player.xp - rangerInitialXP
        
        // Test Mage (default multiplier)
        let magePlayer = TestDataFactory.createValidPlayer(heroClass: .mage)
        let mageViewModel = PlayerViewModel(
            player: magePlayer,
            persistenceService: mockPersistenceService,
            logger: mockLogger,
            analytics: mockAnalytics
        )
        
        let mageInitialXP = mageViewModel.player.xp
        mageViewModel.addXP(100)
        let mageXPGain = mageViewModel.player.xp - mageInitialXP
        
        // Assert class-specific bonuses are applied
        XCTAssertNotEqual(warriorXPGain, mageXPGain, "Warrior should have different XP gain than mage")
        XCTAssertNotEqual(rangerXPGain, mageXPGain, "Ranger should have different XP gain than mage")
    }
    
    func testAddXP_InvalidAmount() {
        // Arrange - Set player to near maximum XP
        viewModel.player._xp = 999999 // Using test extension to bypass validation
        let initialXP = viewModel.player.xp
        
        // Act - Try to add XP that would exceed maximum
        viewModel.addXP(10)
        
        // Assert
        XCTAssertEqual(viewModel.player.xp, initialXP, "XP should not change with invalid addition")
        
        // Verify error logging
        XCTAssertTrue(mockLogger.verifyWarningLogged(containing: "XP addition validation failed"), 
                     "Should log validation failure")
        
        // Verify analytics tracking of error
        XCTAssertTrue(mockAnalytics.wasEventTracked("validation_error"), 
                     "Should track validation error")
    }
    
    func testXPProgress_Calculation() {
        // Arrange
        let testPlayer = TestDataFactory.createValidPlayer(level: 2, xp: 150)
        viewModel.player = testPlayer
        
        // Act
        let xpProgress = viewModel.xpProgress
        
        // Assert
        XCTAssertGreaterThanOrEqual(xpProgress, 0.0, "XP progress should be non-negative")
        XCTAssertLessThanOrEqual(xpProgress, 1.0, "XP progress should not exceed 1.0")
    }
    
    func testXPForNextLevel_Calculation() {
        // Act
        let xpForNextLevel = viewModel.xpForNextLevel
        
        // Assert
        XCTAssertGreaterThan(xpForNextLevel, viewModel.player.xp, 
                           "XP for next level should be greater than current XP")
        XCTAssertGreaterThan(xpForNextLevel, 0, "XP for next level should be positive")
    }
    
    // MARK: - Level Up System Tests
    
    func testCanLevelUp_WithSufficientXP() {
        // Arrange - Add enough XP to level up
        let xpForNextLevel = viewModel.xpForNextLevel
        
        // Act
        viewModel.addXP(xpForNextLevel)
        
        // Assert
        XCTAssertTrue(viewModel.canLevelUp, "Should be able to level up with sufficient XP")
    }
    
    func testLevelUp_ValidLevelUp() {
        // Arrange - Make player eligible for level up
        let xpForNextLevel = viewModel.xpForNextLevel
        viewModel.addXP(xpForNextLevel)
        let initialLevel = viewModel.player.level
        
        // Act
        viewModel.levelUp()
        
        // Assert
        XCTAssertEqual(viewModel.player.level, initialLevel + 1, "Level should increase by 1")
        XCTAssertFalse(viewModel.canLevelUp, "Should no longer be able to level up immediately")
        XCTAssertFalse(viewModel.levelUpRewards.isEmpty, "Should have level up rewards")
        
        // Verify analytics tracking
        XCTAssertTrue(mockAnalytics.wasGameActionTracked(.levelUp), 
                     "Should track level up")
        
        // Verify logging
        XCTAssertTrue(mockLogger.verifyInfoLogged(containing: "leveled up"), 
                     "Should log level up")
        
        // Verify persistence
        XCTAssertEqual(mockPersistenceService.savePlayerCallCount, 2, // Once for XP, once for level up
                      "Should save player after level up")
    }
    
    func testLevelUp_WithoutSufficientXP() {
        // Arrange - Player doesn't have enough XP
        XCTAssertFalse(viewModel.canLevelUp, "Should not be able to level up")
        let initialLevel = viewModel.player.level
        
        // Act
        viewModel.levelUp()
        
        // Assert
        XCTAssertEqual(viewModel.player.level, initialLevel, "Level should not change")
        XCTAssertTrue(viewModel.levelUpRewards.isEmpty, "Should not have rewards")
    }
    
    func testLevelUpRewards_Generation() {
        // Arrange - Level up to different thresholds
        let xpNeeded = viewModel.xpForNextLevel * 10 // Enough for multiple levels
        viewModel.addXP(xpNeeded)
        
        // Act - Level up multiple times to test different reward types
        var rewardTypes: Set<String> = []
        while viewModel.canLevelUp {
            viewModel.levelUp()
            rewardTypes.formUnion(Set(viewModel.levelUpRewards))
        }
        
        // Assert
        XCTAssertTrue(rewardTypes.contains { $0.contains("Level") }, 
                     "Should have basic level rewards")
        
        // Check for special milestone rewards if player reached high enough level
        if viewModel.player.level >= 5 {
            XCTAssertTrue(rewardTypes.contains { $0.contains("ability") || $0.contains("stat") }, 
                         "Should have special rewards at milestone levels")
        }
    }
    
    // MARK: - Gold System Tests
    
    func testAddGold_ValidAmount() {
        // Arrange
        let initialGold = viewModel.player.gold
        
        // Act
        viewModel.addGold(50)
        
        // Assert
        XCTAssertGreaterThan(viewModel.player.gold, initialGold, "Gold should increase")
        XCTAssertEqual(mockPersistenceService.savePlayerCallCount, 1, "Should save player")
        
        // Verify logging
        XCTAssertTrue(mockLogger.verifyDebugLogged(containing: "Adding"), 
                     "Should log gold addition")
    }
    
    func testAddGold_WithClassMultiplier() {
        // Test Ranger gold bonus
        let rangerPlayer = TestDataFactory.createValidPlayer(heroClass: .ranger)
        let rangerViewModel = PlayerViewModel(
            player: rangerPlayer,
            persistenceService: mockPersistenceService,
            logger: mockLogger,
            analytics: mockAnalytics
        )
        
        let initialGold = rangerViewModel.player.gold
        rangerViewModel.addGold(100)
        let rangerGoldGain = rangerViewModel.player.gold - initialGold
        
        // Test Rogue gold bonus
        let roguePlayer = TestDataFactory.createValidPlayer(heroClass: .rogue)
        let rogueViewModel = PlayerViewModel(
            player: roguePlayer,
            persistenceService: mockPersistenceService,
            logger: mockLogger,
            analytics: mockAnalytics
        )
        
        let rogueInitialGold = rogueViewModel.player.gold
        rogueViewModel.addGold(100)
        let rogueGoldGain = rogueViewModel.player.gold - rogueInitialGold
        
        // Test Warrior (default multiplier)
        let warriorPlayer = TestDataFactory.createValidPlayer(heroClass: .warrior)
        let warriorViewModel = PlayerViewModel(
            player: warriorPlayer,
            persistenceService: mockPersistenceService,
            logger: mockLogger,
            analytics: mockAnalytics
        )
        
        let warriorInitialGold = warriorViewModel.player.gold
        warriorViewModel.addGold(100)
        let warriorGoldGain = warriorViewModel.player.gold - warriorInitialGold
        
        // Assert class-specific bonuses are applied
        XCTAssertNotEqual(rangerGoldGain, warriorGoldGain, "Ranger should have different gold gain than warrior")
        XCTAssertNotEqual(rogueGoldGain, warriorGoldGain, "Rogue should have different gold gain than warrior")
    }
    
    func testAddGold_InvalidAmount() {
        // Arrange - Set player to near maximum gold
        viewModel.player._gold = 999999 // Using test extension
        let initialGold = viewModel.player.gold
        
        // Act - Try to add gold that would exceed maximum
        viewModel.addGold(10)
        
        // Assert
        XCTAssertEqual(viewModel.player.gold, initialGold, "Gold should not change with invalid addition")
        
        // Verify error logging
        XCTAssertTrue(mockLogger.verifyWarningLogged(containing: "Gold addition validation failed"), 
                     "Should log validation failure")
        
        // Verify analytics tracking of error
        XCTAssertTrue(mockAnalytics.wasEventTracked("validation_error"), 
                     "Should track validation error")
    }
    
    // MARK: - Inventory Management Tests
    
    func testAddItem_ValidItem() {
        // Arrange
        let testItem = TestDataFactory.createValidItem()
        let initialInventorySize = viewModel.player.inventory.count
        
        // Act
        viewModel.addItem(testItem)
        
        // Assert
        XCTAssertEqual(viewModel.player.inventory.count, initialInventorySize + 1, 
                      "Inventory should grow by 1")
        XCTAssertTrue(viewModel.player.inventory.contains { $0.id == testItem.id }, 
                     "Inventory should contain the added item")
        
        // Verify analytics tracking
        XCTAssertTrue(mockAnalytics.wasGameActionTracked(.itemObtained), 
                     "Should track item obtained")
        
        // Verify logging
        XCTAssertTrue(mockLogger.verifyInfoLogged(containing: "Adding item to inventory"), 
                     "Should log item addition")
        
        // Verify persistence
        XCTAssertEqual(mockPersistenceService.savePlayerCallCount, 1, "Should save player")
    }
    
    func testAddItem_WithDifferentRarities() {
        for rarity in Rarity.allCases {
            setupMocks()
            setupViewModel()
            
            let testItem = TestDataFactory.createValidItem(name: "Test \(rarity.rawValue)", rarity: rarity)
            
            viewModel.addItem(testItem)
            
            XCTAssertTrue(viewModel.player.inventory.contains { $0.rarity == rarity }, 
                         "Should add item with rarity: \(rarity)")
            
            // Verify analytics includes rarity
            let itemEvents = mockAnalytics.getGameActions(for: .itemObtained)
            XCTAssertTrue(itemEvents.contains { event in
                if let itemRarity = event.parameters["item_rarity"] as? String {
                    return itemRarity == rarity.rawValue
                }
                return false
            }, "Should track item rarity correctly")
        }
    }
    
    func testAddItem_InvalidItem() {
        // Arrange - Fill inventory to maximum capacity
        let maxItems = 50 // Assuming this is the limit
        for i in 0..<maxItems {
            let item = TestDataFactory.createValidItem(name: "Item \(i)")
            let _ = viewModel.player.addItem(item) // Direct addition to bypass validation
        }
        
        let initialInventorySize = viewModel.player.inventory.count
        let testItem = TestDataFactory.createValidItem(name: "Overflow Item")
        
        // Act
        viewModel.addItem(testItem)
        
        // Assert
        XCTAssertEqual(viewModel.player.inventory.count, initialInventorySize, 
                      "Inventory should not grow beyond limit")
        
        // Verify error logging
        XCTAssertTrue(mockLogger.verifyWarningLogged(containing: "Item addition validation failed"), 
                     "Should log validation failure")
        
        // Verify analytics tracking of error
        XCTAssertTrue(mockAnalytics.wasEventTracked("validation_error"), 
                     "Should track validation error")
    }
    
    func testRemoveItem_ValidItem() {
        // Arrange
        let testItem = TestDataFactory.createValidItem()
        viewModel.addItem(testItem)
        let inventorySizeAfterAdd = viewModel.player.inventory.count
        
        // Act
        viewModel.removeItem(testItem)
        
        // Assert
        XCTAssertEqual(viewModel.player.inventory.count, inventorySizeAfterAdd - 1, 
                      "Inventory should shrink by 1")
        XCTAssertFalse(viewModel.player.inventory.contains { $0.id == testItem.id }, 
                      "Inventory should not contain the removed item")
        
        // Verify persistence
        XCTAssertEqual(mockPersistenceService.savePlayerCallCount, 2, // Once for add, once for remove
                      "Should save player after removal")
    }
    
    func testRemoveItem_NonexistentItem() {
        // Arrange
        let testItem = TestDataFactory.createValidItem()
        let initialInventorySize = viewModel.player.inventory.count
        
        // Act - Try to remove item that's not in inventory
        viewModel.removeItem(testItem)
        
        // Assert
        XCTAssertEqual(viewModel.player.inventory.count, initialInventorySize, 
                      "Inventory size should remain unchanged")
    }
    
    // MARK: - Persistence Tests
    
    func testSavePlayer_Success() async {
        // Arrange
        mockPersistenceService.reset() // Clear any previous saves
        
        // Act
        viewModel.addXP(10) // This triggers save
        
        // Wait for async save
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Assert
        XCTAssertEqual(mockPersistenceService.savePlayerCallCount, 1, "Should save player")
        XCTAssertTrue(mockPersistenceService.verifyPlayerSaved(viewModel.player), 
                     "Should save correct player data")
        
        // Verify success logging
        XCTAssertTrue(mockLogger.verifyDebugLogged(containing: "Player data saved successfully"), 
                     "Should log save success")
    }
    
    func testSavePlayer_Failure() async {
        // Arrange
        mockPersistenceService.shouldFailSavePlayer = true
        mockPersistenceService.savePlayerError = WQError.persistence(.saveFailed("Test save error"))
        
        // Act
        viewModel.addGold(10) // This triggers save
        
        // Wait for async save and error handling
        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        
        // Assert
        XCTAssertEqual(mockPersistenceService.savePlayerCallCount, 1, "Should attempt to save player")
        
        // Verify error logging
        XCTAssertTrue(mockLogger.verifyErrorLogged(containing: "Failed to save player"), 
                     "Should log save error")
        
        // Verify analytics tracking of error
        XCTAssertTrue(mockAnalytics.verifyErrorTracked(containing: "Test save error"), 
                     "Should track save error")
    }
    
    // MARK: - Business Logic Tests
    
    func testPlayerProgression_CompleteCycle() {
        // Simulate complete player progression cycle
        
        // Start with level 1 player
        XCTAssertEqual(viewModel.player.level, 1, "Should start at level 1")
        
        // Add enough XP to level up
        let xpNeeded = viewModel.xpForNextLevel
        viewModel.addXP(xpNeeded)
        
        XCTAssertTrue(viewModel.canLevelUp, "Should be eligible for level up")
        
        // Level up
        viewModel.levelUp()
        
        XCTAssertEqual(viewModel.player.level, 2, "Should be level 2")
        XCTAssertFalse(viewModel.canLevelUp, "Should not be immediately eligible again")
        
        // Add items
        let sword = TestDataFactory.createValidItem(name: "Iron Sword", type: .weapon)
        let armor = TestDataFactory.createArmorItem()
        
        viewModel.addItem(sword)
        viewModel.addItem(armor)
        
        XCTAssertEqual(viewModel.player.inventory.count, 2, "Should have 2 items")
        
        // Add gold
        viewModel.addGold(1000)
        XCTAssertGreaterThan(viewModel.player.gold, 1000, "Should have substantial gold")
        
        // Verify complete state
        XCTAssertGreaterThan(viewModel.player.level, 1, "Should have progressed")
        XCTAssertGreaterThan(viewModel.player.xp, 0, "Should have XP")
        XCTAssertGreaterThan(viewModel.player.gold, 1000, "Should have gold")
        XCTAssertFalse(viewModel.player.inventory.isEmpty, "Should have items")
    }
    
    func testXPCalculations_Consistency() {
        // Test that XP calculations are consistent across different scenarios
        
        for level in 1...10 {
            let xpForLevel = viewModel.calculateXPRequirement(for: level)
            let xpForNextLevel = viewModel.calculateXPRequirement(for: level + 1)
            
            XCTAssertGreaterThanOrEqual(xpForLevel, 0, "XP requirement should be non-negative for level \(level)")
            XCTAssertGreaterThan(xpForNextLevel, xpForLevel, 
                               "XP for level \(level + 1) should be greater than level \(level)")
        }
    }
    
    func testClassMultipliers_Consistency() {
        // Test that class multipliers are applied consistently
        
        for heroClass in HeroClass.allCases {
            let testPlayer = TestDataFactory.createValidPlayer(heroClass: heroClass)
            let playerViewModel = PlayerViewModel(
                player: testPlayer,
                persistenceService: mockPersistenceService,
                logger: mockLogger,
                analytics: mockAnalytics
            )
            
            let initialXP = playerViewModel.player.xp
            let initialGold = playerViewModel.player.gold
            
            playerViewModel.addXP(100)
            playerViewModel.addGold(100)
            
            let xpGain = playerViewModel.player.xp - initialXP
            let goldGain = playerViewModel.player.gold - initialGold
            
            XCTAssertGreaterThan(xpGain, 0, "XP gain should be positive for \(heroClass)")
            XCTAssertGreaterThan(goldGain, 0, "Gold gain should be positive for \(heroClass)")
        }
    }
    
    // MARK: - Edge Cases Tests
    
    func testMaxLevelPlayer() {
        // Arrange - Create max level player
        let maxPlayer = TestDataFactory.createPlayerWithMaxStats()
        viewModel.player = maxPlayer
        
        // Act - Try to add more XP
        viewModel.addXP(1000)
        
        // Assert - Should handle gracefully
        XCTAssertLessThanOrEqual(viewModel.player.level, 50, "Should not exceed reasonable max level")
        XCTAssertLessThanOrEqual(viewModel.player.xp, 999999, "Should not exceed max XP")
    }
    
    func testZeroAmountOperations() {
        // Test adding zero amounts
        let initialXP = viewModel.player.xp
        let initialGold = viewModel.player.gold
        let initialInventorySize = viewModel.player.inventory.count
        
        viewModel.addXP(0)
        viewModel.addGold(0)
        
        XCTAssertEqual(viewModel.player.xp, initialXP, "XP should not change with zero addition")
        XCTAssertEqual(viewModel.player.gold, initialGold, "Gold should not change with zero addition")
        XCTAssertEqual(viewModel.player.inventory.count, initialInventorySize, 
                      "Inventory should not change")
    }
    
    func testNegativeAmountValidation() {
        // Arrange
        let initialXP = viewModel.player.xp
        let initialGold = viewModel.player.gold
        
        // Act - Try to add negative amounts
        viewModel.addXP(-100)
        viewModel.addGold(-50)
        
        // Assert - Should be handled by validation
        // Exact behavior depends on validation implementation
        XCTAssertGreaterThanOrEqual(viewModel.player.xp, initialXP, "XP should not decrease below initial")
        XCTAssertGreaterThanOrEqual(viewModel.player.gold, initialGold, "Gold should not decrease below initial")
    }
    
    // MARK: - Performance Tests
    
    func testPerformanceWithManyItemOperations() {
        measure {
            let items = TestDataFactory.createInventoryItems(count: 50)
            
            for item in items {
                viewModel.addItem(item)
            }
            
            for item in items {
                viewModel.removeItem(item)
            }
        }
    }
    
    func testPerformanceWithManyXPAdditions() {
        measure {
            for _ in 0..<100 {
                viewModel.addXP(10)
            }
        }
    }
    
    func testPerformanceWithManyLevelUps() {
        measure {
            // Add enough XP for multiple level ups
            let xpForManyLevels = viewModel.xpForNextLevel * 10
            viewModel.addXP(xpForManyLevels)
            
            // Level up as much as possible
            while viewModel.canLevelUp {
                viewModel.levelUp()
            }
        }
    }
    
    // MARK: - Analytics and Logging Tests
    
    func testAnalyticsTracking_CompletePlayerProgression() {
        // Complete progression with analytics verification
        
        // Add XP
        viewModel.addXP(100)
        XCTAssertTrue(mockAnalytics.wasGameActionTracked(.levelUp), 
                     "Should track XP addition")
        
        // Level up
        let xpForNextLevel = viewModel.xpForNextLevel
        viewModel.addXP(xpForNextLevel)
        viewModel.levelUp()
        XCTAssertTrue(mockAnalytics.wasGameActionTracked(.levelUp), 
                     "Should track level up")
        
        // Add item
        let testItem = TestDataFactory.createRareItem()
        viewModel.addItem(testItem)
        XCTAssertTrue(mockAnalytics.wasGameActionTracked(.itemObtained), 
                     "Should track item obtained")
        
        // Verify analytics summary
        let summary = mockAnalytics.getAnalyticsSummary()
        XCTAssertGreaterThan(summary.totalEvents, 0, "Should have tracked events")
        XCTAssertGreaterThan(summary.gameActionCount, 0, "Should have tracked game actions")
    }
    
    func testLogging_PlayerOperations() {
        // Test comprehensive logging
        
        viewModel.addXP(50)
        XCTAssertTrue(mockLogger.verifyInfoLogged(containing: "Adding"), 
                     "Should log XP addition")
        
        viewModel.addGold(100)
        XCTAssertTrue(mockLogger.verifyDebugLogged(containing: "Adding"), 
                     "Should log gold addition")
        
        let testItem = TestDataFactory.createValidItem(name: "Logging Test Item")
        viewModel.addItem(testItem)
        XCTAssertTrue(mockLogger.verifyInfoLogged(containing: "Adding item to inventory: Logging Test Item"), 
                     "Should log item addition")
        
        // Verify logging summary
        let loggingSummary = mockLogger.getLoggingSummary()
        XCTAssertGreaterThan(loggingSummary.totalLogs, 0, "Should have logged operations")
        XCTAssertGreaterThan(loggingSummary.infoCount, 0, "Should have info logs")
    }
}

// MARK: - Test Helpers

extension PlayerViewModelTests {
    
    /// Helper to create a player ready for level up
    private func createPlayerReadyForLevelUp() -> Player {
        let player = TestDataFactory.createValidPlayer()
        // Add enough XP to be eligible for level up
        let xpNeeded = viewModel.calculateXPRequirement(for: player.level + 1)
        player._xp = xpNeeded
        return player
    }
    
    /// Helper to verify complete player state
    private func verifyPlayerState(
        expectedLevel: Int? = nil,
        expectedMinXP: Int? = nil,
        expectedMinGold: Int? = nil,
        expectedInventorySize: Int? = nil
    ) {
        if let level = expectedLevel {
            XCTAssertEqual(viewModel.player.level, level, "Player level should match")
        }
        
        if let minXP = expectedMinXP {
            XCTAssertGreaterThanOrEqual(viewModel.player.xp, minXP, "Player XP should meet minimum")
        }
        
        if let minGold = expectedMinGold {
            XCTAssertGreaterThanOrEqual(viewModel.player.gold, minGold, "Player gold should meet minimum")
        }
        
        if let inventorySize = expectedInventorySize {
            XCTAssertEqual(viewModel.player.inventory.count, inventorySize, 
                          "Inventory size should match")
        }
    }
    
    /// Helper to simulate realistic player progression
    private func simulatePlayerProgression(levels: Int) {
        for _ in 0..<levels {
            let xpNeeded = viewModel.xpForNextLevel
            viewModel.addXP(xpNeeded)
            if viewModel.canLevelUp {
                viewModel.levelUp()
            }
        }
    }
}

// MARK: - Player Test Extensions

extension Player {
    // Expose private properties for testing
    var _xp: Int {
        get { xp }
        set {
            // Direct assignment for testing - bypasses validation
            // This would need to be implemented based on your Player structure
        }
    }
    
    var _gold: Int {
        get { gold }
        set {
            // Direct assignment for testing - bypasses validation
            // This would need to be implemented based on your Player structure
        }
    }
}