import Foundation
import Combine
@testable import WristQuest_Watch_App

/// Mock implementation of PersistenceService for testing with in-memory storage
class MockPersistenceService: PersistenceServiceProtocol {
    
    // MARK: - In-Memory Storage
    
    private var storedPlayer: Player?
    private var storedActiveQuest: Quest?
    private var storedQuestLogs: [QuestLog] = []
    private var storedGameSessions: [GameSession] = []
    
    // MARK: - Mock Control Properties
    
    /// Control whether operations should fail
    var shouldFailSavePlayer = false
    var shouldFailLoadPlayer = false
    var shouldFailSaveQuest = false
    var shouldFailLoadQuest = false
    var shouldFailSaveQuestLogs = false
    var shouldFailLoadQuestLogs = false
    var shouldFailClearData = false
    
    /// Control specific errors to return
    var savePlayerError: WQError?
    var loadPlayerError: WQError?
    var saveQuestError: WQError?
    var loadQuestError: WQError?
    var saveQuestLogsError: WQError?
    var loadQuestLogsError: WQError?
    var clearDataError: WQError?
    
    /// Track method calls for verification
    var savePlayerCallCount = 0
    var loadPlayerCallCount = 0
    var saveActiveQuestCallCount = 0
    var loadActiveQuestCallCount = 0
    var clearActiveQuestCallCount = 0
    var saveQuestLogsCallCount = 0
    var loadQuestLogsCallCount = 0
    var clearPlayerDataCallCount = 0
    var saveGameSessionCallCount = 0
    var loadGameSessionsCallCount = 0
    
    /// Simulate network delay
    var simulateNetworkDelay = false
    var networkDelayDuration: TimeInterval = 0.1
    
