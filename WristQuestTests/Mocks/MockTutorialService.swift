import Foundation
@testable import WristQuest_Watch_App

/// Mock implementation of TutorialService for testing
class MockTutorialService: TutorialServiceProtocol {
    
    // MARK: - Mock Data Storage
    
    /// Pre-defined tutorial quests for different hero classes
    private var tutorialQuests: [HeroClass: TutorialQuest] = [:]
    
    /// Stage progression mapping
    private let stageProgression: [TutorialStage: TutorialStage] = [
        .notStarted: .introduction,
        .introduction: .basicMovement,
        .basicMovement: .encounter,
        .encounter: .rewards,
        .rewards: .completion,
        .completion: .completion // Stay at completion
    ]
    
    /// Stage progress percentages
    private let stageProgressMap: [TutorialStage: Double] = [
        .notStarted: 0.0,
        .introduction: 0.2,
        .basicMovement: 0.4,
        .encounter: 0.6,
        .rewards: 0.8,
        .completion: 1.0
    ]
    
    // MARK: - Mock Control Properties
    
    /// Control whether operations should fail
    var shouldFailCreateQuest = false
    var shouldFailCreateRewards = false
    var shouldFailGetDialogue = false
    var shouldFailGetEncounter = false
    
    /// Control specific errors to return
    var createQuestError: Error?
    var createRewardsError: Error?
    
    /// Track method calls for verification
    var createTutorialQuestCallCount = 0
    var getNextStageCallCount = 0
    var getStageProgressCallCount = 0
    var getNarrativeCallCount = 0
    var getDialogueCallCount = 0
    var getEncounterCallCount = 0
    var createRewardsCallCount = 0
    
    /// Control custom content for testing
    var customNarratives: [TutorialStage: [HeroClass: String]] = [:]
    var customDialogues: [TutorialStage: [HeroClass: TutorialDialogue]] = [:]
    var customEncounters: [HeroClass: TutorialEncounter] = [:]
    var customRewards: [HeroClass: TutorialRewards] = [:]
    
    // MARK: - Protocol Implementation
    
    func createTutorialQuest(for heroClass: HeroClass) -> TutorialQuest {
        createTutorialQuestCallCount += 1
        
        if shouldFailCreateQuest {
            // In a real scenario, this might throw an error
            // For testing, we'll return a minimal quest
            return TutorialQuest(
                id: UUID(),
                heroClass: heroClass,
                title: "Failed Tutorial",
                description: "Tutorial creation failed",
                stages: [],
                currentStage: .notStarted,
                isCompleted: false
            )
        }
        
        // Return cached quest if available
        if let existingQuest = tutorialQuests[heroClass] {
            return existingQuest
        }
        
        // Create new tutorial quest
        let quest = createDefaultTutorialQuest(for: heroClass)
        tutorialQuests[heroClass] = quest
        return quest
    }
    
    func getNextStage(from currentStage: TutorialStage) -> TutorialStage {
        getNextStageCallCount += 1
        return stageProgression[currentStage] ?? .completion
    }
    
    func getStageProgress(for stage: TutorialStage) -> Double {
        getStageProgressCallCount += 1
        return stageProgressMap[stage] ?? 0.0
    }
    
    func getNarrative(for stage: TutorialStage, heroClass: HeroClass) -> String {
        getNarrativeCallCount += 1
        
        // Check for custom narrative first
        if let customNarrative = customNarratives[stage]?[heroClass] {
            return customNarrative
        }
        
        return getDefaultNarrative(for: stage, heroClass: heroClass)
    }
    
    func getDialogue(for stage: TutorialStage, heroClass: HeroClass) -> TutorialDialogue {
        getDialogueCallCount += 1
        
        if shouldFailGetDialogue {
            return TutorialDialogue(
                speaker: "Error",
                message: "Failed to load dialogue",
                options: ["Continue"],
                isSkippable: true
            )
        }
        
        // Check for custom dialogue first
        if let customDialogue = customDialogues[stage]?[heroClass] {
            return customDialogue
        }
        
        return getDefaultDialogue(for: stage, heroClass: heroClass)
    }
    
