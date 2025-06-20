import SwiftUI

/// Reusable accessibility view modifiers for consistent WristQuest accessibility patterns
/// These modifiers encapsulate common accessibility behaviors specific to the game

// MARK: - Game-Specific Accessibility Modifiers

extension View {
    
    /// Applies WristQuest styling with accessibility support
    /// Combines visual design with comprehensive accessibility features
    /// - Parameters:
    ///   - title: The main title/label for the element
    ///   - description: Optional description for VoiceOver
    ///   - role: The accessibility role/trait
    /// - Returns: Styled view with accessibility
    func wqAccessible(
        title: String,
        description: String? = nil,
        role: WQAccessibilityRole = .none
    ) -> some View {
        self
            .accessibilityLabel(title)
            .accessibilityValue(description ?? "")
            .accessibilityAddTraits(role.traits)
            .accessibilityHint(role.defaultHint)
    }
    
    /// Applies accessibility for WristQuest progress indicators
    /// Handles both circular and linear progress displays
    /// - Parameters:
    ///   - type: The type of progress being shown
    ///   - current: Current progress value
    ///   - total: Total/maximum progress value
    ///   - unit: Unit of measurement
    /// - Returns: Progress view with accessibility
    func wqProgressAccessible(
        type: WQProgressType,
        current: Double,
        total: Double,
        unit: String = ""
    ) -> some View {
        let percentage = total > 0 ? (current / total) * 100 : 0
        let description = "\(String(format: "%.1f", current)) of \(String(format: "%.1f", total)) \(unit)".trimmingCharacters(in: .whitespaces)
        
        return self
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(type.accessibilityLabel)
            .accessibilityValue("\(Int(percentage)) percent complete. \(description)")
            .accessibilityHint("Progress indicator")
            .accessibilityAddTraits(.updatesFrequently)
    }
    
    /// Applies accessibility for WristQuest character and player stats
    /// Handles player info, character classes, and stat displays
    /// - Parameters:
    ///   - statType: The type of stat being displayed
    ///   - value: The current value
    ///   - context: Additional context information
    /// - Returns: Stat view with accessibility
    func wqStatAccessible(
        statType: WQStatType,
        value: String,
        context: String? = nil
    ) -> some View {
        var fullDescription = "\(statType.displayName): \(value)"
        if let context = context {
            fullDescription += ". \(context)"
        }
        
        return self
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(statType.displayName)
            .accessibilityValue(value)
            .accessibilityHint(context ?? statType.defaultHint)
    }
    
    /// Applies accessibility for WristQuest activity and health metrics
    /// Handles HealthKit data display with appropriate formatting
    /// - Parameters:
    ///   - metric: The health metric being displayed
    ///   - value: The current value
    ///   - isActive: Whether this metric is currently active/highlighted
    /// - Returns: Health metric view with accessibility
    func wqHealthMetricAccessible(
        metric: WQHealthMetric,
        value: String,
        isActive: Bool = false
    ) -> some View {
        var traits: AccessibilityTraits = []
        var statusDescription = ""
        
        if isActive {
            traits.insert(.startsMediaSession)
            statusDescription = "Currently active"
        }
        
        return self
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(metric.accessibilityLabel)
            .accessibilityValue("\(value) \(statusDescription)".trimmingCharacters(in: .whitespaces))
            .accessibilityHint(metric.accessibilityHint)
            .accessibilityAddTraits(traits)
    }
    
    /// Applies accessibility for WristQuest quest-related elements
    /// Handles quest cards, progress, and actions
    /// - Parameters:
    ///   - quest: Quest information
    ///   - action: The action type for this quest element
    /// - Returns: Quest element with accessibility
    func wqQuestAccessible(
        quest: WQQuestAccessibilityInfo,
        action: WQQuestAction = .view
    ) -> some View {
        let statusText = quest.isCompleted ? "Completed" : 
                        quest.isActive ? "In progress" : "Available"
        
        var description = "\(quest.title). \(statusText)."
        if let questDescription = quest.description {
            description += " \(questDescription)"
        }
        
        if quest.isActive && !quest.isCompleted {
            let progress = Int(quest.progress * 100)
            description += " \(progress) percent complete."
        }
        
        if quest.rewardXP > 0 || quest.rewardGold > 0 {
            description += " Rewards: \(quest.rewardXP) experience points"
            if quest.rewardGold > 0 {
                description += " and \(quest.rewardGold) gold"
            }
        }
        
        return self
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Quest: \(quest.title)")
            .accessibilityValue(description)
            .accessibilityHint(action.accessibilityHint)
            .accessibilityAddTraits(action.traits)
    }
    
