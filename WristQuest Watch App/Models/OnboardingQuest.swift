import Foundation
import SwiftUI

// MARK: - Onboarding Quest Model
struct OnboardingQuest: Codable, Identifiable {
    let id: UUID
    let title: String
    let epicIntroduction: String
    let questGiver: QuestGiver
    let storyBeats: [StoryBeat]
    let mysticalLocation: MysticalLocation
    let ancientCreatures: [AncientCreature]
    let prophecyText: String
    let completionRitual: String
    
    init(title: String, epicIntroduction: String, questGiver: QuestGiver, 
         storyBeats: [StoryBeat], mysticalLocation: MysticalLocation,
         ancientCreatures: [AncientCreature], prophecyText: String, completionRitual: String) {
        self.id = UUID()
        self.title = title
        self.epicIntroduction = epicIntroduction
        self.questGiver = questGiver
        self.storyBeats = storyBeats
        self.mysticalLocation = mysticalLocation
        self.ancientCreatures = ancientCreatures
        self.prophecyText = prophecyText
        self.completionRitual = completionRitual
    }
}

// MARK: - Quest Giver
struct QuestGiver: Codable {
    let name: String
    let title: String
    let appearance: String
    let voice: String
    let backstory: String
    let mysticalPowers: [String]
    
    var fullIntroduction: String {
        return "\(title) \(name), \(appearance). \(backstory)"
    }
}

// MARK: - Story Beat
struct StoryBeat: Codable, Identifiable {
    let id: UUID
    let sequence: Int
    let title: String
    let narrativeText: String
    let worldBuildingLore: String
    let characterDialogue: String?
    let mysticalEvent: String?
    let requiredAction: OnboardingAction
    let epicMoment: Bool
    
    init(sequence: Int, title: String, narrativeText: String, worldBuildingLore: String,
         characterDialogue: String? = nil, mysticalEvent: String? = nil,
         requiredAction: OnboardingAction, epicMoment: Bool = false) {
        self.id = UUID()
        self.sequence = sequence
        self.title = title
        self.narrativeText = narrativeText
        self.worldBuildingLore = worldBuildingLore
        self.characterDialogue = characterDialogue
        self.mysticalEvent = mysticalEvent
        self.requiredAction = requiredAction
        self.epicMoment = epicMoment
    }
}

// MARK: - Onboarding Action
enum OnboardingAction: String, Codable {
    case chooseDestiny = "choose_destiny"
    case forgeIdentity = "forge_identity"
    case acceptMysticalBond = "accept_mystical_bond"
    case embracePower = "embrace_power"
    case beginJourney = "begin_journey"
    
    var displayName: String {
        switch self {
        case .chooseDestiny: return "Choose Your Destiny"
        case .forgeIdentity: return "Forge Your Identity"
        case .acceptMysticalBond: return "Accept the Mystical Bond"
        case .embracePower: return "Embrace Your Power"
        case .beginJourney: return "Begin Your Journey"
        }
    }
    
    var epicDescription: String {
        switch self {
        case .chooseDestiny: return "The ancient paths of power await your choice. Select the path that calls to your very soul."
        case .forgeIdentity: return "Speak your true name into existence, that the realm may know the hero who has awakened."
        case .acceptMysticalBond: return "Allow the ancient magics to flow through you, binding your essence to the mystical forces of the realm."
        case .embracePower: return "Feel the power coursing through your veins as destiny recognizes your worthiness."
        case .beginJourney: return "Step forth into legend, champion. Your epic tale begins now."
        }
    }
}

// MARK: - Mystical Location
struct MysticalLocation: Codable {
    let name: String
    let description: String
    let atmosphere: String
    let ancientHistory: String
    let magicalProperties: [String]
    let hiddenSecrets: String
    
    var fullDescription: String {
        return "\(description) \(atmosphere) \(ancientHistory)"
    }
}

