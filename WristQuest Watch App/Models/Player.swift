import Foundation

struct Player: Codable, Identifiable {
    let id: UUID
    private var _name: String
    private var _level: Int
    private var _xp: Int
    private var _gold: Int
    var stepsToday: Int
    var activeClass: HeroClass
    private var _inventory: [Item]
    var journal: [QuestLog]
    
    // MARK: - Validated Properties
    
    var name: String {
        get { _name }
        set {
            let validationResult = InputValidator.shared.validatePlayerName(newValue)
            if validationResult.isValid {
                _name = newValue
            } else {
                ValidationLogger.shared.logValidationErrors(
                    [ValidationError(field: "name", message: validationResult.message ?? "Invalid name", severity: validationResult.severity)],
                    context: .gameplayContext
                )
                // Keep the old value if validation fails
            }
        }
    }
    
    var level: Int {
        get { _level }
        set {
            let validationResult = InputValidator.shared.validatePlayerLevel(newValue)
            if validationResult.isValid {
                _level = newValue
            } else {
                ValidationLogger.shared.logValidationErrors(
                    [ValidationError(field: "level", message: validationResult.message ?? "Invalid level", severity: validationResult.severity)],
                    context: .gameplayContext
                )
                // Keep the old value if validation fails
            }
        }
    }
    
    var xp: Int {
        get { _xp }
        set {
            let validationResult = InputValidator.shared.validatePlayerXP(newValue)
            if validationResult.isValid {
                _xp = newValue
            } else {
                ValidationLogger.shared.logValidationErrors(
                    [ValidationError(field: "xp", message: validationResult.message ?? "Invalid XP", severity: validationResult.severity)],
                    context: .gameplayContext
                )
                // Keep the old value if validation fails
            }
        }
    }
    
    var gold: Int {
        get { _gold }
        set {
            let validationResult = InputValidator.shared.validatePlayerGold(newValue)
            if validationResult.isValid {
                _gold = newValue
            } else {
                ValidationLogger.shared.logValidationErrors(
                    [ValidationError(field: "gold", message: validationResult.message ?? "Invalid gold", severity: validationResult.severity)],
                    context: .gameplayContext
                )
                // Keep the old value if validation fails
            }
        }
    }
    
    var inventory: [Item] {
        get { _inventory }
        set {
            let validationResult = InputValidator.shared.validateInventorySize(newValue)
            if validationResult.isValid {
                _inventory = newValue
            } else {
                ValidationLogger.shared.logValidationErrors(
                    [ValidationError(field: "inventory", message: validationResult.message ?? "Invalid inventory", severity: validationResult.severity)],
                    context: .gameplayContext
                )
                // Keep the old value if validation fails
            }
        }
    }
    
    // MARK: - Initializers
    
    init(name: String, activeClass: HeroClass) throws {
        // Validate input parameters
        let validationErrors = InputValidator.shared.validatePlayerCreation(name: name, heroClass: activeClass)
        
        if !validationErrors.isEmpty {
            ValidationLogger.shared.logValidationErrors(validationErrors, context: .onboardingContext)
            
            // Check if there are any blocking errors
            let blockingErrors = validationErrors.filter { $0.isBlocking }
            if !blockingErrors.isEmpty {
                let firstBlockingError = blockingErrors.first!
                throw WQError.validation(.invalidPlayerName(firstBlockingError.message))
            }
        }
        
        self.id = UUID()
        self._name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        self._level = 1
        self._xp = 0
        self._gold = 0
        self.stepsToday = 0
        self.activeClass = activeClass
        self._inventory = []
        self.journal = []
        
        // Validate the complete player object
        let playerValidationErrors = InputValidator.shared.validatePlayer(self)
        if !playerValidationErrors.isEmpty {
            ValidationLogger.shared.logValidationErrors(playerValidationErrors, context: .onboardingContext)
        }
    }
    
    // MARK: - Safe Initializer (for existing data)
    
