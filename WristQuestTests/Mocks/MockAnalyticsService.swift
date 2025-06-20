import Foundation
@testable import WristQuest_Watch_App

/// Mock implementation of AnalyticsService for testing
class MockAnalyticsService: AnalyticsServiceProtocol {
    
    // MARK: - Analytics Storage
    
    /// Captured events for verification
    private(set) var trackedEvents: [AnalyticsEvent] = []
    
    /// Captured user properties for verification
    private(set) var userProperties: [String: String] = [:]
    
    /// Captured game actions for verification
    private(set) var gameActions: [GameActionEvent] = []
    
    /// Captured errors for verification
    private(set) var trackedErrors: [ErrorEvent] = []
    
    // MARK: - Mock Control Properties
    
    /// Control whether analytics should fail
    var shouldFailTracking = false
    
    /// Track method calls for verification
    var trackEventCallCount = 0
    var trackGameActionCallCount = 0
    var trackUserPropertyCallCount = 0
    var trackErrorCallCount = 0
    var setUserIdCallCount = 0
    
    /// Control whether to simulate network delays
    var simulateNetworkDelay = false
    var networkDelayDuration: TimeInterval = 0.1
    
    /// Current user ID for verification
    private(set) var currentUserId: String?
    
    // MARK: - Protocol Implementation
    
    func trackEvent(_ eventName: String, parameters: [String: Any]?) {
        trackEventCallCount += 1
        
        guard !shouldFailTracking else { return }
        
        let event = AnalyticsEvent(
            name: eventName,
            parameters: parameters ?? [:],
            timestamp: Date(),
            userId: currentUserId
        )
        
        trackedEvents.append(event)
        
        if simulateNetworkDelay {
            Task {
                try? await Task.sleep(nanoseconds: UInt64(networkDelayDuration * 1_000_000_000))
            }
        }
    }
    
    func trackGameAction(_ action: GameAction, parameters: [String: Any]?) {
        trackGameActionCallCount += 1
        
        guard !shouldFailTracking else { return }
        
        let gameActionEvent = GameActionEvent(
            action: action,
            parameters: parameters ?? [:],
            timestamp: Date(),
            userId: currentUserId
        )
        
        gameActions.append(gameActionEvent)
        
        // Also track as regular event for consistency
        trackEvent("game_action_\(action.rawValue)", parameters: parameters)
    }
    
    func trackUserProperty(_ property: UserProperty, value: String) {
        trackUserPropertyCallCount += 1
        
        guard !shouldFailTracking else { return }
        
        userProperties[property.rawValue] = value
        
        if simulateNetworkDelay {
            Task {
                try? await Task.sleep(nanoseconds: UInt64(networkDelayDuration * 1_000_000_000))
            }
        }
    }
    
    func trackError(_ error: Error, context: String?) {
        trackErrorCallCount += 1
        
        guard !shouldFailTracking else { return }
        
        let errorEvent = ErrorEvent(
            error: error,
            context: context,
            timestamp: Date(),
            userId: currentUserId
        )
        
        trackedErrors.append(errorEvent)
        
        // Also track as regular event
        let parameters: [String: Any] = [
            "error_type": String(describing: type(of: error)),
            "error_description": error.localizedDescription,
            "context": context ?? "unknown"
        ]
        
        trackEvent("error_occurred", parameters: parameters)
    }
    
    func setUserId(_ userId: String) {
        setUserIdCallCount += 1
        currentUserId = userId
    }
    
    // MARK: - Mock Control Methods
    
    /// Reset all mock state
    func reset() {
        trackedEvents.removeAll()
        userProperties.removeAll()
        gameActions.removeAll()
        trackedErrors.removeAll()
        currentUserId = nil
        shouldFailTracking = false
        simulateNetworkDelay = false
        networkDelayDuration = 0.1
        
        // Reset call counts
        trackEventCallCount = 0
        trackGameActionCallCount = 0
        trackUserPropertyCallCount = 0
        trackErrorCallCount = 0
        setUserIdCallCount = 0
    }
    
    /// Clear only the tracked data but keep configuration
    func clearTrackedData() {
        trackedEvents.removeAll()
        gameActions.removeAll()
        trackedErrors.removeAll()
    }
    
    /// Check if a specific event was tracked
    func wasEventTracked(_ eventName: String) -> Bool {
        return trackedEvents.contains { $0.name == eventName }
    }
    
    /// Check if a specific game action was tracked
    func wasGameActionTracked(_ action: GameAction) -> Bool {
        return gameActions.contains { $0.action == action }
    }
    
    /// Get the most recent event
    var lastEvent: AnalyticsEvent? {
        return trackedEvents.last
    }
    
    /// Get the most recent game action
    var lastGameAction: GameActionEvent? {
        return gameActions.last
    }
    
    /// Get the most recent error
    var lastError: ErrorEvent? {
        return trackedErrors.last
    }
    
    /// Get events by name
    func getEvents(named eventName: String) -> [AnalyticsEvent] {
        return trackedEvents.filter { $0.name == eventName }
    }
    
    /// Get game actions by type
    func getGameActions(for action: GameAction) -> [GameActionEvent] {
        return gameActions.filter { $0.action == action }
    }
    
