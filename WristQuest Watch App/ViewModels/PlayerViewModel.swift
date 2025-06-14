import Foundation
import SwiftUI
import Combine

@MainActor
class PlayerViewModel: ObservableObject {
    @Published var player: Player
    @Published var canLevelUp = false
    @Published var levelUpRewards: [String] = []
    
    private var cancellables = Set<AnyCancellable>()
    private let persistenceService: PersistenceServiceProtocol
    
    init(player: Player, persistenceService: PersistenceServiceProtocol = PersistenceService()) {
        self.player = player
        self.persistenceService = persistenceService
        
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
        
        player.xp += finalAmount
        checkLevelUp()
        savePlayer()
    }
    
    func addGold(_ amount: Int) {
        let multiplier = getClassGoldMultiplier()
        let finalAmount = Int(Double(amount) * multiplier)
        
        player.gold += finalAmount
        savePlayer()
    }
    
    func addItem(_ item: Item) {
        player.inventory.append(item)
        savePlayer()
    }
    
    func removeItem(_ item: Item) {
        player.inventory.removeAll { $0.id == item.id }
        savePlayer()
    }
    
    func levelUp() {
        guard canLevelUp else { return }
        
        player.level += 1
        levelUpRewards = generateLevelUpRewards()
        canLevelUp = false
        
        checkLevelUp()
        savePlayer()
    }
    
    private func checkLevelUp() {
        let requiredXP = calculateXPRequirement(for: player.level + 1)
        canLevelUp = player.xp >= requiredXP
    }
    
    private func calculateXPRequirement(for level: Int) -> Int {
        if level <= 1 { return 0 }
        return Int(pow(Double(level - 1), 1.5) * 100)
    }
    
    private func getClassXPMultiplier() -> Double {
        switch player.activeClass {
        case .warrior:
            return 1.1
        case .ranger:
            return 1.05
        default:
            return 1.0
        }
    }
    
    private func getClassGoldMultiplier() -> Double {
        switch player.activeClass {
        case .ranger:
            return 1.2
        case .rogue:
            return 1.15
        default:
            return 1.0
        }
    }
    
    private func generateLevelUpRewards() -> [String] {
        var rewards = ["Level \(player.level) reached!"]
        
        if player.level % 5 == 0 {
            rewards.append("New ability slot unlocked!")
        }
        
        if player.level % 10 == 0 {
            rewards.append("Major stat boost applied!")
        }
        
        return rewards
    }
    
    private func savePlayer() {
        Task {
            do {
                try await persistenceService.savePlayer(player)
            } catch {
                print("Failed to save player: \(error)")
            }
        }
    }
}