    /// Error publisher for testing error handling
    private let errorSubject = PassthroughSubject<WQError, Never>()
    var errorPublisher: AnyPublisher<WQError, Never> {
        errorSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Player Operations
    
    func savePlayer(_ player: Player) async throws {
        savePlayerCallCount += 1
        
        if simulateNetworkDelay {
            try await Task.sleep(nanoseconds: UInt64(networkDelayDuration * 1_000_000_000))
        }
        
        if shouldFailSavePlayer {
            let error = savePlayerError ?? WQError.persistence(.saveFailed("Mock save player failed"))
            errorSubject.send(error)
            throw error
        }
        
        // Validate player data before saving
        let validationErrors = InputValidator.shared.validatePlayer(player)
        if !validationErrors.isEmpty {
            let errorCollection = ValidationErrorCollection(validationErrors)
            if errorCollection.hasBlockingErrors {
                let error = WQError.validation(.invalidPlayerName("Player validation failed: \(errorCollection.summaryMessage())"))
                errorSubject.send(error)
                throw error
            }
        }
        
        storedPlayer = player
    }
    
    func loadPlayer() async throws -> Player? {
        loadPlayerCallCount += 1
        
        if simulateNetworkDelay {
            try await Task.sleep(nanoseconds: UInt64(networkDelayDuration * 1_000_000_000))
        }
        
        if shouldFailLoadPlayer {
            let error = loadPlayerError ?? WQError.persistence(.loadFailed("Mock load player failed"))
            errorSubject.send(error)
            throw error
        }
        
        return storedPlayer
    }
    
    func clearPlayerData() async throws {
        clearPlayerDataCallCount += 1
        
        if simulateNetworkDelay {
            try await Task.sleep(nanoseconds: UInt64(networkDelayDuration * 1_000_000_000))
        }
        
        if shouldFailClearData {
            let error = clearDataError ?? WQError.persistence(.clearFailed("Mock clear data failed"))
            errorSubject.send(error)
            throw error
        }
        
        storedPlayer = nil
        storedActiveQuest = nil
        storedQuestLogs = []
        storedGameSessions = []
    }
    
    // MARK: - Quest Operations
    
    func saveActiveQuest(_ quest: Quest) async throws {
        saveActiveQuestCallCount += 1
        
        if simulateNetworkDelay {
            try await Task.sleep(nanoseconds: UInt64(networkDelayDuration * 1_000_000_000))
        }
        
        if shouldFailSaveQuest {
            let error = saveQuestError ?? WQError.persistence(.saveFailed("Mock save quest failed"))
            errorSubject.send(error)
            throw error
        }
        
        // Validate quest data before saving
        let validationErrors = InputValidator.shared.validateQuest(quest)
        if !validationErrors.isEmpty {
            let errorCollection = ValidationErrorCollection(validationErrors)
            if errorCollection.hasBlockingErrors {
                let error = WQError.validation(.invalidQuestData("Quest validation failed: \(errorCollection.summaryMessage())"))
                errorSubject.send(error)
                throw error
            }
        }
        
        storedActiveQuest = quest
    }
    
    func loadActiveQuest() async throws -> Quest? {
        loadActiveQuestCallCount += 1
        
        if simulateNetworkDelay {
            try await Task.sleep(nanoseconds: UInt64(networkDelayDuration * 1_000_000_000))
        }
        
        if shouldFailLoadQuest {
            let error = loadQuestError ?? WQError.persistence(.loadFailed("Mock load quest failed"))
            errorSubject.send(error)
            throw error
        }
        
        return storedActiveQuest
    }
    
    func clearActiveQuest() async throws {
        clearActiveQuestCallCount += 1
        
        if simulateNetworkDelay {
            try await Task.sleep(nanoseconds: UInt64(networkDelayDuration * 1_000_000_000))
        }
        
        storedActiveQuest = nil
    }
    
    // MARK: - Quest Log Operations
    
    func saveQuestLogs(_ questLogs: [QuestLog]) async throws {
        saveQuestLogsCallCount += 1
        
        if simulateNetworkDelay {
            try await Task.sleep(nanoseconds: UInt64(networkDelayDuration * 1_000_000_000))
        }
        
        if shouldFailSaveQuestLogs {
            let error = saveQuestLogsError ?? WQError.persistence(.saveFailed("Mock save quest logs failed"))
            errorSubject.send(error)
            throw error
        }
        
        storedQuestLogs = questLogs
    }
    
    func loadQuestLogs() async throws -> [QuestLog] {
        loadQuestLogsCallCount += 1
        
        if simulateNetworkDelay {
            try await Task.sleep(nanoseconds: UInt64(networkDelayDuration * 1_000_000_000))
        }
        
        if shouldFailLoadQuestLogs {
            let error = loadQuestLogsError ?? WQError.persistence(.loadFailed("Mock load quest logs failed"))
            errorSubject.send(error)
            throw error
        }
        
        return storedQuestLogs
    }
    
    // MARK: - Game Session Operations
    
    func saveGameSession(_ session: GameSession) async throws {
        saveGameSessionCallCount += 1
        
        if simulateNetworkDelay {
            try await Task.sleep(nanoseconds: UInt64(networkDelayDuration * 1_000_000_000))
        }
        
        storedGameSessions.append(session)
    }
    
    func loadGameSessions() async throws -> [GameSession] {
        loadGameSessionsCallCount += 1
        
        if simulateNetworkDelay {
            try await Task.sleep(nanoseconds: UInt64(networkDelayDuration * 1_000_000_000))
        }
        
        return storedGameSessions
    }
    
    // MARK: - Mock Control Methods
    
    /// Reset all mock state to default values
    func reset() {
        // Clear stored data
        storedPlayer = nil
        storedActiveQuest = nil
        storedQuestLogs = []
        storedGameSessions = []
        
        // Reset failure flags
        shouldFailSavePlayer = false
        shouldFailLoadPlayer = false
        shouldFailSaveQuest = false
        shouldFailLoadQuest = false
        shouldFailSaveQuestLogs = false
        shouldFailLoadQuestLogs = false
        shouldFailClearData = false
        
        // Clear error overrides
        savePlayerError = nil
        loadPlayerError = nil
        saveQuestError = nil
        loadQuestError = nil
        saveQuestLogsError = nil
        loadQuestLogsError = nil
        clearDataError = nil
        
        // Reset simulation settings
        simulateNetworkDelay = false
        networkDelayDuration = 0.1
        
        // Reset call counts
        savePlayerCallCount = 0
        loadPlayerCallCount = 0
        saveActiveQuestCallCount = 0
        loadActiveQuestCallCount = 0
        clearActiveQuestCallCount = 0
        saveQuestLogsCallCount = 0
        loadQuestLogsCallCount = 0
        clearPlayerDataCallCount = 0
        saveGameSessionCallCount = 0
        loadGameSessionsCallCount = 0
    }
    
    /// Pre-populate with test data
    func populateWithTestData() {
        storedPlayer = TestDataFactory.createValidPlayer()
        storedActiveQuest = TestDataFactory.createInProgressQuest()
        storedQuestLogs = TestDataFactory.createMultipleQuestLogs()
    }
    
    /// Get the currently stored player for verification
    var currentStoredPlayer: Player? {
        return storedPlayer
    }
    
    /// Get the currently stored quest for verification
    var currentStoredQuest: Quest? {
        return storedActiveQuest
    }
    
    /// Get the currently stored quest logs for verification
    var currentStoredQuestLogs: [QuestLog] {
        return storedQuestLogs
    }
    
    /// Verify that specific data was saved
    func verifyPlayerSaved(_ expectedPlayer: Player) -> Bool {
        guard let stored = storedPlayer else { return false }
        return stored.id == expectedPlayer.id && 
               stored.name == expectedPlayer.name &&
               stored.level == expectedPlayer.level &&
               stored.xp == expectedPlayer.xp
    }
    
    func verifyQuestSaved(_ expectedQuest: Quest) -> Bool {
        guard let stored = storedActiveQuest else { return false }
        return stored.id == expectedQuest.id &&
               stored.title == expectedQuest.title &&
               stored.currentProgress == expectedQuest.currentProgress
    }
    
    /// Simulate data corruption scenario
    func simulateDataCorruption() {
        // Create invalid data that would cause validation errors
        storedPlayer = try! Player(
            id: UUID(),
            name: "", // Invalid empty name
            level: -1, // Invalid negative level
            xp: -100, // Invalid negative XP
            gold: -50, // Invalid negative gold
            stepsToday: -1000, // Invalid negative steps
            activeClass: .warrior,
            inventory: [],
            journal: []
        )
    }
    
    /// Trigger a specific error for testing error handling
    func triggerError(_ error: WQError) {
        errorSubject.send(error)
    }
}

// MARK: - Test Helper Extensions

extension MockPersistenceService {
    /// Create pre-configured mock with valid player data
    static func withPlayerData() -> MockPersistenceService {
        let mock = MockPersistenceService()
        mock.populateWithTestData()
        return mock
    }
    
