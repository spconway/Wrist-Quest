import Foundation
import SwiftUI

// MARK: - Onboarding Narrative Model
struct OnboardingNarrative: Codable, Identifiable {
    let id: UUID
    let narrativeTitle: String
    let overallTheme: NarrativeTheme
    let dialogueTree: DialogueTree
    let worldBuildingElements: [WorldBuildingElement]
    let epicMoments: [EpicMoment]
    let celebrationEvents: [CelebrationEvent]
    var currentProgress: NarrativeProgress
    
    init(narrativeTitle: String, overallTheme: NarrativeTheme, dialogueTree: DialogueTree,
         worldBuildingElements: [WorldBuildingElement], epicMoments: [EpicMoment],
         celebrationEvents: [CelebrationEvent], currentProgress: NarrativeProgress) {
        self.id = UUID()
        self.narrativeTitle = narrativeTitle
        self.overallTheme = overallTheme
        self.dialogueTree = dialogueTree
        self.worldBuildingElements = worldBuildingElements
        self.epicMoments = epicMoments
        self.celebrationEvents = celebrationEvents
        self.currentProgress = currentProgress
    }
}

// MARK: - Narrative Theme
enum NarrativeTheme: String, CaseIterable, Codable {
    case heroicAwakening = "heroic_awakening"
    case destinyForged = "destiny_forged"
    case ancientPowerRising = "ancient_power_rising"
    case cosmicAlignment = "cosmic_alignment"
    case legendBorn = "legend_born"
    
    var displayName: String {
        switch self {
        case .heroicAwakening: return "The Heroic Awakening"
        case .destinyForged: return "Destiny Forged in Starfire"
        case .ancientPowerRising: return "Ancient Power Rising"
        case .cosmicAlignment: return "Cosmic Alignment"
        case .legendBorn: return "A Legend is Born"
        }
    }
    
    var thematicDescription: String {
        switch self {
        case .heroicAwakening: return "The moment when ordinary becomes extraordinary, when mortal potential touches divine purpose"
        case .destinyForged: return "The cosmic forces align to create a hero capable of changing the course of history"
        case .ancientPowerRising: return "Long-dormant magics stir to life, responding to the call of a worthy champion"
        case .cosmicAlignment: return "The universe itself rearranges to accommodate the birth of a new legend"
        case .legendBorn: return "The first chapter of a story that will be told for generations to come"
        }
    }
}

// MARK: - Dialogue Tree
struct DialogueTree: Codable {
    let rootDialogue: DialogueNode
    let characterVoices: [CharacterVoice]
    let conversationFlow: [DialogueSequence]
    
    func getDialogue(for step: OnboardingAction) -> DialogueNode? {
        return conversationFlow.first { $0.triggerAction == step }?.dialogueNode
    }
}

// MARK: - Dialogue Node
struct DialogueNode: Codable, Identifiable {
    let id: UUID
    let speaker: String
    let speakerTitle: String
    let text: String
    let emotionalTone: EmotionalTone
    let mysticalElements: [String]
    let responseOptions: [DialogueResponse]?
    let nextNode: UUID?
    
    init(speaker: String, speakerTitle: String, text: String, emotionalTone: EmotionalTone,
         mysticalElements: [String], responseOptions: [DialogueResponse]? = nil, nextNode: UUID? = nil) {
        self.id = UUID()
        self.speaker = speaker
        self.speakerTitle = speakerTitle
        self.text = text
        self.emotionalTone = emotionalTone
        self.mysticalElements = mysticalElements
        self.responseOptions = responseOptions
        self.nextNode = nextNode
    }
    
    var fullSpeakerName: String {
        return "\(speakerTitle) \(speaker)"
    }
}

// MARK: - Emotional Tone
enum EmotionalTone: String, CaseIterable, Codable {
    case mystical = "mystical"
    case encouraging = "encouraging"
    case aweInspiring = "awe_inspiring"
    case warmWisdom = "warm_wisdom"
    case epicGrandeur = "epic_grandeur"
    case gentleGuiding = "gentle_guiding"
    case powerfulResolve = "powerful_resolve"
    