// MARK: - Ancient Creature
struct AncientCreature: Codable, Identifiable {
    let id: UUID
    let name: String
    let species: String
    let appearance: String
    let personality: String
    let ancientWisdom: String
    let roleInQuest: String
    let magicalAbilities: [String]
    
    init(name: String, species: String, appearance: String, personality: String,
         ancientWisdom: String, roleInQuest: String, magicalAbilities: [String]) {
        self.id = UUID()
        self.name = name
        self.species = species
        self.appearance = appearance
        self.personality = personality
        self.ancientWisdom = ancientWisdom
        self.roleInQuest = roleInQuest
        self.magicalAbilities = magicalAbilities
    }
    
    var fullDescription: String {
        return "\(name), the \(species). \(appearance) \(personality) \(roleInQuest)"
    }
}

// MARK: - Default Onboarding Quest
extension OnboardingQuest {
    static var theAwakening: OnboardingQuest {
        let questGiver = QuestGiver(
            name: "Eldara the Timekeeper",
            title: "Ancient Oracle",
            appearance: "A figure cloaked in starlight and shadow, her eyes hold the wisdom of countless ages",
            voice: "speaks in harmonious tones that seem to echo from distant realms",
            backstory: "Guardian of the threshold between worlds, she has watched over sleeping heroes for millennia, waiting for the prophesied awakening",
            mysticalPowers: ["Sight Beyond Time", "Soul Recognition", "Destiny Weaving", "Portal Opening"]
        )
        
        let storyBeats = [
            StoryBeat(
                sequence: 1,
                title: "The Stirring of Ancient Powers",
                narrativeText: "Deep within the Crystal Sanctum, ancient energies begin to pulse with newfound life. The sleeping chamber, dormant for centuries, suddenly blazes with ethereal light.",
                worldBuildingLore: "The Crystal Sanctum exists between dimensions, a sacred space where heroes of legend rest until the realm calls them to service. Its crystalline walls hold the memories of a thousand adventures.",
                characterDialogue: "At last... the prophecy stirs to life. A new champion awakens to answer destiny's call.",
                mysticalEvent: "The Crystal of Eternal Potential begins to resonate with your life force",
                requiredAction: .chooseDestiny,
                epicMoment: true
            ),
            StoryBeat(
                sequence: 2,
                title: "The Forging of Legend",
                narrativeText: "With your path chosen, the very essence of your being begins to take shape. The mystical energies recognize your true nature and begin to weave your legend.",
                worldBuildingLore: "Names hold power in this realm. To speak your true name is to anchor your soul to this dimension and claim your place among the heroes of old.",
                characterDialogue: "Speak your name, champion, that the realm may know who has chosen to stand against the darkness.",
                requiredAction: .forgeIdentity
            ),
            StoryBeat(
                sequence: 3,
                title: "The Mystical Bonding",
                narrativeText: "The final seal must be broken. Your mortal form must be connected to the magical forces that flow through all living things. Only through this bond can you truly harness your power.",
                worldBuildingLore: "The Life Force Bond is an ancient ritual that connects a hero's physical essence to the magical energies of the realm. It allows the hero to draw power from their very life force.",
                characterDialogue: "Accept the bond, brave soul. Let your life essence become one with the mystical forces that protect this realm.",
                mysticalEvent: "Ancient runes of power appear around you, pulsing with your heartbeat",
                requiredAction: .acceptMysticalBond,
                epicMoment: true
            ),
            StoryBeat(
                sequence: 4,
                title: "The Embrace of Destiny",
                narrativeText: "Power flows through you like liquid starlight. Your transformation is nearly complete. Feel the strength of heroes past flowing through your veins.",
                worldBuildingLore: "Each hero who awakens adds their strength to the eternal cycle. You are both unique and part of an ancient tradition stretching back to the realm's creation.",
                characterDialogue: "Rise, champion! Your power is awakened, your destiny clear. The realm has need of your strength.",
                mysticalEvent: "A crown of pure energy appears above your head, marking you as a true hero",
                requiredAction: .embracePower,
                epicMoment: true
            ),
            StoryBeat(
                sequence: 5,
                title: "The First Step of Legend",
                narrativeText: "The portal to the realm awaits. Beyond lies adventure, glory, and the chance to forge a legend that will echo through eternity. Your story begins now.",
                worldBuildingLore: "Every hero's journey begins with a single step. From this moment forward, your actions will shape not just your own destiny, but the fate of the entire realm.",
                characterDialogue: "Go forth, hero of legend. May your name be spoken with reverence for ages to come.",
                mysticalEvent: "The Portal of Infinite Possibilities opens before you, shimmering with otherworldly beauty",
                requiredAction: .beginJourney,
                epicMoment: true
            )
        ]
        
        let mysticalLocation = MysticalLocation(
            name: "The Crystal Sanctum of Eternal Potential",
            description: "A breathtaking chamber carved from a single, massive crystal that pulses with inner light.",
            atmosphere: "The air itself seems alive with possibility, sparkling with motes of magical energy that dance and swirl in impossible patterns.",
            ancientHistory: "Built by the First Mages as a repository of heroic potential, this sanctum has witnessed the awakening of every great champion in the realm's history.",
            magicalProperties: ["Amplifies heroic potential", "Reveals true nature", "Preserves legendary essence", "Opens portals between realms"],
            hiddenSecrets: "The crystal walls contain the memories and experiences of every hero who has ever awakened here, accessible to those who know the ancient words of power."
        )
        
        let ancientCreatures = [
            AncientCreature(
                name: "Lumina",
                species: "Crystal Phoenix",
                appearance: "A magnificent phoenix whose feathers are made of living crystal, casting rainbow reflections throughout the sanctum",
                personality: "Wise and serene, speaking in musical tones that sound like wind chimes in a gentle breeze",
                ancientWisdom: "She has witnessed the rise and fall of civilizations, and her songs carry the wisdom of ages past",
                roleInQuest: "Guardian of the awakening ritual, she ensures only those pure of heart may claim their heroic destiny",
                magicalAbilities: ["Song of Awakening", "Crystal Sight", "Phoenix Rebirth", "Memory Preservation"]
            ),
            AncientCreature(
                name: "Theron",
                species: "Starlight Stag",
                appearance: "A majestic stag whose antlers seem to be made of condensed starlight, with a coat that shimmers like the night sky",
                personality: "Noble and patient, communicating through thoughts and emotions rather than words",
                ancientWisdom: "He carries the knowledge of all paths through the mystical forest, knowing which routes lead to glory and which to peril",
                roleInQuest: "Guide between worlds, he will lead the hero from the sanctum to their first real quest",
                magicalAbilities: ["Stellar Navigation", "Dimensional Walking", "Path Revelation", "Destiny Sight"]
            )
        ]
        
        return OnboardingQuest(
            title: "The Awakening of Legends",
            epicIntroduction: "From the depths of eternal slumber, a new champion stirs. The Crystal Sanctum pulses with ancient power as destiny calls forth another hero to save the realm from encroaching darkness. Your awakening was foretold in prophecies written before the first sunrise.",
            questGiver: questGiver,
            storyBeats: storyBeats,
            mysticalLocation: mysticalLocation,
            ancientCreatures: ancientCreatures,
            prophecyText: "When shadow threatens to consume the light, when ancient evils stir from their timeless prison, a hero shall rise from crystal dreams. Bound by mystical forces, empowered by pure will, they shall walk the path of legends and restore balance to the realm.",
            completionRitual: "As the final words of power are spoken, reality shimmers around you. The Crystal Sanctum fades into memory, replaced by the vast expanse of the mystical realm. Your journey of legend begins now, champion. May your deeds echo through eternity."
        )
    }
}