    /// Applies accessibility for WristQuest navigation elements
    /// Handles menu items, tabs, and navigation buttons
    /// - Parameters:
    ///   - destination: The navigation destination
    ///   - badge: Optional badge/notification count
    /// - Returns: Navigation element with accessibility
    func wqNavigationAccessible(
        destination: WQNavigationDestination,
        badge: Int? = nil
    ) -> some View {
        var label = destination.accessibilityLabel
        var hint = "Double tap to navigate to \(destination.displayName)"
        
        if let badge = badge, badge > 0 {
            label += ", \(badge) notifications"
            hint += ". \(badge) new items available"
        }
        
        return self
            .accessibilityLabel(label)
            .accessibilityHint(hint)
            .accessibilityAddTraits(.isButton)
    }
    
    /// Applies accessibility for WristQuest form elements
    /// Handles text fields, pickers, and form validation
    /// - Parameters:
    ///   - field: The form field information
    ///   - validation: Current validation state
    /// - Returns: Form element with accessibility
    func wqFormAccessible(
        field: WQFormField,
        validation: ValidationResult = .valid
    ) -> some View {
        var traits: AccessibilityTraits = [.allowsDirectInteraction]
        var value = ""
        
        if field.isRequired {
            value = "Required field"
        }
        
        switch validation {
        case .valid:
            if !value.isEmpty { value += ", valid" }
            else { value = "Valid" }
        case .invalid(let errorInfo):
            if !value.isEmpty { value += ", invalid" }
            else { value = "Invalid" }
            if !errorInfo.message.isEmpty {
                value += ": \(errorInfo.message)"
            }
            traits.insert(.causesPageTurn)
        }
        
        return self
            .accessibilityLabel(field.label)
            .accessibilityValue(value)
            .accessibilityHint(field.hint)
            .accessibilityAddTraits(traits)
    }
    
    /// Applies accessibility for WristQuest reward displays
    /// Handles XP, gold, and item rewards with celebration
    /// - Parameters:
    ///   - reward: The reward information
    ///   - isNewlyEarned: Whether this reward was just earned
    /// - Returns: Reward display with accessibility
    func wqRewardAccessible(
        reward: WQRewardInfo,
        isNewlyEarned: Bool = false
    ) -> some View {
        var description = reward.description
        var traits: AccessibilityTraits = []
        
        if isNewlyEarned {
            description = "Newly earned: \(description)"
            traits.insert(.startsMediaSession)
        }
        
        return self
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(reward.type.displayName)
            .accessibilityValue(description)
            .accessibilityHint("Reward information")
            .accessibilityAddTraits(traits)
    }
}

// MARK: - Supporting Types

/// Accessibility roles for WristQuest UI elements
enum WQAccessibilityRole {
    case none
    case button
    case navigationButton
    case toggleButton
    case progressIndicator
    case statusIndicator
    case formField
    case card
    case header
    
    var traits: AccessibilityTraits {
        switch self {
        case .none: return []
        case .button: return .isButton
        case .navigationButton: return .isButton
        case .toggleButton: return [.isButton, .isToggle]
        case .progressIndicator: return .updatesFrequently
        case .statusIndicator: return .updatesFrequently
        case .formField: return .allowsDirectInteraction
        case .card: return []
        case .header: return .isHeader
        }
    }
    
    var defaultHint: String {
        switch self {
        case .none: return ""
        case .button: return "Double tap to activate"
        case .navigationButton: return "Double tap to navigate"
        case .toggleButton: return "Double tap to toggle"
        case .progressIndicator: return "Progress information"
        case .statusIndicator: return "Status information"
        case .formField: return "Editable text field"
        case .card: return "Information card"
        case .header: return "Section header"
        }
    }
}

/// Progress types for accessibility
enum WQProgressType {
    case questProgress
    case experienceProgress
    case healthGoal
    case activityRing
    
    var accessibilityLabel: String {
        switch self {
        case .questProgress: return "Quest progress"
        case .experienceProgress: return "Experience progress" 
        case .healthGoal: return "Health goal progress"
        case .activityRing: return "Activity ring progress"
        }
    }
}

/// Stat types for accessibility
enum WQStatType {
    case level
    case experience
    case gold
    case health
    case steps
    case heartRate
    case standHours
    case exerciseMinutes
    
    var displayName: String {
        switch self {
        case .level: return "Level"
        case .experience: return "Experience"
        case .gold: return "Gold"
        case .health: return "Health"
        case .steps: return "Steps"
        case .heartRate: return "Heart rate"
        case .standHours: return "Stand hours"
        case .exerciseMinutes: return "Exercise minutes"
        }
    }
    
