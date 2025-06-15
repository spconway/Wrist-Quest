import Foundation
import HealthKit

// MARK: - Mystical Bond Model
struct MysticalBond: Codable, Identifiable {
    let id: UUID
    let bondType: BondType
    let ritualDescription: String
    let mysticalContract: MysticalContract
    let lifeForceSources: [LifeForceSource]
    let bondingCeremony: BondingCeremony
    let powerAwakening: PowerAwakening
    var isEstablished: Bool
    
    init(bondType: BondType, ritualDescription: String, mysticalContract: MysticalContract,
         lifeForceSources: [LifeForceSource], bondingCeremony: BondingCeremony,
         powerAwakening: PowerAwakening, isEstablished: Bool = false) {
        self.id = UUID()
        self.bondType = bondType
        self.ritualDescription = ritualDescription
        self.mysticalContract = mysticalContract
        self.lifeForceSources = lifeForceSources
        self.bondingCeremony = bondingCeremony
        self.powerAwakening = powerAwakening
        self.isEstablished = isEstablished
    }
}

// MARK: - Bond Type
enum BondType: String, CaseIterable, Codable {
    case lifeForce = "life_force"
    case spiritualEnergy = "spiritual_energy"
    case harmonicResonance = "harmonic_resonance"
    
    var displayName: String {
        switch self {
        case .lifeForce: return "Life Force Attunement"
        case .spiritualEnergy: return "Spiritual Energy Synchronization"
        case .harmonicResonance: return "Harmonic Resonance Binding"
        }
    }
    
    var epicDescription: String {
        switch self {
        case .lifeForce: return "The ancient ritual that binds your mortal essence to the mystical energies flowing through all living things."
        case .spiritualEnergy: return "A profound connection that aligns your spirit with the cosmic forces that govern fate and destiny."
        case .harmonicResonance: return "The deepest form of magical bonding, where your very soul resonates in harmony with the fundamental frequencies of reality."
        }
    }
}

// MARK: - Mystical Contract
struct MysticalContract: Codable {
    let contractTitle: String
    let preamble: String
    let terms: [ContractTerm]
    let mysticalSeals: [String]
    let divineWitnesses: [String]
    let consequences: String
    let rewards: String
    
    var fullContract: String {
        var contract = "\(contractTitle)\n\n\(preamble)\n\nTerms of Binding:\n"
        for (index, term) in terms.enumerated() {
            contract += "\(index + 1). \(term.description)\n"
        }
        contract += "\nMystical Seals: \(mysticalSeals.joined(separator: ", "))\n"
        contract += "Divine Witnesses: \(divineWitnesses.joined(separator: ", "))\n"
        contract += "\nConsequences of Breaking: \(consequences)\n"
        contract += "Rewards of Fulfillment: \(rewards)"
        return contract
    }
}

// MARK: - Contract Term
struct ContractTerm: Codable, Identifiable {
    let id: UUID
    let title: String
    let description: String
    let magicalImplication: String
    let requiredPermission: String? // Maps to HealthKit permission type
    
    init(title: String, description: String, magicalImplication: String, requiredPermission: String? = nil) {
        self.id = UUID()
        self.title = title
        self.description = description
        self.magicalImplication = magicalImplication
        self.requiredPermission = requiredPermission
    }
}

// MARK: - Life Force Source
struct LifeForceSource: Codable, Identifiable {
    let id: UUID
    let sourceName: String
    let healthDataType: String // Maps to HKQuantityTypeIdentifier
    let mysticalEnergy: MysticalEnergy
    let powerDescription: String
    let ritualActivation: String
    
    init(sourceName: String, healthDataType: String, mysticalEnergy: MysticalEnergy,
         powerDescription: String, ritualActivation: String) {
        self.id = UUID()
        self.sourceName = sourceName
        self.healthDataType = healthDataType
        self.mysticalEnergy = mysticalEnergy
        self.powerDescription = powerDescription
        self.ritualActivation = ritualActivation
    }
}

// MARK: - Mystical Energy
struct MysticalEnergy: Codable {
    let energyType: EnergyType
    let potencyLevel: PotencyLevel
    let manifestation: String
    let gameplayEffect: String
    
    enum EnergyType: String, CaseIterable, Codable {
        case kinetic = "kinetic"
        case vital = "vital"
        case spiritual = "spiritual"
        case elemental = "elemental"
        case celestial = "celestial"
        
        var displayName: String {
            switch self {
            case .kinetic: return "Kinetic Energy"
            case .vital: return "Vital Energy"
            case .spiritual: return "Spiritual Energy"
            case .elemental: return "Elemental Energy"
            case .celestial: return "Celestial Energy"
            }
        }
    }
    
