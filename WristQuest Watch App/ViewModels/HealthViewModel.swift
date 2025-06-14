import Foundation
import SwiftUI
import Combine

@MainActor
class HealthViewModel: ObservableObject {
    @Published var currentHealthData = HealthData()
    @Published var isAuthorized = false
    @Published var authorizationStatus: HealthAuthorizationStatus = .notDetermined
    @Published var dailyActivityScore = 0
    @Published var isInCombatMode = false
    
    private var cancellables = Set<AnyCancellable>()
    private let healthService: HealthServiceProtocol
    
    init(healthService: HealthServiceProtocol = HealthService()) {
        self.healthService = healthService
        
        setupSubscriptions()
        checkAuthorizationStatus()
    }
    
    private func setupSubscriptions() {
        healthService.healthDataPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] healthData in
                self?.updateHealthData(healthData)
            }
            .store(in: &cancellables)
        
        healthService.authorizationStatusPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.authorizationStatus = status
                self?.isAuthorized = status == .authorized
            }
            .store(in: &cancellables)
    }
    
    func requestHealthAuthorization() async {
        do {
            try await healthService.requestAuthorization()
        } catch {
            print("Failed to request health authorization: \(error)")
        }
    }
    
    func startHealthMonitoring() {
        Task {
            await healthService.startMonitoring()
        }
    }
    
    func stopHealthMonitoring() {
        healthService.stopMonitoring()
    }
    
    private func updateHealthData(_ healthData: HealthData) {
        currentHealthData = healthData
        dailyActivityScore = healthData.dailyActivityScore
        isInCombatMode = healthData.isInCombatMode
    }
    
    private func checkAuthorizationStatus() {
        Task {
            let status = await healthService.checkAuthorizationStatus()
            await MainActor.run {
                authorizationStatus = status
                isAuthorized = status == .authorized
            }
        }
    }
    
    func getClassBonusDescription(for heroClass: HeroClass) -> String {
        switch heroClass {
        case .warrior:
            return "Your steps count for \(Int(1.1 * 100))% normal XP"
        case .mage:
            return "Minor encounters auto-complete"
        case .rogue:
            return "Quest distances reduced by 25%"
        case .ranger:
            return "Outdoor workouts provide bonus XP"
        case .cleric:
            return "Mindful minutes restore health"
        }
    }
    
    func getActivitySummary() -> String {
        let data = currentHealthData
        var summary: [String] = []
        
        if data.steps > 0 {
            summary.append("\(data.steps) steps")
        }
        
        if data.standingHours > 0 {
            summary.append("\(data.standingHours) stand hours")
        }
        
        if data.exerciseMinutes > 0 {
            summary.append("\(data.exerciseMinutes) exercise minutes")
        }
        
        if data.mindfulMinutes > 0 {
            summary.append("\(data.mindfulMinutes) mindful minutes")
        }
        
        return summary.isEmpty ? "No activity data" : summary.joined(separator: ", ")
    }
    
    // MARK: - UI Convenience Properties
    var isHealthDataAvailable: Bool {
        return isAuthorized
    }
    
    var todaySteps: Int {
        return currentHealthData.steps
    }
    
    var standHours: Int {
        return currentHealthData.standingHours
    }
    
    var exerciseMinutes: Int {
        return currentHealthData.exerciseMinutes
    }
    
    // MARK: - Settings Methods
    func requestHealthPermissions() {
        Task {
            await requestHealthAuthorization()
        }
    }
    
    func simulateSteps(_ steps: Int) {
        // Debug method for simulating step data
        currentHealthData = HealthData(
            steps: currentHealthData.steps + steps,
            standingHours: currentHealthData.standingHours,
            heartRate: currentHealthData.heartRate,
            exerciseMinutes: currentHealthData.exerciseMinutes,
            mindfulMinutes: currentHealthData.mindfulMinutes
        )
    }
}

enum HealthAuthorizationStatus {
    case notDetermined
    case denied
    case authorized
    case restricted
}