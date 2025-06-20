import Foundation

/// Global constants for the WristQuest application
/// Centralizes all magic numbers and configuration values for maintainability
struct WQConstants {
    
    // MARK: - Game Mechanics
    
    /// Core game mechanics constants
    static let stepsPerQuestUnit = 100
    static let maxInventorySize = 50
    static let maxQuestLogEntries = 100
    static let maxDailyXPBonus = 500
    
    // MARK: - Health & Activity Constants
    
    /// Health monitoring thresholds and calculations
    struct Health {
        /// Heart rate threshold (BPM) above which combat mode is triggered
        static let combatHeartRateThreshold: Double = 120.0
        
        /// Steps required to equal one distance unit for quest progress
        static let stepsPerDistanceUnit: Double = 100.0
        
        /// Maximum and minimum heart rate bounds
        static let maxSafeHeartRate: Double = 200.0
        static let minActiveHeartRate: Double = 60.0
        
        /// Activity score calculation multipliers
        static let stepScoreMultiplier = 100
        static let standHourScoreMultiplier = 10
        static let exerciseMinuteScoreMultiplier = 2
        static let mindfulMinuteScoreMultiplier = 3
    }
    
    // MARK: - Experience & Leveling System
    
    struct XP {
        /// Base XP values and multipliers
        static let baseQuestXP = 100
        static let baseXPMultiplier: Double = 100.0
        static let levelMultiplier: Double = 1.5
        static let xpCurveExponent: Double = 1.5
        
        /// Activity bonuses
        static let standHourBonus = 0.05
        static let exerciseMinuteXP = 2
        static let combatModeMultiplier = 1.5
        
        /// Class-specific XP bonuses
        static let warriorXPBonus: Double = 1.1
        static let rangerXPBonus: Double = 1.05
        static let defaultXPMultiplier: Double = 1.0
    }
    
    // MARK: - Economy & Rewards
    
    struct Economy {
        /// Gold multipliers by class
        static let rangerGoldBonus: Double = 1.2
        static let rogueGoldBonus: Double = 1.15
        static let defaultGoldMultiplier: Double = 1.0
        
        /// Item drop rates
        static let mageItemDropRate = 1.25
    }
    
    // MARK: - Quest System
    
    struct Quest {
        /// Distance modifiers by class
        static let rogueDistanceModifier: Double = 1.33
        static let rangerDistanceModifier: Double = 1.15
        static let warriorDistanceModifier: Double = 1.1
        static let defaultDistanceModifier: Double = 1.0
        static let rogueDistanceReduction = 0.75
        
        /// Quest generation parameters
        static let baseQuestDistance: Double = 25.0
        static let questDistancePerLevel: Double = 10.0
        static let baseQuestXP = 50
        static let questXPPerLevel = 25
        static let baseQuestGold = 10
        static let questGoldPerLevel = 5
        
        /// Random variation ranges for quest generation
        static let questDistanceVariationMin: Double = 0.8
        static let questDistanceVariationMax: Double = 1.5
        static let questXPVariationMin: Double = 0.9
        static let questXPVariationMax: Double = 1.4
        static let questGoldVariationMin: Double = 0.8
        static let questGoldVariationMax: Double = 1.6
    }
    
    // MARK: - Level Up & Progression
    
    struct LevelUp {
        /// Level intervals for special rewards
        static let abilitySlotInterval = 5
        static let majorStatBoostInterval = 10
    }
    
    // MARK: - Tutorial System
    
    struct Tutorial {
        /// Tutorial quest configuration
        static let totalTutorialSteps = 5
        static let tutorialXPReward = 50
        static let tutorialGoldReward = 10
        
        /// Tutorial stage progress values
        static let introductionProgress: Double = 0.2
        static let firstChallengeProgress: Double = 0.4
        static let encounterProgress: Double = 0.6
        static let finalTestProgress: Double = 0.8
        static let completionProgress: Double = 1.0
    }
    
    // MARK: - UI & Animation
    
