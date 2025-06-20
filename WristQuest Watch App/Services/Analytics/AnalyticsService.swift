import Foundation

// MARK: - Analytics Service Protocol

protocol AnalyticsServiceProtocol {
    func trackEvent(_ event: AnalyticsEvent)
    func trackScreenView(_ screenName: String)
    func trackUserProperty(_ property: UserProperty, value: String)
    func trackGameAction(_ action: GameAction, parameters: [String: Any]?)
    func trackError(_ error: Error, context: String)
    func setUserId(_ userId: String)
}

// MARK: - Analytics Event Types

struct AnalyticsEvent {
    let name: String
    let parameters: [String: Any]?
    let timestamp: Date
    
    init(name: String, parameters: [String: Any]? = nil) {
        self.name = name
        self.parameters = parameters
        self.timestamp = Date()
    }
}

enum UserProperty: String {
    case heroClass = "hero_class"
    case playerLevel = "player_level"
    case totalSteps = "total_steps"
    case questsCompleted = "quests_completed"
    case healthPermission = "health_permission"
    case appVersion = "app_version"
}

enum GameAction: String {
    case onboardingCompleted = "onboarding_completed"
    case questStarted = "quest_started"
    case questCompleted = "quest_completed"
    case questCancelled = "quest_cancelled"
    case levelUp = "level_up"
    case itemObtained = "item_obtained"
    case heroClassSelected = "hero_class_selected"
    case healthPermissionGranted = "health_permission_granted"
    case healthPermissionDenied = "health_permission_denied"
    case encounterStarted = "encounter_started"
    case encounterCompleted = "encounter_completed"
    case settingsChanged = "settings_changed"
    case appLaunched = "app_launched"
    case appBackgrounded = "app_backgrounded"
    case complicationInteraction = "complication_interaction"
}

// MARK: - Analytics Service Implementation

class AnalyticsService: AnalyticsServiceProtocol {
    private var userId: String?
    private var events: [AnalyticsEvent] = []
    private let logger: LoggingServiceProtocol?
    
    init(logger: LoggingServiceProtocol? = nil) {
        self.logger = logger
    }
    
    func trackEvent(_ event: AnalyticsEvent) {
        events.append(event)
        logger?.info("Analytics Event: \(event.name)", category: .analytics)
        
        // In a real implementation, this would send to your analytics service
        // For now, we'll just log it
        logEvent(event)
    }
    
    func trackScreenView(_ screenName: String) {
        let event = AnalyticsEvent(
            name: "screen_view",
            parameters: ["screen_name": screenName]
        )
        trackEvent(event)
    }
    
    func trackUserProperty(_ property: UserProperty, value: String) {
        let event = AnalyticsEvent(
            name: "user_property_set",
            parameters: [
                "property": property.rawValue,
                "value": value
            ]
        )
        trackEvent(event)
    }
    
    func trackGameAction(_ action: GameAction, parameters: [String: Any]? = nil) {
        var eventParameters = parameters ?? [:]
        eventParameters["action"] = action.rawValue
        
        if let userId = userId {
            eventParameters["user_id"] = userId
        }
        
        let event = AnalyticsEvent(
            name: "game_action",
            parameters: eventParameters
        )
        trackEvent(event)
    }
    
    func trackError(_ error: Error, context: String) {
        let event = AnalyticsEvent(
            name: "error_occurred",
            parameters: [
                "error_description": error.localizedDescription,
                "context": context,
                "error_domain": (error as NSError).domain,
                "error_code": (error as NSError).code
            ]
        )
        trackEvent(event)
        logger?.error("Error tracked: \(error.localizedDescription) in context: \(context)", category: .analytics)
    }
    
    func setUserId(_ userId: String) {
        self.userId = userId
        logger?.info("Analytics User ID set: \(userId)", category: .analytics)
    }
    
    // MARK: - Private Methods
    
    private func logEvent(_ event: AnalyticsEvent) {
        print("📊 Analytics: \(event.name)")
        if let parameters = event.parameters {
            for (key, value) in parameters {
                print("  - \(key): \(value)")
            }
        }
    }
    
    // MARK: - Debug Methods
    
    func getTrackedEvents() -> [AnalyticsEvent] {
        return events
    }
    
    func clearEvents() {
        events.removeAll()
    }
}

// MARK: - Mock Analytics Service for Testing

class MockAnalyticsService: AnalyticsServiceProtocol {
    var trackedEvents: [AnalyticsEvent] = []
    var screenViews: [String] = []
    var userProperties: [(UserProperty, String)] = []
    var gameActions: [(GameAction, [String: Any]?)] = []
    var errors: [(Error, String)] = []
    var userId: String?
    
    func trackEvent(_ event: AnalyticsEvent) {
        trackedEvents.append(event)
    }
    
    func trackScreenView(_ screenName: String) {
        screenViews.append(screenName)
        trackEvent(AnalyticsEvent(name: "screen_view", parameters: ["screen_name": screenName]))
    }
    
    func trackUserProperty(_ property: UserProperty, value: String) {
        userProperties.append((property, value))
        trackEvent(AnalyticsEvent(name: "user_property_set", parameters: ["property": property.rawValue, "value": value]))
    }
    
    func trackGameAction(_ action: GameAction, parameters: [String: Any]?) {
        gameActions.append((action, parameters))
        var eventParameters = parameters ?? [:]
        eventParameters["action"] = action.rawValue
        trackEvent(AnalyticsEvent(name: "game_action", parameters: eventParameters))
    }
    
    func trackError(_ error: Error, context: String) {
        errors.append((error, context))
        trackEvent(AnalyticsEvent(name: "error_occurred", parameters: ["error": error.localizedDescription, "context": context]))
    }
    
    func setUserId(_ userId: String) {
        self.userId = userId
    }
    
    // Test utilities
    func reset() {
        trackedEvents.removeAll()
        screenViews.removeAll()
        userProperties.removeAll()
        gameActions.removeAll()
        errors.removeAll()
        userId = nil
    }
    
    func getEventsOfType(_ eventName: String) -> [AnalyticsEvent] {
        return trackedEvents.filter { $0.name == eventName }
    }
    
    func hasTrackedAction(_ action: GameAction) -> Bool {
        return gameActions.contains { $0.0 == action }
    }
}