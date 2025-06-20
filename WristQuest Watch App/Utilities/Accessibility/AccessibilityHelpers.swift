import SwiftUI
import Combine

/// Accessibility helpers and utilities for WristQuest
/// Provides custom modifiers, VoiceOver announcements, and accessibility testing utilities
struct AccessibilityHelpers {
    
    // MARK: - VoiceOver Announcements
    
    /// Announces important messages to VoiceOver users
    /// - Parameter message: The message to announce
    static func announce(_ message: String) {
        DispatchQueue.main.async {
            AccessibilityNotification.Announcement(message).post()
        }
    }
    
    /// Announces quest progress updates
    /// - Parameters:
    ///   - questTitle: The title of the quest
    ///   - progress: Progress percentage (0.0 to 1.0)
    static func announceQuestProgress(_ questTitle: String, progress: Double) {
        let percentage = Int(progress * 100)
        let message = "\(questTitle) is \(percentage) percent complete"
        announce(message)
    }
    
    /// Announces level up achievements
    /// - Parameters:
    ///   - newLevel: The new level achieved
    ///   - className: The character class name
    static func announceLevelUp(newLevel: Int, className: String) {
        let message = "Congratulations! You've reached level \(newLevel) as a \(className). New abilities may be available."
        announce(message)
    }
    
    /// Announces quest completion
    /// - Parameters:
    ///   - questTitle: The completed quest title
    ///   - xpReward: Experience points earned
    ///   - goldReward: Gold earned
    static func announceQuestCompletion(questTitle: String, xpReward: Int, goldReward: Int) {
        let message = "Quest completed: \(questTitle). You've earned \(xpReward) experience points and \(goldReward) gold."
        announce(message)
    }
    
    /// Announces combat mode activation
    static func announceCombatMode() {
        let message = "Combat mode activated! Your elevated heart rate may trigger encounters."
        announce(message)
    }
    
    /// Announces activity milestones
    /// - Parameters:
    ///   - activityType: The type of activity (steps, heart rate, etc.)
    ///   - value: The milestone value
    static func announceActivityMilestone(activityType: String, value: String) {
        let message = "Great job! You've reached \(value) \(activityType) today."
        announce(message)
    }
    
    // MARK: - Dynamic Type Support
    
    /// Scales a value based on the current dynamic type size
    /// - Parameters:
    ///   - baseValue: The base value to scale
    ///   - category: The dynamic type category
    /// - Returns: Scaled value
    static func scaledValue(_ baseValue: CGFloat, for category: DynamicTypeSize) -> CGFloat {
        let scaleFactor = dynamicTypeScaleFactor(for: category)
        return baseValue * scaleFactor
    }
    
    /// Returns the scale factor for a given dynamic type size
    /// - Parameter category: The dynamic type category
    /// - Returns: Scale factor (1.0 is normal size)
    static func dynamicTypeScaleFactor(for category: DynamicTypeSize) -> CGFloat {
        switch category {
        case .xSmall: return 0.8
        case .small: return 0.9
        case .medium: return 1.0
        case .large: return 1.1
        case .xLarge: return 1.2
        case .xxLarge: return 1.3
        case .xxxLarge: return 1.4
        case .accessibility1: return 1.6
        case .accessibility2: return 1.8
        case .accessibility3: return 2.0
        case .accessibility4: return 2.2
        case .accessibility5: return 2.4
        default: return 1.0
        }
    }
    
    /// Checks if the current dynamic type size is an accessibility size
    /// - Parameter category: The dynamic type category
    /// - Returns: True if it's an accessibility size
    static func isAccessibilitySize(_ category: DynamicTypeSize) -> Bool {
        switch category {
        case .accessibility1, .accessibility2, .accessibility3, .accessibility4, .accessibility5:
            return true
        default:
            return false
        }
    }
    
    // MARK: - Accessibility Testing
    
    /// Validates accessibility labels for debugging
    /// - Parameters:
    ///   - label: The accessibility label to validate
    ///   - context: Context for the validation
    /// - Returns: True if valid, false otherwise
    static func validateAccessibilityLabel(_ label: String?, context: String) -> Bool {
        guard let label = label, !label.isEmpty else {
            print("⚠️ Accessibility Warning: Missing label for \(context)")
            return false
        }
        
        if label.count < 3 {
            print("⚠️ Accessibility Warning: Label too short for \(context): '\(label)'")
            return false
        }
        
        return true
    }
    
