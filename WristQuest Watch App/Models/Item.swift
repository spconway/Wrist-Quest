import Foundation

enum ItemType: String, CaseIterable, Codable {
    case weapon, armor, trinket, potion, misc
    
    var displayName: String {
        switch self {
        case .weapon: return "Weapon"
        case .armor: return "Armor"
        case .trinket: return "Trinket"
        case .potion: return "Potion"
        case .misc: return "Miscellaneous"
        }
    }
}

enum Rarity: String, CaseIterable, Codable {
    case common, uncommon, rare, epic, legendary
    
    var displayName: String {
        switch self {
        case .common: return "Common"
        case .uncommon: return "Uncommon"
        case .rare: return "Rare"
        case .epic: return "Epic"
        case .legendary: return "Legendary"
        }
    }
    
    var colorHex: String {
        switch self {
        case .common: return "#FFFFFF"
        case .uncommon: return "#1EFF00"
        case .rare: return "#0070DD"
        case .epic: return "#A335EE"
        case .legendary: return "#FF8000"
        }
    }
}

enum AffectedStat: String, CaseIterable, Codable {
    case strength, agility, intelligence, xpGain, healthRegen
    
    var displayName: String {
        switch self {
        case .strength: return "Strength"
        case .agility: return "Agility"
        case .intelligence: return "Intelligence"
        case .xpGain: return "XP Gain"
        case .healthRegen: return "Health Regen"
        }
    }
}

struct ItemEffect: Codable, Hashable {
    var stat: AffectedStat
    var amount: Int
    
    init(stat: AffectedStat, amount: Int) {
        self.stat = stat
        self.amount = amount
    }
}

struct Item: Codable, Identifiable, Hashable {
    let id: UUID
    var name: String
    var type: ItemType
    var level: Int
    var rarity: Rarity
    var effects: [ItemEffect]
    
    init(name: String, type: ItemType, level: Int, rarity: Rarity, effects: [ItemEffect] = []) {
        self.id = UUID()
        self.name = name
        self.type = type
        self.level = level
        self.rarity = rarity
        self.effects = effects
    }
    
    var description: String {
        var desc = "\(rarity.displayName) \(type.displayName) (Level \(level))"
        if !effects.isEmpty {
            desc += "\n\nEffects:"
            for effect in effects {
                let sign = effect.amount >= 0 ? "+" : ""
                desc += "\n\(sign)\(effect.amount) \(effect.stat.displayName)"
            }
        }
        return desc
    }
}