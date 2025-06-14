import Foundation
import SwiftUI
import Combine

@MainActor
class QuestViewModel: ObservableObject {
    @Published var availableQuests: [Quest] = []
    @Published var activeQuest: Quest?
    @Published var completedQuests: [QuestLog] = []
    @Published var isLoading = false
    
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
        
        saveQuests()
    }
    
    func completeQuest() {
        guard let quest = activeQuest else { return }
        
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
        saveQuests()
    }
    
    func cancelQuest() {
        guard let quest = activeQuest else { return }
        
        var restoredQuest = quest
        restoredQuest.currentProgress = 0
        restoredQuest.isCompleted = false
        
        availableQuests.append(restoredQuest)
        activeQuest = nil
        
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
        
        saveQuests()
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
            availableQuests = [
                Quest(
                    title: "Explore the Goblin Caves",
                    description: "Venture into the dark caverns beneath the forest",
                    totalDistance: 50.0,
                    rewardXP: 100,
                    rewardGold: 25
                ),
                Quest(
                    title: "Escort the Caravan",
                    description: "Protect merchants on their journey to market",
                    totalDistance: 75.0,
                    rewardXP: 150,
                    rewardGold: 40
                ),
                Quest(
                    title: "Slay the Dragon",
                    description: "Face the ancient beast terrorizing the village",
                    totalDistance: 100.0,
                    rewardXP: 300,
                    rewardGold: 100
                )
            ]
            saveQuests()
        }
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
        
        return [
            Quest(
                title: "Ancient Ruins Expedition",
                description: "Explore mysterious ruins for lost treasures",
                totalDistance: baseDistance,
                rewardXP: baseXP,
                rewardGold: baseGold
            ),
            Quest(
                title: "Bandit Ambush",
                description: "Clear the roads of dangerous bandits",
                totalDistance: baseDistance * 1.2,
                rewardXP: Int(Double(baseXP) * 1.3),
                rewardGold: Int(Double(baseGold) * 1.1)
            ),
            Quest(
                title: "Mystic Grove",
                description: "Investigate strange magical phenomena",
                totalDistance: baseDistance * 0.8,
                rewardXP: Int(Double(baseXP) * 1.1),
                rewardGold: Int(Double(baseGold) * 1.4)
            )
        ]
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
}