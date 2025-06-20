import Foundation

// MARK: - Business Logic Validator

/// Validates game-specific business rules and constraints
class BusinessLogicValidator {
    
    static let shared = BusinessLogicValidator()
    
    private init() {}
    
    // MARK: - Level Progression Validation
    
    /// Validates if a player can level up based on current XP
    func validateLevelUp(player: Player, targetLevel: Int) -> ValidationResult {
        // Check if target level is valid
        let levelValidation = InputValidator.shared.validatePlayerLevel(targetLevel)
        if !levelValidation.isValid {
            return levelValidation
        }
        
        // Check if target level is achievable
        guard targetLevel > player.level else {
            return .invalid(message: "Target level must be higher than current level", severity: .error)
        }
        
        // Check if player has enough XP
        let requiredXP = calculateMinXPForLevel(targetLevel)
        guard player.xp >= requiredXP else {
            return .invalid(message: "Insufficient XP for level \(targetLevel). Need \(requiredXP - player.xp) more XP", severity: .error)
        }
        
        // Check if level progression is reasonable (no more than 1 level at a time)
        guard targetLevel <= player.level + 1 else {
            return .invalid(message: "Cannot level up more than one level at a time", severity: .warning)
        }
        
        return .valid
    }
    
    /// Validates if XP gain is reasonable and not exploitative
    public func validateXPGain(currentXP: Int, gainAmount: Int, context: String) -> ValidationResult {
        // Check for negative XP gain
        guard gainAmount >= 0 else {
            return .invalid(message: "XP gain cannot be negative", severity: .error)
        }
        
        // Check for excessive XP gain (potential exploitation)
        let maxReasonableGain = calculateMaxReasonableXPGain(context: context)
        if gainAmount > maxReasonableGain {
            return .invalid(message: "XP gain of \(gainAmount) exceeds reasonable maximum of \(maxReasonableGain) for \(context)", severity: .warning)
        }
        
        // Check if total XP would exceed maximum
        let newTotalXP = currentXP + gainAmount
        let xpValidation = InputValidator.shared.validatePlayerXP(newTotalXP)
        if !xpValidation.isValid {
            return xpValidation
        }
        
        return .valid
    }
    
    // MARK: - Quest Validation
    
    /// Validates quest completion conditions
    func validateQuestCompletion(quest: Quest, player: Player) -> ValidationResult {
        // Check if quest is already completed
        guard !quest.isCompleted else {
            return .invalid(message: "Quest is already completed", severity: .warning)
        }
        
        // Check if progress is sufficient
        guard quest.currentProgress >= quest.totalDistance else {
            return .invalid(message: "Quest progress insufficient for completion", severity: .error)
        }
        
        // Check if player meets any level requirements (if implemented)
        // This could be extended with quest prerequisites
        
        return .valid
    }
    
    /// Validates quest reward distribution
    func validateQuestRewards(quest: Quest, player: Player) -> ValidationResult {
        // Validate XP reward
        let xpValidation = validateXPGain(currentXP: player.xp, gainAmount: quest.rewardXP, context: "quest_completion")
        if !xpValidation.isValid {
            return xpValidation
        }
        
        // Validate gold reward amount
        let goldValidation = InputValidator.shared.validatePlayerGold(player.gold + quest.rewardGold)
        if !goldValidation.isValid {
            return goldValidation
        }
        
        return .valid
    }
    
    /// Validates quest state transition
    func validateQuestStateChange(from oldQuest: Quest, to newQuest: Quest, player: Player) -> ValidationResult {
        // Use the existing quest state transition validation
        let transitionResult = InputValidator.shared.validateQuestStateTransition(from: oldQuest, to: newQuest)
        if !transitionResult.isValid {
            return transitionResult
        }
        
        // Additional business logic checks
        
        // Check if quest completion triggers appropriate player rewards
        if !oldQuest.isCompleted && newQuest.isCompleted {
            let rewardValidation = validateQuestRewards(quest: newQuest, player: player)
            if !rewardValidation.isValid {
                return rewardValidation
            }
        }
        
        return .valid
    }
    
    // MARK: - Inventory Management Validation
    
    /// Validates item addition to inventory
    func validateItemAddition(item: Item, player: Player) -> ValidationResult {
        // Check inventory capacity
        let inventoryValidation = InputValidator.shared.validateInventorySize(player.inventory + [item])
        if !inventoryValidation.isValid {
            return inventoryValidation
        }
        
        // Check if item is appropriate for player level
        if item.level > player.level + 5 { // Allow some flexibility
            return .invalid(message: "Item level (\(item.level)) is too high for player level (\(player.level))", severity: .warning)
        }
        
        // Check for duplicate unique items
        if item.rarity == .legendary || item.rarity == .epic {
            let existingSimilar = player.inventory.filter { $0.name == item.name }
            if !existingSimilar.isEmpty {
                return .invalid(message: "Player already has a similar rare item: \(item.name)", severity: .warning)
            }
        }
        
        return .valid
    }
    
