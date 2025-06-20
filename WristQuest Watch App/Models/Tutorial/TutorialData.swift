import Foundation

// Note: WQConstants are accessed globally via WQC typealias

/// TutorialData contains all static data for the tutorial system,
/// externalized from the business logic for better maintainability
struct TutorialData {
    
    // MARK: - Tutorial Quest Templates
    
    static func getQuestTemplate(for heroClass: HeroClass) -> (title: String, description: String, narrative: String) {
        switch heroClass {
        case .warrior:
            return (
                "Trial of the Stalwart Shield",
                "Prove your mettle in the warrior's proving grounds",
                "The ancient training grounds echo with the clash of steel. Your first trial awaits, young warrior."
            )
        case .mage:
            return (
                "The Arcane Awakening",
                "Channel the mystical energies of the cosmos",
                "The ethereal planes shimmer with power. Feel the arcane forces respond to your will, apprentice."
            )
        case .rogue:
            return (
                "Dance of Shadows",
                "Master the art of stealth and precision",
                "The shadows whisper secrets to those who know how to listen. Step lightly, young shadow-walker."
            )
        case .ranger:
            return (
                "Call of the Wild",
                "Commune with nature's ancient wisdom",
                "The forest speaks in rustling leaves and flowing streams. Listen closely, child of the wild."
            )
        case .cleric:
            return (
                "Light of Divine Grace",
                "Channel the sacred power of the divine",
                "Divine light flows through you like a gentle stream. Let your faith guide your first steps, chosen one."
            )
        }
    }
    
    // MARK: - Tutorial Narratives
    
    static let stageNarratives: [TutorialStage: [HeroClass: String]] = [
        .introduction: [
            .warrior: "The training master nods approvingly as you grasp your weapon. 'Show me your resolve, warrior.'",
            .mage: "Mystical runes begin to glow around you. The arcane energies recognize your potential.",
            .rogue: "The shadows seem to bend toward you, as if welcoming a kindred spirit.",
            .ranger: "A gentle breeze carries the scent of pine and earth. Nature acknowledges your presence.",
            .cleric: "Warm light surrounds you like an embrace. The divine presence is unmistakable."
        ],
        .firstChallenge: [
            .warrior: "Your first test: demonstrate your combat stance and defensive techniques.",
            .mage: "Focus your mind and channel the flowing energies into a simple spell.",
            .rogue: "Move silently through the shadows, unseen and unheard.",
            .ranger: "Track the forest spirits through their natural domain.",
            .cleric: "Heal this withered flower with your divine touch."
        ],
        .encounter: [
            .warrior: "A spectral opponent appears, testing your combat skills in ethereal battle.",
            .mage: "Magical constructs challenge your arcane mastery.",
            .rogue: "Navigate the maze of shadows while avoiding detection.",
            .ranger: "A wounded forest creature needs your aid.",
            .cleric: "Dispel the dark curse that plagues this sacred grove."
        ],
        .finalTest: [
            .warrior: "Face the final challenge: protect the innocent from spectral threats.",
            .mage: "Weave complex magic to solve the ancient puzzle.",
            .rogue: "Retrieve the sacred artifact without triggering the guardian wards.",
            .ranger: "Restore balance to the disturbed ecosystem.",
            .cleric: "Purify the corrupted shrine with your holy power."
        ],
        .completion: [
            .warrior: "You have proven yourself worthy. Rise, true warrior of the realm.",
            .mage: "The arcane mysteries bow before your growing power. Well done, mage.",
            .rogue: "The shadows themselves applaud your skill. Welcome, master of stealth.",
            .ranger: "Nature sings your praise. You are truly one with the wild.",
            .cleric: "Divine light shines through you. You are blessed among the faithful."
        ]
    ]
    
    // MARK: - Tutorial Dialogues
    