    var defaultHint: String {
        switch self {
        case .level: return "Character level"
        case .experience: return "Experience points"
        case .gold: return "Gold currency"
        case .health: return "Character health"
        case .steps: return "Daily step count"
        case .heartRate: return "Current heart rate"
        case .standHours: return "Stand hours today"
        case .exerciseMinutes: return "Exercise minutes today"
        }
    }
}

/// Health metrics for accessibility
enum WQHealthMetric {
    case steps
    case heartRate
    case standHours
    case exerciseMinutes
    case combatMode
    
    var accessibilityLabel: String {
        switch self {
        case .steps: return "Steps today"
        case .heartRate: return "Heart rate"
        case .standHours: return "Stand hours"
        case .exerciseMinutes: return "Exercise minutes"
        case .combatMode: return "Combat mode"
        }
    }
    
    var accessibilityHint: String {
        switch self {
        case .steps: return "Daily step count from HealthKit"
        case .heartRate: return "Current heart rate from HealthKit"
        case .standHours: return "Stand hours completed today"
        case .exerciseMinutes: return "Exercise minutes completed today"
        case .combatMode: return "Combat mode status based on heart rate"
        }
    }
}

/// Quest actions for accessibility
enum WQQuestAction {
    case view
    case start
    case cancel
    case complete
    case retry
    
    var traits: AccessibilityTraits {
        switch self {
        case .view: return .isButton
        case .start: return [.isButton, .startsMediaSession]
        case .cancel: return .isButton
        case .complete: return .isButton
        case .retry: return .isButton
        }
    }
    
    var accessibilityHint: String {
        switch self {
        case .view: return "Double tap to view quest details"
        case .start: return "Double tap to start this quest"
        case .cancel: return "Double tap to cancel the current quest"
        case .complete: return "Double tap to complete the quest"
        case .retry: return "Double tap to retry the quest"
        }
    }
}

/// Navigation destinations for accessibility
enum WQNavigationDestination {
    case mainMenu
    case questList
    case activeQuest
    case character
    case inventory
    case journal
    case settings
    
    var displayName: String {
        switch self {
        case .mainMenu: return "Main menu"
        case .questList: return "Quest list"
        case .activeQuest: return "Active quest"
        case .character: return "Character"
        case .inventory: return "Inventory"
        case .journal: return "Journal"
        case .settings: return "Settings"
        }
    }
    
    var accessibilityLabel: String {
        return "Navigate to \(displayName)"
    }
}

/// Form field information for accessibility
struct WQFormField {
    let label: String
    let hint: String
    let isRequired: Bool
    
    init(label: String, hint: String = "", isRequired: Bool = false) {
        self.label = label
        self.hint = hint.isEmpty ? "Enter \(label.lowercased())" : hint
        self.isRequired = isRequired
    }
}

/// Quest information for accessibility
struct WQQuestAccessibilityInfo {
    let title: String
    let description: String?
    let isActive: Bool
    let isCompleted: Bool
    let progress: Double
    let rewardXP: Int
    let rewardGold: Int
    
    init(
        title: String,
        description: String? = nil,
        isActive: Bool = false,
        isCompleted: Bool = false,
        progress: Double = 0.0,
        rewardXP: Int = 0,
        rewardGold: Int = 0
    ) {
        self.title = title
        self.description = description
        self.isActive = isActive
        self.isCompleted = isCompleted
        self.progress = progress
        self.rewardXP = rewardXP
        self.rewardGold = rewardGold
    }
}

/// Reward information for accessibility
struct WQRewardInfo {
    let type: RewardType
    let amount: Int
    
    var description: String {
        return "\(amount) \(type.unit)"
    }
    
    enum RewardType {
        case experience
        case gold
        case item
        
        var displayName: String {
            switch self {
            case .experience: return "Experience"
            case .gold: return "Gold"
            case .item: return "Item"
            }
        }
        
        var unit: String {
            switch self {
            case .experience: return "experience points"
            case .gold: return "gold"
            case .item: return "items"
            }
        }
    }
}

// MARK: - Accessibility Preview Helpers

#if DEBUG
extension View {
    /// Adds accessibility debugging information in preview mode
    func accessibilityDebug(_ identifier: String) -> some View {
        self.accessibilityIdentifier(identifier)
            .onAppear {
                AccessibilityHelpers.debugAccessibility(for: identifier, context: "Preview")
            }
    }
}
#endif