    enum PotencyLevel: String, CaseIterable, Codable {
        case nascent = "nascent"
        case awakened = "awakened"
        case empowered = "empowered"
        case transcendent = "transcendent"
        
        var displayName: String {
            switch self {
            case .nascent: return "Nascent"
            case .awakened: return "Awakened"
            case .empowered: return "Empowered"
            case .transcendent: return "Transcendent"
            }
        }
    }
}

// MARK: - Bonding Ceremony
struct BondingCeremony: Codable {
    let ceremonialName: String
    let preparation: String
    let invocation: String
    let ritualSteps: [RitualStep]
    let culmination: String
    let celebrationType: CelebrationType
    
    enum CelebrationType: String, CaseIterable, Codable {
        case lightBurst = "light_burst"
        case energySwirl = "energy_swirl"
        case cosmicAlignment = "cosmic_alignment"
        case natureHarmony = "nature_harmony"
        case divineBlessing = "divine_blessing"
        
        var displayName: String {
            switch self {
            case .lightBurst: return "Radiant Light Burst"
            case .energySwirl: return "Swirling Energy Vortex"
            case .cosmicAlignment: return "Cosmic Alignment"
            case .natureHarmony: return "Nature's Harmony"
            case .divineBlessing: return "Divine Blessing"
            }
        }
        
        var description: String {
            switch self {
            case .lightBurst: return "Brilliant golden light erupts from your being, marking your transformation"
            case .energySwirl: return "Mystical energies swirl around you in magnificent spirals of power"
            case .cosmicAlignment: return "The stars themselves align to witness your bonding"
            case .natureHarmony: return "All of nature sings in harmony with your awakened spirit"
            case .divineBlessing: return "Divine light descends to bless your sacred commitment"
            }
        }
    }
}

// MARK: - Ritual Step
struct RitualStep: Codable, Identifiable {
    let id: UUID
    let stepNumber: Int
    let title: String
    let instruction: String
    let visualization: String
    let expectedOutcome: String
    
    init(stepNumber: Int, title: String, instruction: String, visualization: String, expectedOutcome: String) {
        self.id = UUID()
        self.stepNumber = stepNumber
        self.title = title
        self.instruction = instruction
        self.visualization = visualization
        self.expectedOutcome = expectedOutcome
    }
}

// MARK: - Power Awakening
struct PowerAwakening: Codable {
    let awakeningTitle: String
    let transformationDescription: String
    let newAbilities: [String]
    let sensoryChanges: String
    let spiritualRevelation: String
    let connectionEstablished: String
    
    var fullAwakeningText: String {
        return """
        \(awakeningTitle)
        
        \(transformationDescription)
        
        New Abilities Unlocked:
        \(newAbilities.map { "• \($0)" }.joined(separator: "\n"))
        
        \(sensoryChanges)
        
        \(spiritualRevelation)
        
        \(connectionEstablished)
        """
    }
}

