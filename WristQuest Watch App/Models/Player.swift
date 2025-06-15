import Foundation

struct Player: Codable, Identifiable {
    let id: UUID
    var name: String
    var level: Int
    var xp: Int
    var gold: Int
    var stepsToday: Int
    var activeClass: HeroClass
    var inventory: [Item]
    var journal: [QuestLog]
    
    init(name: String, activeClass: HeroClass) {
        self.id = UUID()
        self.name = name
        self.level = 1
        self.xp = 0
        self.gold = 0
        self.stepsToday = 0
        self.activeClass = activeClass
        self.inventory = []
        self.journal = []
    }
    
    static var preview: Player {
        Player(name: "Hero", activeClass: .warrior)
    }
}