import Foundation
import WatchKit
import Combine

class BackgroundTaskManager: NSObject, ObservableObject {
    private var backgroundTask: WKApplicationRefreshBackgroundTask?
    private let healthService: HealthServiceProtocol
    private let persistenceService: PersistenceServiceProtocol
    private let logger: LoggingServiceProtocol?
    private let analytics: AnalyticsServiceProtocol?
    private let errorSubject = PassthroughSubject<WQError, Never>()
    
    // Error handling state
    private var consecutiveFailures = 0
    private let maxConsecutiveFailures = 3
    private var lastSuccessfulSync: Date?
    
    var errorPublisher: AnyPublisher<WQError, Never> {
        errorSubject.eraseToAnyPublisher()
    }
    
    init(healthService: HealthServiceProtocol = HealthService(),
         persistenceService: PersistenceServiceProtocol = PersistenceService(),
         logger: LoggingServiceProtocol? = nil,
         analytics: AnalyticsServiceProtocol? = nil) {
        self.healthService = healthService
        self.persistenceService = persistenceService
        self.logger = logger
        self.analytics = analytics
        super.init()
        
        logger?.info("BackgroundTaskManager initializing", category: .background)
        setupBackgroundTaskHandling()
    }
    
    convenience override init() {
        let config = DIConfiguration.shared
        self.init(
            healthService: config.resolveHealthService(),
            persistenceService: config.resolvePersistenceService(),
            logger: config.resolveLoggingService(),
            analytics: config.resolveAnalyticsService()
        )
    }
    
    private func setupBackgroundTaskHandling() {
        // Background task delegate should be set in the main app delegate
        // This is handled in WristQuestApp.swift
        logger?.debug("Background task handling setup complete", category: .background)
    }
    
    func scheduleBackgroundRefresh() {
        // Adjust scheduling interval based on failure history
        let baseInterval: TimeInterval = 30 * 60 // 30 minutes
        let adjustedInterval = calculateSchedulingInterval(baseInterval: baseInterval)
        let fireDate = Date().addingTimeInterval(adjustedInterval)
        
        logger?.info("Scheduling background refresh for \(fireDate)", category: .background)
        
        WKExtension.shared().scheduleBackgroundRefresh(
            withPreferredDate: fireDate,
            userInfo: ["type": "healthSync"] as NSSecureCoding & NSObjectProtocol
        ) { [weak self] error in
            if let error = error {
                let wqError = WQError.system(.backgroundProcessingFailed)
                self?.logger?.error("Failed to schedule background refresh: \(error.localizedDescription)", category: .background)
                self?.handleError(wqError)
            } else {
                self?.logger?.debug("Background refresh scheduled successfully", category: .background)
            }
        }
    }
    
    private func calculateSchedulingInterval(baseInterval: TimeInterval) -> TimeInterval {
        // If we've had consecutive failures, back off exponentially
        if consecutiveFailures > 0 {
            let backoffMultiplier = min(pow(2.0, Double(consecutiveFailures)), 8.0) // Max 8x backoff
            return baseInterval * backoffMultiplier
        }
        return baseInterval
    }
    
    private func handleBackgroundRefresh(_ backgroundTask: WKApplicationRefreshBackgroundTask) {
        self.backgroundTask = backgroundTask
        logger?.info("Handling background refresh task", category: .background)
        
        Task {
            do {
                try await performBackgroundSync()
                
                await MainActor.run {
                    self.consecutiveFailures = 0
                    self.lastSuccessfulSync = Date()
                    backgroundTask.setTaskCompletedWithSnapshot(false)
                    self.backgroundTask = nil
                    self.scheduleBackgroundRefresh()
                    
                    self.analytics?.trackEvent(AnalyticsEvent(name: "background_sync_success", parameters: [
                        "sync_time": Date().timeIntervalSince1970
                    ]))
                }
            } catch {
                await MainActor.run {
                    self.consecutiveFailures += 1
                    let wqError = WQError.system(.backgroundProcessingFailed)
                    self.handleError(wqError)
                    
                    backgroundTask.setTaskCompletedWithSnapshot(false)
                    self.backgroundTask = nil
                    
                    // Still schedule next refresh, but with backoff
                    if self.consecutiveFailures < self.maxConsecutiveFailures {
                        self.scheduleBackgroundRefresh()
                    } else {
                        self.logger?.error("Max consecutive background failures reached, stopping scheduling", category: .background)
                    }
                    
                    self.analytics?.trackError(
                        NSError(domain: "BackgroundSync", code: -1, userInfo: [
                            NSLocalizedDescriptionKey: "Background sync failed"
                        ]),
                        context: "BackgroundTaskManager.handleBackgroundRefresh"
                    )
                }
            }
        }
    }
    
