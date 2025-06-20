import Foundation
import SwiftUI
import Combine

// Note: WQConstants are accessed globally via WQC typealias

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
    private let logger: LoggingServiceProtocol?
    private let analytics: AnalyticsServiceProtocol?
    private let tutorialService: TutorialServiceProtocol
    private let questGenerationService: QuestGenerationServiceProtocol
    
    init(playerViewModel: PlayerViewModel,
         persistenceService: PersistenceServiceProtocol = PersistenceService(),
         healthService: HealthServiceProtocol = HealthService(),
         tutorialService: TutorialServiceProtocol = TutorialService(),
         questGenerationService: QuestGenerationServiceProtocol = QuestGenerationService(),
         logger: LoggingServiceProtocol? = nil,
         analytics: AnalyticsServiceProtocol? = nil) {
        self.playerViewModel = playerViewModel
        self.persistenceService = persistenceService
        self.healthService = healthService
        self.tutorialService = tutorialService
        self.questGenerationService = questGenerationService
        self.logger = logger
        self.analytics = analytics
        
        logger?.info("QuestViewModel initializing", category: .quest)
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
        logger?.info("Starting quest: \(quest.title)", category: .quest)
        analytics?.trackGameAction(.questStarted, parameters: [
            "quest_title": quest.title,
            "quest_distance": quest.totalDistance,
            "quest_xp_reward": quest.rewardXP,
            "player_level": playerViewModel.player.level
        ])
        
        var updatedQuest = quest
        updatedQuest.currentProgress = 0
        updatedQuest.isCompleted = false
        
        activeQuest = updatedQuest
        availableQuests.removeAll { $0.id == quest.id }
        
        // Trigger quest beginning epic moment
        triggerQuestEpicMoment(.questBegin(quest.title))
        
        // Announce quest start for accessibility
        AccessibilityHelpers.announce("Quest started: \(quest.title)")
        
        saveActiveQuest()
        saveQuests()
    }
    
    func completeQuest() {
        guard let quest = activeQuest else { return }
        
        logger?.info("Completing quest: \(quest.title)", category: .quest)
        analytics?.trackGameAction(.questCompleted, parameters: [
            "quest_title": quest.title,
            "quest_distance": quest.totalDistance,
            "quest_xp_reward": quest.rewardXP,
            "quest_gold_reward": quest.rewardGold,
            "player_level": playerViewModel.player.level
        ])
        
        // Trigger quest completion epic moment
        triggerQuestEpicMoment(.questComplete(quest.title))
        
        // Announce quest completion for accessibility
        AccessibilityHelpers.announceQuestCompletion(
            questTitle: quest.title,
            xpReward: quest.rewardXP,
            goldReward: quest.rewardGold
        )
        
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
        
        logger?.info("Cancelling quest: \(quest.title)", category: .quest)
        analytics?.trackGameAction(.questCancelled, parameters: [
            "quest_title": quest.title,
            "progress_when_cancelled": quest.currentProgress / quest.totalDistance,
            "player_level": playerViewModel.player.level
        ])
        
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
        
        // Validate health data before processing
        let healthValidationErrors = InputValidator.shared.validateHealthData(healthData)
        if !healthValidationErrors.isEmpty {
            let errorCollection = ValidationErrorCollection(healthValidationErrors)
            ValidationLogger.shared.logValidationErrors(healthValidationErrors, context: .questProgressContext)
            
            // Log warning but continue with available data
            if errorCollection.hasBlockingErrors {
                logger?.error("Health data validation failed, skipping quest progress update: \(errorCollection.summaryMessage())", category: .quest)
                return
            }
        }
        
        let newProgress = QuestProgressCalculator.calculateProgress(
            from: healthData,
            for: playerViewModel.player.activeClass
        )
        
        // Validate progress update before applying
        let progressValidation = QuestProgressCalculator.validateProgressUpdate(
            newProgress,
            currentProgress: quest.currentProgress,
            maxProgress: quest.totalDistance
        )
        
        if !progressValidation.isValid {
            logger?.warning("Quest progress validation failed: \(progressValidation.message ?? "Unknown error")", category: .quest)
            return
        }
        
        // Use the quest's safe update method with validation
        let progressResult = quest.updateProgress(newProgress)
        
        if !progressResult.isValid {
            logger?.warning("Quest progress update validation failed: \(progressResult.message ?? "Unknown error")", category: .quest)
            // Continue with the old progress value
            return
        }
        
        // Update the active quest
        activeQuest = quest
        
        // Check for completion
        if quest.isCompleted {
            logger?.info("Quest completed: \(quest.title)", category: .quest)
            analytics?.trackEvent(AnalyticsEvent(name: "quest_completed", parameters: [
                "quest_id": quest.id.uuidString,
                "quest_title": quest.title,
                "final_progress": quest.currentProgress
            ]))
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.completeQuest()
            }
        }
        
        saveActiveQuest()
    }
    
    // Progress calculation methods moved to QuestProgressCalculator utility
    
    private func generateInitialQuests() {
        if availableQuests.isEmpty {
            availableQuests = questGenerationService.generateInitialQuests()
            saveQuests()
        }
    }
    
    // Quest generation methods moved to QuestGenerationService
    
    private func generateNewQuests() {
        let playerLevel = playerViewModel.player.level
        let newQuests = questGenerationService.generateNewQuests(for: playerLevel, count: 1)
        availableQuests.append(contentsOf: newQuests)
    }
    
    // Quest template methods moved to QuestGenerationService
    
    private func loadQuests() {
        isLoading = true
        logger?.info("Loading quest logs", category: .quest)
        
        Task {
            do {
                completedQuests = try await persistenceService.loadQuestLogs()
                logger?.info("Loaded \(completedQuests.count) completed quests", category: .quest)
            } catch {
                logger?.error("Failed to load quest logs: \(error.localizedDescription)", category: .quest)
                analytics?.trackError(error, context: "QuestViewModel.loadQuests")
            }
            
            isLoading = false
        }
    }
    
    private func saveQuests() {
        Task {
            do {
                try await persistenceService.saveQuestLogs(completedQuests)
                logger?.debug("Saved \(completedQuests.count) quest logs", category: .quest)
            } catch {
                logger?.error("Failed to save quests: \(error.localizedDescription)", category: .quest)
                analytics?.trackError(error, context: "QuestViewModel.saveQuests")
            }
        }
    }
    
    private func saveActiveQuest() {
        guard let quest = activeQuest else { return }
        
        Task {
            do {
                try await persistenceService.saveActiveQuest(quest, for: playerViewModel.player)
                logger?.debug("Saved active quest: \(quest.title)", category: .quest)
            } catch {
                logger?.error("Failed to save active quest: \(error.localizedDescription)", category: .quest)
                analytics?.trackError(error, context: "QuestViewModel.saveActiveQuest")
            }
        }
    }
    
    private func loadActiveQuest() {
        Task {
            do {
                activeQuest = try await persistenceService.loadActiveQuest(for: playerViewModel.player)
                if let quest = activeQuest {
                    logger?.info("Loaded active quest: \(quest.title)", category: .quest)
                }
            } catch {
                logger?.error("Failed to load active quest: \(error.localizedDescription)", category: .quest)
                analytics?.trackError(error, context: "QuestViewModel.loadActiveQuest")
            }
        }
    }
    
    private func clearActiveQuest() {
        Task {
            do {
                try await persistenceService.clearActiveQuest(for: playerViewModel.player)
                logger?.debug("Cleared active quest", category: .quest)
            } catch {
                logger?.error("Failed to clear active quest: \(error.localizedDescription)", category: .quest)
                analytics?.trackError(error, context: "QuestViewModel.clearActiveQuest")
            }
        }
    }
    
    // MARK: - Tutorial Quest Management
    
    func startTutorialQuest(for heroClass: HeroClass) {
        tutorialQuest = tutorialService.createTutorialQuest(for: heroClass)
        tutorialStage = .introduction
        tutorialProgress = 0.0
        
        // Start tutorial sequence
        progressTutorialStage()
    }
    
    func advanceTutorialQuest() {
        if tutorialStage == .completion {
            completeTutorialQuest()
        } else {
            tutorialStage = tutorialService.getNextStage(from: tutorialStage)
            progressTutorialStage()
        }
    }
    
    // Tutorial quest creation moved to TutorialService
    
    private func progressTutorialStage() {
        updateTutorialProgress()
        updateTutorialNarrative()
        updateTutorialDialogue()
        
        if tutorialStage == .encounter {
            updateTutorialEncounter()
        }
        
        triggerTutorialEffects()
    }
    
    private func updateTutorialProgress() {
        tutorialProgress = tutorialService.getStageProgress(for: tutorialStage)
    }
    
    private func updateTutorialNarrative() {
        guard let quest = tutorialQuest else { return }
        tutorialNarrative = tutorialService.getNarrative(for: tutorialStage, heroClass: quest.heroClass)
    }
    
    private func updateTutorialDialogue() {
        guard let quest = tutorialQuest else { return }
        tutorialDialogue = tutorialService.getDialogue(for: tutorialStage, heroClass: quest.heroClass)
    }
    
    private func updateTutorialEncounter() {
        guard let quest = tutorialQuest else { return }
        tutorialEncounter = tutorialService.getEncounter(for: quest.heroClass)
    }
    
    private func triggerTutorialEffects() {
        isShowingTutorialEffects = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + WQC.UI.tutorialEffectsDuration) {
            self.isShowingTutorialEffects = false
        }
    }
    
    private func completeTutorialQuest() {
        guard let quest = tutorialQuest else { return }
        
        // Award tutorial rewards
        tutorialRewards = tutorialService.createRewards(for: quest.heroClass)
        
        // Trigger completion effects
        triggerQuestEpicMoment(.tutorialComplete)
        
        // Mark tutorial as complete
        tutorialStage = .completion
    }
    
    // Tutorial reward generation moved to TutorialService
    
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

// MARK: - Tutorial Supporting Types moved to Models/Tutorial/TutorialModels.swift