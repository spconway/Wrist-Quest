import Foundation

/// Centralized accessibility constants for WristQuest
/// Provides consistent labels, hints, and VoiceOver descriptions across the app
struct AccessibilityConstants {
    
    // MARK: - Navigation
    struct Navigation {
        static let mainMenu = "Main menu"
        static let questList = "Quest list"
        static let activeQuest = "Active quest"
        static let characterDetail = "Character details"
        static let settings = "Settings"
        static let inventory = "Inventory"
        static let journal = "Quest journal"
        
        static let navigationHint = "Double tap to navigate"
        static let backButton = "Back"
        static let closeButton = "Close"
        static let cancelButton = "Cancel"
        static let continueButton = "Continue"
    }
    
    // MARK: - Onboarding
    struct Onboarding {
        static let welcomeTitle = "Welcome to Wrist Quest"
        static let welcomeDescription = "Fantasy RPG adventure for your Apple Watch"
        
        static let healthPermissionTitle = "Health permission required"
        static let healthPermissionDescription = "Grant access to power your quests with real activity data"
        static let healthPermissionButton = "Grant health access"
        static let healthPermissionGranted = "Health access granted"
        static let healthPermissionHint = "Double tap to request health permissions"
        
        static let characterCreationTitle = "Character creation"
        static let characterCreationDescription = "Choose your hero class and enter your name"
        static let nameFieldLabel = "Hero name"
        static let nameFieldHint = "Enter your character's name"
        static let classSelectionLabel = "Character class selection"
        static let classSelectionHint = "Choose your hero's class and abilities"
        
        static let tutorialQuestTitle = "Tutorial quest"
        static let tutorialQuestDescription = "Learn the basics with your first adventure"
        static let startTutorialButton = "Start tutorial quest"
        
        static let completionTitle = "Onboarding complete"
        static let completionDescription = "Your hero is ready to begin their journey"
        static let beginAdventureButton = "Begin adventure"
    }
    
    // MARK: - Character Classes
    struct CharacterClasses {
        static let warrior = "Warrior"
        static let warriorDescription = "Strong melee fighter with bonus experience from steps and battle abilities"
        
        static let mage = "Mage"
        static let mageDescription = "Magical spellcaster with auto-complete abilities and higher item drop rates"
        
        static let rogue = "Rogue"
        static let rogueDescription = "Stealthy adventurer with reduced quest distances and critical loot upgrades"
        
        static let ranger = "Ranger"
        static let rangerDescription = "Nature explorer with outdoor bonuses and enhanced gold finding"
        
        static let cleric = "Cleric"
        static let clericDescription = "Divine healer with mindful healing and failure prevention abilities"
        
        static func classDescription(for heroClass: String) -> String {
            switch heroClass.lowercased() {
            case "warrior": return warriorDescription
            case "mage": return mageDescription
            case "rogue": return rogueDescription
            case "ranger": return rangerDescription
            case "cleric": return clericDescription
            default: return "Unknown character class"
            }
        }
        
        static let selectionHint = "Double tap to select this character class"
        static let selectedIndicator = "Selected"
        static let notSelectedIndicator = "Not selected"
    }
    
    // MARK: - Player Progress
    struct Player {
        static let levelLabel = "Level"
        static let experienceLabel = "Experience points"
        static let goldLabel = "Gold"
        static let healthLabel = "Health"
        
        static func levelDescription(_ level: Int, _ className: String) -> String {
            return "Level \(level) \(className)"
        }
        
        static func experienceDescription(_ currentXP: Int, _ totalXP: Int) -> String {
            return "\(currentXP) of \(totalXP) experience points"
        }
        
        static func experienceProgress(_ percentage: Double) -> String {
            return "\(Int(percentage * 100)) percent progress to next level"
        }
        
        static let experienceProgressHint = "Experience needed to reach the next level"
    }
    
    // MARK: - Quests
    struct Quests {
        static let questTitle = "Quest"
        static let activeQuestTitle = "Active quest"
        static let availableQuestsTitle = "Available quests"
        static let completedQuestsTitle = "Completed quests"
        
        static let questProgress = "Quest progress"
        static let questComplete = "Quest complete"
        static let questInProgress = "Quest in progress"
        static let questNotStarted = "Quest not started"
        
        static func questProgressDescription(_ percentage: Double) -> String {
            return "\(Int(percentage * 100)) percent complete"
        }
        
        static func questDistanceProgress(_ current: Double, _ total: Double) -> String {
            return "\(current.formatted(decimalPlaces: 1)) of \(total.formatted(decimalPlaces: 1)) miles completed"
        }
        
        static func questRewards(_ xp: Int, _ gold: Int) -> String {
            return "Rewards: \(xp) experience points and \(gold) gold"
        }
        
        static let startQuestButton = "Start quest"
        static let startQuestHint = "Double tap to begin this quest"
        static let cancelQuestButton = "Cancel quest"
        static let cancelQuestHint = "Double tap to cancel the current quest"
        static let viewQuestDetailsButton = "View quest details"
        static let viewQuestDetailsHint = "Double tap to see more information about this quest"
        
        static let noActiveQuestTitle = "No active quest"
        static let noActiveQuestDescription = "Start a quest to begin your adventure"
        static let browseQuestsButton = "Browse available quests"
        static let browseQuestsHint = "Double tap to see available quests"
    }
    
