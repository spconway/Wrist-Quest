import Foundation
@testable import WristQuest_Watch_App

/// Mock implementation of QuestGenerationService for testing
class MockQuestGenerationService: QuestGenerationServiceProtocol {
    
    // MARK: - Mock Data Storage
    
    /// Pre-defined quest templates for consistent testing
    private var questTemplates: [QuestTemplate] = []
    
    /// Generated quests storage for verification
    private(set) var generatedQuests: [Quest] = []
    
    /// Quest generation history for testing
    private(set) var generationHistory: [QuestGenerationRequest] = []
    
    // MARK: - Mock Control Properties
    
    /// Control whether operations should fail
    var shouldFailGenerateQuests = false
    var shouldFailGenerateInitialQuests = false
    var shouldFailLoadTemplates = false
    
    /// Control specific errors to return
    var generateQuestsError: Error?
    var loadTemplatesError: Error?
    
    /// Track method calls for verification
    var generateInitialQuestsCallCount = 0
    var generateNewQuestsCallCount = 0
    var generateQuestFromTemplateCallCount = 0
    var loadQuestTemplatesCallCount = 0
    var validateQuestBalanceCallCount = 0
    
    /// Control quest generation parameters
    var defaultQuestCount = 3
    var questDifficultyMultiplier: Double = 1.0
    var questRewardMultiplier: Double = 1.0
    var enableQuestVariation = true
    
    /// Predefined quests for specific testing scenarios
    var predefinedQuests: [Quest] = []
    var usePredefinedQuests = false
    
    // MARK: - Protocol Implementation
    
    func generateInitialQuests() -> [Quest] {
        generateInitialQuestsCallCount += 1
        
        if shouldFailGenerateInitialQuests {
            return [] // Return empty array on failure
        }
        
        if usePredefinedQuests && !predefinedQuests.isEmpty {
            generatedQuests.append(contentsOf: predefinedQuests)
            return predefinedQuests
        }
        
        let request = QuestGenerationRequest(
            playerLevel: 1,
            questCount: defaultQuestCount,
            difficulty: .beginner,
            requestType: .initial
        )
        generationHistory.append(request)
        
        let quests = createInitialQuests()
        generatedQuests.append(contentsOf: quests)
        return quests
    }
    
    func generateNewQuests(for playerLevel: Int, count: Int) -> [Quest] {
        generateNewQuestsCallCount += 1
        
        if shouldFailGenerateQuests {
            return [] // Return empty array on failure
        }
        
        let difficulty = determineDifficulty(for: playerLevel)
        let request = QuestGenerationRequest(
            playerLevel: playerLevel,
            questCount: count,
            difficulty: difficulty,
            requestType: .new
        )
        generationHistory.append(request)
        
        if usePredefinedQuests && !predefinedQuests.isEmpty {
            let questsToReturn = Array(predefinedQuests.prefix(count))
            generatedQuests.append(contentsOf: questsToReturn)
            return questsToReturn
        }
        
        let quests = createQuestsForLevel(playerLevel, count: count)
        generatedQuests.append(contentsOf: quests)
        return quests
    }
    
    func generateQuestFromTemplate(_ template: QuestTemplate, playerLevel: Int) -> Quest {
        generateQuestFromTemplateCallCount += 1
        
        let difficulty = determineDifficulty(for: playerLevel)
        let request = QuestGenerationRequest(
            playerLevel: playerLevel,
            questCount: 1,
            difficulty: difficulty,
            requestType: .fromTemplate,
            templateUsed: template
        )
        generationHistory.append(request)
        
        let quest = createQuestFromTemplate(template, playerLevel: playerLevel)
        generatedQuests.append(quest)
        return quest
    }
    
    func loadQuestTemplates() -> [QuestTemplate] {
        loadQuestTemplatesCallCount += 1
        
        if shouldFailLoadTemplates {
            return [] // Return empty array on failure
        }
        
        if questTemplates.isEmpty {
            questTemplates = createDefaultQuestTemplates()
        }
        
        return questTemplates
    }
    
