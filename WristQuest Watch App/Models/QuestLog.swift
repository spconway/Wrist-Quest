import Foundation

struct QuestLog: Codable, Identifiable {
    let id: UUID
    let questId: UUID
    let questName: String
    let completionDate: Date
    let summary: String
    let rewards: QuestRewards
    
    init(questId: UUID, questName: String, summary: String, rewards: QuestRewards) {
        self.id = UUID()
        self.questId = questId
        self.questName = questName
        self.completionDate = Date()
        self.summary = summary
        self.rewards = rewards
    }
}

struct QuestRewards: Codable {
    let xp: Int
    let gold: Int
    
    init(xp: Int, gold: Int) {
        self.xp = xp
        self.gold = gold
    }
}