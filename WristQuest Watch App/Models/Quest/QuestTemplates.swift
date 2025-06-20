import Foundation

/// QuestTemplates contains all static data for quest generation,
/// organized by category and difficulty for better maintainability
struct QuestTemplates {
    
    // MARK: - Initial Fantasy Quests
    
    static let initialQuests: [(title: String, description: String, distance: Double, xp: Int, gold: Int)] = [
        (
            "The Whispering Woods",
            "Ancient spirits call from the enchanted forest depths",
            50.0,
            100,
            25
        ),
        (
            "Merchant's Peril",
            "Protect the sacred caravan from shadow creatures",
            75.0,
            150,
            40
        ),
        (
            "The Crimson Wyrm",
            "Face the ancient dragon lord of the flame peaks",
            100.0,
            300,
            100
        ),
        (
            "Moonlit Sanctum",
            "Explore the forgotten temple under starlight",
            60.0,
            120,
            30
        )
    ]
    
    // MARK: - Procedural Quest Templates
    
    static let questTemplates: [(title: String, description: String)] = [
        ("The Sunken Crypts", "Delve into waterlogged tombs of forgotten kings"),
        ("Shadowmere Crossing", "Navigate the treacherous bridge over dark waters"),
        ("The Singing Stones", "Discover the melody that awakens ancient magic"),
        ("Wraith's Hollow", "Banish the restless spirits from their cursed domain"),
        ("The Crystal Caverns", "Harvest mystical gems from the living mountain"),
        ("Phoenix Nesting Grounds", "Seek the legendary firebird's sacred feathers"),
        ("The Starfall Crater", "Investigate the celestial impact site"),
        ("Thornwood Labyrinth", "Navigate the ever-shifting maze of thorns"),
        ("The Midnight Market", "Trade with mysterious vendors in the shadow realm"),
        ("Echoing Depths", "Explore the cavern where sound becomes magic"),
        ("The Floating Isles", "Journey through sky-bound mystical lands"),
        ("Serpent's Coil", "Navigate the massive ancient snake's petrified remains"),
        ("The Glass Desert", "Cross the crystalline wasteland of broken dreams"),
        ("Whirlpool of Souls", "Brave the spiritual maelstrom to rescue the lost"),
        ("The Bone Garden", "Tend to the skeletal forest where death meets life"),
        ("Clockwork Ruins", "Uncover secrets in the mechanical civilization's remains")
    ]
    
    // MARK: - Quest Categories by Theme
    
    enum QuestTheme: CaseIterable {
        case exploration
        case combat
        case mystical
        case nature
        case ancient
        case cosmic
        
        var templates: [(title: String, description: String)] {
            switch self {
            case .exploration:
                return [
                    ("The Hidden Valley", "Discover the secret realm beyond the mist"),
                    ("Lost Cartographer", "Follow the mysterious map to unknown lands"),
                    ("The Forgotten Path", "Traverse the overgrown trail of ancient pilgrims")
                ]
            case .combat:
                return [
                    ("Arena of Echoes", "Prove your worth against phantom gladiators"),
                    ("The War Camp", "Aid the spectral army in their eternal battle"),
                    ("Duelist's Honor", "Accept challenges from legendary weapon masters")
                ]
            case .mystical:
                return [
                    ("The Spell Forge", "Craft magical items in the arcane workshop"),
                    ("Ley Line Junction", "Stabilize the chaotic magical convergence"),
                    ("The Dream Weaver", "Navigate the tapestry of sleeping minds")
                ]
            case .nature:
                return [
                    ("The Great Bloom", "Witness the century's most magnificent flowering"),
                    ("Migration of Shadows", "Guide the shadow creatures to their breeding grounds"),
                    ("The Root Network", "Commune with the forest's underground consciousness")
                ]
            case .ancient:
                return [
                    ("The First Library", "Recover knowledge from civilization's dawn"),
                    ("Titan's Graveyard", "Explore where the old gods fell to earth"),
                    ("The Origin Stone", "Touch the rock from which all magic flows")
                ]
            case .cosmic:
                return [
                    ("Stellar Alignment", "Harness power during the celestial convergence"),
                    ("The Void Walker", "Journey between realms through empty space"),
                    ("Comet's Trail", "Follow the cosmic wanderer's glowing path")
                ]
            }
        }
    }
    
    // MARK: - Difficulty-Based Modifiers
    
    enum QuestDifficulty: CaseIterable {
        case easy
        case normal
        case hard
        case epic
        
        var distanceMultiplier: Double {
            switch self {
            case .easy: return 0.7
            case .normal: return 1.0
            case .hard: return 1.3
            case .epic: return 1.8
            }
        }
        
        var xpMultiplier: Double {
            switch self {
            case .easy: return 0.8
            case .normal: return 1.0
            case .hard: return 1.4
            case .epic: return 2.0
            }
        }
        
        var goldMultiplier: Double {
            switch self {
            case .easy: return 0.9
            case .normal: return 1.0
            case .hard: return 1.2
            case .epic: return 1.6
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// Get random quest templates for level-appropriate generation
    static func getRandomTemplates(count: Int = 3) -> [(title: String, description: String)] {
        return questTemplates.shuffled().prefix(count).map { $0 }
    }
    
    /// Get themed quest templates
    static func getThemedTemplates(theme: QuestTheme, count: Int = 2) -> [(title: String, description: String)] {
        return theme.templates.shuffled().prefix(count).map { $0 }
    }
    
    /// Get all available quest templates
    static func getAllTemplates() -> [(title: String, description: String)] {
        var allTemplates = questTemplates
        for theme in QuestTheme.allCases {
            allTemplates.append(contentsOf: theme.templates)
        }
        return allTemplates
    }
    
    /// Get difficulty-modified values
    static func applyDifficulty(_ difficulty: QuestDifficulty, 
                               to baseValues: (distance: Double, xp: Int, gold: Int)) -> (distance: Double, xp: Int, gold: Int) {
        return (
            distance: baseValues.distance * difficulty.distanceMultiplier,
            xp: Int(Double(baseValues.xp) * difficulty.xpMultiplier),
            gold: Int(Double(baseValues.gold) * difficulty.goldMultiplier)
        )
    }
}