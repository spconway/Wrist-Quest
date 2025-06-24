import Foundation

enum GameSessionType: String, CaseIterable, Codable {
    case onboarding, quest, settings, inventory, character, stats
    
    var displayName: String {
        switch self {
        case .onboarding: return "Onboarding"
        case .quest: return "Quest"
        case .settings: return "Settings"
        case .inventory: return "Inventory"
        case .character: return "Character"
        case .stats: return "Statistics"
        }
    }
}

struct GameSession: Codable, Identifiable {
    let id: UUID
    let startTime: Date
    var endTime: Date?
    let sessionType: GameSessionType

    init(sessionType: GameSessionType) {
        self.id = UUID()
        self.startTime = Date()
        self.endTime = nil
        self.sessionType = sessionType
    }

    /// Initializer for loading existing sessions from persistence
    init(id: UUID, startTime: Date, endTime: Date?, sessionType: GameSessionType) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.sessionType = sessionType
    }
    
    var duration: TimeInterval? {
        guard let endTime = endTime else { return nil }
        return endTime.timeIntervalSince(startTime)
    }
    
    var isActive: Bool {
        return endTime == nil
    }
    
    mutating func end() {
        if endTime == nil {
            endTime = Date()
        }
    }
    
    var durationDescription: String {
        guard let duration = duration else {
            return "Active"
        }
        
        if duration < 60 {
            return "\(Int(duration))s"
        } else if duration < 3600 {
            return "\(Int(duration / 60))m"
        } else {
            let hours = Int(duration / 3600)
            let minutes = Int((duration.truncatingRemainder(dividingBy: 3600)) / 60)
            return "\(hours)h \(minutes)m"
        }
    }
}