    /// Initializer for loading existing player data with validation
    init(id: UUID, name: String, level: Int, xp: Int, gold: Int, stepsToday: Int, activeClass: HeroClass, inventory: [Item], journal: [QuestLog]) {
        self.id = id
        self.stepsToday = stepsToday
        self.activeClass = activeClass
        self.journal = journal
        
        // Validate and set properties with fallbacks
        let nameValidation = InputValidator.shared.validatePlayerName(name)
        self._name = nameValidation.isValid ? name.trimmingCharacters(in: .whitespacesAndNewlines) : WQC.Defaults.defaultHeroName
        
        let levelValidation = InputValidator.shared.validatePlayerLevel(level)
        self._level = levelValidation.isValid ? level : 1
        
        let xpValidation = InputValidator.shared.validatePlayerXP(xp)
        self._xp = xpValidation.isValid ? xp : 0
        
        let goldValidation = InputValidator.shared.validatePlayerGold(gold)
        self._gold = goldValidation.isValid ? gold : 0
        
        let inventoryValidation = InputValidator.shared.validateInventorySize(inventory)
        self._inventory = inventoryValidation.isValid ? inventory : []
        
        // Log any validation issues
        var errors: [ValidationError] = []
        if !nameValidation.isValid {
            errors.append(ValidationError(field: "name", message: nameValidation.message ?? "Invalid name", severity: nameValidation.severity))
        }
        if !levelValidation.isValid {
            errors.append(ValidationError(field: "level", message: levelValidation.message ?? "Invalid level", severity: levelValidation.severity))
        }
        if !xpValidation.isValid {
            errors.append(ValidationError(field: "xp", message: xpValidation.message ?? "Invalid XP", severity: xpValidation.severity))
        }
        if !goldValidation.isValid {
            errors.append(ValidationError(field: "gold", message: goldValidation.message ?? "Invalid gold", severity: goldValidation.severity))
        }
        if !inventoryValidation.isValid {
            errors.append(ValidationError(field: "inventory", message: inventoryValidation.message ?? "Invalid inventory", severity: inventoryValidation.severity))
        }
        
        if !errors.isEmpty {
            ValidationLogger.shared.logValidationErrors(errors, context: .persistenceContext)
        }
    }
    
    // MARK: - Validation Methods
    
    /// Validates the current player state
    func validate() -> ValidationErrorCollection {
        let errors = InputValidator.shared.validatePlayer(self)
        return ValidationErrorCollection(errors)
    }
    
    /// Checks if the player data is in a valid state
    var isValid: Bool {
        return validate().errors.isEmpty
    }
    
    // MARK: - Safe Update Methods
    
    /// Safely updates player name with validation
    @discardableResult
    mutating func updateName(_ newName: String) -> ValidationResult {
        let validationResult = InputValidator.shared.validatePlayerName(newName)
        if validationResult.isValid {
            _name = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            ValidationLogger.shared.logValidationErrors(
                [ValidationError(field: "name", message: validationResult.message ?? "Invalid name", severity: validationResult.severity)],
                context: .gameplayContext
            )
        }
        return validationResult
    }
    
    /// Safely adds XP with validation
    @discardableResult
    mutating func addXP(_ amount: Int) -> ValidationResult {
        let newXP = _xp + amount
        let validationResult = InputValidator.shared.validatePlayerXP(newXP)
        if validationResult.isValid {
            _xp = newXP
            
            // Check for level up
            checkForLevelUp()
        } else {
            ValidationLogger.shared.logValidationErrors(
                [ValidationError(field: "xp", message: validationResult.message ?? "Invalid XP amount", severity: validationResult.severity)],
                context: .gameplayContext
            )
        }
        return validationResult
    }
    
