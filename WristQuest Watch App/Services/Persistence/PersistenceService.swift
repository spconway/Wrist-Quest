import Foundation
import CoreData

protocol PersistenceServiceProtocol {
    func savePlayer(_ player: Player) async throws
    func loadPlayer() async throws -> Player?
    func saveQuestLogs(_ questLogs: [QuestLog]) async throws
    func loadQuestLogs() async throws -> [QuestLog]
    func saveActiveQuest(_ quest: Quest) async throws
    func loadActiveQuest() async throws -> Quest?
    func clearActiveQuest() async throws
    func clearAllData() async throws
    func clearPlayerData() async throws
}

actor PersistenceService: PersistenceServiceProtocol {
    private let container: NSPersistentContainer
    private let context: NSManagedObjectContext
    
    init() {
        print("💾 PersistenceService: Initializing Core Data")
        container = NSPersistentContainer(name: "WristQuestDataModel")
        container.loadPersistentStores { _, error in
            if let error = error {
                print("💾 PersistenceService: Core Data failed to load: \(error.localizedDescription)")
                fatalError("Core Data failed to load: \(error.localizedDescription)")
            } else {
                print("💾 PersistenceService: Core Data loaded successfully")
            }
        }
        
        context = container.viewContext
        context.automaticallyMergesChangesFromParent = true
        print("💾 PersistenceService: Core Data initialization complete")
    }
    
    func savePlayer(_ player: Player) async throws {
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
            
            playerEntity.name = player.name
            playerEntity.level = Int32(player.level)
            playerEntity.xp = Int32(player.xp)
            playerEntity.gold = Int32(player.gold)
            playerEntity.stepsToday = Int32(player.stepsToday)
            playerEntity.activeClass = player.activeClass.rawValue
            
            try self.context.save()
        }
    }
    
    func loadPlayer() async throws -> Player? {
        print("💾 PersistenceService: Starting loadPlayer")
        return try await context.perform {
            print("💾 PersistenceService: Inside context.perform")
            let request: NSFetchRequest<PlayerEntity> = PlayerEntity.fetchRequest()
            request.fetchLimit = 1
            
            print("💾 PersistenceService: About to fetch player entities")
            guard let playerEntity = try self.context.fetch(request).first else {
                print("💾 PersistenceService: No player entity found")
                return nil
            }
            
            print("💾 PersistenceService: Found player entity: \(playerEntity.name ?? "nil")")
            let heroClass = HeroClass(rawValue: playerEntity.activeClass ?? "warrior") ?? .warrior
            
            var player = Player(
                name: playerEntity.name ?? "Unknown Hero",
                activeClass: heroClass
            )
            
            // Set the loaded properties
            player.level = Int(playerEntity.level)
            player.xp = Int(playerEntity.xp)
            player.gold = Int(playerEntity.gold)
            player.stepsToday = Int(playerEntity.stepsToday)
            player.inventory = []
            player.journal = []
            print("💾 PersistenceService: Created player object: \(player.name)")
            return player
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
            let playerRequest: NSFetchRequest<NSFetchRequestResult> = PlayerEntity.fetchRequest()
            let playerDeleteRequest = NSBatchDeleteRequest(fetchRequest: playerRequest)
            
            let questLogRequest: NSFetchRequest<NSFetchRequestResult> = QuestLogEntity.fetchRequest()
            let questLogDeleteRequest = NSBatchDeleteRequest(fetchRequest: questLogRequest)
            
            try self.context.execute(playerDeleteRequest)
            try self.context.execute(questLogDeleteRequest)
            try self.context.save()
        }
    }
    
    func clearPlayerData() async throws {
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
        
        var quest = Quest(
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
        try await context.perform {
            let request: NSFetchRequest<ActiveQuestEntity> = ActiveQuestEntity.fetchRequest()
            let activeQuests = try self.context.fetch(request)
            
            for quest in activeQuests {
                self.context.delete(quest)
            }
            
            try self.context.save()
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