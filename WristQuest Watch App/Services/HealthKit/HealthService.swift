import Foundation
import HealthKit
import Combine
import os.log
import UIKit

protocol HealthServiceProtocol {
    var healthDataPublisher: AnyPublisher<HealthData, Never> { get }
    var authorizationStatusPublisher: AnyPublisher<HealthAuthorizationStatus, Never> { get }
    var errorPublisher: AnyPublisher<WQError, Never> { get }
    
    func requestAuthorization() async throws
    func checkAuthorizationStatus() async -> HealthAuthorizationStatus
    func startMonitoring() async throws
    func stopMonitoring()
    func isHealthDataAvailable() -> Bool
}

// MARK: - Query Health Metrics

private struct QueryHealthMetrics {
    var startTime: Date = Date()
    var lastSuccess: Date = Date.distantPast
    var lastFailure: Date = Date.distantPast
    var successCount: Int = 0
    var failureCount: Int = 0
    var isFailed: Bool = false
    
    mutating func recordSuccess() {
        lastSuccess = Date()
        successCount += 1
        isFailed = false
    }
    
    mutating func recordFailure() {
        lastFailure = Date()
        failureCount += 1
    }
    
    mutating func markAsFailed() {
        isFailed = true
    }
    
    var healthScore: Double {
        guard successCount + failureCount > 0 else { return 1.0 }
        return Double(successCount) / Double(successCount + failureCount)
    }
    
    var isHealthy: Bool {
        return !isFailed && healthScore > 0.8
    }
}

// MARK: - Optimized HealthService Implementation

class HealthService: HealthServiceProtocol {
    private let healthStore = HKHealthStore()
    private let healthDataSubject = CurrentValueSubject<HealthData, Never>(HealthData())
    private let authStatusSubject = CurrentValueSubject<HealthAuthorizationStatus, Never>(.notDetermined)
    private let errorSubject = PassthroughSubject<WQError, Never>()
    
    // MARK: - Query Management
    private var activeQueries: [String: HKQuery] = [:] // Query ID -> Query mapping
    private var queryAnchors: [String: HKQueryAnchor] = [:] // Store anchors for efficient queries
    private var workoutSession: HKWorkoutSession?
    
    // MARK: - Dependencies
    private let logger: LoggingServiceProtocol?
    private let analytics: AnalyticsServiceProtocol?
    
    // MARK: - Performance & Memory Management
    private let queryQueue = DispatchQueue(label: "com.wristquest.health.queries", qos: .utility)
    private let dataUpdateQueue = DispatchQueue(label: "com.wristquest.health.updates", qos: .background)
    private var lastUpdateTimestamp: [String: Date] = [:]
    private let updateThrottleInterval: TimeInterval = 5.0 // Throttle updates to every 5 seconds
    private var isMonitoring = false
    private var appStateObserver: NSObjectProtocol?
    
    // MARK: - Error Handling & Monitoring
    private var queryRetryCount: [String: Int] = [:]
    private let maxRetryAttempts = 3
    private let retryDelay: TimeInterval = 2.0
    private var queryHealthMetrics: [String: QueryHealthMetrics] = [:]
    
    // MARK: - Battery Optimization
    private var isPowerSavingMode = false
    private var backgroundTaskIdentifier: Int = -1
    
    // MARK: - Publishers
    
    var healthDataPublisher: AnyPublisher<HealthData, Never> {
        healthDataSubject.eraseToAnyPublisher()
    }
    
    var authorizationStatusPublisher: AnyPublisher<HealthAuthorizationStatus, Never> {
        authStatusSubject.eraseToAnyPublisher()
    }
    