    func getEncounter(for heroClass: HeroClass) -> TutorialEncounter {
        getEncounterCallCount += 1
        
        if shouldFailGetEncounter {
            return TutorialEncounter(
                id: UUID(),
                heroClass: heroClass,
                type: .combat,
                description: "Failed to load encounter",
                difficulty: .easy,
                successRate: 0.5,
                rewards: TutorialRewards()
            )
        }
        
        // Check for custom encounter first
        if let customEncounter = customEncounters[heroClass] {
            return customEncounter
        }
        
        return getDefaultEncounter(for: heroClass)
    }
    
    func createRewards(for heroClass: HeroClass) -> TutorialRewards {
        createRewardsCallCount += 1
        
        if shouldFailCreateRewards {
            return TutorialRewards() // Empty rewards on failure
        }
        
        // Check for custom rewards first
        if let customReward = customRewards[heroClass] {
            return customReward
        }
        
        return getDefaultRewards(for: heroClass)
    }
    
    // MARK: - Default Content Creation
    
    private func createDefaultTutorialQuest(for heroClass: HeroClass) -> TutorialQuest {
        let titles: [HeroClass: String] = [
            .warrior: "The Warrior's Path",
            .mage: "Arcane Awakening",
            .rogue: "Shadow Training",
            .ranger: "Nature's Calling",
            .cleric: "Divine Purpose"
        ]
        
        let descriptions: [HeroClass: String] = [
            .warrior: "Learn the ways of combat and valor",
            .mage: "Master the arcane arts and mystical forces",
            .rogue: "Perfect stealth and cunning techniques",
            .ranger: "Understand the harmony of nature and wilderness",
            .cleric: "Embrace divine power and healing wisdom"
        ]
        
        return TutorialQuest(
            id: UUID(),
            heroClass: heroClass,
            title: titles[heroClass] ?? "Tutorial Quest",
            description: descriptions[heroClass] ?? "Learn your class basics",
            stages: Array(TutorialStage.allCases),
            currentStage: .notStarted,
            isCompleted: false
        )
    }
    
    private func getDefaultNarrative(for stage: TutorialStage, heroClass: HeroClass) -> String {
        switch (stage, heroClass) {
        case (.introduction, .warrior):
            return "Welcome, warrior! Your journey of strength and honor begins now."
        case (.introduction, .mage):
            return "Greetings, mage! The arcane mysteries await your discovery."
        case (.introduction, .rogue):
            return "Welcome, rogue! The shadows will be your greatest ally."
        case (.introduction, .ranger):
            return "Welcome, ranger! Nature itself will guide your path."
        case (.introduction, .cleric):
            return "Welcome, cleric! Divine light illuminates your sacred journey."
            
        case (.basicMovement, _):
            return "Learn to navigate the realm using your steps and movement."
            
        case (.encounter, _):
            return "Prepare for your first encounter! Choose your actions wisely."
            
        case (.rewards, _):
            return "Excellent! You've earned your first rewards. Your legend grows."
            
        case (.completion, _):
            return "Tutorial complete! You are now ready for true adventures."
            
        default:
            return "Continue your training, brave adventurer."
        }
    }
    
    private func getDefaultDialogue(for stage: TutorialStage, heroClass: HeroClass) -> TutorialDialogue {
        let speakers: [HeroClass: String] = [
            .warrior: "Battle Master",
            .mage: "Archmage",
            .rogue: "Shadow Mentor",
            .ranger: "Beast Lord",
            .cleric: "High Priest"
        ]
        
        let speaker = speakers[heroClass] ?? "Mentor"
        let message = getNarrative(for: stage, heroClass: heroClass)
        
        let options: [String]
        let isSkippable: Bool
        
        switch stage {
        case .introduction:
            options = ["I'm ready!", "Tell me more", "What should I know?"]
            isSkippable = false
        case .basicMovement:
            options = ["Let's practice", "How does it work?"]
            isSkippable = true
        case .encounter:
            options = ["I'm prepared", "Give me tips"]
            isSkippable = true
        case .rewards:
            options = ["Claim rewards", "What did I earn?"]
            isSkippable = true
        case .completion:
            options = ["Begin my journey!", "Review training"]
            isSkippable = true
        default:
            options = ["Continue"]
            isSkippable = true
        }
        
        return TutorialDialogue(
            speaker: speaker,
            message: message,
            options: options,
            isSkippable: isSkippable
        )
    }
    