    /// Safely adds gold with validation
    @discardableResult
    mutating func addGold(_ amount: Int) -> ValidationResult {
        let newGold = _gold + amount
        let validationResult = InputValidator.shared.validatePlayerGold(newGold)
        if validationResult.isValid {
            _gold = newGold
        } else {
            ValidationLogger.shared.logValidationErrors(
                [ValidationError(field: "gold", message: validationResult.message ?? "Invalid gold amount", severity: validationResult.severity)],
                context: .gameplayContext
            )
        }
        return validationResult
    }
    
    /// Safely adds item to inventory with validation
    @discardableResult
    mutating func addItem(_ item: Item) -> ValidationResult {
        var newInventory = _inventory
        newInventory.append(item)
        
        let validationResult = InputValidator.shared.validateInventorySize(newInventory)
        if validationResult.isValid {
            _inventory = newInventory
        } else {
            ValidationLogger.shared.logValidationErrors(
                [ValidationError(field: "inventory", message: validationResult.message ?? "Cannot add item", severity: validationResult.severity)],
                context: .gameplayContext
            )
        }
        return validationResult
    }
    
    // MARK: - Private Methods
    
    private mutating func checkForLevelUp() {
        let expectedLevel = calculateLevelFromXP(_xp)
        if expectedLevel > _level {
            let oldLevel = _level
            _level = expectedLevel
            
            // Log level up for analytics
            ValidationLogger.shared.logValidationEvent(
                ValidationEvent(
                    context: .gameplayContext,
                    validationType: .levelProgression,
                    input: "Level up from \(oldLevel) to \(_level)",
                    result: .valid
                )
            )
        }
    }
    
    private func calculateLevelFromXP(_ totalXP: Int) -> Int {
        var level = 1
        var xpRequired = 0
        
        while xpRequired < totalXP && level < WQC.Validation.Player.maxLevel {
            level += 1
            let xpForLevel = Int(WQC.XP.baseXPMultiplier * pow(Double(level), WQC.XP.xpCurveExponent))
            xpRequired += xpForLevel
        }
        
        return max(1, level - 1) // Return the level we can actually afford
    }
    
    // MARK: - Preview
    
    static var preview: Player {
        do {
            return try Player(name: "Hero", activeClass: .warrior)
        } catch {
            // Fallback for preview - this should never happen with valid input
            return Player(
                id: UUID(),
                name: "Hero",
                level: 1,
                xp: 0,
                gold: 0,
                stepsToday: 0,
                activeClass: .warrior,
                inventory: [],
                journal: []
            )
        }
    }
}

// MARK: - Codable Implementation

extension Player {
    enum CodingKeys: String, CodingKey {
        case id, name = "_name", level = "_level", xp = "_xp", gold = "_gold", stepsToday, activeClass, inventory = "_inventory", journal
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let id = try container.decode(UUID.self, forKey: .id)
        let name = try container.decode(String.self, forKey: .name)
        let level = try container.decode(Int.self, forKey: .level)
        let xp = try container.decode(Int.self, forKey: .xp)
        let gold = try container.decode(Int.self, forKey: .gold)
        let stepsToday = try container.decode(Int.self, forKey: .stepsToday)
        let activeClass = try container.decode(HeroClass.self, forKey: .activeClass)
        let inventory = try container.decode([Item].self, forKey: .inventory)
        let journal = try container.decode([QuestLog].self, forKey: .journal)
        
        // Use safe initializer for loaded data
        self.init(
            id: id,
            name: name,
            level: level,
            xp: xp,
            gold: gold,
            stepsToday: stepsToday,
            activeClass: activeClass,
            inventory: inventory,
            journal: journal
        )
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(_name, forKey: .name)
        try container.encode(_level, forKey: .level)
        try container.encode(_xp, forKey: .xp)
        try container.encode(_gold, forKey: .gold)
        try container.encode(stepsToday, forKey: .stepsToday)
        try container.encode(activeClass, forKey: .activeClass)
        try container.encode(_inventory, forKey: .inventory)
        try container.encode(journal, forKey: .journal)
    }
}