    // MARK: - Health & Activity
    struct Health {
        static let activitySummary = "Today's activity summary"
        static let activityTracking = "Activity tracking"
        static let dailyActivityScore = "Daily activity score"
        
        static let stepsLabel = "Steps"
        static let heartRateLabel = "Heart rate"
        static let standHoursLabel = "Stand hours"
        static let exerciseMinutesLabel = "Exercise minutes"
        static let mindfulMinutesLabel = "Mindful minutes"
        
        static func stepsValue(_ steps: Int) -> String {
            return "\(steps) steps today"
        }
        
        static func heartRateValue(_ bpm: Int) -> String {
            return "\(bpm) beats per minute"
        }
        
        static func standHoursValue(_ hours: Int) -> String {
            return "\(hours) stand hours today"
        }
        
        static func exerciseMinutesValue(_ minutes: Int) -> String {
            return "\(minutes) exercise minutes today"
        }
        
        static let combatModeActive = "Combat mode active"
        static let combatModeDescription = "Your elevated heart rate may trigger combat encounters"
        static let combatModeIndicator = "Combat mode indicator"
        
        static let activityMetricHint = "Activity data from HealthKit"
    }
    
    // MARK: - Game Actions
    struct Actions {
        static let getStarted = "Get started"
        static let getStartedHint = "Double tap to begin the onboarding process"
        
        static let nextStep = "Next step"
        static let nextStepHint = "Double tap to continue to the next step"
        
        static let completedAction = "Completed"
        static let pendingAction = "Pending"
        static let inProgressAction = "In progress"
        
        static let retryAction = "Retry"
        static let retryActionHint = "Double tap to try again"
        
        static let confirmAction = "Confirm"
        static let confirmActionHint = "Double tap to confirm this action"
    }
    
    // MARK: - Progress Indicators
    struct Progress {
        static let progressBar = "Progress bar"
        static let progressCircle = "Progress circle"
        static let loadingIndicator = "Loading"
        
        static func progressValue(_ percentage: Double) -> String {
            return "\(Int(percentage * 100)) percent"
        }
        
        static func progressDescription(_ current: Double, _ total: Double, _ unit: String) -> String {
            return "\(current.formatted(decimalPlaces: 1)) of \(total.formatted(decimalPlaces: 1)) \(unit)"
        }
        
        static let progressHint = "Progress towards completion"
    }
    
    // MARK: - Rewards & Achievements
    struct Rewards {
        static let rewardsEarned = "Rewards earned"
        static let experienceReward = "Experience reward"
        static let goldReward = "Gold reward"
        static let itemReward = "Item reward"
        
        static func experienceRewardValue(_ xp: Int) -> String {
            return "\(xp) experience points earned"
        }
        
        static func goldRewardValue(_ gold: Int) -> String {
            return "\(gold) gold earned"
        }
        
        static let levelUpAnnouncement = "Level up! You've reached a new level"
        static let questCompleteAnnouncement = "Quest completed! Rewards have been earned"
        static let combatModeAnnouncement = "Combat mode activated due to elevated heart rate"
    }
    
    // MARK: - UI Elements
    struct UI {
        static let button = "Button"
        static let textField = "Text field"
        static let card = "Card"
        static let list = "List"
        static let grid = "Grid"
        static let tab = "Tab"
        static let sheet = "Sheet"
        static let alert = "Alert"
        static let confirmation = "Confirmation dialog"
        
        static let expandedState = "Expanded"
        static let collapsedState = "Collapsed"
        static let selectedState = "Selected"
        static let unselectedState = "Not selected"
        static let enabledState = "Enabled"
        static let disabledState = "Disabled"
        
        static let required = "Required"
        static let optional = "Optional"
        static let invalid = "Invalid"
        static let valid = "Valid"
    }
    
    // MARK: - Tutorials & Tips
    struct Tips {
        static let questTips = "Quest tips"
        static let tip1 = "Keep walking to progress your quest"
        static let tip2 = "Elevated heart rate may trigger encounters"
        static let tip3 = "Check back periodically for updates"
        
        static let featureExplanation = "Feature explanation"
        static let walkingMechanic = "Steps become travel distance in quests"
        static let heartRateMechanic = "High heart rate triggers combat encounters"
        static let rewardMechanic = "Real activity earns experience points and gold"
    }
    
    // MARK: - Error States
    struct Errors {
        static let errorOccurred = "Error occurred"
        static let retryAvailable = "Retry available"
        static let helpAvailable = "Help available"
        
        static let validationError = "Validation error"
        static let networkError = "Network error"
        static let permissionError = "Permission error"
        
        static let errorDismissHint = "Double tap to dismiss error"
        static let errorRetryHint = "Double tap to retry failed action"
    }
    
    // MARK: - Announcements
    struct Announcements {
        static let welcomeMessage = "Welcome to Wrist Quest, your fantasy adventure begins now"
        static let onboardingComplete = "Onboarding complete, your hero is ready for adventure"
        static let healthPermissionGranted = "Health permission granted, activity tracking is now enabled"
        static let characterCreated = "Character created successfully"
        static let questStarted = "Quest started, begin your adventure"
        static let questCompleted = "Congratulations, quest completed with rewards earned"
        static let levelUp = "Level up achieved, new abilities unlocked"
        static let combatModeActivated = "Combat mode activated, encounters may occur"
        static let activityGoalReached = "Activity goal reached, bonus rewards earned"
    }
}

