import Foundation
import CoreData
import Combine

protocol PersistenceServiceProtocol {
    nonisolated var errorPublisher: AnyPublisher<WQError, Never> { get }
    
    // Player operations
    func savePlayer(_ player: Player) async throws
    func loadPlayer() async throws -> Player?
    func clearPlayerData() async throws
    
    // Quest operations
    func saveQuestLogs(_ questLogs: [QuestLog]) async throws
    func loadQuestLogs() async throws -> [QuestLog]
    func loadQuestLogs(for player: Player) async throws -> [QuestLog]
    func saveActiveQuest(_ quest: Quest, for player: Player) async throws
    func loadActiveQuest(for player: Player) async throws -> Quest?
    func clearActiveQuest(for player: Player) async throws
    
    // Inventory operations
    func saveInventoryItem(_ item: Item, for player: Player) async throws
    func loadInventory(for player: Player) async throws -> [Item]
    func removeInventoryItem(itemId: UUID, from player: Player) async throws
    func updateInventoryItemQuantity(itemId: UUID, quantity: Int32, for player: Player) async throws
    
    // Health data operations
    func saveHealthData(_ healthData: HealthData, for player: Player) async throws
    func loadRecentHealthData(for player: Player, days: Int) async throws -> [HealthData]
    func loadHealthDataForDate(_ date: Date, for player: Player) async throws -> HealthData?
    
    // Game session operations
    func saveGameSession(_ session: GameSession, for player: Player) async throws
    func loadGameSessions(for player: Player, limit: Int?) async throws -> [GameSession]
    func endGameSession(sessionId: UUID, for player: Player) async throws
    
    // Utility operations
    func clearAllData() async throws
    func validateDataIntegrity() async throws -> Bool
    func performDataMigration() async throws
}

