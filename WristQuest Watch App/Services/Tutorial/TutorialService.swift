import Foundation

// Note: WQConstants are accessed globally via WQC typealias

/// Protocol defining the tutorial service interface for dependency injection
protocol TutorialServiceProtocol {
    func createTutorialQuest(for heroClass: HeroClass) -> TutorialQuest
    func getNarrative(for stage: TutorialStage, heroClass: HeroClass) -> String
    func getDialogue(for stage: TutorialStage, heroClass: HeroClass) -> TutorialDialogue?
    func getEncounter(for heroClass: HeroClass) -> TutorialEncounter?
    func getStageProgress(for stage: TutorialStage) -> Double
    func createRewards(for heroClass: HeroClass) -> TutorialRewards
    func getNextStage(from currentStage: TutorialStage) -> TutorialStage
}

/// TutorialService handles all tutorial-related business logic,
/// separated from the ViewModel for better testability and maintainability
class TutorialService: TutorialServiceProtocol {
    
    private let logger: LoggingServiceProtocol?
    
    init(logger: LoggingServiceProtocol? = nil) {
        self.logger = logger
        logger?.info("TutorialService initialized", category: .quest)
    }
    
    // MARK: - Quest Creation
    
    func createTutorialQuest(for heroClass: HeroClass) -> TutorialQuest {
        logger?.info("Creating tutorial quest for \(heroClass.rawValue)", category: .quest)
        
        let questTemplate = TutorialData.getQuestTemplate(for: heroClass)
        
        return TutorialQuest(
            title: questTemplate.title,
            description: questTemplate.description,
            narrative: questTemplate.narrative,
            heroClass: heroClass,
            totalSteps: WQC.Tutorial.totalTutorialSteps,
            currentStep: 0
        )
    }
    
    // MARK: - Narrative Management
    
    func getNarrative(for stage: TutorialStage, heroClass: HeroClass) -> String {
        logger?.debug("Getting narrative for stage \(stage) and class \(heroClass.rawValue)", category: .quest)
        return TutorialData.getNarrative(for: stage, heroClass: heroClass)
    }
    
    // MARK: - Dialogue Management
    
    func getDialogue(for stage: TutorialStage, heroClass: HeroClass) -> TutorialDialogue? {
        logger?.debug("Getting dialogue for stage \(stage) and class \(heroClass.rawValue)", category: .quest)
        return TutorialData.getDialogue(for: stage, heroClass: heroClass)
    }
    
    // MARK: - Encounter Management
    
    func getEncounter(for heroClass: HeroClass) -> TutorialEncounter? {
        logger?.debug("Getting encounter for class \(heroClass.rawValue)", category: .quest)
        return TutorialData.encounterTemplates[heroClass]
    }
    
    // MARK: - Progress Management
    
    func getStageProgress(for stage: TutorialStage) -> Double {
        return TutorialData.getStageProgress(for: stage)
    }
    
    func getNextStage(from currentStage: TutorialStage) -> TutorialStage {
        switch currentStage {
        case .notStarted:
            return .introduction
        case .introduction:
            return .firstChallenge
        case .firstChallenge:
            return .encounter
        case .encounter:
            return .finalTest
        case .finalTest:
            return .completion
        case .completion:
            return .completion // Stay at completion
        }
    }
    
    // MARK: - Rewards Management
    
    func createRewards(for heroClass: HeroClass) -> TutorialRewards {
        logger?.info("Creating tutorial rewards for \(heroClass.rawValue)", category: .quest)
        
        return TutorialRewards(
            xp: WQC.Tutorial.tutorialXPReward,
            gold: WQC.Tutorial.tutorialGoldReward,
            item: TutorialData.getRewardItem(for: heroClass),
            title: "\(heroClass.rawValue.capitalized) Initiate"
        )
    }
}

// Tutorial logging uses the existing .quest category