import Foundation
import CoreData

protocol PersistenceServiceProtocol {
    func savePlayer(_ player: Player) async throws
    func loadPlayer() async throws -> Player?
    func saveQuestLogs(_ questLogs: [QuestLog]) async throws
    func loadQuestLogs() async throws -> [QuestLog]
    func clearAllData() async throws
    func clearPlayerData() async throws
}

actor PersistenceService: PersistenceServiceProtocol {
    private let container: NSPersistentContainer
    private let context: NSManagedObjectContext
    
    init() {
        container = NSPersistentContainer(name: "WristQuestDataModel")
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Core Data failed to load: \(error.localizedDescription)")
            }
        }
        
        context = container.viewContext
        context.automaticallyMergesChangesFromParent = true
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
        try await context.perform {
            let request: NSFetchRequest<PlayerEntity> = PlayerEntity.fetchRequest()
            request.fetchLimit = 1
            
            guard let playerEntity = try self.context.fetch(request).first else {
                return nil
            }
            
            let heroClass = HeroClass(rawValue: playerEntity.activeClass ?? "warrior") ?? .warrior
            
            return Player(
                id: playerEntity.id ?? UUID(),
                name: playerEntity.name ?? "Unknown Hero",
                level: Int(playerEntity.level),
                xp: Int(playerEntity.xp),
                gold: Int(playerEntity.gold),
                stepsToday: Int(playerEntity.stepsToday),
                activeClass: heroClass,
                inventory: [],
                journal: []
            )
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
}

extension Player {
    init(id: UUID, name: String, level: Int, xp: Int, gold: Int, stepsToday: Int, activeClass: HeroClass, inventory: [Item], journal: [QuestLog]) {
        self.id = id
        self.name = name
        self.level = level
        self.xp = xp
        self.gold = gold
        self.stepsToday = stepsToday
        self.activeClass = activeClass
        self.inventory = inventory
        self.journal = journal
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