    private func getDefaultEncounter(for heroClass: HeroClass) -> TutorialEncounter {
        let encounterTypes: [HeroClass: EncounterType] = [
            .warrior: .combat,
            .mage: .discovery,
            .rogue: .decision,
            .ranger: .discovery,
            .cleric: .decision
        ]
        
        let descriptions: [HeroClass: String] = [
            .warrior: "A training dummy stands before you. Practice your combat skills!",
            .mage: "A magical crystal pulses with energy. Study its arcane properties.",
            .rogue: "Multiple paths diverge ahead. Choose your route carefully.",
            .ranger: "Animal tracks lead in different directions. Which will you follow?",
            .cleric: "A wounded traveler needs aid. How will you help?"
        ]
        
        let difficulties: [HeroClass: TutorialDifficulty] = [
            .warrior: .easy,
            .mage: .medium,
            .rogue: .medium,
            .ranger: .easy,
            .cleric: .easy
        ]
        
        let successRates: [HeroClass: Double] = [
            .warrior: 0.9,
            .mage: 0.8,
            .rogue: 0.85,
            .ranger: 0.9,
            .cleric: 0.95
        ]
        
        return TutorialEncounter(
            id: UUID(),
            heroClass: heroClass,
            type: encounterTypes[heroClass] ?? .combat,
            description: descriptions[heroClass] ?? "A tutorial encounter awaits.",
            difficulty: difficulties[heroClass] ?? .easy,
            successRate: successRates[heroClass] ?? 0.8,
            rewards: getDefaultRewards(for: heroClass)
        )
    }
    
    private func getDefaultRewards(for heroClass: HeroClass) -> TutorialRewards {
        let baseXP = 50
        let baseGold = 25
        
        let classMultipliers: [HeroClass: Double] = [
            .warrior: 1.0,
            .mage: 1.2,
            .rogue: 0.9,
            .ranger: 1.1,
            .cleric: 1.0
        ]
        
        let multiplier = classMultipliers[heroClass] ?? 1.0
        
        let items: [HeroClass: Item] = [
            .warrior: TestDataFactory.createValidItem(name: "Training Sword", type: .weapon),
            .mage: TestDataFactory.createValidItem(name: "Apprentice Staff", type: .weapon),
            .rogue: TestDataFactory.createValidItem(name: "Practice Dagger", type: .weapon),
            .ranger: TestDataFactory.createValidItem(name: "Simple Bow", type: .weapon),
            .cleric: TestDataFactory.createValidItem(name: "Holy Symbol", type: .trinket)
        ]
        
        let bonuses: [HeroClass: String] = [
            .warrior: "Gained Warrior's Resolve: +10% combat effectiveness",
            .mage: "Learned Mana Focus: +15% spell power",
            .rogue: "Mastered Shadow Step: +20% stealth success",
            .ranger: "Earned Nature's Bond: +10% outdoor quest progress",
            .cleric: "Received Divine Blessing: +5% healing effectiveness"
        ]
        
        return TutorialRewards(
            xp: Int(Double(baseXP) * multiplier),
            gold: Int(Double(baseGold) * multiplier),
            item: items[heroClass],
            classSpecificBonus: bonuses[heroClass] ?? "Tutorial completed successfully"
        )
    }
    
    // MARK: - Mock Control Methods
    