    var errorPublisher: AnyPublisher<WQError, Never> {
        errorSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Initialization
    
    init(logger: LoggingServiceProtocol? = nil, analytics: AnalyticsServiceProtocol? = nil) {
        self.logger = logger
        self.analytics = analytics
        
        logger?.info("HealthService initializing", category: .health)
        setupAppStateObserver()
        checkInitialAuthorizationStatus()
    }
    
    convenience init() {
        // Remove circular dependency - services should not resolve dependencies during init
        self.init(logger: nil, analytics: nil)
    }
    
    deinit {
        cleanup()
        logger?.info("HealthService deallocated", category: .health)
    }
    
    // MARK: - Public Interface
    
    func requestAuthorization() async throws {
        logger?.info("Requesting health authorization", category: .health)
        
        guard HKHealthStore.isHealthDataAvailable() else {
            let error = WQError.healthKit(.healthDataNotAvailable)
            handleError(error)
            throw error
        }
        
        let typesToRead: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .appleExerciseTime)!,
            HKObjectType.quantityType(forIdentifier: .appleStandTime)!,
            HKObjectType.categoryType(forIdentifier: .mindfulSession)!
        ]
        
        do {
            try await healthStore.requestAuthorization(toShare: Set<HKSampleType>(), read: typesToRead)
            logger?.info("Health authorization request completed", category: .health)
            analytics?.trackEvent(AnalyticsEvent(name: "health_authorization_requested", parameters: [:]))
            
            await updateAuthorizationStatus()
            
            // Check if we actually got permission - but don't throw error if denied
            let status = await checkAuthorizationStatus()
            if status == .denied {
                logger?.info("Health authorization was denied by user", category: .health)
                // Don't throw error - this is a valid user choice
            }
        } catch let error as WQError {
            throw error
        } catch {
            let wqError = WQError.healthKit(.queryFailed(error.localizedDescription))
            handleError(wqError)
            throw wqError
        }
    }
    
    func checkAuthorizationStatus() async -> HealthAuthorizationStatus {
        guard HKHealthStore.isHealthDataAvailable() else {
            return .restricted
        }
        
        let stepCountType = HKObjectType.quantityType(forIdentifier: .stepCount)!
        let authStatus = healthStore.authorizationStatus(for: stepCountType)
        
        let status: HealthAuthorizationStatus
        switch authStatus {
        case .notDetermined:
            status = .notDetermined
        case .sharingDenied:
            status = .denied
        case .sharingAuthorized:
            status = .authorized
        @unknown default:
            status = .notDetermined
        }
        
        await MainActor.run {
            authStatusSubject.send(status)
        }
        
        return status
    }
    
    func startMonitoring() async throws {
        logger?.info("Starting health monitoring", category: .health)
        
        let authStatus = await checkAuthorizationStatus()
        guard authStatus == .authorized else {
            let error = WQError.healthKit(.permissionRequired)
            handleError(error)
            throw error
        }
        
        isMonitoring = true
        
        do {
            // Start monitoring all health data types concurrently but managed
            async let _ = startOptimizedStepCountMonitoring()
            async let _ = startOptimizedHeartRateMonitoring()
            async let _ = startOptimizedExerciseTimeMonitoring()
            async let _ = startOptimizedStandTimeMonitoring()
            async let _ = startOptimizedMindfulnessMonitoring()
            
            // Wait for all monitoring to start
            try await Task.sleep(nanoseconds: 100_000_000) // Small delay to ensure monitoring starts
            
            logger?.info("Health monitoring started successfully", category: .health)
            analytics?.trackEvent(AnalyticsEvent(name: "health_monitoring_started", parameters: [
                "query_count": activeQueries.count,
                "power_saving_mode": isPowerSavingMode
            ]))
            
            // Start health monitoring diagnostics
            startHealthMonitoringDiagnostics()
            
        } catch {
            isMonitoring = false
            let wqError = WQError.healthKit(.backgroundQueryFailed)
            handleError(wqError)
            throw wqError
        }
    }
    
    func stopMonitoring() {
        logger?.info("Stopping health monitoring", category: .health)
        isMonitoring = false
        
        queryQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Stop all active queries
            for (queryId, query) in self.activeQueries {
                self.healthStore.stop(query)
                self.logger?.debug("Stopped query: \(queryId)", category: .health)
            }
            
            // Clear all query state
            self.activeQueries.removeAll()
            self.queryAnchors.removeAll()
            self.lastUpdateTimestamp.removeAll()
            self.queryRetryCount.removeAll()
            self.queryHealthMetrics.removeAll()
            
            // End workout session if active
            self.workoutSession?.end()
            self.workoutSession = nil
            
            // End background task if active
            self.endBackgroundTask()
            
            self.logger?.info("Health monitoring stopped successfully", category: .health)
        }
    }
    
    func isHealthDataAvailable() -> Bool {
        return HKHealthStore.isHealthDataAvailable()
    }
    
    // MARK: - App State Management
    
    private func setupAppStateObserver() {
        // Note: WatchOS doesn't have UIApplication notifications
        // Background/foreground handling is managed by the system
        logger?.info("App state observer setup (watchOS)", category: .health)
    }
    
    private func handleAppDidEnterBackground() {
        logger?.info("App entering background, optimizing health monitoring", category: .health)
        isPowerSavingMode = true
        startBackgroundTask()
        optimizeForBackground()
    }
    
    private func handleAppWillEnterForeground() {
        logger?.info("App entering foreground, resuming full health monitoring", category: .health)
        isPowerSavingMode = false
        endBackgroundTask()
        resumeFullMonitoring()
    }
    
    private func optimizeForBackground() {
        // Reduce query frequency in background
        // This is handled by checking isPowerSavingMode in update handlers
    }
    
    private func resumeFullMonitoring() {
        guard isMonitoring else { return }
        
        // Force refresh all data when returning to foreground
        Task {
            await refreshAllHealthData()
        }
    }
    
    // MARK: - Background Task Management
    
    private func startBackgroundTask() {
        // Background tasks not available on watchOS the same way
        backgroundTaskIdentifier = -1
        logger?.debug("Background task started (watchOS)", category: .health)
    }
    
    private func endBackgroundTask() {
        if backgroundTaskIdentifier != -1 {
            logger?.debug("Background task ended (watchOS)", category: .health)
            backgroundTaskIdentifier = -1
        }
    }
    
    // MARK: - Memory Management
    
    private func cleanup() {
        // Remove app state observer
        if let observer = appStateObserver {
            NotificationCenter.default.removeObserver(observer)
            appStateObserver = nil
        }
        
        // Stop all monitoring
        stopMonitoring()
        
        // Clear all state
        queryRetryCount.removeAll()
        queryHealthMetrics.removeAll()
        lastUpdateTimestamp.removeAll()
        
        // End background task
        endBackgroundTask()
    }
    
    private func checkInitialAuthorizationStatus() {
        Task {
            await checkAuthorizationStatus()
        }
    }
    
    private func updateAuthorizationStatus() async {
        let status = await checkAuthorizationStatus()
        await MainActor.run {
            authStatusSubject.send(status)
        }
    }
    
    // MARK: - Optimized Health Data Monitoring
    
    private func startOptimizedStepCountMonitoring() async throws {
        guard let stepType = HKObjectType.quantityType(forIdentifier: .stepCount) else {
            throw WQError.healthKit(.deviceNotSupported)
        }
        
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        // Initial query for current data
        let queryId = "step_count_initial"
        let query = HKStatisticsQuery(
            quantityType: stepType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { [weak self] _, result, error in
            self?.handleStepCountQueryResult(result, error: error, queryType: queryId)
        }
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            queryQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(throwing: WQError.healthKit(.queryFailed("Service deallocated")))
                    return
                }
                
                self.healthStore.execute(query)
                self.activeQueries[queryId] = query
                self.trackQueryStart(queryId)
                continuation.resume()
            }
        }
        
        // Anchored query for real-time updates
        let anchoredQueryId = "step_count_anchored"
        let anchor = queryAnchors[anchoredQueryId]
        
        let anchoredQuery = HKAnchoredObjectQuery(
            type: stepType,
            predicate: predicate,
            anchor: anchor,
            limit: HKObjectQueryNoLimit
        ) { [weak self] _, samples, deletedObjects, newAnchor, error in
            self?.handleStepCountAnchoredResult(samples, deletedObjects: deletedObjects, newAnchor: newAnchor, error: error, queryId: anchoredQueryId)
        }
        
        anchoredQuery.updateHandler = { [weak self] _, samples, deletedObjects, newAnchor, error in
            self?.handleStepCountAnchoredResult(samples, deletedObjects: deletedObjects, newAnchor: newAnchor, error: error, queryId: anchoredQueryId)
        }
        
        queryQueue.async { [weak self] in
            guard let self = self else { return }
            self.healthStore.execute(anchoredQuery)
            self.activeQueries[anchoredQueryId] = anchoredQuery
            self.trackQueryStart(anchoredQueryId)
        }
    }
    
    private func startOptimizedHeartRateMonitoring() async throws {
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else {
            throw WQError.healthKit(.deviceNotSupported)
        }
        
        let queryId = "heart_rate_anchored"
        let anchor = queryAnchors[queryId]
        
        let query = HKAnchoredObjectQuery(
            type: heartRateType,
            predicate: nil,
            anchor: anchor,
            limit: 1
        ) { [weak self] _, samples, deletedObjects, newAnchor, error in
            self?.handleHeartRateAnchoredResult(samples, deletedObjects: deletedObjects, newAnchor: newAnchor, error: error, queryId: queryId)
        }
        
        query.updateHandler = { [weak self] _, samples, deletedObjects, newAnchor, error in
            self?.handleHeartRateAnchoredResult(samples, deletedObjects: deletedObjects, newAnchor: newAnchor, error: error, queryId: queryId)
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            queryQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(throwing: WQError.healthKit(.queryFailed("Service deallocated")))
                    return
                }
                
                self.healthStore.execute(query)
                self.activeQueries[queryId] = query
                self.trackQueryStart(queryId)
                continuation.resume()
            }
        }
    }
    
    private func startOptimizedExerciseTimeMonitoring() async throws {
        guard let exerciseType = HKObjectType.quantityType(forIdentifier: .appleExerciseTime) else {
            throw WQError.healthKit(.deviceNotSupported)
        }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)
        
        let queryId = "exercise_time"
        let query = HKStatisticsQuery(
            quantityType: exerciseType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { [weak self] _, result, error in
            self?.handleExerciseTimeQueryResult(result, error: error, queryType: queryId)
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            queryQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(throwing: WQError.healthKit(.queryFailed("Service deallocated")))
                    return
                }
                
                self.healthStore.execute(query)
                self.activeQueries[queryId] = query
                self.trackQueryStart(queryId)
                continuation.resume()
            }
        }
    }
    
    private func startOptimizedStandTimeMonitoring() async throws {
        guard let standType = HKObjectType.quantityType(forIdentifier: .appleStandTime) else {
            throw WQError.healthKit(.deviceNotSupported)
        }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)
        
        let queryId = "stand_time"
        let query = HKStatisticsQuery(
            quantityType: standType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { [weak self] _, result, error in
            self?.handleStandTimeQueryResult(result, error: error, queryType: queryId)
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            queryQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(throwing: WQError.healthKit(.queryFailed("Service deallocated")))
                    return
                }
                
                self.healthStore.execute(query)
                self.activeQueries[queryId] = query
                self.trackQueryStart(queryId)
                continuation.resume()
            }
        }
    }
    
    private func startOptimizedMindfulnessMonitoring() async throws {
        guard let mindfulType = HKObjectType.categoryType(forIdentifier: .mindfulSession) else {
            throw WQError.healthKit(.deviceNotSupported)
        }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)
        
        let queryId = "mindfulness"
        let query = HKSampleQuery(
            sampleType: mindfulType,
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
        ) { [weak self] _, samples, error in
            self?.handleMindfulnessQueryResult(samples, error: error, queryType: queryId)
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            queryQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(throwing: WQError.healthKit(.queryFailed("Service deallocated")))
                    return
                }
                
                self.healthStore.execute(query)
                self.activeQueries[queryId] = query
                self.trackQueryStart(queryId)
                continuation.resume()
            }
        }
    }
    
    // MARK: - Query Result Handlers
    
    private func handleStepCountQueryResult(_ result: HKStatistics?, error: Error?, queryType: String) {
        if let error = error {
            let wqError = WQError.healthKit(.queryFailed("\(queryType): \(error.localizedDescription)"))
            handleQueryError(wqError, queryType: queryType)
            return
        }
        
        let steps = result?.sumQuantity()?.doubleValue(for: HKUnit.count()) ?? 0
        
        updateHealthDataThrottled(queryType: queryType) { [weak self] currentData in
            var newData = currentData
            newData.steps = Int(steps)
            return newData
        }
    }
    
    private func handleStepCountAnchoredResult(_ samples: [HKSample]?, deletedObjects: [HKDeletedObject]?, newAnchor: HKQueryAnchor?, error: Error?, queryId: String) {
        if let error = error {
            let wqError = WQError.healthKit(.queryFailed("\(queryId): \(error.localizedDescription)"))
            handleQueryError(wqError, queryType: queryId)
            return
        }
        
        // Store the new anchor for efficient future queries
        if let newAnchor = newAnchor {
            queryAnchors[queryId] = newAnchor
        }
        
        guard let samples = samples as? [HKQuantitySample] else {
            logger?.debug("No step count samples in anchored query result", category: .health)
            return
        }
        
        let totalSteps = samples.reduce(0) { result, sample in
            result + sample.quantity.doubleValue(for: HKUnit.count())
        }
        
        updateHealthDataThrottled(queryType: queryId) { [weak self] currentData in
            var newData = currentData
            newData.steps = Int(totalSteps)
            return newData
        }
    }
    
    private func handleHeartRateAnchoredResult(_ samples: [HKSample]?, deletedObjects: [HKDeletedObject]?, newAnchor: HKQueryAnchor?, error: Error?, queryId: String) {
        if let error = error {
            let wqError = WQError.healthKit(.queryFailed("\(queryId): \(error.localizedDescription)"))
            handleQueryError(wqError, queryType: queryId)
            return
        }
        
        // Store the new anchor for efficient future queries
        if let newAnchor = newAnchor {
            queryAnchors[queryId] = newAnchor
        }
        
        guard let samples = samples as? [HKQuantitySample],
              let latestSample = samples.max(by: { $0.startDate < $1.startDate }) else {
            logger?.debug("No heart rate samples in anchored query result", category: .health)
            return
        }
        
        let heartRate = latestSample.quantity.doubleValue(for: HKUnit(from: "count/min"))
        
        updateHealthDataThrottled(queryType: queryId) { [weak self] currentData in
            var newData = currentData
            newData.heartRate = heartRate
            return newData
        }
    }
    
    private func handleExerciseTimeQueryResult(_ result: HKStatistics?, error: Error?, queryType: String) {
        if let error = error {
            let wqError = WQError.healthKit(.queryFailed("\(queryType): \(error.localizedDescription)"))
            handleQueryError(wqError, queryType: queryType)
            return
        }
        
        let minutes = result?.sumQuantity()?.doubleValue(for: HKUnit.minute()) ?? 0
        
        updateHealthDataThrottled(queryType: queryType) { [weak self] currentData in
            var newData = currentData
            newData.exerciseMinutes = Int(minutes)
            return newData
        }
    }
    
    private func handleStandTimeQueryResult(_ result: HKStatistics?, error: Error?, queryType: String) {
        if let error = error {
            let wqError = WQError.healthKit(.queryFailed("\(queryType): \(error.localizedDescription)"))
            handleQueryError(wqError, queryType: queryType)
            return
        }
        
        let hours = result?.sumQuantity()?.doubleValue(for: HKUnit.hour()) ?? 0
        
        updateHealthDataThrottled(queryType: queryType) { [weak self] currentData in
            var newData = currentData
            newData.standingHours = Int(hours)
            return newData
        }
    }
    
    private func handleMindfulnessQueryResult(_ samples: [HKSample]?, error: Error?, queryType: String) {
        if let error = error {
            let wqError = WQError.healthKit(.queryFailed("\(queryType): \(error.localizedDescription)"))
            handleQueryError(wqError, queryType: queryType)
            return
        }
        
        let totalMinutes = samples?.reduce(0) { result, sample in
            let duration = sample.endDate.timeIntervalSince(sample.startDate)
            return result + (duration / 60.0)
        } ?? 0
        
        updateHealthDataThrottled(queryType: queryType) { [weak self] currentData in
            var newData = currentData
            newData.mindfulMinutes = Int(totalMinutes)
            return newData
        }
    }
    
    // MARK: - Throttled Data Updates
    
    private func updateHealthDataThrottled(queryType: String, update: @escaping (HealthData) -> HealthData) {
        let now = Date()
        let lastUpdate = lastUpdateTimestamp[queryType] ?? Date.distantPast
        
        // Skip update if we're in power saving mode and it's too soon
        if isPowerSavingMode && now.timeIntervalSince(lastUpdate) < updateThrottleInterval * 2 {
            return
        }
        
        // Regular throttling
        guard now.timeIntervalSince(lastUpdate) >= updateThrottleInterval else {
            return
        }
        
        lastUpdateTimestamp[queryType] = now
        
        dataUpdateQueue.async { [weak self] in
            guard let self = self else { return }
            
            Task { @MainActor in
                let currentData = self.healthDataSubject.value
                let newData = update(currentData)
                
                // Only send update if data actually changed
                if !self.isHealthDataEqual(currentData, newData) {
                    self.healthDataSubject.send(newData)
                    self.logger?.debug("Health data updated for \(queryType)", category: .health)
                    
                    // Track metrics
                    self.trackQuerySuccess(queryType)
                }
            }
        }
    }
    
    private func isHealthDataEqual(_ lhs: HealthData, _ rhs: HealthData) -> Bool {
        return lhs.steps == rhs.steps &&
               lhs.standingHours == rhs.standingHours &&
               abs(lhs.heartRate - rhs.heartRate) < 1.0 &&
               lhs.exerciseMinutes == rhs.exerciseMinutes &&
               lhs.mindfulMinutes == rhs.mindfulMinutes
    }
    
    // MARK: - Data Refresh
    
    private func refreshAllHealthData() async {
        guard isMonitoring else { return }
        
        logger?.info("Refreshing all health data", category: .health)
        
        // Clear throttling to allow immediate updates
        lastUpdateTimestamp.removeAll()
        
        // Restart monitoring to get fresh data
        do {
            try await startMonitoring()
        } catch {
            logger?.error("Failed to refresh health data: \(error.localizedDescription)", category: .health)
        }
    }
    
    // MARK: - Query Health Monitoring
    
    private func startHealthMonitoringDiagnostics() {
        // Run diagnostics every 60 seconds
        Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            self?.runHealthDiagnostics()
        }
    }
    
    private func runHealthDiagnostics() {
        guard isMonitoring else { return }
        
        let activeQueryCount = activeQueries.count
        let failedQueryCount = queryHealthMetrics.values.filter { $0.failureCount > 0 }.count
        
        logger?.info("Health diagnostics - Active queries: \(activeQueryCount), Failed queries: \(failedQueryCount)", category: .health)
        
        analytics?.trackEvent(AnalyticsEvent(name: "health_diagnostics", parameters: [
            "active_queries": activeQueryCount,
            "failed_queries": failedQueryCount,
            "power_saving_mode": isPowerSavingMode
        ]))
        
        // Check for stuck queries and restart if needed
        checkForStuckQueries()
    }
    
    private func checkForStuckQueries() {
        let now = Date()
        let stuckThreshold: TimeInterval = 300 // 5 minutes
        
        for (queryId, metrics) in queryHealthMetrics {
            if now.timeIntervalSince(metrics.lastSuccess) > stuckThreshold && metrics.failureCount > 0 {
                logger?.warning("Query \(queryId) appears stuck, attempting restart", category: .health)
                restartQuery(queryId)
            }
        }
    }
    
    private func restartQuery(_ queryId: String) {
        // Stop the stuck query
        if let query = activeQueries[queryId] {
            healthStore.stop(query)
            activeQueries.removeValue(forKey: queryId)
        }
        
        // Reset metrics
        queryHealthMetrics.removeValue(forKey: queryId)
        queryRetryCount.removeValue(forKey: queryId)
        
        // Restart monitoring for this specific query type
        Task {
            do {
                switch queryId {
                case let id where id.contains("step_count"):
                    try await startOptimizedStepCountMonitoring()
                case let id where id.contains("heart_rate"):
                    try await startOptimizedHeartRateMonitoring()
                case "exercise_time":
                    try await startOptimizedExerciseTimeMonitoring()
                case "stand_time":
                    try await startOptimizedStandTimeMonitoring()
                case "mindfulness":
                    try await startOptimizedMindfulnessMonitoring()
                default:
                    logger?.warning("Unknown query type for restart: \(queryId)", category: .health)
                }
            } catch {
                logger?.error("Failed to restart query \(queryId): \(error.localizedDescription)", category: .health)
            }
        }
    }
    
    // MARK: - Query Metrics Tracking
    
    private func trackQueryStart(_ queryId: String) {
        queryHealthMetrics[queryId] = QueryHealthMetrics()
    }
    
    private func trackQuerySuccess(_ queryId: String) {
        queryHealthMetrics[queryId]?.recordSuccess()
    }
    
    private func trackQueryFailure(_ queryId: String) {
        queryHealthMetrics[queryId]?.recordFailure()
    }
    
    // MARK: - Error Handling
    
    private func handleError(_ error: WQError) {
        logger?.error("HealthService error: \(error.errorDescription ?? "Unknown")", category: .health)
        analytics?.trackError(
            NSError(domain: "HealthService", code: error.errorDescription?.hash ?? 0, userInfo: [
                NSLocalizedDescriptionKey: error.errorDescription ?? "Unknown health error"
            ]),
            context: "HealthService.handleError"
        )
        
        Task { @MainActor in
            errorSubject.send(error)
        }
    }
    
    private func handleQueryError(_ error: WQError, queryType: String) {
        // Track the failure
        trackQueryFailure(queryType)
        
        let retryKey = "query_\(queryType)"
        let currentRetries = queryRetryCount[retryKey, default: 0]
        
        if currentRetries < maxRetryAttempts {
            queryRetryCount[retryKey] = currentRetries + 1
            logger?.warning("Query \(queryType) failed, retrying (\(currentRetries + 1)/\(maxRetryAttempts))", category: .health)
            
            // Exponential backoff for retries
            let backoffDelay = retryDelay * pow(2.0, Double(currentRetries))
            
            Task {
                try? await Task.sleep(nanoseconds: UInt64(backoffDelay * 1_000_000_000))
                await retryQuery(queryType)
            }
        } else {
            queryRetryCount.removeValue(forKey: retryKey)
            logger?.error("Query \(queryType) failed after max retries", category: .health)
            
            // Mark query as failed in metrics
            queryHealthMetrics[queryType]?.markAsFailed()
            
            handleError(error)
        }
    }
    
    private func retryQuery(_ queryType: String) async {
        logger?.info("Retrying query: \(queryType)", category: .health)
        
        do {
            switch queryType {
            case let type where type.contains("step_count"):
                try await startOptimizedStepCountMonitoring()
            case let type where type.contains("heart_rate"):
                try await startOptimizedHeartRateMonitoring()
            case "exercise_time":
                try await startOptimizedExerciseTimeMonitoring()
            case "stand_time":
                try await startOptimizedStandTimeMonitoring()
            case "mindfulness":
                try await startOptimizedMindfulnessMonitoring()
            default:
                logger?.warning("Unknown query type for retry: \(queryType)", category: .health)
            }
        } catch {
            logger?.error("Retry failed for query \(queryType): \(error.localizedDescription)", category: .health)
        }
    }
}

// MARK: - Performance Monitoring Extensions

#if DEBUG
extension HealthService {
    private func getQueryMetrics() -> [String: QueryHealthMetrics] {
        return queryHealthMetrics
    }
    
    func getActiveQueryCount() -> Int {
        return activeQueries.count
    }
    
    func getQueryAnchors() -> [String: HKQueryAnchor] {
        return queryAnchors
    }
    
    func isInPowerSavingMode() -> Bool {
        return isPowerSavingMode
    }
}
#endif

// MARK: - Legacy Error Support (for backward compatibility)

@available(*, deprecated, message: "Use WQError.HealthKitError instead")
enum HealthServiceError: Error, LocalizedError {
    case healthDataNotAvailable
    case authorizationDenied
    case queryFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .healthDataNotAvailable:
            return "Health data is not available on this device"
        case .authorizationDenied:
            return "Health data access was denied"
        case .queryFailed(let message):
            return "Health query failed: \(message)"
        }
    }
    
    var wqError: WQError {
        switch self {
        case .healthDataNotAvailable:
            return .healthKit(.healthDataNotAvailable)
        case .authorizationDenied:
            return .healthKit(.authorizationDenied)
        case .queryFailed(let message):
            return .healthKit(.queryFailed(message))
        }
    }
}