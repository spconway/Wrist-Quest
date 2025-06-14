import Foundation

struct HealthData: Codable {
    var steps: Int
    var standingHours: Int
    var heartRate: Double
    var exerciseMinutes: Int
    var mindfulMinutes: Int
    
    init(steps: Int = 0, standingHours: Int = 0, heartRate: Double = 0.0, exerciseMinutes: Int = 0, mindfulMinutes: Int = 0) {
        self.steps = steps
        self.standingHours = standingHours
        self.heartRate = heartRate
        self.exerciseMinutes = exerciseMinutes
        self.mindfulMinutes = mindfulMinutes
    }
    
    var isInCombatMode: Bool {
        heartRate > 120.0
    }
    
    var dailyActivityScore: Int {
        let stepScore = min(steps / 100, 100)
        let standScore = standingHours * 10
        let exerciseScore = exerciseMinutes * 2
        let mindfulScore = mindfulMinutes * 3
        
        return stepScore + standScore + exerciseScore + mindfulScore
    }
}