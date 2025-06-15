import Foundation
import SwiftUI

enum HeroClass: String, CaseIterable, Codable {
    case warrior, mage, rogue, ranger, cleric
    
    var displayName: String {
        switch self {
        case .warrior: return "Warrior"
        case .mage: return "Mage"
        case .rogue: return "Rogue" 
        case .ranger: return "Ranger"
        case .cleric: return "Cleric"
        }
    }
    
    var passivePerk: String {
        switch self {
        case .warrior: return "Bonus XP for steps"
        case .mage: return "Auto-completes minor events"
        case .rogue: return "Reduced quest distance"
        case .ranger: return "Bonus XP when walking outdoors"
        case .cleric: return "Heal via mindful minutes"
        }
    }
    
    var activeAbility: String {
        switch self {
        case .warrior: return "Battle Roar: Double XP"
        case .mage: return "Mana Surge: Auto-travel"
        case .rogue: return "Shadowstep: Skip encounter"
        case .ranger: return "Hawk Vision: Preview events"
        case .cleric: return "Divine Light: Cleanse debuffs"
        }
    }
    
    var specialTrait: String {
        switch self {
        case .warrior: return "More likely to trigger combat events"
        case .mage: return "Higher item drop rates"
        case .rogue: return "Critical loot upgrades"
        case .ranger: return "Finds more gold during quests"
        case .cleric: return "Prevents failed outcomes 1x/day"
        }
    }
    
    // MARK: - UI Properties
    var iconName: String {
        switch self {
        case .warrior: return "shield.fill"
        case .mage: return "sparkles"
        case .rogue: return "eye.slash.fill"
        case .ranger: return "leaf.fill"
        case .cleric: return "cross.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .warrior: return WQDesignSystem.Colors.questRed
        case .mage: return WQDesignSystem.Colors.questBlue
        case .rogue: return WQDesignSystem.Colors.secondaryText
        case .ranger: return WQDesignSystem.Colors.questGreen
        case .cleric: return WQDesignSystem.Colors.questGold
        }
    }
    
    var gradientColors: [Color] {
        switch self {
        case .warrior: return [WQDesignSystem.Colors.questRed, WQDesignSystem.Colors.questRed.opacity(0.7)]
        case .mage: return [WQDesignSystem.Colors.questBlue, WQDesignSystem.Colors.questBlue.opacity(0.7)]
        case .rogue: return [WQDesignSystem.Colors.secondaryText, WQDesignSystem.Colors.secondaryText.opacity(0.7)]
        case .ranger: return [WQDesignSystem.Colors.questGreen, WQDesignSystem.Colors.questGreen.opacity(0.7)]
        case .cleric: return [WQDesignSystem.Colors.questGold, WQDesignSystem.Colors.questGold.opacity(0.7)]
        }
    }
    
    var shortDescription: String {
        switch self {
        case .warrior: return "Strong and resilient fighter"
        case .mage: return "Master of magical arts"
        case .rogue: return "Stealthy and cunning"
        case .ranger: return "Nature's skilled guardian"
        case .cleric: return "Divine healer and protector"
        }
    }
    
    var fullDescription: String {
        switch self {
        case .warrior: 
            return "Warriors are frontline fighters who excel in direct combat. They gain bonus experience from physical activity and can unleash a powerful battle roar to double their XP gains."
        case .mage:
            return "Mages harness arcane energies to overcome obstacles. They automatically resolve minor encounters and can use mana surge to instantly travel to quest destinations."
        case .rogue:
            return "Rogues rely on stealth and cunning to achieve their goals. They can complete quests with reduced travel requirements and use shadowstep to avoid dangerous encounters."
        case .ranger:
            return "Rangers are one with nature, gaining enhanced benefits from outdoor activities. They can preview upcoming events with hawk vision and discover more treasure during their adventures."
        case .cleric:
            return "Clerics channel divine power to heal and protect. They recover health through mindful meditation and can use divine light to cleanse harmful effects once per day."
        }
    }
    
    var specialAbility: String {
        switch self {
        case .warrior: return "Battle Roar - Double XP gain for next encounter"
        case .mage: return "Mana Surge - Instantly complete travel phase"
        case .rogue: return "Shadowstep - Skip one encounter per quest"
        case .ranger: return "Hawk Vision - Preview next three encounters"
        case .cleric: return "Divine Light - Remove all negative effects"
        }
    }
    
    var loreBackground: String {
        switch self {
        case .warrior:
            return "Born from the ancient order of the Iron Guard, warriors have protected the realm for centuries. Their strength comes from within, fueled by determination and the will to never surrender."
        case .mage:
            return "Students of the Arcane Academy, mages channel the raw energies of creation itself. They see beyond the veil of reality, manipulating the very fabric of the world through pure will."
        case .rogue:
            return "Shadow dancers from the Thieves' Guild, rogues move unseen through the world. They are the whispered rumors in taverns, the figures that vanish when you turn your head."
        case .ranger:
            return "Guardians of the Emerald Woods, rangers are one with nature's rhythm. They speak the language of wind and leaf, finding strength in the wild places others fear to tread."
        case .cleric:
            return "Chosen of the Divine Light, clerics serve as bridges between mortal and celestial realms. Their faith burns bright, healing wounds and banishing darkness wherever they walk."
        }
    }
}