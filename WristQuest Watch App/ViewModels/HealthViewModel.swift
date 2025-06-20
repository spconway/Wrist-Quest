import Foundation
import SwiftUI
import Combine

// Note: WQConstants are accessed globally via WQC typealias

@MainActor
class HealthViewModel: ObservableObject {
    @Published var currentHealthData = HealthData()
    @Published var isAuthorized = false
    @Published var authorizationStatus: HealthAuthorizationStatus = .notDetermined
    @Published var dailyActivityScore = 0
    @Published var isInCombatMode = false
    @Published var isMonitoring = false
    @Published var healthServiceError: WQError?
    
    private var cancellables = Set<AnyCancellable>()
    private let healthService: HealthServiceProtocol
    private let logger: LoggingServiceProtocol?
    private let analytics: AnalyticsServiceProtocol?
    
    // Performance monitoring
    private var lastHealthDataUpdate = Date()
    private let updateThrottleInterval: TimeInterval = 1.0
    
    convenience init() {
        // Create services directly to avoid circular dependency during DI setup
        let logger = LoggingService()
        let analytics = AnalyticsService(logger: logger)
        let healthService = HealthService(logger: logger, analytics: analytics)
        
        self.init(
            healthService: healthService,
            logger: logger,
            analytics: analytics
        )
    }
    
    init(healthService: HealthServiceProtocol,
         logger: LoggingServiceProtocol?,
         analytics: AnalyticsServiceProtocol?) {
        self.healthService = healthService
        self.logger = logger
        self.analytics = analytics
        
        logger?.info("HealthViewModel initializing", category: .health)
        setupSubscriptions()
        checkAuthorizationStatus()
    }
    
