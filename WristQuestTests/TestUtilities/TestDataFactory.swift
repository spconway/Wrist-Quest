import Foundation
@testable import WristQuest_Watch_App

/// Factory for creating test data objects with predefined valid and invalid scenarios
struct TestDataFactory {
    
    // MARK: - Player Test Data
    
    static func createValidPlayer(
        name: String = "TestHero",
        level: Int = 1,
        xp: Int = 0,
        gold: Int = 100,
        heroClass: HeroClass = .warrior
    ) -> Player {
        return try! Player(
            id: UUID(),
            name: name,
            level: level,
            xp: xp,
            gold: gold,
            stepsToday: 0,
            activeClass: heroClass,
            inventory: [],
            journal: []
        )
    }
    
    static func createHighLevelPlayer() -> Player {
        return try! Player(
            id: UUID(),
            name: "VeteranHero",
            level: 15,
            xp: 2500,
            gold: 5000,
            stepsToday: 8000,
            activeClass: .mage,
            inventory: [createValidItem()],
            journal: [createValidQuestLog()]
        )
    }
    
    static func createPlayerWithMaxStats() -> Player {
        return try! Player(
            id: UUID(),
            name: "MaxHero",
            level: 50,
            xp: 999999,
            gold: 999999,
            stepsToday: 50000,
            activeClass: .ranger,
            inventory: Array(repeating: createValidItem(), count: 10),
            journal: Array(repeating: createValidQuestLog(), count: 5)
        )
    }
    
    // MARK: - Quest Test Data
    
    static func createValidQuest(
        title: String = "Test Quest",
        description: String = "A test quest for validation",
        totalDistance: Double = 100.0,
        currentProgress: Double = 0.0,
        rewardXP: Int = 50,
        rewardGold: Int = 25
    ) -> Quest {
        return try! Quest(
            id: UUID(),
            title: title,
            description: description,
            totalDistance: totalDistance,
            currentProgress: currentProgress,
            isCompleted: currentProgress >= totalDistance,
            rewardXP: rewardXP,
            rewardGold: rewardGold,
            encounters: []
        )
    }
    
    static func createInProgressQuest() -> Quest {
        return try! Quest(
            id: UUID(),
            title: "Journey to the Ancient Forest",
            description: "Explore the mystical woodland realm",
            totalDistance: 200.0,
            currentProgress: 75.0,
            isCompleted: false,
            rewardXP: 150,
            rewardGold: 80,
            encounters: [createValidEncounter()]
        )
    }
    
    static func createCompletedQuest() -> Quest {
        return try! Quest(
            id: UUID(),
            title: "Completed Adventure",
            description: "A quest that has been finished",
            totalDistance: 50.0,
            currentProgress: 50.0,
            isCompleted: true,
            rewardXP: 75,
            rewardGold: 35,
            encounters: []
        )
    }
    
    static func createHighLevelQuest() -> Quest {
        return try! Quest(
            id: UUID(),
            title: "Dragon's Lair Expedition",
            description: "Face the ancient dragon in its mountain stronghold",
            totalDistance: 1000.0,
            currentProgress: 0.0,
            isCompleted: false,
            rewardXP: 500,
            rewardGold: 300,
            encounters: [createCombatEncounter(), createDecisionEncounter()]
        )
    }
    
    // MARK: - Health Data Test Objects
    
    static func createValidHealthData(
        steps: Int = 5000,
        standingHours: Int = 8,
        heartRate: Double = 75.0,
        exerciseMinutes: Int = 30,
        mindfulMinutes: Int = 10
    ) -> HealthData {
        return HealthData(
            steps: steps,
            standingHours: standingHours,
            heartRate: heartRate,
            exerciseMinutes: exerciseMinutes,
            mindfulMinutes: mindfulMinutes
        )
    }
    
    static func createLowActivityHealthData() -> HealthData {
        return HealthData(
            steps: 500,
            standingHours: 2,
            heartRate: 65.0,
            exerciseMinutes: 0,
            mindfulMinutes: 0
        )
    }
    
    static func createHighActivityHealthData() -> HealthData {
        return HealthData(
            steps: 15000,
            standingHours: 12,
            heartRate: 140.0,
            exerciseMinutes: 90,
            mindfulMinutes: 20
        )
    }
    
    static func createCombatModeHealthData() -> HealthData {
        return HealthData(
            steps: 8000,
            standingHours: 6,
            heartRate: 160.0, // High heart rate triggers combat mode
            exerciseMinutes: 45,
            mindfulMinutes: 5
        )
    }
    
