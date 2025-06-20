import Foundation
import SwiftUI
import Combine

// Note: WQConstants are accessed globally via WQC typealias

@MainActor
class PlayerViewModel: ObservableObject {
    @Published var player: Player
    @Published var canLevelUp = false
    @Published var levelUpRewards: [String] = []
    
    private var cancellables = Set<AnyCancellable>()
    private let persistenceService: PersistenceServiceProtocol
    private let logger: LoggingServiceProtocol?
    private let analytics: AnalyticsServiceProtocol?
    
    init(player: Player, 
         persistenceService: PersistenceServiceProtocol = PersistenceService(),
         logger: LoggingServiceProtocol? = nil,
         analytics: AnalyticsServiceProtocol? = nil) {
        self.player = player
        self.persistenceService = persistenceService
        self.logger = logger
        self.analytics = analytics
        
        logger?.info("PlayerViewModel initializing for player: \(player.name)", category: .player)
        checkLevelUp()
    }
    
    var xpForNextLevel: Int {
        calculateXPRequirement(for: player.level + 1)
    }
    
    var xpProgress: Double {
        let currentLevelXP = calculateXPRequirement(for: player.level)
        let nextLevelXP = calculateXPRequirement(for: player.level + 1)
        let progressXP = player.xp - currentLevelXP
        let requiredXP = nextLevelXP - currentLevelXP
        
        return Double(progressXP) / Double(requiredXP)
    }
    
    func addXP(_ amount: Int) {
        let multiplier = getClassXPMultiplier()
        let finalAmount = Int(Double(amount) * multiplier)
        
        logger?.info("Adding \(finalAmount) XP to player \(player.name) (base: \(amount), multiplier: \(multiplier))", category: .player)
        
        // Use the player's safe addXP method with validation
        let result = player.addXP(finalAmount)
        
        if !result.isValid {
            logger?.warning("XP addition validation failed: \(result.message ?? "Unknown error")", category: .player)
            analytics?.trackEvent(AnalyticsEvent(name: "validation_error", parameters: [
                "error_type": "xp_addition",
                "attempted_amount": finalAmount,
                "player_id": player.id.uuidString
            ]))
            return
        }
        
        checkLevelUp()
        savePlayer()
        
        analytics?.trackGameAction(.levelUp, parameters: [
            "xp_gained": finalAmount,
            "total_xp": player.xp,
            "player_level": player.level,
            "hero_class": player.activeClass.rawValue
        ])
    }
    
    func addGold(_ amount: Int) {
        let multiplier = getClassGoldMultiplier()
        let finalAmount = Int(Double(amount) * multiplier)
        
        logger?.debug("Adding \(finalAmount) gold to player \(player.name) (base: \(amount), multiplier: \(multiplier))", category: .player)
        
        // Use the player's safe addGold method with validation
        let result = player.addGold(finalAmount)
        
        if !result.isValid {
            logger?.warning("Gold addition validation failed: \(result.message ?? "Unknown error")", category: .player)
            analytics?.trackEvent(AnalyticsEvent(name: "validation_error", parameters: [
                "error_type": "gold_addition",
                "attempted_amount": finalAmount,
                "player_id": player.id.uuidString
            ]))
            return
        }
        
        savePlayer()
    }
    
    func addItem(_ item: Item) {
        logger?.info("Adding item to inventory: \(item.name) (\(item.rarity.rawValue))", category: .player)
        analytics?.trackGameAction(.itemObtained, parameters: [
            "item_name": item.name,
            "item_type": item.type.rawValue,
            "item_rarity": item.rarity.rawValue,
            "item_level": item.level,
            "player_level": player.level
        ])
        
        // Use the player's safe addItem method with validation
        let result = player.addItem(item)
        
        if !result.isValid {
            logger?.warning("Item addition validation failed: \(result.message ?? "Unknown error")", category: .player)
            analytics?.trackEvent(AnalyticsEvent(name: "validation_error", parameters: [
                "error_type": "item_addition",
                "item_name": item.name,
                "inventory_size": player.inventory.count,
                "player_id": player.id.uuidString
            ]))
            return
        }
        
        savePlayer()
    }
    
    func removeItem(_ item: Item) {
        player.inventory.removeAll { $0.id == item.id }
        savePlayer()
    }
    
    func levelUp() {
        guard canLevelUp else { return }
        
        let previousLevel = player.level
        player.level += 1
        levelUpRewards = generateLevelUpRewards()
        canLevelUp = false
        
        logger?.info("Player \(player.name) leveled up: \(previousLevel) -> \(player.level)", category: .player)
        analytics?.trackGameAction(.levelUp, parameters: [
            "previous_level": previousLevel,
            "new_level": player.level,
            "hero_class": player.activeClass.rawValue,
            "total_xp": player.xp
        ])
        
        // Announce level up for accessibility
        AccessibilityHelpers.announceLevelUp(newLevel: player.level, className: player.activeClass.displayName)
        
        checkLevelUp()
        savePlayer()
    }
    
    private func checkLevelUp() {
        let requiredXP = calculateXPRequirement(for: player.level + 1)
        canLevelUp = player.xp >= requiredXP
    }
    
    private func calculateXPRequirement(for level: Int) -> Int {
        if level <= 1 { return 0 }
        return Int(pow(Double(level - 1), WQC.XP.xpCurveExponent) * WQC.XP.baseXPMultiplier)
    }
    
    private func getClassXPMultiplier() -> Double {
        switch player.activeClass {
        case .warrior:
            return WQC.XP.warriorXPBonus
        case .ranger:
            return WQC.XP.rangerXPBonus
        default:
            return WQC.XP.defaultXPMultiplier
        }
    }
    
    private func getClassGoldMultiplier() -> Double {
        switch player.activeClass {
        case .ranger:
            return WQC.Economy.rangerGoldBonus
        case .rogue:
            return WQC.Economy.rogueGoldBonus
        default:
            return WQC.Economy.defaultGoldMultiplier
        }
    }
    
    private func generateLevelUpRewards() -> [String] {
        var rewards = ["Level \(player.level) reached!"]
        
        if player.level % WQC.LevelUp.abilitySlotInterval == 0 {
            rewards.append("New ability slot unlocked!")
        }
        
        if player.level % WQC.LevelUp.majorStatBoostInterval == 0 {
            rewards.append("Major stat boost applied!")
        }
        
        return rewards
    }
    
    private func savePlayer() {
        Task {
            do {
                try await persistenceService.savePlayer(player)
                logger?.debug("Player data saved successfully", category: .player)
            } catch {
                logger?.error("Failed to save player: \(error.localizedDescription)", category: .player)
                analytics?.trackError(error, context: "PlayerViewModel.savePlayer")
            }
        }
    }
}