    private func setupSubscriptions() {
        // Health data subscription with throttling
        healthService.healthDataPublisher
            .throttle(for: .seconds(updateThrottleInterval), scheduler: DispatchQueue.main, latest: true)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] healthData in
                self?.updateHealthDataOptimized(healthData)
            }
            .store(in: &cancellables)
        
        // Authorization status subscription
        healthService.authorizationStatusPublisher
            .receive(on: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] status in
                self?.handleAuthorizationStatusChange(status)
            }
            .store(in: &cancellables)
        
        // Error handling subscription
        healthService.errorPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                self?.handleHealthServiceError(error)
            }
            .store(in: &cancellables)
    }
    
    func requestHealthAuthorization() async {
        logger?.info("Requesting health authorization", category: .health)
        do {
            try await healthService.requestAuthorization()
            logger?.info("Health authorization request completed", category: .health)
            analytics?.trackGameAction(.healthPermissionGranted, parameters: nil)
        } catch {
            logger?.error("Failed to request health authorization: \(error.localizedDescription)", category: .health)
            analytics?.trackGameAction(.healthPermissionDenied, parameters: ["error": error.localizedDescription])
            analytics?.trackError(error, context: "HealthViewModel.requestHealthAuthorization")
        }
    }
    
    func startHealthMonitoring() {
        logger?.info("Starting health monitoring", category: .health)
        Task {
            do {
                try await healthService.startMonitoring()
                await MainActor.run {
                    self.isMonitoring = true
                    self.healthServiceError = nil
                }
                logger?.info("Health monitoring started successfully", category: .health)
            } catch {
                await MainActor.run {
                    self.isMonitoring = false
                    if let wqError = error as? WQError {
                        self.healthServiceError = wqError
                    } else {
                        self.healthServiceError = WQError.healthKit(.queryFailed(error.localizedDescription))
                    }
                }
                logger?.error("Failed to start health monitoring: \(error.localizedDescription)", category: .health)
                analytics?.trackError(error, context: "HealthViewModel.startHealthMonitoring")
            }
        }
    }
    
    func stopHealthMonitoring() {
        logger?.info("Stopping health monitoring", category: .health)
        healthService.stopMonitoring()
        isMonitoring = false
        healthServiceError = nil
    }
    
    private func updateHealthDataOptimized(_ healthData: HealthData) {
        let now = Date()
        let timeSinceLastUpdate = now.timeIntervalSince(lastHealthDataUpdate)
        
        // Skip update if too frequent (additional throttling)
        guard timeSinceLastUpdate >= updateThrottleInterval else {
            return
        }
        
        let previousData = currentHealthData
        
        // Only update if data actually changed
        guard !isHealthDataEqual(previousData, healthData) else {
            return
        }
        
        // Check for combat mode changes before updating
        let wasPreviouslyInCombat = previousData.isInCombatMode
        let isNowInCombat = healthData.isInCombatMode
        
        currentHealthData = healthData
        dailyActivityScore = healthData.dailyActivityScore
        isInCombatMode = healthData.isInCombatMode
        lastHealthDataUpdate = now
        
        // Announce combat mode changes for accessibility
        if isNowInCombat && !wasPreviouslyInCombat {
            AccessibilityHelpers.announceCombatMode()
        }
        
        // Log significant health data changes
        logHealthDataChanges(previous: previousData, current: healthData)
        
        // Track daily step milestones
        trackStepMilestones(previous: previousData, current: healthData)
    }
    
    private func isHealthDataEqual(_ lhs: HealthData, _ rhs: HealthData) -> Bool {
        return lhs.steps == rhs.steps &&
               lhs.standingHours == rhs.standingHours &&
               abs(lhs.heartRate - rhs.heartRate) < 1.0 &&
               lhs.exerciseMinutes == rhs.exerciseMinutes &&
               lhs.mindfulMinutes == rhs.mindfulMinutes
    }
    
    private func logHealthDataChanges(previous: HealthData, current: HealthData) {
        var changes: [String] = []
        
        if current.steps != previous.steps {
            changes.append("Steps: \(previous.steps) → \(current.steps)")
        }
        if abs(current.heartRate - previous.heartRate) >= 1.0 {
            changes.append("Heart Rate: \(Int(previous.heartRate)) → \(Int(current.heartRate)) bpm")
        }
        if current.exerciseMinutes != previous.exerciseMinutes {
            changes.append("Exercise: \(previous.exerciseMinutes) → \(current.exerciseMinutes) min")
        }
        if current.standingHours != previous.standingHours {
            changes.append("Stand Hours: \(previous.standingHours) → \(current.standingHours)")
        }
        if current.mindfulMinutes != previous.mindfulMinutes {
            changes.append("Mindful: \(previous.mindfulMinutes) → \(current.mindfulMinutes) min")
        }
        
        if !changes.isEmpty {
            logger?.debug("Health data updated - \(changes.joined(separator: ", "))", category: .health)
        }
    }
    
    private func trackStepMilestones(previous: HealthData, current: HealthData) {
        let stepMilestones = [1000, 5000, 10000, 15000, 20000]
        
        for milestone in stepMilestones {
            if current.steps >= milestone && previous.steps < milestone {
                analytics?.trackGameAction(.healthPermissionGranted, parameters: [
                    "milestone_type": "steps",
                    "milestone_value": milestone,
                    "actual_steps": current.steps
                ])
                logger?.info("Step milestone reached: \(milestone) steps", category: .health)
                
                // Announce step milestones for accessibility
                AccessibilityHelpers.announceActivityMilestone(
                    activityType: "steps",
                    value: "\(milestone)"
                )
            }
        }
    }
    
    private func handleAuthorizationStatusChange(_ status: HealthAuthorizationStatus) {
        authorizationStatus = status
        isAuthorized = status == .authorized
        logger?.info("Health authorization status changed: \(status)", category: .health)
        analytics?.trackUserProperty(.healthPermission, value: "\(status)")
        
        // Auto-start monitoring if authorized and not already monitoring
        if status == .authorized && !isMonitoring {
            startHealthMonitoring()
        } else if status != .authorized && isMonitoring {
            stopHealthMonitoring()
        }
    }
    
    private func handleHealthServiceError(_ error: WQError) {
        healthServiceError = error
        logger?.error("Health service error: \(error.errorDescription ?? "Unknown")", category: .health)
        analytics?.trackError(
            NSError(domain: "HealthViewModel", code: error.errorDescription?.hash ?? 0, userInfo: [
                NSLocalizedDescriptionKey: error.errorDescription ?? "Unknown health error"
            ]),
            context: "HealthViewModel.handleHealthServiceError"
        )
    }
    
    private func checkAuthorizationStatus() {
        Task {
            let status = await healthService.checkAuthorizationStatus()
            await MainActor.run {
                authorizationStatus = status
                isAuthorized = status == .authorized
                logger?.info("Initial health authorization status: \(status)", category: .health)
                analytics?.trackUserProperty(.healthPermission, value: "\(status)")
            }
        }
    }
    
    func getClassBonusDescription(for heroClass: HeroClass) -> String {
        switch heroClass {
        case .warrior:
            return "Your steps count for \(Int(WQC.XP.warriorXPBonus * 100))% normal XP"
        case .mage:
            return "Minor encounters auto-complete"
        case .rogue:
            return "Quest distances reduced by \(Int((1.0 - WQC.Quest.rogueDistanceReduction) * 100))%"
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
        return isAuthorized && isMonitoring
    }
    
    var hasRecentHealthData: Bool {
        let timeSinceUpdate = Date().timeIntervalSince(lastHealthDataUpdate)
        return timeSinceUpdate < 300 // 5 minutes
    }
    
    var healthStatusDescription: String {
        if !isAuthorized {
            return "Health access not authorized"
        } else if !isMonitoring {
            return "Health monitoring not active"
        } else if let error = healthServiceError {
            return "Health error: \(error.userMessage)"
        } else if hasRecentHealthData {
            return "Health monitoring active"
        } else {
            return "Waiting for health data"
        }
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
    
    // MARK: - Debug Methods
    
    #if DEBUG
    func simulateSteps(_ steps: Int) {
        // Debug method for simulating step data
        let newData = HealthData(
            steps: currentHealthData.steps + steps,
            standingHours: currentHealthData.standingHours,
            heartRate: currentHealthData.heartRate,
            exerciseMinutes: currentHealthData.exerciseMinutes,
            mindfulMinutes: currentHealthData.mindfulMinutes
        )
        updateHealthDataOptimized(newData)
        logger?.debug("Simulated \(steps) additional steps", category: .health)
    }
    
    func simulateHeartRate(_ bpm: Double) {
        let newData = HealthData(
            steps: currentHealthData.steps,
            standingHours: currentHealthData.standingHours,
            heartRate: bpm,
            exerciseMinutes: currentHealthData.exerciseMinutes,
            mindfulMinutes: currentHealthData.mindfulMinutes
        )
        updateHealthDataOptimized(newData)
        logger?.debug("Simulated heart rate: \(bpm) bpm", category: .health)
    }
    
    func getHealthServiceDebugInfo() -> String {
        guard let healthService = healthService as? HealthService else {
            return "Debug info not available"
        }
        
        let activeQueries = healthService.getActiveQueryCount()
        let powerSaving = healthService.isInPowerSavingMode()
        
        var info = "Active Queries: \(activeQueries)\n"
        info += "Power Saving Mode: \(powerSaving)\n"
        info += "Query Metrics: Available via HealthService\n"
        
        return info
    }
    #endif
}

enum HealthAuthorizationStatus {
    case notDetermined
    case denied
    case authorized
    case restricted
}