    /// Validates inventory state and consistency
    func validateInventoryState(player: Player) -> [ValidationError] {
        var errors: [ValidationError] = []
        
        // Check total inventory size
        let sizeValidation = InputValidator.shared.validateInventorySize(player.inventory)
        if !sizeValidation.isValid {
            errors.append(ValidationError(field: "inventory_size", message: sizeValidation.message ?? "Invalid inventory size", severity: sizeValidation.severity))
        }
        
        // Check for items with invalid levels
        let invalidLevelItems = player.inventory.filter { $0.level < 1 || $0.level > 100 }
        if !invalidLevelItems.isEmpty {
            errors.append(ValidationError(field: "item_levels", message: "Found \(invalidLevelItems.count) items with invalid levels", severity: .warning))
        }
        
        // Check for duplicate IDs
        let itemIDs = player.inventory.map { $0.id }
        let uniqueIDs = Set(itemIDs)
        if itemIDs.count != uniqueIDs.count {
            errors.append(ValidationError(field: "item_ids", message: "Found duplicate item IDs in inventory", severity: .error))
        }
        
        return errors
    }
    
    // MARK: - Economy Validation
    
    /// Validates gold transactions
    func validateGoldTransaction(player: Player, amount: Int, transactionType: String) -> ValidationResult {
        if amount < 0 {
            // Spending gold
            let spendAmount = abs(amount)
            guard player.gold >= spendAmount else {
                return .invalid(message: "Insufficient gold for \(transactionType). Need \(spendAmount), have \(player.gold)", severity: .error)
            }
            
            // Check for excessive spending (potential exploitation)
            if spendAmount > player.gold / 2 && spendAmount > 1000 {
                return .invalid(message: "Large gold transaction detected: \(spendAmount) for \(transactionType)", severity: .warning)
            }
        } else {
            // Gaining gold
            let gainValidation = validateGoldGain(currentGold: player.gold, gainAmount: amount, context: transactionType)
            if !gainValidation.isValid {
                return gainValidation
            }
        }
        
        return .valid
    }
    
    /// Validates gold gain for potential exploitation
    public func validateGoldGain(currentGold: Int, gainAmount: Int, context: String) -> ValidationResult {
        guard gainAmount >= 0 else {
            return .invalid(message: "Gold gain cannot be negative", severity: .error)
        }
        
        // Check for excessive gold gain
        let maxReasonableGain = calculateMaxReasonableGoldGain(context: context)
        if gainAmount > maxReasonableGain {
            return .invalid(message: "Gold gain of \(gainAmount) exceeds reasonable maximum of \(maxReasonableGain) for \(context)", severity: .warning)
        }
        
        // Check if total gold would exceed maximum
        let newTotalGold = currentGold + gainAmount
        let goldValidation = InputValidator.shared.validatePlayerGold(newTotalGold)
        if !goldValidation.isValid {
            return goldValidation
        }
        
        return .valid
    }
    
    // MARK: - Health Data Business Logic
    
    /// Validates health data for gameplay consistency
    func validateHealthDataForGameplay(healthData: HealthData, previousHealthData: HealthData?) -> ValidationResult {
        // Basic validation first
        let basicValidation = InputValidator.shared.validateHealthData(healthData)
        if !ValidationErrorCollection(basicValidation).hasBlockingErrors {
            // Continue with business logic validation even if there are warnings
        } else {
            return .invalid(message: "Health data failed basic validation", severity: .error)
        }
        
        // Check for unrealistic changes if we have previous data
        if let previous = previousHealthData {
            // Check for impossible step count changes
            let stepDifference = abs(healthData.steps - previous.steps)
            if stepDifference > 10000 { // More than 10k steps change in one update
                return .invalid(message: "Unrealistic step count change: \(stepDifference)", severity: .warning)
            }
            
            // Check for heart rate spikes
            let heartRateDifference = abs(healthData.heartRate - previous.heartRate)
            if heartRateDifference > 50 && previous.heartRate > 0 && healthData.heartRate > 0 {
                return .invalid(message: "Sudden heart rate change: \(heartRateDifference) BPM", severity: .warning)
            }
        }
        
        return .valid
    }
    
    // MARK: - Game State Validation
    
    /// Validates overall game state consistency
    func validateGameState(player: Player, activeQuest: Quest?) -> [ValidationError] {
        var errors: [ValidationError] = []
        
        // Validate player state
        let playerErrors = InputValidator.shared.validatePlayer(player)
        errors.append(contentsOf: playerErrors)
        
        // Validate inventory state
        let inventoryErrors = validateInventoryState(player: player)
        errors.append(contentsOf: inventoryErrors)
        
        // Validate active quest if present
        if let quest = activeQuest {
            let questErrors = InputValidator.shared.validateQuest(quest)
            errors.append(contentsOf: questErrors)
            
            // Validate quest-player relationship
            if quest.isCompleted && quest.currentProgress < quest.totalDistance {
                errors.append(ValidationError(field: "quest_completion", message: "Quest marked complete but progress insufficient", severity: .error))
            }
        }
        
        // Validate level-XP consistency
        let expectedLevel = calculateLevelFromXP(player.xp)
        if expectedLevel != player.level {
            errors.append(ValidationError(field: "level_xp_consistency", message: "Player level (\(player.level)) doesn't match XP (\(player.xp)), expected level \(expectedLevel)", severity: .warning))
        }
        
        return errors
    }
    