    /// Validates accessibility traits for debugging
    /// - Parameters:
    ///   - traits: The accessibility traits to validate
    ///   - context: Context for the validation
    /// - Returns: True if valid, false otherwise
    static func validateAccessibilityTraits(_ traits: AccessibilityTraits, context: String) -> Bool {
        // Check for common issues
        if traits.contains(.isButton) && traits.contains(.isStaticText) {
            print("⚠️ Accessibility Warning: Conflicting traits (button + staticText) for \(context)")
            return false
        }
        
        return true
    }
    
    // MARK: - Accessibility State Management
    
    /// Checks if VoiceOver is currently running
    /// - Returns: True if VoiceOver is active
    static var isVoiceOverRunning: Bool {
        return false // UIAccessibility.isVoiceOverRunning not available on watchOS
    }
    
    /// Checks if Switch Control is currently running
    /// - Returns: True if Switch Control is active
    static var isSwitchControlRunning: Bool {
        return false // UIAccessibility.isSwitchControlRunning not available on watchOS
    }
    
    /// Checks if any assistive technology is running
    /// - Returns: True if any assistive tech is active
    static var isAssistiveTechnologyRunning: Bool {
        return isVoiceOverRunning || isSwitchControlRunning
    }
    
    /// Checks if reduced motion is enabled
    /// - Returns: True if reduce motion is enabled
    static var isReduceMotionEnabled: Bool {
        return false // UIAccessibility.isReduceMotionEnabled not available on watchOS
    }
    
    /// Checks if increased contrast is enabled
    /// - Returns: True if increased contrast is enabled
    static var isIncreasedContrastEnabled: Bool {
        return false // UIAccessibility.isDarkerSystemColorsEnabled not available on watchOS
    }
}

// MARK: - Custom Accessibility Modifiers

extension View {
    
    /// Applies consistent accessibility formatting for quest progress
    /// - Parameters:
    ///   - questTitle: The title of the quest
    ///   - progress: Progress percentage (0.0 to 1.0)
    ///   - hint: Optional accessibility hint
    /// - Returns: Modified view with accessibility
    func accessibleQuestProgress(questTitle: String, progress: Double, hint: String? = nil) -> some View {
        self
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Quest progress: \(questTitle)")
            .accessibilityValue(AccessibilityConstants.Quests.questProgressDescription(progress))
            .accessibilityHint(hint ?? AccessibilityConstants.Progress.progressHint)
            .accessibilityAddTraits(.updatesFrequently)
    }
    
    /// Applies consistent accessibility formatting for activity metrics
    /// - Parameters:
    ///   - activityType: The type of activity
    ///   - value: The current value
    ///   - unit: The unit of measurement
    /// - Returns: Modified view with accessibility
    func accessibleActivityMetric(activityType: String, value: String, unit: String = "") -> some View {
        self
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(activityType)")
            .accessibilityValue("\(value) \(unit)".trimmingCharacters(in: .whitespaces))
            .accessibilityHint(AccessibilityConstants.Health.activityMetricHint)
    }
    