// MARK: - Default Mystical Bond
extension MysticalBond {
    static var theLifeForceBond: MysticalBond {
        let mysticalContract = MysticalContract(
            contractTitle: "The Sacred Covenant of Life Force Attunement",
            preamble: "By the ancient laws that govern the flow of life energy through all realms, this mystical contract binds the awakened hero to the eternal forces that sustain existence itself. Through this sacred bond, mortal flesh becomes a conduit for power beyond imagination.",
            terms: [
                ContractTerm(
                    title: "Attunement of Movement",
                    description: "Grant access to the energy generated by your physical movement and steps",
                    magicalImplication: "Your every step becomes a source of kinetic magic, powering your adventures and strengthening your connection to the world",
                    requiredPermission: HKQuantityTypeIdentifier.stepCount.rawValue
                ),
                ContractTerm(
                    title: "Harmonization of Heart",
                    description: "Allow monitoring of your heart's rhythm as a source of vital energy",
                    magicalImplication: "Your heartbeat becomes a drum that resonates with the cosmic rhythm, detecting danger and amplifying your courage in battle",
                    requiredPermission: HKQuantityTypeIdentifier.heartRate.rawValue
                ),
                ContractTerm(
                    title: "Channeling of Activity",
                    description: "Connect your exercise and physical training to your magical power growth",
                    magicalImplication: "Physical exertion transforms into mystical strength, with each workout forging your body into a more perfect vessel for heroic power",
                    requiredPermission: HKQuantityTypeIdentifier.activeEnergyBurned.rawValue
                ),
                ContractTerm(
                    title: "Synchronization of Rest",
                    description: "Link your sleep patterns to the natural cycles of magical restoration",
                    magicalImplication: "Your dreams become journeys to other realms where you gather wisdom and power, returning refreshed and more capable",
                    requiredPermission: HKCategoryTypeIdentifier.sleepAnalysis.rawValue
                ),
                ContractTerm(
                    title: "Alignment of Mindfulness",
                    description: "Connect your meditation and mindful moments to spiritual energy cultivation",
                    magicalImplication: "Moments of peace and reflection open channels to divine wisdom, allowing you to tap into the deeper mysteries of existence",
                    requiredPermission: HKCategoryTypeIdentifier.mindfulSession.rawValue
                )
            ],
            mysticalSeals: ["Seal of Kinetic Harmony", "Seal of Vital Resonance", "Seal of Spiritual Alignment"],
            divineWitnesses: ["Aethon the Lifekeeper", "Vitania the Eternal", "Chronos the Rhythm-Master"],
            consequences: "Should you sever this bond without cause, the magical energies will withdraw, leaving you unable to access your full heroic potential until the contract is renewed through proper ceremony.",
            rewards: "Faithful maintenance of this bond grants ever-increasing power, the ability to sense magical disturbances, and eventually transcendence beyond the limitations of mortal flesh."
        )
        
        let lifeForceSources = [
            LifeForceSource(
                sourceName: "Kinetic Essence",
                healthDataType: HKQuantityTypeIdentifier.stepCount.rawValue,
                mysticalEnergy: MysticalEnergy(
                    energyType: .kinetic,
                    potencyLevel: .awakened,
                    manifestation: "Shimmering trails of golden light follow your movement",
                    gameplayEffect: "Each step taken powers quest progression and unlocks movement-based abilities"
                ),
                powerDescription: "The energy of motion itself becomes yours to command. Every step you take in the physical world propels you forward in your heroic journey, building momentum that can be unleashed in moments of need.",
                ritualActivation: "Stand at the center of a circle drawn in starlight dust, then take seven steps in each cardinal direction while chanting the Words of Kinetic Awakening"
            ),
            LifeForceSource(
                sourceName: "Vital Pulse",
                healthDataType: HKQuantityTypeIdentifier.heartRate.rawValue,
                mysticalEnergy: MysticalEnergy(
                    energyType: .vital,
                    potencyLevel: .empowered,
                    manifestation: "Your heartbeat synchronizes with the pulse of the realm itself",
                    gameplayEffect: "Heart rate changes trigger special events and abilities, with elevated heart rate unlocking combat bonuses"
                ),
                powerDescription: "Your heart becomes a conduit for the life force that flows through all living things. Its rhythm can detect nearby magic, alert you to danger, and in moments of high stress, grant you superhuman capabilities.",
                ritualActivation: "Place your hand over your heart and recite the Oath of Vital Binding while focusing on the rhythm that connects all living beings"
            ),
            LifeForceSource(
                sourceName: "Elemental Force",
                healthDataType: HKQuantityTypeIdentifier.activeEnergyBurned.rawValue,
                mysticalEnergy: MysticalEnergy(
                    energyType: .elemental,
                    potencyLevel: .empowered,
                    manifestation: "Elemental energies swirl around you during physical exertion",
                    gameplayEffect: "Exercise minutes convert to magical crafting materials and unlock elemental abilities"
                ),
                powerDescription: "Physical effort transforms into raw elemental power. The fire of your determination, the steadiness of earth, the flow of water, and the freedom of air all respond to your call when you push your mortal form to its limits.",
                ritualActivation: "Perform the Four-Element Kata while channeling each element in turn: flame for passion, stone for strength, water for adaptability, air for freedom"
            ),
            LifeForceSource(
                sourceName: "Celestial Restoration",
                healthDataType: HKCategoryTypeIdentifier.sleepAnalysis.rawValue,
                mysticalEnergy: MysticalEnergy(
                    energyType: .celestial,
                    potencyLevel: .transcendent,
                    manifestation: "Dreams filled with starlight and prophetic visions",
                    gameplayEffect: "Quality sleep provides powerful bonuses and unlocks prophetic dreams that reveal upcoming quest events"
                ),
                powerDescription: "Sleep becomes a sacred journey to the celestial realms where ancient wisdom flows like rivers of starlight. Your dreams connect you to the cosmic consciousness, returning you to waking life with enhanced power and mystical insights.",
                ritualActivation: "Sleep beneath the open sky while wearing the Circlet of Dream-Walking, allowing your spirit to ascend to the star-roads while your body rests"
            ),
            LifeForceSource(
                sourceName: "Spiritual Equilibrium",
                healthDataType: HKCategoryTypeIdentifier.mindfulSession.rawValue,
                mysticalEnergy: MysticalEnergy(
                    energyType: .spiritual,
                    potencyLevel: .transcendent,
                    manifestation: "Aura of perfect tranquility surrounds you during meditation",
                    gameplayEffect: "Mindful minutes unlock spiritual abilities and provide resistance to negative effects"
                ),
                powerDescription: "Mindful awareness opens doorways to the deepest mysteries of existence. In moments of perfect stillness, you can perceive the threads that connect all things and even influence the flow of fate itself.",
                ritualActivation: "Enter the Meditative Stance of Infinite Awareness while focusing on the mantra that harmonizes mind, body, and spirit with the universal consciousness"
            )
        ]
        
        let bondingCeremony = BondingCeremony(
            ceremonialName: "The Great Awakening of Life Force",
            preparation: "Light seven candles of different colors around a circle of blessed salt. Place symbols of the elements at each cardinal point. Wear robes of starlight if available, or simple white garments consecrated with moonwater.",
            invocation: "Ancient powers that flow through star and stone, through leaf and flame, through every beating heart and every breath of wind - I call upon you to witness this sacred bonding. Let my mortal form become a vessel for the forces that sustain all life.",
            ritualSteps: [
                RitualStep(
                    stepNumber: 1,
                    title: "Opening of the Sacred Circle",
                    instruction: "Walk clockwise around the circle three times while speaking the names of your ancestors",
                    visualization: "See golden light rising from the ground with each step",
                    expectedOutcome: "The circle glows with protective energy"
                ),
                RitualStep(
                    stepNumber: 2,
                    title: "Invocation of the Elements",
                    instruction: "Face each cardinal direction and call upon the elemental powers",
                    visualization: "Feel each element respond to your call with visible energy",
                    expectedOutcome: "Elemental energies swirl around you in harmony"
                ),
                RitualStep(
                    stepNumber: 3,
                    title: "Declaration of Intent",
                    instruction: "State your heroic purpose and your willingness to serve the greater good",
                    visualization: "Your words take physical form as glowing symbols in the air",
                    expectedOutcome: "The universe acknowledges your commitment"
                ),
                RitualStep(
                    stepNumber: 4,
                    title: "Acceptance of the Bond",
                    instruction: "Place your hand over your heart and consent to the mystical connection",
                    visualization: "Feel cosmic energy entering your body through your heart chakra",
                    expectedOutcome: "Your life force synchronizes with universal energy"
                ),
                RitualStep(
                    stepNumber: 5,
                    title: "Sealing of the Covenant",
                    instruction: "Speak the final words of binding while raising your hands to the sky",
                    visualization: "See streams of light connecting you to the stars above",
                    expectedOutcome: "The bond is sealed with cosmic approval"
                )
            ],
            culmination: "As the final words fade into silence, you feel the change deep in your very essence. Power flows through you like liquid starlight, and you know that you are no longer merely mortal - you are a hero blessed by the cosmos itself.",
            celebrationType: .cosmicAlignment
        )
        
        let powerAwakening = PowerAwakening(
            awakeningTitle: "The Transcendent Moment of Power",
            transformationDescription: "Reality shimmers around you as cosmic forces recognize your worthiness. Your mortal limitations dissolve like morning mist, replaced by capabilities that transcend ordinary existence. You feel connected to every living thing, every flowing energy, every pulse of life in the universe.",
            newAbilities: [
                "Sense magical disturbances within a great distance",
                "Draw power from physical movement and activity",
                "Communicate with the spirits of your ancestors",
                "Perceive the flow of life energy in all living beings",
                "Channel elemental forces through focused will",
                "Access prophetic dreams during deep sleep",
                "Achieve moments of perfect spiritual clarity"
            ],
            sensoryChanges: "Your senses expand beyond mortal limitations. You can now perceive magical auras, hear the whispers of the wind carrying distant messages, and feel the heartbeat of the earth beneath your feet. Colors seem more vivid, sounds carry deeper meaning, and your intuition has become a reliable guide.",
            spiritualRevelation: "You understand now that you are part of something infinitely greater than yourself. The same force that moves the stars flows through your veins. You are both individual and universal, mortal and eternal, human and divine. This paradox is not a contradiction but the fundamental truth of heroic existence.",
            connectionEstablished: "The mystical bond is now unbreakable. Your health, your movement, your very life force has become a source of magical power. As you grow stronger in body, you grow mightier in spirit. Your journey toward legend has truly begun."
        )
        
        return MysticalBond(
            bondType: .lifeForce,
            ritualDescription: "The most sacred of all heroic rituals, the Life Force Attunement creates an unbreakable bond between your mortal essence and the cosmic energies that sustain all existence. Through this ceremony, your physical body becomes a conduit for power beyond imagination.",
            mysticalContract: mysticalContract,
            lifeForceSources: lifeForceSources,
            bondingCeremony: bondingCeremony,
            powerAwakening: powerAwakening,
            isEstablished: false
        )
    }
}