    // MARK: - Private Helper Methods
    
    private func calculateMinXPForLevel(_ level: Int) -> Int {
        guard level > 1 else { return 0 }
        
        var totalXP = 0
        for currentLevel in 1..<level {
            let xpForLevel = Int(WQC.XP.baseXPMultiplier * pow(Double(currentLevel), WQC.XP.xpCurveExponent))
            totalXP += xpForLevel
        }
        
        return totalXP
    }
    
    private func calculateLevelFromXP(_ totalXP: Int) -> Int {
        var level = 1
        var xpRequired = 0
        
        while xpRequired < totalXP && level < WQC.Validation.Player.maxLevel {
            level += 1
            let xpForLevel = Int(WQC.XP.baseXPMultiplier * pow(Double(level), WQC.XP.xpCurveExponent))
            xpRequired += xpForLevel
        }
        
        return max(1, level - 1)
    }
    
    private func calculateMaxReasonableXPGain(context: String) -> Int {
        switch context {
        case "quest_completion":
            return 1000 // Maximum XP from a single quest
        case "health_activity":
            return 500  // Maximum XP from health activity in one update
        case "encounter":
            return 200  // Maximum XP from an encounter
        case "daily_bonus":
            return 300  // Maximum daily bonus XP
        default:
            return 100  // Conservative default
        }
    }
    
    private func calculateMaxReasonableGoldGain(context: String) -> Int {
        switch context {
        case "quest_completion":
            return 500  // Maximum gold from a single quest
        case "item_sale":
            return 1000 // Maximum from selling items
        case "encounter":
            return 100  // Maximum gold from an encounter
        case "daily_bonus":
            return 200  // Maximum daily bonus gold
        default:
            return 50   // Conservative default
        }
    }
}

// MARK: - Business Rule Extensions

extension BusinessLogicValidator {
    
    /// Validates if a player action is allowed based on current state
    func validatePlayerAction(_ action: PlayerAction, player: Player, context: GameContext) -> ValidationResult {
        switch action {
        case .startQuest(let quest):
            return validateQuestStart(quest: quest, player: player)
        case .completeQuest(let quest):
            return validateQuestCompletion(quest: quest, player: player)
        case .purchaseItem(let item, let cost):
            return validateItemPurchase(item: item, cost: cost, player: player)
        case .useItem(let item):
            return validateItemUsage(item: item, player: player)
        }
    }
    
    private func validateQuestStart(quest: Quest, player: Player) -> ValidationResult {
        // Check if player meets quest requirements
        // This could include level requirements, prerequisite quests, etc.
        
        // For now, just validate the quest itself
        let questValidation = InputValidator.shared.validateQuest(quest)
        let questErrors = ValidationErrorCollection(questValidation)
        
        if questErrors.hasBlockingErrors {
            return .invalid(message: "Quest validation failed: \(questErrors.summaryMessage())", severity: .error)
        }
        
        return .valid
    }
    
    private func validateItemPurchase(item: Item, cost: Int, player: Player) -> ValidationResult {
        // Check if player has enough gold
        let goldValidation = validateGoldTransaction(player: player, amount: -cost, transactionType: "item_purchase")
        if !goldValidation.isValid {
            return goldValidation
        }
        
        // Check if item can be added to inventory
        let inventoryValidation = validateItemAddition(item: item, player: player)
        if !inventoryValidation.isValid {
            return inventoryValidation
        }
        
        return .valid
    }
    
    private func validateItemUsage(item: Item, player: Player) -> ValidationResult {
        // Check if player owns the item
        guard player.inventory.contains(where: { $0.id == item.id }) else {
            return .invalid(message: "Player does not own this item", severity: .error)
        }
        
        // Check if item can be used (not broken, appropriate level, etc.)
        if item.level > player.level {
            return .invalid(message: "Item level too high for player", severity: .warning)
        }
        
        return .valid
    }
}

// MARK: - Supporting Types

enum PlayerAction {
    case startQuest(Quest)
    case completeQuest(Quest)
    case purchaseItem(Item, cost: Int)
    case useItem(Item)
}

struct GameContext {
    let currentState: String
    let timestamp: Date
    let sessionDuration: TimeInterval
    
    public init(currentState: String, timestamp: Date = Date(), sessionDuration: TimeInterval = 0) {
        self.currentState = currentState
        self.timestamp = timestamp
        self.sessionDuration = sessionDuration
    }
}