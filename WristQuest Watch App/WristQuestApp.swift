//
//  WristQuestApp.swift
//  WristQuest Watch App
//
//  Created by Stephen Conway on 6/13/25.
//

import SwiftUI
import WatchKit
import ClockKit

@main
struct WristQuest_Watch_AppApp: App {
    @StateObject private var navigationCoordinator = NavigationCoordinator()
    @StateObject private var gameViewModel: GameViewModel
    @StateObject private var healthViewModel: HealthViewModel
    @StateObject private var backgroundTaskManager = BackgroundTaskManager()
    
    init() {
        print("🚀 WristQuestApp: Starting app initialization")
        
        // Configure dependency injection FIRST - before creating any services
        print("🚀 WristQuestApp: Configuring DIConfiguration")
        DIConfiguration.shared.configure(for: .production)
        print("🚀 WristQuestApp: DIConfiguration configured")
        
        // Create ViewModels AFTER DI configuration is complete
        // ViewModels now create their own service instances to avoid circular dependencies
        print("🚀 WristQuestApp: Creating GameViewModel")
        let gameVM = GameViewModel()
        print("🚀 WristQuestApp: GameViewModel created")
        
        print("🚀 WristQuestApp: Creating HealthViewModel")
        let healthVM = HealthViewModel()
        print("🚀 WristQuestApp: HealthViewModel created")
        
        self._gameViewModel = StateObject(wrappedValue: gameVM)
        self._healthViewModel = StateObject(wrappedValue: healthVM)
        
        print("🚀 WristQuestApp: App initialization complete")
    }
    
    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environmentObject(navigationCoordinator)
                .environmentObject(gameViewModel)
                .environmentObject(healthViewModel)
                .environmentObject(backgroundTaskManager)
                .onAppear {
                    setupApp()
                }
                .onReceive(NotificationCenter.default.publisher(for: WKExtension.applicationWillEnterForegroundNotification)) { _ in
                    handleAppForeground()
                }
                .onReceive(NotificationCenter.default.publisher(for: WKExtension.applicationDidEnterBackgroundNotification)) { _ in
                    handleAppBackground()
                }
        }
    }
    
    private func setupApp() {
        let logger = DIConfiguration.shared.resolveLoggingService()
        let analytics = DIConfiguration.shared.resolveAnalyticsService()
        
        logger.info("Setting up WristQuest app", category: .system)
        analytics.trackGameAction(.appLaunched, parameters: nil)
        
        backgroundTaskManager.scheduleBackgroundRefresh()
        
        if healthViewModel.isAuthorized {
            healthViewModel.startHealthMonitoring()
        }
        
        // Setup complication updates
        setupComplicationUpdates()
    }
    
    private func handleAppForeground() {
        let logger = DIConfiguration.shared.resolveLoggingService()
        logger.info("App entering foreground", category: .system)
        
        if healthViewModel.isAuthorized {
            healthViewModel.startHealthMonitoring()
        }
        
        // Update complications when app comes to foreground
        updateComplications()
    }
    
    private func handleAppBackground() {
        let logger = DIConfiguration.shared.resolveLoggingService()
        let analytics = DIConfiguration.shared.resolveAnalyticsService()
        
        logger.info("App entering background", category: .system)
        analytics.trackGameAction(.appBackgrounded, parameters: nil)
        
        backgroundTaskManager.scheduleBackgroundRefresh()
        
        // Update complications when app goes to background
        updateComplications()
    }
    
    private func setupComplicationUpdates() {
        // Subscribe to game state changes to update complications
        NotificationCenter.default.addObserver(
            forName: .gameStateDidChange,
            object: nil,
            queue: .main
        ) { _ in
            updateComplications()
        }
        
        // Subscribe to health data changes to update complications
        NotificationCenter.default.addObserver(
            forName: .healthDataDidUpdate,
            object: nil,
            queue: .main
        ) { _ in
            updateComplications()
        }
    }
    
    private func updateComplications() {
        // TODO: Implement complication updates
        // This will be implemented when the complication controller is properly set up
    }
}

// MARK: - Notification Extensions
extension Notification.Name {
    static let gameStateDidChange = Notification.Name("gameStateDidChange")
    static let healthDataDidUpdate = Notification.Name("healthDataDidUpdate")
}