    /// Applies consistent accessibility formatting for character class selection
    /// - Parameters:
    ///   - className: The name of the character class
    ///   - isSelected: Whether this class is currently selected
    ///   - description: Description of the class abilities
    /// - Returns: Modified view with accessibility
    func accessibleCharacterClass(className: String, isSelected: Bool, description: String) -> some View {
        self
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Character class: \(className)")
            .accessibilityValue(description)
            .accessibilityHint(AccessibilityConstants.CharacterClasses.selectionHint)
            .accessibilityAddTraits(.isButton)
            .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
    
    /// Applies consistent accessibility formatting for action buttons
    /// - Parameters:
    ///   - actionName: The name of the action
    ///   - description: Description of what the action does
    ///   - isEnabled: Whether the button is enabled
    /// - Returns: Modified view with accessibility
    func accessibleActionButton(actionName: String, description: String? = nil, isEnabled: Bool = true) -> some View {
        self
            .accessibilityLabel(actionName)
            .accessibilityHint(description ?? "Double tap to \(actionName.lowercased())")
            .accessibilityAddTraits(.isButton)
            .accessibilityRemoveTraits(isEnabled ? [] : .allowsDirectInteraction)
    }
    
    /// Applies consistent accessibility formatting for navigation elements
    /// - Parameters:
    ///   - destination: The destination name
    ///   - description: Optional description of the destination
    /// - Returns: Modified view with accessibility
    func accessibleNavigation(to destination: String, description: String? = nil) -> some View {
        self
            .accessibilityLabel("Navigate to \(destination)")
            .accessibilityHint(description ?? AccessibilityConstants.Navigation.navigationHint)
            .accessibilityAddTraits(.isButton)
    }
    
    /// Applies consistent accessibility formatting for cards and containers
    /// - Parameters:
    ///   - title: The title of the card content
    ///   - description: Description of the card content
    ///   - isInteractive: Whether the card is interactive
    /// - Returns: Modified view with accessibility
    func accessibleCard(title: String, description: String? = nil, isInteractive: Bool = false) -> some View {
        self
            .accessibilityElement(children: .combine)
            .accessibilityLabel(title)
            .accessibilityValue(description ?? "")
            .accessibilityAddTraits(isInteractive ? .isButton : [])
    }
    
    /// Applies accessibility for form fields with validation
    /// - Parameters:
    ///   - fieldName: The name of the form field
    ///   - isRequired: Whether the field is required
    ///   - validationState: The current validation state
    ///   - hint: Optional accessibility hint
    /// - Returns: Modified view with accessibility
    func accessibleFormField(
        fieldName: String,
        isRequired: Bool = false,
        validationState: ValidationResult? = nil,
        hint: String? = nil
    ) -> some View {
        var traits: AccessibilityTraits = []
        var value = ""
        
        if isRequired {
            value += AccessibilityConstants.UI.required
        }
        
        if let validation = validationState {
            switch validation {
            case .valid:
                value += value.isEmpty ? AccessibilityConstants.UI.valid : ", \(AccessibilityConstants.UI.valid)"
            case .invalid(let errorInfo):
                value += value.isEmpty ? AccessibilityConstants.UI.invalid : ", \(AccessibilityConstants.UI.invalid)"
                if !errorInfo.message.isEmpty {
                    value += ": \(errorInfo.message)"
                }
                traits.insert(.causesPageTurn) // Indicates error state
            }
        }
        
        return self
            .accessibilityLabel(fieldName)
            .accessibilityValue(value)
            .accessibilityHint(hint ?? "")
            .accessibilityAddTraits(traits)
    }
    
    /// Applies reduced motion animations when accessibility settings require it
    /// - Parameter animation: The animation to potentially reduce
    /// - Returns: Modified view with appropriate animation
    func accessibleAnimation<V>(_ animation: Animation?, value: V) -> some View where V: Equatable {
        if AccessibilityHelpers.isReduceMotionEnabled {
            return self.animation(nil, value: value)
        } else {
            return self.animation(animation, value: value)
        }
    }
    
    /// Applies high contrast colors when accessibility settings require it
    /// - Parameters:
    ///   - normalColor: The normal color
    ///   - highContrastColor: The high contrast alternative
    /// - Returns: Modified view with appropriate colors
    func accessibleForegroundColor(normal: Color, highContrast: Color) -> some View {
        let color = AccessibilityHelpers.isIncreasedContrastEnabled ? highContrast : normal
        return self.foregroundColor(color)
    }
}

// MARK: - Accessibility Debugging

#if DEBUG
extension AccessibilityHelpers {
    
    /// Prints accessibility information for debugging
    /// - Parameters:
    ///   - view: The view to debug
    ///   - context: Context for the debug information
    static func debugAccessibility(for view: String, context: String) {
        print("🔍 Accessibility Debug - \(context):")
        print("  View: \(view)")
        print("  VoiceOver: \(isVoiceOverRunning ? "ON" : "OFF")")
        print("  Switch Control: \(isSwitchControlRunning ? "ON" : "OFF")")
        print("  Reduce Motion: \(isReduceMotionEnabled ? "ON" : "OFF")")
        print("  High Contrast: \(isIncreasedContrastEnabled ? "ON" : "OFF")")
    }
    
    /// Logs accessibility announcements for debugging
    /// - Parameter message: The announcement message
    static func logAnnouncement(_ message: String) {
        print("📢 Accessibility Announcement: \(message)")
    }
}
#endif