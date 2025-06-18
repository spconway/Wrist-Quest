import Foundation
import SwiftUI
import Combine

@MainActor
class QuestViewModel: ObservableObject {
    @Published var availableQuests: [Quest] = []
    @Published var activeQuest: Quest?
    @Published var completedQuests: [QuestLog] = []
    @Published var isLoading = false
    
    // Fantasy Tutorial Quest State
    @Published var tutorialQuest: TutorialQuest?
    @Published var tutorialStage: TutorialStage = .notStarted
    @Published var tutorialDialogue: TutorialDialogue?
    @Published var tutorialProgress: Double = 0.0
    @Published var isShowingTutorialEffects = false
    @Published var tutorialEncounter: TutorialEncounter?
    @Published var tutorialRewards: TutorialRewards = TutorialRewards()
    @Published var tutorialNarrative: String = ""
    
    private var cancellables = Set<AnyCancellable>()
    private let persistenceService: PersistenceServiceProtocol
    private let healthService: HealthServiceProtocol
    private let playerViewModel: PlayerViewModel
    
    init(playerViewModel: PlayerViewModel,
         persistenceService: PersistenceServiceProtocol = PersistenceService(),
         healthService: HealthServiceProtocol = HealthService()) {
        self.playerViewModel = playerViewModel
        self.persistenceService = persistenceService
        self.healthService = healthService
        
        setupSubscriptions()
        loadQuests()
        loadActiveQuest()
        generateInitialQuests()
    }
    
