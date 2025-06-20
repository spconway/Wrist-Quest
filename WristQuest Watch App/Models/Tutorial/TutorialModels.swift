import Foundation

// MARK: - Tutorial Quest Model

struct TutorialQuest {
    let title: String
    let description: String
    let narrative: String
    let heroClass: HeroClass
    let totalSteps: Int
    var currentStep: Int
}

// MARK: - Tutorial Stage Enum

enum TutorialStage {
    case notStarted
    case introduction
    case firstChallenge
    case encounter
    case finalTest
    case completion
}

// MARK: - Tutorial Dialogue Model

struct TutorialDialogue {
    let speaker: String
    let text: String
    let options: [String]
}

// MARK: - Tutorial Encounter Model

struct TutorialEncounter {
    let type: TutorialEncounterType
    let title: String
    let description: String
    let difficulty: TutorialDifficulty
    let successMessage: String
    let failureMessage: String
}

// MARK: - Tutorial Encounter Type Enum

enum TutorialEncounterType {
    case combat
    case puzzle
    case stealth
    case nature
    case healing
}

// MARK: - Tutorial Difficulty Enum

enum TutorialDifficulty {
    case easy
    case medium
    case hard
}

// MARK: - Tutorial Rewards Model

struct TutorialRewards {
    var xp: Int = 0
    var gold: Int = 0
    var item: String = ""
    var title: String = ""
}

// MARK: - Quest Epic Moment Enum

enum QuestEpicMoment {
    case questBegin(String)
    case questComplete(String)
    case tutorialComplete
}