    var description: String {
        switch self {
        case .mystical: return "Filled with otherworldly mystery and ancient knowledge"
        case .encouraging: return "Warm and supportive, building confidence"
        case .aweInspiring: return "Commanding respect and wonder at cosmic forces"
        case .warmWisdom: return "Like a beloved mentor sharing life-changing insights"
        case .epicGrandeur: return "Befitting the birth of legends and the making of heroes"
        case .gentleGuiding: return "Patient and kind, leading without pressure"
        case .powerfulResolve: return "Unshakeable determination and divine purpose"
        }
    }
}

// MARK: - Dialogue Response
struct DialogueResponse: Codable, Identifiable {
    let id: UUID
    let responseText: String
    let playerPersonality: PlayerPersonalityTrait
    let consequenceNode: UUID
    
    init(responseText: String, playerPersonality: PlayerPersonalityTrait, consequenceNode: UUID) {
        self.id = UUID()
        self.responseText = responseText
        self.playerPersonality = playerPersonality
        self.consequenceNode = consequenceNode
    }
}

// MARK: - Player Personality Trait
enum PlayerPersonalityTrait: String, CaseIterable, Codable {
    case brave = "brave"
    case wise = "wise"
    case humble = "humble"
    case determined = "determined"
    case curious = "curious"
    case compassionate = "compassionate"
    
    var displayName: String {
        switch self {
        case .brave: return "Brave"
        case .wise: return "Wise"
        case .humble: return "Humble"
        case .determined: return "Determined"
        case .curious: return "Curious"
        case .compassionate: return "Compassionate"
        }
    }
}

// MARK: - Character Voice
struct CharacterVoice: Codable, Identifiable {
    let id: UUID
    let characterName: String
    let voicePattern: String
    let speechMannerisms: [String]
    let vocabularyStyle: String
    let emotionalRange: [EmotionalTone]
    
    init(characterName: String, voicePattern: String, speechMannerisms: [String],
         vocabularyStyle: String, emotionalRange: [EmotionalTone]) {
        self.id = UUID()
        self.characterName = characterName
        self.voicePattern = voicePattern
        self.speechMannerisms = speechMannerisms
        self.vocabularyStyle = vocabularyStyle
        self.emotionalRange = emotionalRange
    }
}

// MARK: - Dialogue Sequence
struct DialogueSequence: Codable, Identifiable {
    let id: UUID
    let triggerAction: OnboardingAction
    let dialogueNode: DialogueNode
    let sequenceOrder: Int
    
    init(triggerAction: OnboardingAction, dialogueNode: DialogueNode, sequenceOrder: Int) {
        self.id = UUID()
        self.triggerAction = triggerAction
        self.dialogueNode = dialogueNode
        self.sequenceOrder = sequenceOrder
    }
}

// MARK: - World Building Element
struct WorldBuildingElement: Codable, Identifiable {
    let id: UUID
    let elementName: String
    let category: WorldBuildingCategory
    let description: String
    let loreSignificance: String
    let visualElements: [String]
    let culturalImpact: String
    let connectionToHero: String
    
    init(elementName: String, category: WorldBuildingCategory, description: String,
         loreSignificance: String, visualElements: [String], culturalImpact: String, connectionToHero: String) {
        self.id = UUID()
        self.elementName = elementName
        self.category = category
        self.description = description
        self.loreSignificance = loreSignificance
        self.visualElements = visualElements
        self.culturalImpact = culturalImpact
        self.connectionToHero = connectionToHero
    }
}

// MARK: - World Building Category
enum WorldBuildingCategory: String, CaseIterable, Codable {
    case location = "location"
    case history = "history"
    case magic = "magic"
    case culture = "culture"
    case prophecy = "prophecy"
    case artifact = "artifact"
    