    static func getDialogue(for stage: TutorialStage, heroClass: HeroClass) -> TutorialDialogue? {
        let dialogues: [TutorialStage: TutorialDialogue] = [
            .introduction: TutorialDialogue(
                speaker: "Training Master",
                text: "Welcome, \(heroClass.rawValue.capitalized). Your trial begins now.",
                options: ["I am ready", "Tell me more about the trial"]
            ),
            .firstChallenge: TutorialDialogue(
                speaker: "Mentor",
                text: "Show me what you've learned. Execute your first technique.",
                options: ["Demonstrate skill", "Ask for guidance"]
            ),
            .encounter: TutorialDialogue(
                speaker: "Spectral Guardian",
                text: "Face me in combat, young \(heroClass.rawValue)!",
                options: ["Accept the challenge", "Attempt to negotiate"]
            ),
            .finalTest: TutorialDialogue(
                speaker: "Ancient Voice",
                text: "One final test remains. Prove your mastery.",
                options: ["I accept", "I need more preparation"]
            ),
            .completion: TutorialDialogue(
                speaker: "Realm Guardian",
                text: "You have exceeded expectations. Your legend begins today.",
                options: ["I am honored", "What comes next?"]
            )
        ]
        
        return dialogues[stage]
    }
    
    // MARK: - Tutorial Encounters
    
    static let encounterTemplates: [HeroClass: TutorialEncounter] = [
        .warrior: TutorialEncounter(
            type: .combat,
            title: "Spectral Duelist",
            description: "A ghostly warrior challenges you to honorable combat.",
            difficulty: .easy,
            successMessage: "Your blade strikes true! The spectral warrior nods in respect.",
            failureMessage: "The spirit's blade finds its mark, but this is only training."
        ),
        .mage: TutorialEncounter(
            type: .puzzle,
            title: "Arcane Codex",
            description: "Decipher the magical runes to unlock ancient knowledge.",
            difficulty: .medium,
            successMessage: "The runes blaze with power as you solve the puzzle!",
            failureMessage: "The magic resists your attempts, but you're learning."
        ),
        .rogue: TutorialEncounter(
            type: .stealth,
            title: "Shadow Maze",
            description: "Navigate the shifting shadows without detection.",
            difficulty: .medium,
            successMessage: "You move like a whisper through the darkness.",
            failureMessage: "The shadows reveal your presence, but you adapt quickly."
        ),
        .ranger: TutorialEncounter(
            type: .nature,
            title: "Wounded Stag",
            description: "A majestic deer needs your help to heal its injuries.",
            difficulty: .easy,
            successMessage: "The stag's wounds close under your gentle care.",
            failureMessage: "Your first attempt fails, but the creature trusts you to try again."
        ),
        .cleric: TutorialEncounter(
            type: .healing,
            title: "Cursed Grove",
            description: "Dark magic has corrupted this sacred place.",
            difficulty: .medium,
            successMessage: "Divine light cleanses the corruption from the land.",
            failureMessage: "The darkness resists, but your faith remains strong."
        )
    ]
    
    // MARK: - Tutorial Reward Items
    
    static let rewardItems: [HeroClass: String] = [
        .warrior: "Apprentice's Sword",
        .mage: "Novice's Wand",
        .rogue: "Shadow Cloak",
        .ranger: "Hunter's Bow",
        .cleric: "Sacred Amulet"
    ]
    
    // MARK: - Helper Methods
    
    static func getNarrative(for stage: TutorialStage, heroClass: HeroClass) -> String {
        return stageNarratives[stage]?[heroClass] ?? "Your journey continues..."
    }
    
    static func getRewardItem(for heroClass: HeroClass) -> String {
        return rewardItems[heroClass] ?? "Training Gear"
    }
    
    static func getStageProgress(for stage: TutorialStage) -> Double {
        switch stage {
        case .notStarted: return 0.0
        case .introduction: return 0.2
        case .firstChallenge: return 0.4
        case .encounter: return 0.6
        case .finalTest: return 0.8
        case .completion: return 1.0
        }
    }
}