actor PersistenceService: PersistenceServiceProtocol {
    private let container: NSPersistentContainer
    private let context: NSManagedObjectContext
    private let errorSubject = PassthroughSubject<WQError, Never>()
    private let logger: LoggingServiceProtocol?
    private let analytics: AnalyticsServiceProtocol?
    
    // Error handling state
    private var retryAttempts: [String: Int] = [:]
    private let maxRetryAttempts = 3
    private let retryDelay: TimeInterval = 1.0
    
    nonisolated var errorPublisher: AnyPublisher<WQError, Never> {
        errorSubject.eraseToAnyPublisher()
    }
    
    // State management for async initialization
    private var isInitialized = false
    private var initializationTask: Task<Void, Error>?
    private let initializationLock = NSLock()
    
    init(logger: LoggingServiceProtocol? = nil, analytics: AnalyticsServiceProtocol? = nil) {
        print("🔄 PersistenceService: Starting non-blocking initialization")
        self.logger = logger
        self.analytics = analytics
        
        print("🔄 PersistenceService: Setting up Core Data container")
        logger?.info("PersistenceService: Starting async Core Data setup", category: .system)
        container = NSPersistentContainer(name: "WristQuestDataModel")
        print("🔄 PersistenceService: Created NSPersistentContainer")
        
        // Configure migration options
        let description = container.persistentStoreDescriptions.first
        description?.shouldInferMappingModelAutomatically = true
        description?.shouldMigrateStoreAutomatically = true
        description?.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description?.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        
        // Initialize context first
        context = container.viewContext
        context.automaticallyMergesChangesFromParent = true
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        print("🔄 PersistenceService: Non-blocking initialization complete")
        logger?.info("PersistenceService: Non-blocking initialization complete", category: .system)
        
        // Start async Core Data loading
        startAsyncInitialization()
    }
    
    convenience init() {
        print("🔄 PersistenceService: Convenience init started")
        // Remove circular dependency - services should not resolve dependencies during init
        print("🔄 PersistenceService: Calling main init without DI resolution")
        self.init(logger: nil, analytics: nil)
    }
    
    // MARK: - Async Initialization
    
    private func startAsyncInitialization() {
        initializationTask = Task {
            print("🔄 PersistenceService: Starting async Core Data loading")
            logger?.info("Starting async Core Data loading", category: .system)
            
            do {
                try await loadPersistentStores()
                
                initializationLock.lock()
                isInitialized = true
                initializationLock.unlock()
                
                print("🔄 PersistenceService: Async Core Data loading complete")
                logger?.info("Async Core Data loading complete", category: .system)
            } catch {
                print("🔄 PersistenceService: Async Core Data loading failed: \(error)")
                let wqError = error as? WQError ?? WQError.persistence(.coreDataUnavailable)
                logger?.error("Async Core Data loading failed: \(error.localizedDescription)", category: .system)
                handleError(wqError)
            }
        }
    }
    
    private func loadPersistentStores() async throws {
        return try await withCheckedThrowingContinuation { continuation in
            container.loadPersistentStores { [weak self] storeDescription, error in
                if let error = error {
                    print("🔄 PersistenceService: Core Data failed to load: \(error)")
                    
                    // Attempt migration recovery
                    if let storeURL = storeDescription.url {
                        self?.attemptStoreRecovery(at: storeURL)
                    }
                    
                    continuation.resume(throwing: WQError.persistence(.coreDataUnavailable))
                } else {
                    print("🔄 PersistenceService: Core Data loaded successfully")
                    continuation.resume()
                }
            }
        }
    }
    
    private func ensureInitialized() async throws {
        initializationLock.lock()
        let initialized = isInitialized
        let task = initializationTask
        initializationLock.unlock()
        
        guard !initialized else { return }
        
        if let task = task {
            try await task.value
        } else {
            throw WQError.persistence(.coreDataUnavailable)
        }
    }
    
    func savePlayer(_ player: Player) async throws {
        try await ensureInitialized()
        logger?.debug("Saving player: \(player.name)", category: .system)
        
        do {
            try await context.perform {
                let request: NSFetchRequest<PlayerEntity> = PlayerEntity.fetchRequest()
                request.predicate = NSPredicate(format: "id == %@", player.id as CVarArg)
                
                let playerEntity: PlayerEntity
                if let existingPlayer = try self.context.fetch(request).first {
                    playerEntity = existingPlayer
                } else {
                    playerEntity = PlayerEntity(context: self.context)
                    playerEntity.id = player.id
                }
                
                // Validate player data before saving
                guard !player.name.isEmpty else {
                    throw WQError.validation(.invalidPlayerName("Player name cannot be empty"))
                }
                
                guard player.level >= 1 && player.level <= 100 else {
                    throw WQError.validation(.rangeError("Level must be between 1 and 100"))
                }
                
                playerEntity.name = player.name
                playerEntity.level = Int32(player.level)
                playerEntity.xp = Int32(player.xp)
                playerEntity.gold = Int32(player.gold)
                playerEntity.stepsToday = Int32(player.stepsToday)
                playerEntity.activeClass = player.activeClass.rawValue
                
                try self.context.save()
                self.logger?.debug("Player saved successfully", category: .system)
            }
        } catch let error as WQError {
            logger?.error("Failed to save player: \(error.errorDescription ?? "Unknown")", category: .system)
            handleError(error)
            throw error
        } catch {
            let wqError = WQError.persistence(.saveFailed("Player save failed: \(error.localizedDescription)"))
            logger?.error("Core Data save failed: \(error.localizedDescription)", category: .system)
            handleError(wqError)
            throw wqError
        }
    }
    
    func loadPlayer() async throws -> Player? {
        print("🔄 PersistenceService: Starting loadPlayer()")
        try await ensureInitialized()
        print("🔄 PersistenceService: Core Data initialized, proceeding with loadPlayer()")
        logger?.debug("Loading player data", category: .system)
        
        do {
            print("🔄 PersistenceService: Calling context.perform")
            return try await context.perform {
                print("🔄 PersistenceService: Inside context.perform, creating fetch request")
                let request: NSFetchRequest<PlayerEntity> = PlayerEntity.fetchRequest()
                request.fetchLimit = 1
                request.relationshipKeyPathsForPrefetching = ["inventory", "questLogs"]
                
                print("🔄 PersistenceService: Executing fetch request")
                guard let playerEntity = try self.context.fetch(request).first else {
                    print("🔄 PersistenceService: No player entity found")
                    self.logger?.info("No player entity found", category: .system)
                    return nil
                }
                
                // Validate loaded data
                guard let playerName = playerEntity.name, !playerName.isEmpty else {
                    throw WQError.persistence(.dataCorrupted)
                }
                
                guard let classRawValue = playerEntity.activeClass,
                      let heroClass = HeroClass(rawValue: classRawValue) else {
                    self.logger?.warning("Invalid hero class found, defaulting to warrior", category: .system)
                    // Use fallback instead of failing
                    let heroClass = HeroClass.warrior
                    
                    var player = try Player(name: playerName, activeClass: heroClass)
                    player.level = max(1, Int(playerEntity.level))
                    player.xp = max(0, Int(playerEntity.xp))
                    player.gold = max(0, Int(playerEntity.gold))
                    player.stepsToday = max(0, Int(playerEntity.stepsToday))
                    player.inventory = self.loadInventoryFromEntities(playerEntity.inventory)
                    player.journal = self.loadQuestLogsFromEntities(playerEntity.questLogs)
                    
                    self.logger?.info("Player loaded with fallback hero class", category: .system)
                    return player
                }
                
                var player = try Player(name: playerName, activeClass: heroClass)
                player.level = max(1, Int(playerEntity.level))
                player.xp = max(0, Int(playerEntity.xp))
                player.gold = max(0, Int(playerEntity.gold))
                player.stepsToday = max(0, Int(playerEntity.stepsToday))
                player.inventory = self.loadInventoryFromEntities(playerEntity.inventory)
                player.journal = self.loadQuestLogsFromEntities(playerEntity.questLogs)
                
                self.logger?.debug("Player loaded successfully: \(player.name)", category: .system)
                return player
            }
        } catch let error as WQError {
            logger?.error("Failed to load player: \(error.errorDescription ?? "Unknown")", category: .system)
            handleError(error)
            throw error
        } catch {
            let wqError = WQError.persistence(.loadFailed("Player load failed: \(error.localizedDescription)"))
            logger?.error("Core Data load failed: \(error.localizedDescription)", category: .system)
            handleError(wqError)
            throw wqError
        }
    }
    
    func saveQuestLogs(_ questLogs: [QuestLog]) async throws {
        try await context.perform {
            let request: NSFetchRequest<QuestLogEntity> = QuestLogEntity.fetchRequest()
            let existingLogs = try self.context.fetch(request)
            
            for log in existingLogs {
                self.context.delete(log)
            }
            
            for questLog in questLogs {
                let entity = QuestLogEntity(context: self.context)
                entity.id = questLog.id
                entity.questId = questLog.questId
                entity.questName = questLog.questName
                entity.completionDate = questLog.completionDate
                entity.summary = questLog.summary
                entity.rewardXP = Int32(questLog.rewards.xp)
                entity.rewardGold = Int32(questLog.rewards.gold)
            }
            
            try self.context.save()
        }
    }
    
    func loadQuestLogs(for player: Player) async throws -> [QuestLog] {
        try await context.perform {
            let request: NSFetchRequest<QuestLogEntity> = QuestLogEntity.fetchRequest()
            request.predicate = NSPredicate(format: "player.id == %@", player.id as CVarArg)
            request.sortDescriptors = [NSSortDescriptor(keyPath: \QuestLogEntity.completionDate, ascending: false)]
            
            let entities = try self.context.fetch(request)
            
            return entities.compactMap { entity in
                guard let id = entity.id,
                      let questId = entity.questId,
                      let questName = entity.questName,
                      let completionDate = entity.completionDate,
                      let summary = entity.summary else {
                    return nil
                }
                
                return QuestLog(
                    id: id,
                    questId: questId,
                    questName: questName,
                    completionDate: completionDate,
                    summary: summary,
                    rewards: QuestRewards(xp: Int(entity.rewardXP), gold: Int(entity.rewardGold))
                )
            }
        }
    }
    
    func saveActiveQuest(_ quest: Quest, for player: Player) async throws {
        try await context.perform {
            // Get the player entity
            let playerRequest: NSFetchRequest<PlayerEntity> = PlayerEntity.fetchRequest()
            playerRequest.predicate = NSPredicate(format: "id == %@", player.id as CVarArg)
            
            guard let playerEntity = try self.context.fetch(playerRequest).first else {
                throw WQError.persistence(.loadFailed("Player not found"))
            }
            
            // Clear any existing active quest
            if let existingQuest = playerEntity.activeQuest {
                self.context.delete(existingQuest)
            }
            
            // Save the new active quest
            let entity = ActiveQuestEntity(context: self.context)
            entity.id = quest.id
            entity.questId = quest.id
            entity.title = quest.title
            entity.questDescription = quest.description
            entity.totalDistance = quest.totalDistance
            entity.currentProgress = quest.currentProgress
            entity.isCompleted = quest.isCompleted
            entity.rewardXP = Int32(quest.rewardXP)
            entity.rewardGold = Int32(quest.rewardGold)
            entity.startDate = Date()
            entity.player = playerEntity
            
            try self.context.save()
        }
    }
    
    func loadActiveQuest(for player: Player) async throws -> Quest? {
        try await context.perform {
            let request: NSFetchRequest<ActiveQuestEntity> = ActiveQuestEntity.fetchRequest()
            request.predicate = NSPredicate(format: "player.id == %@", player.id as CVarArg)
            request.fetchLimit = 1
            
            guard let questEntity = try self.context.fetch(request).first else {
                return nil
            }
            
            var quest = try Quest(
                title: questEntity.title ?? "Unknown Quest",
                description: questEntity.questDescription ?? "",
                totalDistance: questEntity.totalDistance,
                rewardXP: Int(questEntity.rewardXP),
                rewardGold: Int(questEntity.rewardGold),
                encounters: []
            )
            
            // Set the properties that aren't in the initializer
            quest.currentProgress = questEntity.currentProgress
            quest.isCompleted = questEntity.isCompleted
            
            return quest
        }
    }
    
    func clearActiveQuest(for player: Player) async throws {
        do {
            try await context.perform {
                let request: NSFetchRequest<ActiveQuestEntity> = ActiveQuestEntity.fetchRequest()
                request.predicate = NSPredicate(format: "player.id == %@", player.id as CVarArg)
                
                let activeQuests = try self.context.fetch(request)
                
                for quest in activeQuests {
                    self.context.delete(quest)
                }
                
                try self.context.save()
                self.logger?.debug("Active quest cleared successfully", category: .system)
            }
        } catch {
            let wqError = WQError.persistence(.saveFailed("Clear active quest failed: \(error.localizedDescription)"))
            logger?.error("Failed to clear active quest: \(error.localizedDescription)", category: .system)
            handleError(wqError)
            throw wqError
        }
    }
    
    func loadQuestLogs() async throws -> [QuestLog] {
        try await context.perform {
            let request: NSFetchRequest<QuestLogEntity> = QuestLogEntity.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(keyPath: \QuestLogEntity.completionDate, ascending: false)]
            
            let entities = try self.context.fetch(request)
            
            return entities.compactMap { entity in
                guard let id = entity.id,
                      let questId = entity.questId,
                      let questName = entity.questName,
                      let completionDate = entity.completionDate,
                      let summary = entity.summary else {
                    return nil
                }
                
                return QuestLog(
                    id: id,
                    questId: questId,
                    questName: questName,
                    completionDate: completionDate,
                    summary: summary,
                    rewards: QuestRewards(xp: Int(entity.rewardXP), gold: Int(entity.rewardGold))
                )
            }
        }
    }
    
    func clearAllData() async throws {
        try await context.perform {
            // Clear all entities (player deletion will cascade to related entities)
            let playerRequest: NSFetchRequest<NSFetchRequestResult> = PlayerEntity.fetchRequest()
            let playerDeleteRequest = NSBatchDeleteRequest(fetchRequest: playerRequest)
            
            let questLogRequest: NSFetchRequest<NSFetchRequestResult> = QuestLogEntity.fetchRequest()
            let questLogDeleteRequest = NSBatchDeleteRequest(fetchRequest: questLogRequest)
            
            let activeQuestRequest: NSFetchRequest<NSFetchRequestResult> = ActiveQuestEntity.fetchRequest()
            let activeQuestDeleteRequest = NSBatchDeleteRequest(fetchRequest: activeQuestRequest)
            
            let inventoryRequest: NSFetchRequest<NSFetchRequestResult> = InventoryItemEntity.fetchRequest()
            let inventoryDeleteRequest = NSBatchDeleteRequest(fetchRequest: inventoryRequest)
            
            let healthDataRequest: NSFetchRequest<NSFetchRequestResult> = HealthDataEntity.fetchRequest()
            let healthDataDeleteRequest = NSBatchDeleteRequest(fetchRequest: healthDataRequest)
            
            let gameSessionRequest: NSFetchRequest<NSFetchRequestResult> = GameSessionEntity.fetchRequest()
            let gameSessionDeleteRequest = NSBatchDeleteRequest(fetchRequest: gameSessionRequest)
            
            try self.context.execute(playerDeleteRequest)
            try self.context.execute(questLogDeleteRequest)
            try self.context.execute(activeQuestDeleteRequest)
            try self.context.execute(inventoryDeleteRequest)
            try self.context.execute(healthDataDeleteRequest)
            try self.context.execute(gameSessionDeleteRequest)
            try self.context.save()
        }
    }
    
    func clearPlayerData() async throws {
        try await ensureInitialized()
        try await context.perform {
            let playerRequest: NSFetchRequest<NSFetchRequestResult> = PlayerEntity.fetchRequest()
            let playerDeleteRequest = NSBatchDeleteRequest(fetchRequest: playerRequest)
            
            try self.context.execute(playerDeleteRequest)
            try self.context.save()
        }
    }
    
    func saveActiveQuest(_ quest: Quest) async throws {
        try await context.perform {
            // Clear any existing active quest
            let request: NSFetchRequest<ActiveQuestEntity> = ActiveQuestEntity.fetchRequest()
            let existingQuests = try self.context.fetch(request)
            
            for existingQuest in existingQuests {
                self.context.delete(existingQuest)
            }
            
            // Save the new active quest
            let entity = ActiveQuestEntity(context: self.context)
            entity.id = quest.id
            entity.questId = quest.id
            entity.title = quest.title
            entity.questDescription = quest.description
            entity.totalDistance = quest.totalDistance
            entity.currentProgress = quest.currentProgress
            entity.isCompleted = quest.isCompleted
            entity.rewardXP = Int32(quest.rewardXP)
            entity.rewardGold = Int32(quest.rewardGold)
            entity.startDate = Date()
            
            try self.context.save()
        }
    }
    
    func loadActiveQuest() async throws -> Quest? {
        let questEntity = try await context.perform {
            let request: NSFetchRequest<ActiveQuestEntity> = ActiveQuestEntity.fetchRequest()
            request.fetchLimit = 1
            return try self.context.fetch(request).first
        }
        
        guard let questEntity = questEntity else {
            return nil
        }
        
        var quest = try Quest(
            title: questEntity.title ?? "Unknown Quest",
            description: questEntity.questDescription ?? "",
            totalDistance: questEntity.totalDistance,
            rewardXP: Int(questEntity.rewardXP),
            rewardGold: Int(questEntity.rewardGold),
            encounters: []
        )
        
        // Set the properties that aren't in the initializer
        quest.currentProgress = questEntity.currentProgress
        quest.isCompleted = questEntity.isCompleted
        
        return quest
    }
    
    func clearActiveQuest() async throws {
        do {
            try await context.perform {
                let request: NSFetchRequest<ActiveQuestEntity> = ActiveQuestEntity.fetchRequest()
                let activeQuests = try self.context.fetch(request)
                
                for quest in activeQuests {
                    self.context.delete(quest)
                }
                
                try self.context.save()
                self.logger?.debug("Active quest cleared successfully", category: .system)
            }
        } catch {
            let wqError = WQError.persistence(.saveFailed("Clear active quest failed: \(error.localizedDescription)"))
            logger?.error("Failed to clear active quest: \(error.localizedDescription)", category: .system)
            handleError(wqError)
            throw wqError
        }
    }
    
    // MARK: - Inventory Operations
    
    func saveInventoryItem(_ item: Item, for player: Player) async throws {
        try await context.perform {
            // Get the player entity
            let playerRequest: NSFetchRequest<PlayerEntity> = PlayerEntity.fetchRequest()
            playerRequest.predicate = NSPredicate(format: "id == %@", player.id as CVarArg)
            
            guard let playerEntity = try self.context.fetch(playerRequest).first else {
                throw WQError.persistence(.loadFailed("Player not found"))
            }
            
            // Check if item already exists (for stackable items)
            let inventoryRequest: NSFetchRequest<InventoryItemEntity> = InventoryItemEntity.fetchRequest()
            inventoryRequest.predicate = NSPredicate(format: "player == %@ AND itemId == %@", playerEntity, item.id as CVarArg)
            
            let inventoryEntity: InventoryItemEntity
            if let existingItem = try self.context.fetch(inventoryRequest).first {
                // Update existing item quantity
                inventoryEntity = existingItem
                inventoryEntity.quantity += 1
            } else {
                // Create new inventory item
                inventoryEntity = InventoryItemEntity(context: self.context)
                inventoryEntity.id = UUID()
                inventoryEntity.itemId = item.id
                inventoryEntity.itemName = item.name
                inventoryEntity.itemType = item.type.rawValue
                inventoryEntity.itemLevel = Int32(item.level)
                inventoryEntity.itemRarity = item.rarity.rawValue
                inventoryEntity.quantity = 1
                inventoryEntity.player = playerEntity
            }
            
            try self.context.save()
        }
    }
    
    func loadInventory(for player: Player) async throws -> [Item] {
        try await context.perform {
            let request: NSFetchRequest<InventoryItemEntity> = InventoryItemEntity.fetchRequest()
            request.predicate = NSPredicate(format: "player.id == %@", player.id as CVarArg)
            request.sortDescriptors = [
                NSSortDescriptor(keyPath: \InventoryItemEntity.itemType, ascending: true),
                NSSortDescriptor(keyPath: \InventoryItemEntity.itemLevel, ascending: false)
            ]
            
            let entities = try self.context.fetch(request)
            
            return entities.compactMap { entity in
                guard let itemName = entity.itemName,
                      let itemTypeRaw = entity.itemType,
                      let itemType = ItemType(rawValue: itemTypeRaw),
                      let itemRarityRaw = entity.itemRarity,
                      let itemRarity = Rarity(rawValue: itemRarityRaw) else {
                    return nil
                }
                
                return Item(
                    name: itemName,
                    type: itemType,
                    level: Int(entity.itemLevel),
                    rarity: itemRarity
                )
            }
        }
    }
    
    func removeInventoryItem(itemId: UUID, from player: Player) async throws {
        try await context.perform {
            let request: NSFetchRequest<InventoryItemEntity> = InventoryItemEntity.fetchRequest()
            request.predicate = NSPredicate(format: "player.id == %@ AND itemId == %@", player.id as CVarArg, itemId as CVarArg)
            
            if let itemEntity = try self.context.fetch(request).first {
                self.context.delete(itemEntity)
                try self.context.save()
            }
        }
    }
    
    func updateInventoryItemQuantity(itemId: UUID, quantity: Int32, for player: Player) async throws {
        try await context.perform {
            let request: NSFetchRequest<InventoryItemEntity> = InventoryItemEntity.fetchRequest()
            request.predicate = NSPredicate(format: "player.id == %@ AND itemId == %@", player.id as CVarArg, itemId as CVarArg)
            
            if let itemEntity = try self.context.fetch(request).first {
                if quantity > 0 {
                    itemEntity.quantity = quantity
                } else {
                    self.context.delete(itemEntity)
                }
                try self.context.save()
            }
        }
    }
    
    // MARK: - Health Data Operations
    
    func saveHealthData(_ healthData: HealthData, for player: Player) async throws {
        try await context.perform {
            // Get the player entity
            let playerRequest: NSFetchRequest<PlayerEntity> = PlayerEntity.fetchRequest()
            playerRequest.predicate = NSPredicate(format: "id == %@", player.id as CVarArg)
            
            guard let playerEntity = try self.context.fetch(playerRequest).first else {
                throw WQError.persistence(.loadFailed("Player not found"))
            }
            
            let today = Calendar.current.startOfDay(for: Date())
            
            // Check if health data already exists for today
            let healthRequest: NSFetchRequest<HealthDataEntity> = HealthDataEntity.fetchRequest()
            healthRequest.predicate = NSPredicate(format: "player == %@ AND recordDate == %@", playerEntity, today as NSDate)
            
            let healthEntity: HealthDataEntity
            if let existingHealth = try self.context.fetch(healthRequest).first {
                healthEntity = existingHealth
            } else {
                healthEntity = HealthDataEntity(context: self.context)
                healthEntity.id = UUID()
                healthEntity.recordDate = today
                healthEntity.player = playerEntity
            }
            
            healthEntity.steps = Int32(healthData.steps)
            healthEntity.standingHours = Int32(healthData.standingHours)
            healthEntity.heartRate = healthData.heartRate
            healthEntity.exerciseMinutes = Int32(healthData.exerciseMinutes)
            healthEntity.mindfulMinutes = Int32(healthData.mindfulMinutes)
            
            try self.context.save()
        }
    }
    
    func loadRecentHealthData(for player: Player, days: Int) async throws -> [HealthData] {
        try await context.perform {
            let endDate = Date()
            let startDate = Calendar.current.date(byAdding: .day, value: -days, to: endDate) ?? endDate
            
            let request: NSFetchRequest<HealthDataEntity> = HealthDataEntity.fetchRequest()
            request.predicate = NSPredicate(format: "player.id == %@ AND recordDate >= %@ AND recordDate <= %@", 
                                          player.id as CVarArg, startDate as NSDate, endDate as NSDate)
            request.sortDescriptors = [NSSortDescriptor(keyPath: \HealthDataEntity.recordDate, ascending: false)]
            
            let entities = try self.context.fetch(request)
            
            return entities.map { entity in
                HealthData(
                    steps: Int(entity.steps),
                    standingHours: Int(entity.standingHours),
                    heartRate: entity.heartRate,
                    exerciseMinutes: Int(entity.exerciseMinutes),
                    mindfulMinutes: Int(entity.mindfulMinutes)
                )
            }
        }
    }
    
    func loadHealthDataForDate(_ date: Date, for player: Player) async throws -> HealthData? {
        try await context.perform {
            let dayStart = Calendar.current.startOfDay(for: date)
            
            let request: NSFetchRequest<HealthDataEntity> = HealthDataEntity.fetchRequest()
            request.predicate = NSPredicate(format: "player.id == %@ AND recordDate == %@", 
                                          player.id as CVarArg, dayStart as NSDate)
            request.fetchLimit = 1
            
            guard let entity = try self.context.fetch(request).first else {
                return nil
            }
            
            return HealthData(
                steps: Int(entity.steps),
                standingHours: Int(entity.standingHours),
                heartRate: entity.heartRate,
                exerciseMinutes: Int(entity.exerciseMinutes),
                mindfulMinutes: Int(entity.mindfulMinutes)
            )
        }
    }
    
    // MARK: - Game Session Operations
    
    func saveGameSession(_ session: GameSession, for player: Player) async throws {
        try await context.perform {
            // Get the player entity
            let playerRequest: NSFetchRequest<PlayerEntity> = PlayerEntity.fetchRequest()
            playerRequest.predicate = NSPredicate(format: "id == %@", player.id as CVarArg)
            
            guard let playerEntity = try self.context.fetch(playerRequest).first else {
                throw WQError.persistence(.loadFailed("Player not found"))
            }
            
            let sessionEntity = GameSessionEntity(context: self.context)
            sessionEntity.id = session.id
            sessionEntity.startTime = session.startTime
            sessionEntity.endTime = session.endTime
            sessionEntity.sessionType = session.sessionType.rawValue
            sessionEntity.player = playerEntity
            
            try self.context.save()
        }
    }
    
    func loadGameSessions(for player: Player, limit: Int?) async throws -> [GameSession] {
        try await context.perform {
            let request: NSFetchRequest<GameSessionEntity> = GameSessionEntity.fetchRequest()
            request.predicate = NSPredicate(format: "player.id == %@", player.id as CVarArg)
            request.sortDescriptors = [NSSortDescriptor(keyPath: \GameSessionEntity.startTime, ascending: false)]
            
            if let limit = limit {
                request.fetchLimit = limit
            }
            
            let entities = try self.context.fetch(request)
            
            return entities.compactMap { entity in
                guard let sessionTypeRaw = entity.sessionType,
                      let sessionType = GameSessionType(rawValue: sessionTypeRaw),
                      let id = entity.id,
                      let startTime = entity.startTime else {
                    return nil
                }

                return GameSession(
                    id: id,
                    startTime: startTime,
                    endTime: entity.endTime,
                    sessionType: sessionType
                )
            }
        }
    }
    
    func endGameSession(sessionId: UUID, for player: Player) async throws {
        try await context.perform {
            let request: NSFetchRequest<GameSessionEntity> = GameSessionEntity.fetchRequest()
            request.predicate = NSPredicate(format: "player.id == %@ AND id == %@", 
                                          player.id as CVarArg, sessionId as CVarArg)
            
            if let sessionEntity = try self.context.fetch(request).first, sessionEntity.endTime == nil {
                sessionEntity.endTime = Date()
                try self.context.save()
            }
        }
    }
    
    func validateDataIntegrity() async throws -> Bool {
        logger?.info("Validating data integrity", category: .system)
        
        do {
            return try await context.perform {
                // Check for player data integrity
                let playerRequest: NSFetchRequest<PlayerEntity> = PlayerEntity.fetchRequest()
                let players = try self.context.fetch(playerRequest)
                
                for player in players {
                    guard let name = player.name, !name.isEmpty else {
                        throw WQError.persistence(.dataCorrupted)
                    }
                    
                    guard let heroClass = player.activeClass, !heroClass.isEmpty else {
                        throw WQError.persistence(.dataCorrupted)
                    }
                    
                    guard player.level >= 1 && player.level <= 100 else {
                        throw WQError.validation(.rangeError("Invalid player level: \(player.level)"))
                    }
                }
                
                // Check for quest log data integrity
                let questLogRequest: NSFetchRequest<QuestLogEntity> = QuestLogEntity.fetchRequest()
                let questLogs = try self.context.fetch(questLogRequest)
                
                for questLog in questLogs {
                    guard let questName = questLog.questName, !questName.isEmpty else {
                        throw WQError.persistence(.dataCorrupted)
                    }
                    
                    guard questLog.rewardXP >= 0 && questLog.rewardGold >= 0 else {
                        throw WQError.validation(.rangeError("Invalid quest rewards"))
                    }
                }
                
                self.logger?.info("Data integrity validation passed", category: .system)
                return true
            }
        } catch let error as WQError {
            logger?.error("Data integrity validation failed: \(error.errorDescription ?? "Unknown")", category: .system)
            handleError(error)
            throw error
        } catch {
            let wqError = WQError.persistence(.dataCorrupted)
            logger?.error("Data integrity check failed: \(error.localizedDescription)", category: .system)
            handleError(wqError)
            throw wqError
        }
    }
    
    func performDataMigration() async throws {
        logger?.info("Performing data migration if needed", category: .system)
        
        do {
            // Check current model version
            let currentVersion = await getCurrentModelVersion()
            logger?.info("Current Core Data model version: \(currentVersion)", category: .system)
            
            // Perform any custom migration logic for version transitions
            switch currentVersion {
            case "1.0":
                try await migrateFromVersion1To2()
            case "2.0":
                logger?.info("Already on latest model version", category: .system)
            default:
                logger?.warning("Unknown model version: \(currentVersion)", category: .system)
            }
            
            // Validate data integrity after migration
            let isValid = try await validateDataIntegrity()
            if isValid {
                logger?.info("Data migration completed successfully", category: .system)
            }
        } catch {
            logger?.warning("Data migration encountered issues: \(error.localizedDescription)", category: .system)
            throw error
        }
    }
    
    private func getCurrentModelVersion() async -> String {
        await context.perform {
            // Check if the persistent store has a model version identifier
            if let storeMetadata = try? NSPersistentStoreCoordinator.metadataForPersistentStore(
                ofType: NSSQLiteStoreType,
                at: self.container.persistentStoreDescriptions.first?.url ?? URL(fileURLWithPath: ""),
                options: nil
            ) {
                return storeMetadata["NSStoreModelVersionIdentifier"] as? String ?? "1.0"
            }
            return "1.0"
        }
    }
    
    private func migrateFromVersion1To2() async throws {
        logger?.info("Migrating from model version 1.0 to 2.0", category: .system)
        
        // Version 1.0 to 2.0 migration involves:
        // 1. Adding relationships between existing entities
        // 2. Creating new entities (inventory, health data, game sessions)
        // 3. Moving existing data to use relationships
        
        try await context.perform {
            // Load existing players and update their relationships
            let playerRequest: NSFetchRequest<PlayerEntity> = PlayerEntity.fetchRequest()
            let players = try self.context.fetch(playerRequest)
            
            for player in players {
                // Load quest logs and link them to the player
                let questLogRequest: NSFetchRequest<QuestLogEntity> = QuestLogEntity.fetchRequest()
                let questLogs = try self.context.fetch(questLogRequest)
                
                for questLog in questLogs {
                    if questLog.player == nil {
                        questLog.player = player
                    }
                }
                
                // Load active quest and link it to the player
                let activeQuestRequest: NSFetchRequest<ActiveQuestEntity> = ActiveQuestEntity.fetchRequest()
                if let activeQuest = try self.context.fetch(activeQuestRequest).first {
                    if activeQuest.player == nil {
                        activeQuest.player = player
                    }
                }
            }
            
            try self.context.save()
            self.logger?.info("Migration from 1.0 to 2.0 completed", category: .system)
        }
    }
    
    private func attemptStoreRecovery(at storeURL: URL) {
        logger?.warning("Attempting Core Data store recovery", category: .system)
        
        do {
            // Try to remove the corrupted store
            let coordinator = container.persistentStoreCoordinator
            if let store = coordinator.persistentStore(for: storeURL) {
                try coordinator.remove(store)
            }
            
            // Remove the store files
            try FileManager.default.removeItem(at: storeURL)
            
            // Try to recreate the store
            let description = container.persistentStoreDescriptions.first
            description?.shouldInferMappingModelAutomatically = true
            description?.shouldMigrateStoreAutomatically = true
            
            container.loadPersistentStores { [weak self] _, error in
                if let error = error {
                    self?.logger?.error("Store recovery failed: \(error.localizedDescription)", category: .system)
                    fatalError("Core Data recovery failed: \(error.localizedDescription)")
                } else {
                    self?.logger?.info("Core Data store recovery successful", category: .system)
                }
            }
        } catch {
            logger?.error("Store recovery failed: \(error.localizedDescription)", category: .system)
            fatalError("Core Data recovery failed: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Helper Methods
    
    private func loadInventoryFromEntities(_ inventorySet: NSSet?) -> [Item] {
        guard let inventorySet = inventorySet as? Set<InventoryItemEntity> else {
            return []
        }
        
        return inventorySet.compactMap { entity in
            guard let itemName = entity.itemName,
                  let itemTypeRaw = entity.itemType,
                  let itemType = ItemType(rawValue: itemTypeRaw),
                  let itemRarityRaw = entity.itemRarity,
                  let itemRarity = Rarity(rawValue: itemRarityRaw) else {
                return nil
            }
            
            return Item(
                name: itemName,
                type: itemType,
                level: Int(entity.itemLevel),
                rarity: itemRarity
            )
        }
    }
    
    private func loadQuestLogsFromEntities(_ questLogSet: NSSet?) -> [QuestLog] {
        guard let questLogSet = questLogSet as? Set<QuestLogEntity> else {
            return []
        }
        
        return questLogSet.compactMap { entity in
            guard let id = entity.id,
                  let questId = entity.questId,
                  let questName = entity.questName,
                  let completionDate = entity.completionDate,
                  let summary = entity.summary else {
                return nil
            }
            
            return QuestLog(
                id: id,
                questId: questId,
                questName: questName,
                completionDate: completionDate,
                summary: summary,
                rewards: QuestRewards(xp: Int(entity.rewardXP), gold: Int(entity.rewardGold))
            )
        }
    }
    
    // MARK: - Error Handling
    
    private func handleError(_ error: WQError) {
        logger?.error("PersistenceService error: \(error.errorDescription ?? "Unknown")", category: .system)
        analytics?.trackError(
            NSError(domain: "PersistenceService", code: error.errorDescription?.hash ?? 0, userInfo: [
                NSLocalizedDescriptionKey: error.errorDescription ?? "Unknown persistence error"
            ]),
            context: "PersistenceService.handleError"
        )
        
        Task { @MainActor in
            errorSubject.send(error)
        }
    }
    
    private func attemptRetry<T>(operation: @escaping () async throws -> T, operationName: String) async throws -> T {
        let retryKey = "operation_\(operationName)"
        let attempts = retryAttempts[retryKey, default: 0]
        
        do {
            let result = try await operation()
            // Reset retry count on success
            retryAttempts.removeValue(forKey: retryKey)
            return result
        } catch {
            if attempts < maxRetryAttempts {
                retryAttempts[retryKey] = attempts + 1
                logger?.warning("Operation \(operationName) failed, retrying (\(attempts + 1)/\(maxRetryAttempts))", category: .system)
                
                // Wait before retry
                try await Task.sleep(nanoseconds: UInt64(retryDelay * Double(attempts + 1) * 1_000_000_000))
                
                return try await attemptRetry(operation: operation, operationName: operationName)
            } else {
                retryAttempts.removeValue(forKey: retryKey)
                throw error
            }
        }
    }
}


extension QuestLog {
    init(id: UUID, questId: UUID, questName: String, completionDate: Date, summary: String, rewards: QuestRewards) {
        self.id = id
        self.questId = questId
        self.questName = questName
        self.completionDate = completionDate
        self.summary = summary
        self.rewards = rewards
    }
}