    private func setupSubscriptions() {
        healthService.healthDataPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] healthData in
                self?.updateQuestProgress(with: healthData)
            }
            .store(in: &cancellables)
    }
    
    func startQuest(_ quest: Quest) {
        var updatedQuest = quest
        updatedQuest.currentProgress = 0
        updatedQuest.isCompleted = false
        
        activeQuest = updatedQuest
        availableQuests.removeAll { $0.id == quest.id }
        
        // Trigger quest beginning epic moment
        triggerQuestEpicMoment(.questBegin(quest.title))
        
        saveActiveQuest()
        saveQuests()
    }
    
    func completeQuest() {
        guard let quest = activeQuest else { return }
        
        // Trigger quest completion epic moment
        triggerQuestEpicMoment(.questComplete(quest.title))
        
        let questLog = QuestLog(
            questId: quest.id,
            questName: quest.title,
            summary: quest.description,
            rewards: QuestRewards(xp: quest.rewardXP, gold: quest.rewardGold)
        )
        
        completedQuests.append(questLog)
        playerViewModel.player.journal.append(questLog)
        playerViewModel.addXP(quest.rewardXP)
        playerViewModel.addGold(quest.rewardGold)
        
        activeQuest = nil
        generateNewQuests()
        clearActiveQuest()
        saveQuests()
    }
    
    func cancelQuest() {
        guard let quest = activeQuest else { return }
        
        var restoredQuest = quest
        restoredQuest.currentProgress = 0
        restoredQuest.isCompleted = false
        
        availableQuests.append(restoredQuest)
        activeQuest = nil
        
        clearActiveQuest()
        saveQuests()
    }
    
    private func updateQuestProgress(with healthData: HealthData) {
        guard var quest = activeQuest else { return }
        
        let stepsToDistance = calculateStepsToDistance(healthData.steps)
        let classModifier = getClassDistanceModifier()
        
        quest.currentProgress = stepsToDistance * classModifier
        
        if quest.currentProgress >= quest.totalDistance {
            quest.currentProgress = quest.totalDistance
            quest.isCompleted = true
            activeQuest = quest
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.completeQuest()
            }
        } else {
            activeQuest = quest
        }
        
        saveActiveQuest()
    }
    
    private func calculateStepsToDistance(_ steps: Int) -> Double {
        return Double(steps) / 100.0
    }
    
    private func getClassDistanceModifier() -> Double {
        switch playerViewModel.player.activeClass {
        case .rogue:
            return 1.33
        case .ranger:
            return 1.15
        case .warrior:
            return 1.1
        default:
            return 1.0
        }
    }
    
    private func generateInitialQuests() {
        if availableQuests.isEmpty {
            availableQuests = generateFantasyQuests()
            saveQuests()
        }
    }
    
    private func generateFantasyQuests() -> [Quest] {
        return [
            Quest(
                title: "The Whispering Woods",
                description: "Ancient spirits call from the enchanted forest depths",
                totalDistance: 50.0,
                rewardXP: 100,
                rewardGold: 25
            ),
            Quest(
                title: "Merchant's Peril",
                description: "Protect the sacred caravan from shadow creatures",
                totalDistance: 75.0,
                rewardXP: 150,
                rewardGold: 40
            ),
            Quest(
                title: "The Crimson Wyrm",
                description: "Face the ancient dragon lord of the flame peaks",
                totalDistance: 100.0,
                rewardXP: 300,
                rewardGold: 100
            ),
            Quest(
                title: "Moonlit Sanctum",
                description: "Explore the forgotten temple under starlight",
                totalDistance: 60.0,
                rewardXP: 120,
                rewardGold: 30
            )
        ]
    }
    
    private func generateNewQuests() {
        let playerLevel = playerViewModel.player.level
        let questTemplates = getQuestTemplates(for: playerLevel)
        
        let newQuest = questTemplates.randomElement()!
        availableQuests.append(newQuest)
    }
    
    private func getQuestTemplates(for level: Int) -> [Quest] {
        let baseXP = 50 + (level * 25)
        let baseGold = 10 + (level * 5)
        let baseDistance = 25.0 + (Double(level) * 10.0)
        
        let questTemplates = [
            ("The Sunken Crypts", "Delve into waterlogged tombs of forgotten kings"),
            ("Shadowmere Crossing", "Navigate the treacherous bridge over dark waters"),
            ("The Singing Stones", "Discover the melody that awakens ancient magic"),
            ("Wraith's Hollow", "Banish the restless spirits from their cursed domain"),
            ("The Crystal Caverns", "Harvest mystical gems from the living mountain"),
            ("Phoenix Nesting Grounds", "Seek the legendary firebird's sacred feathers"),
            ("The Starfall Crater", "Investigate the celestial impact site"),
            ("Thornwood Labyrinth", "Navigate the ever-shifting maze of thorns")
        ]
        
        return questTemplates.shuffled().prefix(3).map { template in
            Quest(
                title: template.0,
                description: template.1,
                totalDistance: baseDistance * Double.random(in: 0.8...1.5),
                rewardXP: Int(Double(baseXP) * Double.random(in: 0.9...1.4)),
                rewardGold: Int(Double(baseGold) * Double.random(in: 0.8...1.6))
            )
        }
    }
    
    private func loadQuests() {
        isLoading = true
        
        Task {
            do {
                completedQuests = try await persistenceService.loadQuestLogs()
            } catch {
                print("Failed to load quest logs: \(error)")
            }
            
            isLoading = false
        }
    }
    
    private func saveQuests() {
        Task {
            do {
                try await persistenceService.saveQuestLogs(completedQuests)
            } catch {
                print("Failed to save quests: \(error)")
            }
        }
    }
    
    private func saveActiveQuest() {
        guard let quest = activeQuest else { return }
        
        Task {
            do {
                try await persistenceService.saveActiveQuest(quest)
            } catch {
                print("Failed to save active quest: \(error)")
            }
        }
    }
    
    private func loadActiveQuest() {
        Task {
            do {
                activeQuest = try await persistenceService.loadActiveQuest()
            } catch {
                print("Failed to load active quest: \(error)")
            }
        }
    }
    
    private func clearActiveQuest() {
        Task {
            do {
                try await persistenceService.clearActiveQuest()
            } catch {
                print("Failed to clear active quest: \(error)")
            }
        }
    }
    
    // MARK: - Tutorial Quest Management
    
    func startTutorialQuest(for heroClass: HeroClass) {
        tutorialQuest = createTutorialQuest(for: heroClass)
        tutorialStage = .introduction
        tutorialProgress = 0.0
        
        // Set initial narrative
        updateTutorialNarrative()
        
        // Start tutorial sequence
        progressTutorialStage()
    }
    
    func advanceTutorialQuest() {
        switch tutorialStage {
        case .notStarted:
            tutorialStage = .introduction
        case .introduction:
            tutorialStage = .firstChallenge
        case .firstChallenge:
            tutorialStage = .encounter
        case .encounter:
            tutorialStage = .finalTest
        case .finalTest:
            tutorialStage = .completion
        case .completion:
            completeTutorialQuest()
        }
        
        progressTutorialStage()
    }
    
    private func createTutorialQuest(for heroClass: HeroClass) -> TutorialQuest {
        let questData: (title: String, description: String, narrative: String) = {
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
        }()
        
        return TutorialQuest(
            title: questData.title,
            description: questData.description,
            narrative: questData.narrative,
            heroClass: heroClass,
            totalSteps: 5,
            currentStep: 0
        )
    }
    
    private func progressTutorialStage() {
        updateTutorialProgress()
        updateTutorialNarrative()
        createTutorialDialogue()
        
        if tutorialStage == .encounter {
            createTutorialEncounter()
        }
        
        triggerTutorialEffects()
    }
    
    private func updateTutorialProgress() {
        let stageProgress: Double = {
            switch tutorialStage {
            case .notStarted: return 0.0
            case .introduction: return 0.2
            case .firstChallenge: return 0.4
            case .encounter: return 0.6
            case .finalTest: return 0.8
            case .completion: return 1.0
            }
        }()
        
        tutorialProgress = stageProgress
    }
    
    private func updateTutorialNarrative() {
        guard let quest = tutorialQuest else { return }
        
        let narratives: [TutorialStage: [HeroClass: String]] = [
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
        
        tutorialNarrative = narratives[tutorialStage]?[quest.heroClass] ?? "Your journey continues..."
    }
    
    private func createTutorialDialogue() {
        guard let quest = tutorialQuest else { return }
        
        let dialogues: [TutorialStage: TutorialDialogue] = [
            .introduction: TutorialDialogue(
                speaker: "Training Master",
                text: "Welcome, \(quest.heroClass.rawValue.capitalized). Your trial begins now.",
                options: ["I am ready", "Tell me more about the trial"]
            ),
            .firstChallenge: TutorialDialogue(
                speaker: "Mentor",
                text: "Show me what you've learned. Execute your first technique.",
                options: ["Demonstrate skill", "Ask for guidance"]
            ),
            .encounter: TutorialDialogue(
                speaker: "Spectral Guardian",
                text: "Face me in combat, young \(quest.heroClass.rawValue)!",
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
        
        tutorialDialogue = dialogues[tutorialStage]
    }
    
    private func createTutorialEncounter() {
        guard let quest = tutorialQuest else { return }
        
        let encounters: [HeroClass: TutorialEncounter] = [
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
        
        tutorialEncounter = encounters[quest.heroClass]
    }
    
    private func triggerTutorialEffects() {
        isShowingTutorialEffects = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.isShowingTutorialEffects = false
        }
    }
    
    private func completeTutorialQuest() {
        guard let quest = tutorialQuest else { return }
        
        // Award tutorial rewards
        tutorialRewards = TutorialRewards(
            xp: 50,
            gold: 10,
            item: generateTutorialRewardItem(for: quest.heroClass),
            title: "\(quest.heroClass.rawValue.capitalized) Initiate"
        )
        
        // Trigger completion effects
        triggerQuestEpicMoment(.tutorialComplete)
        
        // Mark tutorial as complete
        tutorialStage = .completion
    }
    
    private func generateTutorialRewardItem(for heroClass: HeroClass) -> String {
        let items: [HeroClass: String] = [
            .warrior: "Apprentice's Sword",
            .mage: "Novice's Wand",
            .rogue: "Shadow Cloak",
            .ranger: "Hunter's Bow",
            .cleric: "Sacred Amulet"
        ]
        
        return items[heroClass] ?? "Training Gear"
    }
    
    func resetTutorialQuest() {
        tutorialQuest = nil
        tutorialStage = .notStarted
        tutorialDialogue = nil
        tutorialProgress = 0.0
        isShowingTutorialEffects = false
        tutorialEncounter = nil
        tutorialRewards = TutorialRewards()
        tutorialNarrative = ""
    }
    
    // MARK: - Epic Moments
    
    private func triggerQuestEpicMoment(_ moment: QuestEpicMoment) {
        // This could integrate with a global effects system
        // For now, we'll just trigger local effects
        
        switch moment {
        case .questBegin(let title):
            print("🗡️ Epic Moment: Quest '\(title)' begins!")
        case .questComplete(let title):
            print("🏆 Epic Moment: Quest '\(title)' completed!")
        case .tutorialComplete:
            print("🎓 Epic Moment: Tutorial quest mastered!")
        }
    }
}

// MARK: - Tutorial Supporting Types

struct TutorialQuest {
    let title: String
    let description: String
    let narrative: String
    let heroClass: HeroClass
    let totalSteps: Int
    var currentStep: Int
}

enum TutorialStage {
    case notStarted
    case introduction
    case firstChallenge
    case encounter
    case finalTest
    case completion
}

struct TutorialDialogue {
    let speaker: String
    let text: String
    let options: [String]
}

struct TutorialEncounter {
    let type: TutorialEncounterType
    let title: String
    let description: String
    let difficulty: TutorialDifficulty
    let successMessage: String
    let failureMessage: String
}

enum TutorialEncounterType {
    case combat
    case puzzle
    case stealth
    case nature
    case healing
}

enum TutorialDifficulty {
    case easy
    case medium
    case hard
}

struct TutorialRewards {
    var xp: Int = 0
    var gold: Int = 0
    var item: String = ""
    var title: String = ""
}

enum QuestEpicMoment {
    case questBegin(String)
    case questComplete(String)
    case tutorialComplete
}