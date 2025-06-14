import Foundation

struct Quest: Codable, Identifiable, Hashable {
    let id: UUID
    var title: String
    var description: String
    var totalDistance: Double
    var currentProgress: Double
    var isCompleted: Bool
    var rewardXP: Int
    var rewardGold: Int
    var encounters: [Encounter]
    
    init(title: String, description: String, totalDistance: Double, rewardXP: Int, rewardGold: Int, encounters: [Encounter] = []) {
        self.id = UUID()
        self.title = title
        self.description = description
        self.totalDistance = totalDistance
        self.currentProgress = 0.0
        self.isCompleted = false
        self.rewardXP = rewardXP
        self.rewardGold = rewardGold
        self.encounters = encounters
    }
    
    var progressPercentage: Double {
        guard totalDistance > 0 else { return 0 }
        return min(currentProgress / totalDistance, 1.0)
    }
    
    var remainingDistance: Double {
        max(totalDistance - currentProgress, 0)
    }
}