    func validateQuestBalance(_ quest: Quest, playerLevel: Int) -> QuestBalanceResult {
        validateQuestBalanceCallCount += 1
        
        let expectedXP = calculateExpectedXP(for: playerLevel)
        let expectedGold = calculateExpectedGold(for: playerLevel)
        let expectedDistance = calculateExpectedDistance(for: playerLevel)
        
        var issues: [String] = []
        var isBalanced = true
        
        // Check XP balance
        let xpRatio = Double(quest.rewardXP) / Double(expectedXP)
        if xpRatio < 0.7 || xpRatio > 1.5 {
            issues.append("XP reward is \(xpRatio < 1 ? "too low" : "too high") for player level")
            isBalanced = false
        }
        
        // Check gold balance
        let goldRatio = Double(quest.rewardGold) / Double(expectedGold)
        if goldRatio < 0.7 || goldRatio > 1.5 {
            issues.append("Gold reward is \(goldRatio < 1 ? "too low" : "too high") for player level")
            isBalanced = false
        }
        
        // Check distance balance
        let distanceRatio = quest.totalDistance / expectedDistance
        if distanceRatio < 0.5 || distanceRatio > 2.0 {
            issues.append("Quest distance is \(distanceRatio < 1 ? "too short" : "too long") for player level")
            isBalanced = false
        }
        
        return QuestBalanceResult(
            isBalanced: isBalanced,
            issues: issues,
            recommendedAdjustments: isBalanced ? [] : generateRecommendations(quest, playerLevel)
        )
    }
    
    // MARK: - Private Quest Creation Methods
    
    private func createInitialQuests() -> [Quest] {
        let templates = [
            createBeginnerTemplate("Forest Exploration", "Discover the mysteries of the ancient forest"),
            createBeginnerTemplate("Village Patrol", "Help the local guards patrol the village"),
            createBeginnerTemplate("Herb Gathering", "Collect medicinal herbs for the village healer")
        ]
        
        return templates.map { template in
            createQuestFromTemplate(template, playerLevel: 1)
        }
    }
    
    private func createQuestsForLevel(_ playerLevel: Int, count: Int) -> [Quest] {
        let templates = loadQuestTemplates()
        let appropriateTemplates = templates.filter { template in
            template.minLevel <= playerLevel && template.maxLevel >= playerLevel
        }
        
        guard !appropriateTemplates.isEmpty else {
            // Fallback to creating basic quests
            return (0..<count).map { index in
                createFallbackQuest(playerLevel: playerLevel, index: index)
            }
        }
        
        return (0..<count).map { _ in
            let template = appropriateTemplates.randomElement()!
            return createQuestFromTemplate(template, playerLevel: playerLevel)
        }
    }
    
    private func createQuestFromTemplate(_ template: QuestTemplate, playerLevel: Int) -> Quest {
        let levelMultiplier = Double(playerLevel)
        let variationFactor = enableQuestVariation ? Double.random(in: 0.8...1.2) : 1.0
        
        let distance = template.baseDistance * levelMultiplier * variationFactor * questDifficultyMultiplier
        let xpReward = Int(Double(template.baseXP) * levelMultiplier * variationFactor * questRewardMultiplier)
        let goldReward = Int(Double(template.baseGold) * levelMultiplier * variationFactor * questRewardMultiplier)
        
        let title = enableQuestVariation ? 
            "\(template.titlePrefix) \(generateTitleSuffix())" : 
            template.titlePrefix
        
        return try! Quest(
            id: UUID(),
            title: title,
            description: template.description,
            totalDistance: max(10.0, distance),
            currentProgress: 0.0,
            isCompleted: false,
            rewardXP: max(1, xpReward),
            rewardGold: max(1, goldReward),
            encounters: createEncountersForTemplate(template, playerLevel: playerLevel)
        )
    }
    
    private func createDefaultQuestTemplates() -> [QuestTemplate] {
        return [
            // Beginner Templates (Level 1-5)
            QuestTemplate(
                id: UUID(),
                titlePrefix: "Forest Path",
                description: "Take your first steps into the mystical woodland",
                category: .exploration,
                minLevel: 1,
                maxLevel: 3,
                baseDistance: 50.0,
                baseXP: 25,
                baseGold: 15,
                encounterTypes: [.discovery, .decision]
            ),
            
            QuestTemplate(
                id: UUID(),
                titlePrefix: "Village Guard",
                description: "Assist the local guards with their duties",
                category: .combat,
                minLevel: 2,
                maxLevel: 5,
                baseDistance: 75.0,
                baseXP: 40,
                baseGold: 25,
                encounterTypes: [.combat, .decision]
            ),
            
            // Intermediate Templates (Level 5-15)
            QuestTemplate(
                id: UUID(),
                titlePrefix: "Ancient Ruins",
                description: "Explore the mysterious ruins and uncover their secrets",
                category: .exploration,
                minLevel: 5,
                maxLevel: 12,
                baseDistance: 150.0,
                baseXP: 100,
                baseGold: 60,
                encounterTypes: [.discovery, .trap, .combat]
            ),
            
            QuestTemplate(
                id: UUID(),
                titlePrefix: "Bandit Hunt",
                description: "Track down the bandits terrorizing travelers",
                category: .combat,
                minLevel: 8,
                maxLevel: 15,
                baseDistance: 200.0,
                baseXP: 150,
                baseGold: 100,
                encounterTypes: [.combat, .decision, .trap]
            ),
            
            // Advanced Templates (Level 15+)
            QuestTemplate(
                id: UUID(),
                titlePrefix: "Dragon's Lair",
                description: "Face the ancient dragon in its mountain stronghold",
                category: .combat,
                minLevel: 15,
                maxLevel: 30,
                baseDistance: 500.0,
                baseXP: 400,
                baseGold: 300,
                encounterTypes: [.combat, .trap, .decision]
            ),
            
            QuestTemplate(
                id: UUID(),
                titlePrefix: "Lost City",
                description: "Discover the legendary lost city of ancient magic",
                category: .exploration,
                minLevel: 20,
                maxLevel: 40,
                baseDistance: 750.0,
                baseXP: 600,
                baseGold: 450,
                encounterTypes: [.discovery, .trap, .combat, .decision]
            )
        ]
    }
    