    private func performBackgroundSync() async throws {
        logger?.info("Starting background sync", category: .background)
        
        do {
            // Check if health data is available
            guard healthService.isHealthDataAvailable() else {
                throw WQError.healthKit(.healthDataNotAvailable)
            }
            
            // Attempt to start health monitoring with timeout
            try await withTimeout(seconds: 10) { [self] in
                try await healthService.startMonitoring()
            }
            
            // Allow some time for data collection
            try await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
            
            // Stop monitoring to conserve battery
            healthService.stopMonitoring()
            
            // Verify we can access persistence layer
            if let player = try await persistenceService.loadPlayer() {
                logger?.info("Background sync completed for player: \(player.name)", category: .background)
                
                // Validate data integrity periodically
                if shouldPerformDataValidation() {
                    _ = try await persistenceService.validateDataIntegrity()
                    logger?.info("Data integrity validation passed during background sync", category: .background)
                }
            } else {
                logger?.info("Background sync completed, no player data found", category: .background)
            }
            
        } catch let error as WQError {
            logger?.error("Background sync failed with WQError: \(error.errorDescription ?? "Unknown")", category: .background)
            throw error
        } catch {
            logger?.error("Background sync failed with error: \(error.localizedDescription)", category: .background)
            throw WQError.system(.backgroundProcessingFailed)
        }
    }
    
    private func shouldPerformDataValidation() -> Bool {
        // Perform validation every 10th sync or if it's been more than 24 hours
        let syncsSinceValidation = consecutiveFailures == 0 ? 10 : 5 // More frequent if we've had failures
        let timeSinceLastValidation = lastSuccessfulSync?.timeIntervalSinceNow ?? -Double.infinity
        
        return abs(timeSinceLastValidation) > 24 * 60 * 60 || // 24 hours
               (consecutiveFailures + 1) % syncsSinceValidation == 0
    }
    
    private func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }
            
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw WQError.system(.backgroundProcessingFailed)
            }
            
            guard let result = try await group.next() else {
                throw WQError.system(.backgroundProcessingFailed)
            }
            
            group.cancelAll()
            return result
        }
    }
    
    // MARK: - Error Handling
    
    private func handleError(_ error: WQError) {
        logger?.error("BackgroundTaskManager error: \(error.errorDescription ?? "Unknown")", category: .background)
        
        analytics?.trackError(
            NSError(domain: "BackgroundTaskManager", code: error.errorDescription?.hash ?? 0, userInfo: [
                NSLocalizedDescriptionKey: error.errorDescription ?? "Unknown background error"
            ]),
            context: "BackgroundTaskManager.handleError"
        )
        
        Task { @MainActor in
            errorSubject.send(error)
        }
    }
    
    // MARK: - Public Interface
    
    func resetFailureCount() {
        consecutiveFailures = 0
        logger?.info("Background failure count reset", category: .background)
    }
    
    func getBackgroundSyncStatus() -> (consecutiveFailures: Int, lastSuccess: Date?) {
        return (consecutiveFailures, lastSuccessfulSync)
    }
    
    func forceBackgroundSync() async throws {
        logger?.info("Forcing background sync", category: .background)
        try await performBackgroundSync()
    }
}

extension BackgroundTaskManager: WKExtensionDelegate {
    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        logger?.info("Handling \(backgroundTasks.count) background tasks", category: .background)
        
        for task in backgroundTasks {
            switch task {
            case let backgroundTask as WKApplicationRefreshBackgroundTask:
                handleBackgroundRefresh(backgroundTask)
                
            case let snapshotTask as WKSnapshotRefreshBackgroundTask:
                logger?.debug("Handling snapshot refresh task", category: .background)
                snapshotTask.setTaskCompleted(restoredDefaultState: true, estimatedSnapshotExpiration: Date.distantFuture, userInfo: nil)
                
            case let connectivityTask as WKWatchConnectivityRefreshBackgroundTask:
                logger?.debug("Handling connectivity refresh task", category: .background)
                connectivityTask.setTaskCompletedWithSnapshot(false)
                
            case let urlSessionTask as WKURLSessionRefreshBackgroundTask:
                logger?.debug("Handling URL session refresh task", category: .background)
                urlSessionTask.setTaskCompletedWithSnapshot(false)
                
            case let relevantShortcutTask as WKRelevantShortcutRefreshBackgroundTask:
                logger?.debug("Handling relevant shortcut refresh task", category: .background)
                relevantShortcutTask.setTaskCompletedWithSnapshot(false)
                
            case let intentDidRunTask as WKIntentDidRunRefreshBackgroundTask:
                logger?.debug("Handling intent did run refresh task", category: .background)
                intentDidRunTask.setTaskCompletedWithSnapshot(false)
                
            default:
                logger?.warning("Handling unknown background task type", category: .background)
                task.setTaskCompletedWithSnapshot(false)
            }
        }
        
        analytics?.trackEvent(AnalyticsEvent(name: "background_tasks_handled", parameters: [
            "task_count": backgroundTasks.count
        ]))
    }
}