import Foundation

enum EncounterType: String, CaseIterable, Codable {
    case decision, combat, discovery, trap
    
    var displayName: String {
        switch self {
        case .decision: return "Decision"
        case .combat: return "Combat"
        case .discovery: return "Discovery"
        case .trap: return "Trap"
        }
    }
}

struct Encounter: Codable, Identifiable, Hashable {
    let id: UUID
    var type: EncounterType
    var description: String
    var options: [EncounterOption]
    var result: EncounterResult?
    
    init(type: EncounterType, description: String, options: [EncounterOption]) {
        self.id = UUID()
        self.type = type
        self.description = description
        self.options = options
        self.result = nil
    }
}

struct EncounterOption: Codable, Identifiable, Hashable {
    let id: UUID
    var text: String
    var successChance: Double
    var result: EncounterResult
    
    init(text: String, successChance: Double, result: EncounterResult) {
        self.id = UUID()
        self.text = text
        self.successChance = successChance
        self.result = result
    }
}

struct EncounterResult: Codable, Hashable {
    var xpGain: Int
    var goldGain: Int
    var itemReward: Item?
    var healthChange: Int
    var message: String
    
    init(xpGain: Int = 0, goldGain: Int = 0, itemReward: Item? = nil, healthChange: Int = 0, message: String) {
        self.xpGain = xpGain
        self.goldGain = goldGain
        self.itemReward = itemReward
        self.healthChange = healthChange
        self.message = message
    }
}