    private func createBeginnerTemplate(_ title: String, _ description: String) -> QuestTemplate {
        return QuestTemplate(
            id: UUID(),
            titlePrefix: title,
            description: description,
            category: .exploration,
            minLevel: 1,
            maxLevel: 3,
            baseDistance: 50.0,
            baseXP: 30,
            baseGold: 20,
            encounterTypes: [.discovery, .decision]
        )
    }
    
    private func createFallbackQuest(playerLevel: Int, index: Int) -> Quest {
        let titles = ["Simple Task", "Basic Mission", "Easy Journey", "Quick Adventure"]
        let descriptions = ["A straightforward quest", "A basic adventure", "An easy challenge", "A simple mission"]
        
        let title = titles[index % titles.count]
        let description = descriptions[index % descriptions.count]
        let distance = Double(50 + (playerLevel * 25))
        let xpReward = 25 + (playerLevel * 10)
        let goldReward = 15 + (playerLevel * 5)
        
        return try! Quest(
            id: UUID(),
            title: title,
            description: description,
            totalDistance: distance,
            currentProgress: 0.0,
            isCompleted: false,
            rewardXP: xpReward,
            rewardGold: goldReward,
            encounters: []
        )
    }
    
    private func createEncountersForTemplate(_ template: QuestTemplate, playerLevel: Int) -> [Encounter] {
        let encounterCount = min(3, template.encounterTypes.count)
        let selectedTypes = Array(template.encounterTypes.prefix(encounterCount))
        
        return selectedTypes.map { encounterType in
            TestDataFactory.createValidEncounter() // Use test data factory for consistency
        }
    }
    
    private func generateTitleSuffix() -> String {
        let suffixes = ["Adventure", "Expedition", "Journey", "Quest", "Mission", "Trial"]
        return suffixes.randomElement() ?? "Quest"
    }
    
    // MARK: - Helper Methods
    
    private func determineDifficulty(for playerLevel: Int) -> QuestDifficulty {
        switch playerLevel {
        case 1...5:
            return .beginner
        case 6...15:
            return .intermediate
        case 16...30:
            return .advanced
        default:
            return .expert
        }
    }
    
    private func calculateExpectedXP(for playerLevel: Int) -> Int {
        return 50 + (playerLevel * 20)
    }
    
    private func calculateExpectedGold(for playerLevel: Int) -> Int {
        return 30 + (playerLevel * 15)
    }
    
    private func calculateExpectedDistance(for playerLevel: Int) -> Double {
        return 100.0 + (Double(playerLevel) * 50.0)
    }
    
    private func generateRecommendations(_ quest: Quest, _ playerLevel: Int) -> [String] {
        var recommendations: [String] = []
        
        let expectedXP = calculateExpectedXP(for: playerLevel)
        let expectedGold = calculateExpectedGold(for: playerLevel)
        let expectedDistance = calculateExpectedDistance(for: playerLevel)
        
        if quest.rewardXP < expectedXP {
            recommendations.append("Increase XP reward to approximately \(expectedXP)")
        } else if quest.rewardXP > Int(Double(expectedXP) * 1.5) {
            recommendations.append("Decrease XP reward to approximately \(expectedXP)")
        }
        
        if quest.rewardGold < expectedGold {
            recommendations.append("Increase gold reward to approximately \(expectedGold)")
        } else if quest.rewardGold > Int(Double(expectedGold) * 1.5) {
            recommendations.append("Decrease gold reward to approximately \(expectedGold)")
        }
        
        if quest.totalDistance < expectedDistance * 0.5 {
            recommendations.append("Increase quest distance to approximately \(Int(expectedDistance))")
        } else if quest.totalDistance > expectedDistance * 2.0 {
            recommendations.append("Decrease quest distance to approximately \(Int(expectedDistance))")
        }
        
        return recommendations
    }
    
    // MARK: - Mock Control Methods
    
