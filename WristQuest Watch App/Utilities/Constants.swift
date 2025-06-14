import Foundation

struct GameConstants {
    static let stepsPerQuestUnit = 100
    static let maxInventorySize = 50
    static let maxQuestLogEntries = 100
    static let combatHeartRateThreshold = 120.0
    static let backgroundRefreshInterval: TimeInterval = 30 * 60
    static let maxDailyXPBonus = 500
    
    struct XP {
        static let baseQuestXP = 100
        static let levelMultiplier = 1.5
        static let standHourBonus = 0.05
        static let exerciseMinuteXP = 2
        static let combatModeMultiplier = 1.5
    }
    
    struct ClassMultipliers {
        static let warriorStepXP = 1.1
        static let rangerOutdoorXP = 1.15
        static let rangerGoldBonus = 1.2
        static let rogueDistanceReduction = 0.75
        static let rogueGoldBonus = 1.15
        static let mageItemDropRate = 1.25
    }
    
    struct UI {
        static let animationDuration = 0.3
        static let hapticDelay = 0.1
        static let progressBarHeight: CGFloat = 8
        static let buttonCornerRadius: CGFloat = 12
        static let cardCornerRadius: CGFloat = 8
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