    static func createInvalidHealthData() -> HealthData {
        return HealthData(
            steps: -100, // Invalid negative steps
            standingHours: 25, // Invalid hours > 24
            heartRate: 300.0, // Invalid high heart rate
            exerciseMinutes: -10, // Invalid negative minutes
            mindfulMinutes: -5 // Invalid negative minutes
        )
    }
    
    // MARK: - Item Test Data
    
    static func createValidItem(
        name: String = "Test Sword",
        type: ItemType = .weapon,
        level: Int = 1,
        rarity: Rarity = .common
    ) -> Item {
        return Item(
            id: UUID(),
            name: name,
            type: type,
            level: level,
            rarity: rarity,
            effects: [ItemEffect(stat: .strength, amount: 5)]
        )
    }
    
    static func createRareItem() -> Item {
        return Item(
            id: UUID(),
            name: "Legendary Blade of Testing",
            type: .weapon,
            level: 10,
            rarity: .legendary,
            effects: [
                ItemEffect(stat: .strength, amount: 25),
                ItemEffect(stat: .xpGain, amount: 10)
            ]
        )
    }
    
    static func createArmorItem() -> Item {
        return Item(
            id: UUID(),
            name: "Chain Mail of Protection",
            type: .armor,
            level: 5,
            rarity: .uncommon,
            effects: [ItemEffect(stat: .healthRegen, amount: 15)]
        )
    }
    
    static func createPotionItem() -> Item {
        return Item(
            id: UUID(),
            name: "Health Potion",
            type: .potion,
            level: 1,
            rarity: .common,
            effects: [ItemEffect(stat: .healthRegen, amount: 50)]
        )
    }
    
    // MARK: - Encounter Test Data
    
    static func createValidEncounter() -> Encounter {
        return Encounter(
            id: UUID(),
            type: .discovery,
            description: "You discover a hidden treasure chest",
            options: [
                EncounterOption(
                    text: "Open the chest",
                    successChance: 0.8,
                    result: EncounterResult(
                        xpGain: 25,
                        goldGain: 50,
                        itemReward: nil,
                        healthChange: 0,
                        message: "You found gold!"
                    )
                )
            ],
            result: nil
        )
    }
    
    static func createCombatEncounter() -> Encounter {
        return Encounter(
            id: UUID(),
            type: .combat,
            description: "A wild goblin blocks your path!",
            options: [
                EncounterOption(
                    text: "Fight",
                    successChance: 0.7,
                    result: EncounterResult(
                        xpGain: 40,
                        goldGain: 20,
                        itemReward: createValidItem(),
                        healthChange: -10,
                        message: "You defeated the goblin!"
                    )
                ),
                EncounterOption(
                    text: "Flee",
                    successChance: 0.9,
                    result: EncounterResult(
                        xpGain: 5,
                        goldGain: 0,
                        itemReward: nil,
                        healthChange: 0,
                        message: "You escaped safely"
                    )
                )
            ],
            result: nil
        )
    }
    
    static func createDecisionEncounter() -> Encounter {
        return Encounter(
            id: UUID(),
            type: .decision,
            description: "You come to a fork in the road",
            options: [
                EncounterOption(
                    text: "Take the left path",
                    successChance: 0.6,
                    result: EncounterResult(
                        xpGain: 30,
                        goldGain: 15,
                        itemReward: nil,
                        healthChange: 0,
                        message: "The left path leads to adventure!"
                    )
                ),
                EncounterOption(
                    text: "Take the right path",
                    successChance: 0.6,
                    result: EncounterResult(
                        xpGain: 20,
                        goldGain: 30,
                        itemReward: nil,
                        healthChange: 0,
                        message: "The right path leads to treasure!"
                    )
                )
            ],
            result: nil
        )
    }
    
    // MARK: - Quest Log Test Data
    
    static func createValidQuestLog() -> QuestLog {
        return QuestLog(
            questId: UUID(),
            questName: "Completed Test Quest",
            summary: "Successfully completed a test adventure",
            rewards: QuestRewards(xp: 100, gold: 50)
        )
    }
    
    static func createMultipleQuestLogs(count: Int = 5) -> [QuestLog] {
        return (0..<count).map { index in
            QuestLog(
                questId: UUID(),
                questName: "Quest \(index + 1)",
                summary: "Completed quest number \(index + 1)",
                rewards: QuestRewards(xp: 50 + (index * 10), gold: 25 + (index * 5))
            )
        }
    }
    
    // MARK: - Tutorial Test Data
    
