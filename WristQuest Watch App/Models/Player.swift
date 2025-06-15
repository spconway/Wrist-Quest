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
    
    // MARK: - Onboarding & Fantasy Elements
    var heroOrigin: HeroOrigin?
    var mysticalBond: MysticalBond?
    var onboardingQuest: OnboardingQuest?
    var onboardingNarrative: OnboardingNarrative?
    var isAwakened: Bool // Has completed the mystical awakening process
    
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
        
        // Initialize onboarding elements
        self.heroOrigin = HeroOrigin.origin(for: activeClass)
        self.mysticalBond = MysticalBond.theLifeForceBond
        self.onboardingQuest = OnboardingQuest.theAwakening
        self.onboardingNarrative = OnboardingNarrative.theAwakeningNarrative
        self.isAwakened = false
    }
    
    // MARK: - Convenience Initializers
    init(name: String, activeClass: HeroClass, isAwakened: Bool) {
        self.init(name: name, activeClass: activeClass)
        self.isAwakened = isAwakened
        
        // If awakened, mark mystical bond as established
        if isAwakened {
            self.mysticalBond?.isEstablished = true
        }
    }
    
    // MARK: - Onboarding Methods
    mutating func completeOnboardingStep(_ action: OnboardingAction) {
        // Update narrative progress
        onboardingNarrative?.currentProgress.completedActions.append(action)
        
        // Update narrative phase based on progress
        let completedCount = onboardingNarrative?.currentProgress.completedActions.count ?? 0
        switch completedCount {
        case 1: onboardingNarrative?.currentProgress.currentPhase = .stirring
        case 2: onboardingNarrative?.currentProgress.currentPhase = .awakening
        case 3: onboardingNarrative?.currentProgress.currentPhase = .transforming
        case 4: onboardingNarrative?.currentProgress.currentPhase = .empowered
        case 5: 
            onboardingNarrative?.currentProgress.currentPhase = .legendary
            isAwakened = true
            mysticalBond?.isEstablished = true
        default: break
        }
    }
    
    func getOnboardingDialogue(for action: OnboardingAction) -> DialogueNode? {
        return onboardingNarrative?.dialogueTree.getDialogue(for: action)
    }
    
    func getEpicMoment(for action: OnboardingAction) -> EpicMoment? {
        return onboardingNarrative?.epicMoments.first { $0.triggerAction == action }
    }
    
    func getCelebrationEvent(for action: OnboardingAction) -> CelebrationEvent? {
        return onboardingNarrative?.celebrationEvents.first { $0.triggerMilestone == action }
    }
    
    var currentOnboardingPhase: String {
        return onboardingNarrative?.currentProgress.currentPhase.displayName ?? "Unknown"
    }
    
    var currentOnboardingPhaseDescription: String {
        return onboardingNarrative?.currentProgress.currentPhase.phaseDescription ?? "The journey awaits..."
    }
    
    // MARK: - Fantasy Lore Access
    var heroicTitle: String {
        guard let origin = heroOrigin else { return "Unknown Hero" }
        return "\(name) of the \(origin.homeland.name)"
    }
    
    var destinyDescription: String {
        return heroOrigin?.destinyProphecy ?? "Your destiny awaits discovery..."
    }
    
    var sacredOath: String {
        return heroOrigin?.sacredOath ?? "No oath has been sworn..."
    }
    
    var mysticalPowers: [String] {
        var powers: [String] = []
        
        if let bond = mysticalBond, bond.isEstablished {
            powers.append(contentsOf: bond.powerAwakening.newAbilities)
        }
        
        if let origin = heroOrigin {
            powers.append(origin.secretPower)
        }
        
        return powers
    }
    
    static var preview: Player {
        Player(name: "Hero", activeClass: .warrior)
    }
    
    static var previewAwakened: Player {
        Player(name: "Awakened Champion", activeClass: .mage, isAwakened: true)
    }
}