    /// Reset all mock state
    func reset() {
        tutorialQuests.removeAll()
        customNarratives.removeAll()
        customDialogues.removeAll()
        customEncounters.removeAll()
        customRewards.removeAll()
        
        shouldFailCreateQuest = false
        shouldFailCreateRewards = false
        shouldFailGetDialogue = false
        shouldFailGetEncounter = false
        
        createQuestError = nil
        createRewardsError = nil
        
        // Reset call counts
        createTutorialQuestCallCount = 0
        getNextStageCallCount = 0
        getStageProgressCallCount = 0
        getNarrativeCallCount = 0
        getDialogueCallCount = 0
        getEncounterCallCount = 0
        createRewardsCallCount = 0
    }
    
    /// Set custom content for testing specific scenarios
    func setCustomNarrative(for stage: TutorialStage, heroClass: HeroClass, narrative: String) {
        if customNarratives[stage] == nil {
            customNarratives[stage] = [:]
        }
        customNarratives[stage]?[heroClass] = narrative
    }
    
    func setCustomDialogue(for stage: TutorialStage, heroClass: HeroClass, dialogue: TutorialDialogue) {
        if customDialogues[stage] == nil {
            customDialogues[stage] = [:]
        }
        customDialogues[stage]?[heroClass] = dialogue
    }
    
    func setCustomEncounter(for heroClass: HeroClass, encounter: TutorialEncounter) {
        customEncounters[heroClass] = encounter
    }
    
    func setCustomRewards(for heroClass: HeroClass, rewards: TutorialRewards) {
        customRewards[heroClass] = rewards
    }
    
    /// Get the cached tutorial quest for verification
    func getCachedTutorialQuest(for heroClass: HeroClass) -> TutorialQuest? {
        return tutorialQuests[heroClass]
    }
    
    /// Verify that specific content was requested
    func verifyStageProgression(from startStage: TutorialStage, to endStage: TutorialStage) -> Bool {
        var currentStage = startStage
        var steps = 0
        let maxSteps = 10 // Prevent infinite loops
        
        while currentStage != endStage && steps < maxSteps {
            currentStage = getNextStage(from: currentStage)
            steps += 1
        }
        
        return currentStage == endStage
    }
}

// MARK: - Test Helper Extensions

extension MockTutorialService {
    /// Create pre-configured mock that fails quest creation
    static func failingQuestCreationMock() -> MockTutorialService {
        let mock = MockTutorialService()
        mock.shouldFailCreateQuest = true
        return mock
    }
    
    /// Create pre-configured mock that fails reward creation
    static func failingRewardsMock() -> MockTutorialService {
        let mock = MockTutorialService()
        mock.shouldFailCreateRewards = true
        return mock
    }
    
    /// Create pre-configured mock with custom content for all classes
    static func withCustomContent() -> MockTutorialService {
        let mock = MockTutorialService()
        
        // Add custom content for testing
        for heroClass in HeroClass.allCases {
            mock.setCustomNarrative(
                for: .introduction,
                heroClass: heroClass,
                narrative: "Custom introduction for \(heroClass.rawValue)"
            )
            
            let customDialogue = TutorialDialogue(
                speaker: "Custom Mentor",
                message: "Custom tutorial message",
                options: ["Custom Option 1", "Custom Option 2"],
                isSkippable: true
            )
            mock.setCustomDialogue(for: .introduction, heroClass: heroClass, dialogue: customDialogue)
        }
        
        return mock
    }
    
    /// Convenience method to verify tutorial progression
    func verifyTutorialFlow(for heroClass: HeroClass) -> Bool {
        let quest = createTutorialQuest(for: heroClass)
        let hasValidTitle = !quest.title.isEmpty
        let hasValidDescription = !quest.description.isEmpty
        let hasStages = !quest.stages.isEmpty
        
        return hasValidTitle && hasValidDescription && hasStages
    }
}

// MARK: - TutorialDifficulty Extension for Testing

enum TutorialDifficulty: String, CaseIterable {
    case easy = "easy"
    case medium = "medium"
    case hard = "hard"
}