    static func createTutorialQuest(for heroClass: HeroClass) -> TutorialQuest {
        let classNames: [HeroClass: String] = [
            .warrior: "Warrior's First Trial",
            .mage: "Arcane Awakening",
            .rogue: "Shadow's Introduction",
            .ranger: "Nature's Calling",
            .cleric: "Divine Beginning"
        ]
        
        return TutorialQuest(
            id: UUID(),
            heroClass: heroClass,
            title: classNames[heroClass] ?? "Tutorial Quest",
            description: "Learn the ways of the \(heroClass.rawValue)",
            stages: createTutorialStages(),
            currentStage: .introduction,
            isCompleted: false
        )
    }
    
    static func createTutorialStages() -> [TutorialStage] {
        return [.introduction, .basicMovement, .encounter, .rewards, .completion]
    }
    
    static func createTutorialDialogue(for stage: TutorialStage, heroClass: HeroClass) -> TutorialDialogue {
        return TutorialDialogue(
            speaker: "Mentor",
            message: "Welcome, young \(heroClass.rawValue). This is your \(stage.rawValue) training.",
            options: ["Continue", "Ask Question"],
            isSkippable: true
        )
    }
    
    static func createTutorialEncounter(for heroClass: HeroClass) -> TutorialEncounter {
        return TutorialEncounter(
            id: UUID(),
            heroClass: heroClass,
            type: .combat,
            description: "Face your first training dummy",
            difficulty: .easy,
            successRate: 0.95,
            rewards: TutorialRewards(
                xp: 25,
                gold: 10,
                item: createValidItem(),
                classSpecificBonus: "Gained basic \(heroClass.rawValue) technique"
            )
        )
    }
    
    // MARK: - Error Test Data
    
    static func createWQError(_ type: WQError.ErrorType = .validation(.invalidPlayerName("Test error"))) -> WQError {
        return WQError(type: type, timestamp: Date())
    }
    
    static func createValidationErrors() -> [ValidationError] {
        return [
            ValidationError(field: "name", message: "Name is too short", severity: .warning),
            ValidationError(field: "xp", message: "XP exceeds maximum", severity: .error),
            ValidationError(field: "health", message: "Invalid health data", severity: .critical)
        ]
    }
    
    // MARK: - Edge Case Data
    
    static func createEmptyPlayer() -> Player {
        return try! Player(
            id: UUID(),
            name: "E", // Minimum valid name
            level: 1,
            xp: 0,
            gold: 0,
            stepsToday: 0,
            activeClass: .warrior,
            inventory: [],
            journal: []
        )
    }
    
    static func createZeroHealthData() -> HealthData {
        return HealthData(
            steps: 0,
            standingHours: 0,
            heartRate: 0.0,
            exerciseMinutes: 0,
            mindfulMinutes: 0
        )
    }
    
    static func createMinimalQuest() -> Quest {
        return try! Quest(
            id: UUID(),
            title: "Short",
            description: "Min",
            totalDistance: 1.0,
            currentProgress: 0.0,
            isCompleted: false,
            rewardXP: 1,
            rewardGold: 1,
            encounters: []
        )
    }
    
    // MARK: - Batch Data Creation
    
    static func createMultipleQuests(count: Int = 5) -> [Quest] {
        return (0..<count).map { index in
            try! Quest(
                id: UUID(),
                title: "Quest \(index + 1)",
                description: "Test quest number \(index + 1)",
                totalDistance: Double(100 + (index * 50)),
                currentProgress: 0.0,
                isCompleted: false,
                rewardXP: 50 + (index * 10),
                rewardGold: 25 + (index * 5),
                encounters: []
            )
        }
    }
    
    static func createInventoryItems(count: Int = 10) -> [Item] {
        return (0..<count).map { index in
            Item(
                id: UUID(),
                name: "Item \(index + 1)",
                type: ItemType.allCases[index % ItemType.allCases.count],
                level: (index % 10) + 1,
                rarity: Rarity.allCases[index % Rarity.allCases.count],
                effects: [ItemEffect(stat: .strength, amount: index + 1)]
            )
        }
    }
}

// MARK: - Hero Class Extension for Testing

extension HeroClass: CaseIterable {
    public static var allCases: [HeroClass] {
        return [.warrior, .mage, .rogue, .ranger, .cleric]
    }
}

// MARK: - ItemType Extension for Testing

extension ItemType: CaseIterable {
    public static var allCases: [ItemType] {
        return [.weapon, .armor, .trinket, .potion, .misc]
    }
}

// MARK: - Rarity Extension for Testing

extension Rarity: CaseIterable {
    public static var allCases: [Rarity] {
        return [.common, .uncommon, .rare, .epic, .legendary]
    }
}

// MARK: - TutorialStage Extension for Testing

extension TutorialStage: CaseIterable {
    public static var allCases: [TutorialStage] {
        return [.notStarted, .introduction, .basicMovement, .encounter, .rewards, .completion]
    }
}