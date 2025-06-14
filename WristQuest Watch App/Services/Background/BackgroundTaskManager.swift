import Foundation
import WatchKit

class BackgroundTaskManager: NSObject, ObservableObject {
    private var backgroundTask: WKApplicationRefreshBackgroundTask?
    private let healthService: HealthServiceProtocol
    private let persistenceService: PersistenceServiceProtocol
    
    init(healthService: HealthServiceProtocol = HealthService(),
         persistenceService: PersistenceServiceProtocol = PersistenceService()) {
        self.healthService = healthService
        self.persistenceService = persistenceService
        super.init()
        
        setupBackgroundTaskHandling()
    }
    
    private func setupBackgroundTaskHandling() {
        // Background task delegate should be set in the main app delegate
        // This is handled in WristQuestApp.swift
    }
    
    func scheduleBackgroundRefresh() {
        let fireDate = Date().addingTimeInterval(30 * 60)
        
        WKExtension.shared().scheduleBackgroundRefresh(
            withPreferredDate: fireDate,
            userInfo: ["type": "healthSync"] as NSSecureCoding & NSObjectProtocol
        ) { error in
            if let error = error {
                print("Failed to schedule background refresh: \(error)")
            }
        }
    }
    
    private func handleBackgroundRefresh(_ backgroundTask: WKApplicationRefreshBackgroundTask) {
        self.backgroundTask = backgroundTask
        
        Task {
            await performBackgroundSync()
            
            DispatchQueue.main.async {
                backgroundTask.setTaskCompletedWithSnapshot(false)
                self.backgroundTask = nil
                self.scheduleBackgroundRefresh()
            }
        }
    }
    
    private func performBackgroundSync() async {
        do {
            await healthService.startMonitoring()
            
            try await Task.sleep(nanoseconds: 5_000_000_000)
            
            healthService.stopMonitoring()
            
            if let player = try await persistenceService.loadPlayer() {
                print("Background sync completed for player: \(player.name)")
            }
        } catch {
            print("Background sync failed: \(error)")
        }
    }
}

extension BackgroundTaskManager: WKExtensionDelegate {
    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        for task in backgroundTasks {
            switch task {
            case let backgroundTask as WKApplicationRefreshBackgroundTask:
                handleBackgroundRefresh(backgroundTask)
            case let snapshotTask as WKSnapshotRefreshBackgroundTask:
                snapshotTask.setTaskCompleted(restoredDefaultState: true, estimatedSnapshotExpiration: Date.distantFuture, userInfo: nil)
            case let connectivityTask as WKWatchConnectivityRefreshBackgroundTask:
                connectivityTask.setTaskCompletedWithSnapshot(false)
            case let urlSessionTask as WKURLSessionRefreshBackgroundTask:
                urlSessionTask.setTaskCompletedWithSnapshot(false)
            case let relevantShortcutTask as WKRelevantShortcutRefreshBackgroundTask:
                relevantShortcutTask.setTaskCompletedWithSnapshot(false)
            case let intentDidRunTask as WKIntentDidRunRefreshBackgroundTask:
                intentDidRunTask.setTaskCompletedWithSnapshot(false)
            default:
                task.setTaskCompletedWithSnapshot(false)
            }
        }
    }
}