    /// Get count of specific event
    func getEventCount(for eventName: String) -> Int {
        return trackedEvents.filter { $0.name == eventName }.count
    }
    
    /// Get count of specific game action
    func getGameActionCount(for action: GameAction) -> Int {
        return gameActions.filter { $0.action == action }.count
    }
    
    /// Check if user property was set
    func wasUserPropertySet(_ property: UserProperty) -> Bool {
        return userProperties[property.rawValue] != nil
    }
    
    /// Get user property value
    func getUserProperty(_ property: UserProperty) -> String? {
        return userProperties[property.rawValue]
    }
    
    /// Verify that specific parameters were included in an event
    func verifyEventParameters(_ eventName: String, expectedParameters: [String: Any]) -> Bool {
        guard let event = trackedEvents.first(where: { $0.name == eventName }) else {
            return false
        }
        
        for (key, expectedValue) in expectedParameters {
            guard let actualValue = event.parameters[key] else {
                return false
            }
            
            // Simple comparison - in real scenarios you might need more sophisticated comparison
            if String(describing: actualValue) != String(describing: expectedValue) {
                return false
            }
        }
        
        return true
    }
    
    /// Get summary of analytics activity
    func getAnalyticsSummary() -> AnalyticsSummary {
        let uniqueEventNames = Set(trackedEvents.map { $0.name })
        let uniqueGameActions = Set(gameActions.map { $0.action })
        
        return AnalyticsSummary(
            totalEvents: trackedEvents.count,
            uniqueEventCount: uniqueEventNames.count,
            gameActionCount: gameActions.count,
            uniqueGameActionCount: uniqueGameActions.count,
            errorCount: trackedErrors.count,
            userPropertyCount: userProperties.count,
            hasUserId: currentUserId != nil
        )
    }
}

// MARK: - Supporting Types

struct AnalyticsEvent {
    let name: String
    let parameters: [String: Any]
    let timestamp: Date
    let userId: String?
}

struct GameActionEvent {
    let action: GameAction
    let parameters: [String: Any]
    let timestamp: Date
    let userId: String?
}

struct ErrorEvent {
    let error: Error
    let context: String?
    let timestamp: Date
    let userId: String?
}

struct AnalyticsSummary {
    let totalEvents: Int
    let uniqueEventCount: Int
    let gameActionCount: Int
    let uniqueGameActionCount: Int
    let errorCount: Int
    let userPropertyCount: Int
    let hasUserId: Bool
    
    var hasTrackedData: Bool {
        return totalEvents > 0 || gameActionCount > 0 || errorCount > 0
    }
}

// MARK: - Test Helper Extensions

extension MockAnalyticsService {
    /// Create pre-configured mock that fails tracking
    static func failingMock() -> MockAnalyticsService {
        let mock = MockAnalyticsService()
        mock.shouldFailTracking = true
        return mock
    }
    
    /// Create pre-configured mock with network delay simulation
    static func withNetworkDelay() -> MockAnalyticsService {
        let mock = MockAnalyticsService()
        mock.simulateNetworkDelay = true
        mock.networkDelayDuration = 0.3
        return mock
    }
    
    /// Create pre-configured mock with user ID set
    static func withUserId(_ userId: String) -> MockAnalyticsService {
        let mock = MockAnalyticsService()
        mock.setUserId(userId)
        return mock
    }
    
    /// Convenience method to verify onboarding completion tracking
    func verifyOnboardingTracked(heroClass: String, playerName: String) -> Bool {
        return wasGameActionTracked(.onboardingCompleted) &&
               verifyEventParameters("game_action_onboardingCompleted", expectedParameters: [
                   "hero_class": heroClass,
                   "player_name": playerName
               ])
    }
    
    /// Convenience method to verify quest tracking
    func verifyQuestTracked(action: GameAction, questTitle: String) -> Bool {
        return wasGameActionTracked(action) &&
               getGameActions(for: action).contains { event in
                   if let title = event.parameters["quest_title"] as? String {
                       return title == questTitle
                   }
                   return false
               }
    }
    
    /// Convenience method to verify error tracking
    func verifyErrorTracked(containing text: String) -> Bool {
        return trackedErrors.contains { event in
            event.error.localizedDescription.contains(text)
        }
    }
    
    /// Get all events as a formatted string for debugging
    func getAllEventsAsString() -> String {
        return trackedEvents.map { event in
            let parametersString = event.parameters.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
            return "\(event.name) - [\(parametersString)]"
        }.joined(separator: "\n")
    }
}

// MARK: - GameAction and UserProperty Extensions for Testing

extension GameAction: CaseIterable {
    public static var allCases: [GameAction] {
        return [
            .appLaunched, .onboardingStarted, .onboardingCompleted,
            .questStarted, .questCompleted, .questCancelled,
            .levelUp, .itemFound, .combatEncounter,
            .healthPermissionGranted, .healthPermissionDenied,
            .settingsChanged, .errorOccurred
        ]
    }
}

extension UserProperty: CaseIterable {
    public static var allCases: [UserProperty] {
        return [.heroClass, .playerLevel, .questsCompleted, .totalPlayTime]
    }
}