    var displayName: String {
        switch self {
        case .location: return "Mystical Location"
        case .history: return "Ancient History"
        case .magic: return "Magical Lore"
        case .culture: return "Cultural Tradition"
        case .prophecy: return "Divine Prophecy"
        case .artifact: return "Legendary Artifact"
        }
    }
}

// MARK: - Epic Moment
struct EpicMoment: Codable, Identifiable {
    let id: UUID
    let momentTitle: String
    let triggerAction: OnboardingAction
    let epicDescription: String
    let visualSpectacle: String
    let emotionalImpact: String
    let soundscapeDescription: String
    let transformationEffect: String
    
    init(momentTitle: String, triggerAction: OnboardingAction, epicDescription: String,
         visualSpectacle: String, emotionalImpact: String, soundscapeDescription: String, transformationEffect: String) {
        self.id = UUID()
        self.momentTitle = momentTitle
        self.triggerAction = triggerAction
        self.epicDescription = epicDescription
        self.visualSpectacle = visualSpectacle
        self.emotionalImpact = emotionalImpact
        self.soundscapeDescription = soundscapeDescription
        self.transformationEffect = transformationEffect
    }
}

// MARK: - Celebration Event
struct CelebrationEvent: Codable, Identifiable {
    let id: UUID
    let eventName: String
    let triggerMilestone: OnboardingAction
    let celebrationDescription: String
    let cosmicReaction: String
    let rewards: [CelebrationReward]
    let memorableQuote: String
    
    init(eventName: String, triggerMilestone: OnboardingAction, celebrationDescription: String,
         cosmicReaction: String, rewards: [CelebrationReward], memorableQuote: String) {
        self.id = UUID()
        self.eventName = eventName
        self.triggerMilestone = triggerMilestone
        self.celebrationDescription = celebrationDescription
        self.cosmicReaction = cosmicReaction
        self.rewards = rewards
        self.memorableQuote = memorableQuote
    }
}

// MARK: - Celebration Reward
struct CelebrationReward: Codable, Identifiable {
    let id: UUID
    let rewardName: String
    let rewardType: RewardType
    let description: String
    let gameplayBenefit: String
    
    init(rewardName: String, rewardType: RewardType, description: String, gameplayBenefit: String) {
        self.id = UUID()
        self.rewardName = rewardName
        self.rewardType = rewardType
        self.description = description
        self.gameplayBenefit = gameplayBenefit
    }
    
    enum RewardType: String, CaseIterable, Codable {
        case title = "title"
        case ability = "ability"
        case blessing = "blessing"
        case insight = "insight"
        case connection = "connection"
        
        var displayName: String {
            switch self {
            case .title: return "Heroic Title"
            case .ability: return "Special Ability"
            case .blessing: return "Divine Blessing"
            case .insight: return "Ancient Insight"
            case .connection: return "Mystical Connection"
            }
        }
    }
}

// MARK: - Narrative Progress
struct NarrativeProgress: Codable {
    var completedActions: [OnboardingAction]
    var currentPhase: NarrativePhase
    var unlockedWorldLore: [String]
    var discoveredSecrets: [String]
    var formedConnections: [String]
    
    enum NarrativePhase: String, CaseIterable, Codable {
        case dormant = "dormant"
        case stirring = "stirring"
        case awakening = "awakening"
        case transforming = "transforming"
        case empowered = "empowered"
        case legendary = "legendary"
        
        var displayName: String {
            switch self {
            case .dormant: return "The Dormant Potential"
            case .stirring: return "The Stirring of Power"
            case .awakening: return "The Great Awakening"
            case .transforming: return "The Transformation"
            case .empowered: return "The Empowerment"
            case .legendary: return "The Birth of Legend"
            }
        }
        
        var phaseDescription: String {
            switch self {
            case .dormant: return "Ancient powers lie sleeping, waiting for the right moment to awaken"
            case .stirring: return "The first whispers of destiny begin to call your name"
            case .awakening: return "Power flows through you as your true nature is revealed"
            case .transforming: return "Your mortal limitations fall away like discarded chains"
            case .empowered: return "You stand transformed, ready to face any challenge"
            case .legendary: return "Your legend begins, destined to echo through eternity"
            }
        }
    }
}

