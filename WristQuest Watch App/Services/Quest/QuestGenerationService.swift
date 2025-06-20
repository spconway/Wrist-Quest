import Foundation

// Note: WQConstants are accessed globally via WQC typealias

/// Protocol defining the quest generation service interface for dependency injection
protocol QuestGenerationServiceProtocol {
    func generateInitialQuests() -> [Quest]
    func generateNewQuests(for playerLevel: Int, count: Int) -> [Quest]
    func generateQuestFromTemplate(_ template: (title: String, description: String), 
                                 playerLevel: Int, 
                                 difficulty: QuestTemplates.QuestDifficulty?) -> Quest
}

/// QuestGenerationService handles all quest generation logic,
/// separated from the ViewModel for better testability and maintainability
class QuestGenerationService: QuestGenerationServiceProtocol {
    
    private let logger: LoggingServiceProtocol?
    
    init(logger: LoggingServiceProtocol? = nil) {
        self.logger = logger
        logger?.info("QuestGenerationService initialized", category: .quest)
    }
    
    // MARK: - Initial Quest Generation
    
    func generateInitialQuests() -> [Quest] {
        logger?.info("Generating initial fantasy quests", category: .quest)
        
        return QuestTemplates.initialQuests.compactMap { template in
            do {
                return try Quest(
                    title: template.title,
                    description: template.description,
                    totalDistance: template.distance,
                    rewardXP: template.xp,
                    rewardGold: template.gold
                )
            } catch {
                logger?.error("Failed to create initial quest '\(template.title)': \(error)", category: .quest)
                return nil
            }
        }
    }
    
    // MARK: - Dynamic Quest Generation
    
    func generateNewQuests(for playerLevel: Int, count: Int = 1) -> [Quest] {
        logger?.info("Generating \(count) new quests for player level \(playerLevel)", category: .quest)
        
        let templates = QuestTemplates.getRandomTemplates(count: count)
        
        return templates.map { template in
            generateQuestFromTemplate(template, playerLevel: playerLevel, difficulty: nil)
        }
    }
    
    func generateQuestFromTemplate(_ template: (title: String, description: String), 
                                 playerLevel: Int, 
                                 difficulty: QuestTemplates.QuestDifficulty? = nil) -> Quest {
        
        let baseValues = calculateBaseValues(for: playerLevel)
        let questDifficulty = difficulty ?? selectRandomDifficulty(for: playerLevel)
        let finalValues = QuestTemplates.applyDifficulty(questDifficulty, to: baseValues)
        
        logger?.debug("Generated quest '\(template.title)' for level \(playerLevel) with difficulty \(questDifficulty)", category: .quest)
        
        do {
            return try Quest(
                title: template.title,
                description: template.description,
                totalDistance: addRandomVariation(to: finalValues.distance, variationType: .distance),
                rewardXP: Int(addRandomVariation(to: Double(finalValues.xp), variationType: .xp)),
                rewardGold: Int(addRandomVariation(to: Double(finalValues.gold), variationType: .gold))
            )
        } catch {
            logger?.error("Failed to create quest '\(template.title)': \(error), using fallback", category: .quest)
            // Return a fallback quest if creation fails
            do {
                return try Quest(
                    title: "Adventure Awaits",
                    description: "A mysterious quest beckons...",
                    totalDistance: WQC.Quest.baseQuestDistance,
                    rewardXP: WQC.Quest.baseQuestXP,
                    rewardGold: WQC.Quest.baseQuestGold
                )
            } catch {
                // This should never happen with valid defaults, but we need to handle it
                fatalError("Failed to create fallback quest: \(error)")
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func calculateBaseValues(for playerLevel: Int) -> (distance: Double, xp: Int, gold: Int) {
        let baseXP = WQC.Quest.baseQuestXP + (playerLevel * WQC.Quest.questXPPerLevel)
        let baseGold = WQC.Quest.baseQuestGold + (playerLevel * WQC.Quest.questGoldPerLevel)
        let baseDistance = WQC.Quest.baseQuestDistance + (Double(playerLevel) * WQC.Quest.questDistancePerLevel)
        
        return (distance: baseDistance, xp: baseXP, gold: baseGold)
    }
    
    private func selectRandomDifficulty(for playerLevel: Int) -> QuestTemplates.QuestDifficulty {
        // Higher level players have higher chance of harder quests
        let random = Double.random(in: 0...1)
        let levelModifier = min(Double(playerLevel) / 20.0, 0.5) // Cap at 50% bonus
        
        switch random + levelModifier {
        case 0.0..<0.4:
            return .easy
        case 0.4..<0.7:
            return .normal
        case 0.7..<0.9:
            return .hard
        default:
            return .epic
        }
    }
    
    private enum VariationType {
        case distance
        case xp
        case gold
        
        var range: ClosedRange<Double> {
            switch self {
            case .distance:
                return WQC.Quest.questDistanceVariationMin...WQC.Quest.questDistanceVariationMax
            case .xp:
                return WQC.Quest.questXPVariationMin...WQC.Quest.questXPVariationMax
            case .gold:
                return WQC.Quest.questGoldVariationMin...WQC.Quest.questGoldVariationMax
            }
        }
    }
    
    private func addRandomVariation(to value: Double, variationType: VariationType) -> Double {
        let variation = Double.random(in: variationType.range)
        return value * variation
    }
    
    // MARK: - Themed Quest Generation
    
    func generateThemedQuests(theme: QuestTemplates.QuestTheme, 
                            playerLevel: Int, 
                            count: Int = 2) -> [Quest] {
        logger?.info("Generating \(count) \(theme) themed quests for level \(playerLevel)", category: .quest)
        
        let templates = QuestTemplates.getThemedTemplates(theme: theme, count: count)
        
        return templates.map { template in
            generateQuestFromTemplate(template, playerLevel: playerLevel, difficulty: nil)
        }
    }
    
    // MARK: - Special Quest Generation
    
    func generateEpicQuest(for playerLevel: Int) -> Quest {
        logger?.info("Generating epic quest for level \(playerLevel)", category: .quest)
        
        let template = QuestTemplates.getRandomTemplates(count: 1).first!
        return generateQuestFromTemplate(template, playerLevel: playerLevel, difficulty: .epic)
    }
}