    /// Reset all mock state
    func reset() {
        questTemplates.removeAll()
        generatedQuests.removeAll()
        generationHistory.removeAll()
        predefinedQuests.removeAll()
        
        shouldFailGenerateQuests = false
        shouldFailGenerateInitialQuests = false
        shouldFailLoadTemplates = false
        
        generateQuestsError = nil
        loadTemplatesError = nil
        
        usePredefinedQuests = false
        enableQuestVariation = true
        questDifficultyMultiplier = 1.0
        questRewardMultiplier = 1.0
        defaultQuestCount = 3
        
        // Reset call counts
        generateInitialQuestsCallCount = 0
        generateNewQuestsCallCount = 0
        generateQuestFromTemplateCallCount = 0
        loadQuestTemplatesCallCount = 0
        validateQuestBalanceCallCount = 0
    }
    
    /// Set predefined quests for testing specific scenarios
    func setPredefinedQuests(_ quests: [Quest]) {
        predefinedQuests = quests
        usePredefinedQuests = true
    }
    
    /// Add custom quest template
    func addCustomTemplate(_ template: QuestTemplate) {
        questTemplates.append(template)
    }
    
    /// Get the last generated quest for verification
    var lastGeneratedQuest: Quest? {
        return generatedQuests.last
    }
    
    /// Get generation history for verification
    func getGenerationHistory() -> [QuestGenerationRequest] {
        return generationHistory
    }
    
    /// Verify that quests were generated for specific level
    func verifyQuestsGeneratedForLevel(_ level: Int) -> Bool {
        return generationHistory.contains { $0.playerLevel == level }
    }
    
    /// Get total number of quests generated
    var totalQuestsGenerated: Int {
        return generatedQuests.count
    }
}

// MARK: - Supporting Types

struct QuestGenerationRequest {
    let playerLevel: Int
    let questCount: Int
    let difficulty: QuestDifficulty
    let requestType: GenerationRequestType
    let templateUsed: QuestTemplate?
    
    init(playerLevel: Int, questCount: Int, difficulty: QuestDifficulty, requestType: GenerationRequestType, templateUsed: QuestTemplate? = nil) {
        self.playerLevel = playerLevel
        self.questCount = questCount
        self.difficulty = difficulty
        self.requestType = requestType
        self.templateUsed = templateUsed
    }
}

enum GenerationRequestType {
    case initial
    case new
    case fromTemplate
}

enum QuestDifficulty {
    case beginner
    case intermediate
    case advanced
    case expert
}

struct QuestTemplate {
    let id: UUID
    let titlePrefix: String
    let description: String
    let category: QuestCategory
    let minLevel: Int
    let maxLevel: Int
    let baseDistance: Double
    let baseXP: Int
    let baseGold: Int
    let encounterTypes: [EncounterType]
}

enum QuestCategory {
    case exploration
    case combat
    case collection
    case delivery
    case social
}

struct QuestBalanceResult {
    let isBalanced: Bool
    let issues: [String]
    let recommendedAdjustments: [String]
}

// MARK: - Test Helper Extensions

extension MockQuestGenerationService {
    /// Create pre-configured mock that fails generation
    static func failingGenerationMock() -> MockQuestGenerationService {
        let mock = MockQuestGenerationService()
        mock.shouldFailGenerateQuests = true
        mock.shouldFailGenerateInitialQuests = true
        return mock
    }
    
    /// Create pre-configured mock with specific quests
    static func withPredefinedQuests(_ quests: [Quest]) -> MockQuestGenerationService {
        let mock = MockQuestGenerationService()
        mock.setPredefinedQuests(quests)
        return mock
    }
    
    /// Create pre-configured mock for high level testing
    static func highLevelMock() -> MockQuestGenerationService {
        let mock = MockQuestGenerationService()
        let highLevelQuests = [
            TestDataFactory.createHighLevelQuest(),
            TestDataFactory.createValidQuest(title: "Epic Adventure", totalDistance: 800.0, rewardXP: 400, rewardGold: 250)
        ]
        mock.setPredefinedQuests(highLevelQuests)
        return mock
    }
    
    /// Create pre-configured mock with balanced rewards
    static func balancedRewardsMock() -> MockQuestGenerationService {
        let mock = MockQuestGenerationService()
        mock.questRewardMultiplier = 1.0
        mock.questDifficultyMultiplier = 1.0
        mock.enableQuestVariation = false
        return mock
    }
    
    /// Convenience method to verify quest balance
    func verifyAllQuestsBalanced(for playerLevel: Int) -> Bool {
        return generatedQuests.allSatisfy { quest in
            let result = validateQuestBalance(quest, playerLevel: playerLevel)
            return result.isBalanced
        }
    }
}