    /// Create pre-configured mock that always fails saves
    static func failingSaveMock() -> MockPersistenceService {
        let mock = MockPersistenceService()
        mock.shouldFailSavePlayer = true
        mock.shouldFailSaveQuest = true
        mock.shouldFailSaveQuestLogs = true
        return mock
    }
    
    /// Create pre-configured mock that always fails loads
    static func failingLoadMock() -> MockPersistenceService {
        let mock = MockPersistenceService()
        mock.shouldFailLoadPlayer = true
        mock.shouldFailLoadQuest = true
        mock.shouldFailLoadQuestLogs = true
        return mock
    }
    
    /// Create pre-configured mock with network delay simulation
    static func withNetworkDelay() -> MockPersistenceService {
        let mock = MockPersistenceService()
        mock.simulateNetworkDelay = true
        mock.networkDelayDuration = 0.5
        return mock
    }
    
    /// Create pre-configured mock for new player scenario
    static func emptyMock() -> MockPersistenceService {
        let mock = MockPersistenceService()
        // No stored data - represents new player scenario
        return mock
    }
    
    /// Create pre-configured mock with corrupted data
    static func corruptedDataMock() -> MockPersistenceService {
        let mock = MockPersistenceService()
        mock.simulateDataCorruption()
        return mock
    }
}