    struct UI {
        /// Animation durations (in seconds)
        static let animationDuration = 0.3
        static let fastAnimationDuration: Double = 0.2
        static let mediumAnimationDuration: Double = 0.3
        static let slowAnimationDuration: Double = 0.5
        static let heroAscensionDuration: Double = 3.0
        static let questProgressAnimationDuration: Double = 0.5
        
        /// UI timing and delays
        static let hapticDelay = 0.1
        static let tutorialEffectsDuration: Double = 2.0
        static let questCompletionDelay: Double = 0.5
        static let gameStartTransitionDelay: Double = 1.0
        
        /// Dimensions and sizing
        static let progressBarHeight: CGFloat = 8
        static let buttonCornerRadius: CGFloat = 12
        static let cardCornerRadius: CGFloat = 8
        static let progressCircleSize: CGFloat = 120
        static let progressLineWidth: CGFloat = 8
        static let heroClassIconSize: CGFloat = 40
        static let completionIconSize: CGFloat = 80
        static let celebrationIconSize: CGFloat = 100
        static let activityMetricIconWidth: CGFloat = 20
        static let activityMetricIconHeight: CGFloat = 24
    }
    
    // MARK: - System & Performance
    
    struct System {
        /// Background and monitoring intervals
        static let backgroundRefreshInterval: TimeInterval = 30 * 60
        static let healthMonitoringInterval: TimeInterval = 60.0
        
        /// Core Data and persistence
        static let maxFetchLimit = 1000
        static let defaultFetchLimit = 100
        
        /// Timeouts and failsafes
        static let loadingTimeout: UInt64 = 3_000_000_000 // 3 seconds in nanoseconds
        
        /// Health query configuration
        static let maxHealthSamples = 100
        static let healthQueryNoLimit = 0 // HKObjectQueryNoLimit equivalent
    }
    
    // MARK: - Default Values
    
    struct Defaults {
        /// String defaults
        static let defaultHeroName = "Unknown Hero"
        static let defaultQuestTitle = "Unknown Quest"
        static let defaultErrorMessage = "An unexpected error occurred"
        static let loadingMessage = "Loading..."
        static let requestingPermissionMessage = "Requesting..."
        
        /// Tutorial reward items by class
        static let tutorialItems: [String: String] = [
            "warrior": "Apprentice's Sword",
            "mage": "Novice's Wand",
            "rogue": "Shadow Cloak",
            "ranger": "Hunter's Bow",
            "cleric": "Sacred Amulet"
        ]
    }
    
    // MARK: - Feature Flags
    
    struct FeatureFlags {
        /// Enable/disable features for testing and gradual rollout
        static let enableTutorialSystem = true
        static let enableAdvancedHealthMetrics = true
        static let enableBackgroundRefresh = true
        static let enableAnalytics = false
        static let enableDebugLogging = true // Should be false in production
    }
}

struct UserDefaultsKeys {
    static let hasCompletedOnboarding = "hasCompletedOnboarding"
    static let selectedHeroClass = "selectedHeroClass"
    static let playerName = "playerName"
    static let lastPlayedDate = "lastPlayedDate"
    static let dailyStreakCount = "dailyStreakCount"
    static let totalPlayTime = "totalPlayTime"
    static let achievementUnlocks = "achievementUnlocks"
}

struct NotificationIdentifiers {
    static let questComplete = "quest.complete"
    static let levelUp = "player.levelup"
    static let dailyReminder = "daily.reminder"
    static let encounterAvailable = "encounter.available"
    static let itemFound = "item.found"
}

struct DeepLinkURLs {
    static let scheme = "wristquest"
    static let questHost = "quest"
    static let characterHost = "character"
    static let journalHost = "journal"
    static let inventoryHost = "inventory"
}

/// Convenience typealias for shorter access to constants
typealias WQC = WQConstants

/// Legacy support - gradually migrate from GameConstants to WQConstants
@available(*, deprecated, message: "Use WQConstants instead")
typealias GameConstants = WQConstants