// MARK: - Default Onboarding Narrative
extension OnboardingNarrative {
    static var theAwakeningNarrative: OnboardingNarrative {
        let rootDialogue = DialogueNode(
            speaker: "Eldara",
            speakerTitle: "Ancient Oracle",
            text: "Welcome, sleeping champion. The time of your awakening has come at last. The realm calls to you from beyond the veil of dreams, and destiny itself has chosen you to answer.",
            emotionalTone: .mystical,
            mysticalElements: ["Swirling mists of starlight", "Echoing chimes of distant realms", "The scent of night-blooming celestial flowers"]
        )
        
        let characterVoices = [
            CharacterVoice(
                characterName: "Eldara the Timekeeper",
                voicePattern: "Speaks in flowing, poetic cadences with pauses that seem to contain eternities",
                speechMannerisms: ["Refers to past and future as if they were present", "Uses metaphors of light and shadow", "Speaks of destiny as a living thing"],
                vocabularyStyle: "Ancient and formal, with words that carry the weight of ages",
                emotionalRange: [.mystical, .warmWisdom, .aweInspiring, .epicGrandeur]
            ),
            CharacterVoice(
                characterName: "Lumina the Crystal Phoenix",
                voicePattern: "Communicates through crystalline song-speech that resonates in harmonious tones",
                speechMannerisms: ["Each word chimes like crystal bells", "Speaks of memory and rebirth", "References the eternal cycle"],
                vocabularyStyle: "Musical and ethereal, with words that seem to shimmer in the air",
                emotionalRange: [.mystical, .encouraging, .aweInspiring]
            )
        ]
        
        let dialogueTree = DialogueTree(
            rootDialogue: rootDialogue,
            characterVoices: characterVoices,
            conversationFlow: [
                DialogueSequence(
                    triggerAction: .chooseDestiny,
                    dialogueNode: DialogueNode(
                        speaker: "Eldara",
                        speakerTitle: "Ancient Oracle",
                        text: "Before you stretch five paths of power, each leading to greatness in its own way. Which calls to your soul, brave one? The choice you make will echo through eternity.",
                        emotionalTone: .epicGrandeur,
                        mysticalElements: ["Five glowing pathways appear", "Each path pulses with unique energy", "The air hums with potential"]
                    ),
                    sequenceOrder: 1
                ),
                DialogueSequence(
                    triggerAction: .forgeIdentity,
                    dialogueNode: DialogueNode(
                        speaker: "Eldara",
                        speakerTitle: "Ancient Oracle",
                        text: "Your path is chosen, your power recognized. Now speak your true name into existence, that the cosmos may know who has awakened to claim their destiny.",
                        emotionalTone: .warmWisdom,
                        mysticalElements: ["Golden light swirls around you", "Ancient runes appear in the air", "Reality itself listens"]
                    ),
                    sequenceOrder: 2
                ),
                DialogueSequence(
                    triggerAction: .acceptMysticalBond,
                    dialogueNode: DialogueNode(
                        speaker: "Eldara",
                        speakerTitle: "Ancient Oracle",
                        text: "The final step approaches. Will you accept the mystical bond that will forever link your mortal essence to the cosmic forces? This is the transformation that separates hero from legend.",
                        emotionalTone: .powerfulResolve,
                        mysticalElements: ["Cosmic energies spiral around you", "The fabric of reality ripples", "Starlight descends from above"]
                    ),
                    sequenceOrder: 3
                ),
                DialogueSequence(
                    triggerAction: .embracePower,
                    dialogueNode: DialogueNode(
                        speaker: "Lumina",
                        speakerTitle: "Crystal Phoenix",
                        text: "Feel the power awakening within you, noble soul. Let it flow through every fiber of your being. You are no longer bound by mortal limitations - you are becoming legend incarnate.",
                        emotionalTone: .aweInspiring,
                        mysticalElements: ["Crystal light erupts from within you", "Phoenix song fills the air", "Your very presence begins to glow"]
                    ),
                    sequenceOrder: 4
                ),
                DialogueSequence(
                    triggerAction: .beginJourney,
                    dialogueNode: DialogueNode(
                        speaker: "Eldara",
                        speakerTitle: "Ancient Oracle",
                        text: "Rise, champion of legend! Your transformation is complete. Step forth into a world that awaits your heroic deeds. May your name be spoken with reverence for ages yet to come.",
                        emotionalTone: .epicGrandeur,
                        mysticalElements: ["Portal of infinite light opens", "All of reality seems to celebrate", "Your legend officially begins"]
                    ),
                    sequenceOrder: 5
                )
            ]
        )
        
        let worldBuildingElements = [
            WorldBuildingElement(
                elementName: "The Crystal Sanctum",
                category: .location,
                description: "A magnificent chamber carved from a single, massive crystal that exists between dimensions",
                loreSignificance: "This is where all heroes throughout history have first awakened to their true potential",
                visualElements: ["Walls of living crystal", "Floating motes of light", "Impossible geometric patterns", "Reflections that show other realms"],
                culturalImpact: "Considered the most sacred space in all existence, where mortal becomes divine",
                connectionToHero: "Your awakening here links you to every great hero who came before"
            ),
            WorldBuildingElement(
                elementName: "The Prophecy of the Chosen",
                category: .prophecy,
                description: "An ancient foretelling that speaks of heroes who will rise in times of great need",
                loreSignificance: "Written before the first sunrise by beings whose names are lost to time",
                visualElements: ["Words that glow with inner fire", "Text that changes based on who reads it", "Scrolls that feel warm to the touch"],
                culturalImpact: "Every culture in the realm knows fragments of this prophecy",
                connectionToHero: "Your awakening fulfills one verse of this eternal prophecy"
            ),
            WorldBuildingElement(
                elementName: "The Life Force Network",
                category: .magic,
                description: "An invisible web of energy that connects all living things in the realm",
                loreSignificance: "Created by the First Mages to ensure that life could never be fully extinguished",
                visualElements: ["Threads of light between all living things", "Pulsing nodes of concentrated energy", "Aurora-like displays of life force"],
                culturalImpact: "Understanding this network is the basis of all healing arts and nature magic",
                connectionToHero: "Your mystical bond taps directly into this universal life force"
            )
        ]
        
        let epicMoments = [
            EpicMoment(
                momentTitle: "The Moment of Destined Choice",
                triggerAction: .chooseDestiny,
                epicDescription: "Reality itself holds its breath as you stand before the five paths of power. Each path blazes with otherworldly light, and you can feel the weight of cosmic significance pressing down upon you. This choice will determine not just your abilities, but the very nature of your heroic legend.",
                visualSpectacle: "Five brilliant beams of light stretch into infinity, each pulsing with the essence of its respective class. The very air crackles with potential energy.",
                emotionalImpact: "A profound sense of standing at the crossroads of destiny, where one decision will echo through eternity",
                soundscapeDescription: "The universe itself seems to sing in harmonious anticipation, with each class path resonating at its own mystical frequency",
                transformationEffect: "Your spiritual essence begins to align with your chosen path, preparing your soul for the power to come"
            ),
            EpicMoment(
                momentTitle: "The Speaking of the True Name",
                triggerAction: .forgeIdentity,
                epicDescription: "As you speak your name, it blazes in letters of pure starfire in the air before you. The cosmos itself acknowledges your identity, and you feel your essence becoming anchored to this reality in a way that transcends mere existence.",
                visualSpectacle: "Your name appears in glowing runes that pulse with your heartbeat, surrounded by constellations that form your personal celestial signature",
                emotionalImpact: "The profound realization that you are no longer just a person, but a force of destiny with a name that will be remembered",
                soundscapeDescription: "Celestial choirs sing your name in harmonies that seem to resonate from the very foundations of reality",
                transformationEffect: "Your identity becomes cosmic truth, giving you unshakeable confidence in your heroic purpose"
            ),
            EpicMoment(
                momentTitle: "The Mystical Bonding Ritual",
                triggerAction: .acceptMysticalBond,
                epicDescription: "Cosmic forces beyond mortal comprehension flow through you as the mystical bond takes hold. You feel your life force expanding to touch every living thing in existence, creating connections that will fuel your heroic journey.",
                visualSpectacle: "Streams of living light connect you to points throughout the cosmos, forming a web of power that spans dimensions",
                emotionalImpact: "Overwhelming joy and responsibility as you realize you are now connected to all life in the universe",
                soundscapeDescription: "The heartbeat of the cosmos synchronizes with your own, creating a rhythm that will guide you forever",
                transformationEffect: "Your mortal limitations dissolve as cosmic energy infuses every cell of your being"
            )
        ]
        
        let celebrationEvents = [
            CelebrationEvent(
                eventName: "The Celestial Recognition",
                triggerMilestone: .chooseDestiny,
                celebrationDescription: "The stars themselves rearrange to acknowledge your choice, forming new constellations that spell out your heroic class in the heavens",
                cosmicReaction: "Throughout the realm, sensitive beings pause in their activities as they feel the cosmic shift announcing a new hero's awakening",
                rewards: [
                    CelebrationReward(
                        rewardName: "Stellar Blessing",
                        rewardType: .blessing,
                        description: "The stars have marked you as their chosen champion",
                        gameplayBenefit: "Bonus experience during nighttime activities"
                    )
                ],
                memorableQuote: "Let all creation bear witness - a new champion has chosen their path to legend!"
            ),
            CelebrationEvent(
                eventName: "The Naming of the Hero",
                triggerMilestone: .forgeIdentity,
                celebrationDescription: "Ancient bells throughout the realm ring in celebration as your name is inscribed in the Book of Heroes, a mystical tome that records all legendary figures",
                cosmicReaction: "Animals throughout the world pause to listen as your name echoes on the wind, and flowers bloom out of season in honor of your awakening",
                rewards: [
                    CelebrationReward(
                        rewardName: "True Name Power",
                        rewardType: .ability,
                        description: "Your spoken name now carries magical authority",
                        gameplayBenefit: "Special abilities can be activated by speaking your character name"
                    )
                ],
                memorableQuote: "By this name shall legends be born and epic tales be told!"
            ),
            CelebrationEvent(
                eventName: "The Great Awakening",
                triggerMilestone: .beginJourney,
                celebrationDescription: "Reality itself celebrates your transformation with displays of pure magic - auroras dance in impossible colors, rivers flow uphill for a moment, and every flower in the realm blooms simultaneously",
                cosmicReaction: "The very fabric of existence seems lighter, as if the universe is celebrating the birth of a new protector",
                rewards: [
                    CelebrationReward(
                        rewardName: "Hero's Mantle",
                        rewardType: .title,
                        description: "You are now recognized as a true Hero of Legend",
                        gameplayBenefit: "All NPCs recognize your heroic status and offer special interactions"
                    ),
                    CelebrationReward(
                        rewardName: "Cosmic Connection",
                        rewardType: .connection,
                        description: "Permanent link to the universal life force network",
                        gameplayBenefit: "Access to mystical insights and prophetic guidance"
                    )
                ],
                memorableQuote: "Rise, Champion of Legend! Let your story begin and may it never end!"
            )
        ]
        
        let narrativeProgress = NarrativeProgress(
            completedActions: [],
            currentPhase: .dormant,
            unlockedWorldLore: [],
            discoveredSecrets: [],
            formedConnections: []
        )
        
        return OnboardingNarrative(
            narrativeTitle: "The Awakening of Eternal Legend",
            overallTheme: .heroicAwakening,
            dialogueTree: dialogueTree,
            worldBuildingElements: worldBuildingElements,
            epicMoments: epicMoments,
            celebrationEvents: celebrationEvents,
            currentProgress: narrativeProgress
        )
    }
}