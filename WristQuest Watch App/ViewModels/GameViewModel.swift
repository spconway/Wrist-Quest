import Foundation
import SwiftUI
import Combine

// Note: WQConstants are accessed globally via WQC typealias

enum GameState: Equatable {
    case onboarding
    case mysticalTransition
    case mainMenu
    case activeQuest(Quest)
    case encounter(Encounter)
    case inventory
    case journal
    case settings
    
    static func == (lhs: GameState, rhs: GameState) -> Bool {
        switch (lhs, rhs) {
        case (.onboarding, .onboarding),
             (.mysticalTransition, .mysticalTransition),
             (.mainMenu, .mainMenu),
             (.inventory, .inventory),
             (.journal, .journal),
             (.settings, .settings):
            return true
        case (.activeQuest(let lQuest), .activeQuest(let rQuest)):
            return lQuest.id == rQuest.id
        case (.encounter(let lEncounter), .encounter(let rEncounter)):
            return lEncounter.id == rEncounter.id
        default:
            return false
        }
    }
}

@MainActor
class GameViewModel: ObservableObject {
    @Published var gameState: GameState = .onboarding
    @Published var currentPlayer: Player?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Enhanced error handling
    @Published var currentError: WQError?
    @Published var isShowingError = false
    @Published var errorRecoveryOptions: [RecoveryOption] = []
    @Published var isRetrying = false
    
    // Fantasy State
    @Published var isPlayingIntroSequence = false
    @Published var heroAscensionProgress: Double = 0.0
    @Published var realmWelcomeMessage: String = ""
    @Published var legendBeginning = false
    
    private var cancellables = Set<AnyCancellable>()
    private let errorHandler: ErrorHandler
    private let errorRecovery: ErrorRecoveryManager
    
    // Services - can be injected via DI or use defaults for backward compatibility
    private let persistenceService: PersistenceServiceProtocol
    private let healthService: HealthServiceProtocol
    private let logger: LoggingServiceProtocol?
    private let analytics: AnalyticsServiceProtocol?
    
    // Error handling state
    private var lastErrorTime: Date?
    private var errorThrottleWindow: TimeInterval = 30.0 // 30 seconds
    
    convenience init() {
        print("🎮 GameViewModel: Convenience init started - creating with nil dependencies to avoid circular DI")
        // Create lightweight services directly to avoid circular dependency during DI setup
        let logger = LoggingService()
        let analytics = AnalyticsService(logger: logger)
        let persistenceService = PersistenceService(logger: logger, analytics: analytics)
        let healthService = HealthService(logger: logger, analytics: analytics)
        
        print("🎮 GameViewModel: Created services directly, calling main init")
        self.init(
            persistenceService: persistenceService,
            healthService: healthService,
            logger: logger,
            analytics: analytics
        )
    }
    
    init(persistenceService: PersistenceServiceProtocol,
         healthService: HealthServiceProtocol,
         logger: LoggingServiceProtocol?,
         analytics: AnalyticsServiceProtocol?,
         errorHandler: ErrorHandler? = nil,
         errorRecovery: ErrorRecoveryManager? = nil) {
        print("🎮 GameViewModel: Starting initialization")
        self.persistenceService = persistenceService
        self.healthService = healthService
        self.logger = logger
        self.analytics = analytics
        self.errorHandler = errorHandler ?? ErrorHandler(logger: logger, analytics: analytics)
        self.errorRecovery = errorRecovery ?? ErrorRecoveryManager(logger: logger, analytics: analytics, persistenceService: persistenceService, healthService: healthService)
        
        print("🎮 GameViewModel: Services injected, calling logger")
        logger?.info("GameViewModel initializing", category: .game)
        print("🎮 GameViewModel: Setting up subscriptions")
        setupSubscriptions()
        print("🎮 GameViewModel: Calling loadGameState")
        loadGameState()
        print("🎮 GameViewModel: Initialization complete")
    }
    
    private func setupSubscriptions() {
        // Health data updates
        healthService.healthDataPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] healthData in
                self?.handleHealthDataUpdate(healthData)
            }
            .store(in: &cancellables)
        
        // Health service errors
        healthService.errorPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                self?.handleServiceError(error, context: ErrorContext(userAction: "health_data_update", gameState: self?.gameState.description))
            }
            .store(in: &cancellables)
        
        // Persistence service errors
        persistenceService.errorPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                self?.handleServiceError(error, context: ErrorContext(userAction: "persistence_operation", gameState: self?.gameState.description))
            }
            .store(in: &cancellables)
        
        // Error handler state
        errorHandler.$currentError
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                self?.currentError = error
            }
            .store(in: &cancellables)
        
        errorHandler.$isShowingError
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isShowing in
                self?.isShowingError = isShowing
            }
            .store(in: &cancellables)
        
        errorHandler.$recoveryOptions
            .receive(on: DispatchQueue.main)
            .sink { [weak self] options in
                self?.errorRecoveryOptions = options
            }
            .store(in: &cancellables)
    }
    
    private func loadGameState() {
        print("🎮 GameViewModel: Starting loadGameState - FAST PATH")
        logger?.info("Starting loadGameState - FAST PATH", category: .game)
        
        // SIMPLE FIX: Skip loading entirely and go straight to onboarding
        // The user can create a character and the app will work
        print("🎮 GameViewModel: Going directly to onboarding for immediate UI")
        gameState = .onboarding
        isLoading = false
        
        analytics?.trackGameAction(.appLaunched, parameters: nil)
        
        // Load player data in background - don't block UI
        Task {
            print("🎮 GameViewModel: Loading player data in background")
            do {
                let savedPlayer = try await persistenceService.loadPlayer()
                print("🎮 GameViewModel: Background load completed: \(savedPlayer?.name ?? "nil")")
                
                if let savedPlayer = savedPlayer {
                    await MainActor.run {
                        print("🎮 GameViewModel: Found saved player in background, switching to mainMenu")
                        currentPlayer = savedPlayer
                        gameState = .mainMenu
                    }
                }
            } catch {
                print("🎮 GameViewModel: Background load failed: \(error)")
                // Silently fail - user can still use onboarding
            }
        }
    }
    
    func startGame(with player: Player) {
        logger?.info("Starting game with player: \(player.name), class: \(player.activeClass.rawValue)", category: .game)
        
        // Validate player data before starting the game
        let validationErrors = InputValidator.shared.validatePlayer(player)
        if !validationErrors.isEmpty {
            let errorCollection = ValidationErrorCollection(validationErrors)
            
            // Log validation issues
            ValidationLogger.shared.logValidationErrors(validationErrors, context: .gameplayContext)
            
            // Check for blocking errors
            if errorCollection.hasBlockingErrors {
                let errorMessage = "Cannot start game: \(errorCollection.summaryMessage())"
                handleError(WQError.validation(.invalidPlayerName(errorMessage)))
                return
            } else if errorCollection.hasOnlyWarnings {
                logger?.warning("Starting game with validation warnings: \(errorCollection.summaryMessage())", category: .game)
            }
        }
        
        analytics?.trackGameAction(.onboardingCompleted, parameters: [
            "hero_class": player.activeClass.rawValue,
            "player_name": player.name,
            "validation_warnings": validationErrors.filter { !$0.isBlocking }.count
        ])
        
        // Begin the mystical transition from onboarding to gameplay
        currentPlayer = player
        gameState = .mysticalTransition
        isPlayingIntroSequence = true
        legendBeginning = true
        
        // Generate welcome message based on player's class
        generateRealmWelcome(for: player)
        
        // Animate hero ascension
        animateHeroAscension {
            self.completeGameStart(with: player)
        }
    }
    
    func transitionTo(_ newState: GameState) {
        gameState = newState
    }
    
    func handleError(_ error: Error) {
        let wqError: WQError
        
        if let existingWQError = error as? WQError {
            wqError = existingWQError
        } else {
            wqError = WQError.gameState(.stateCorrupted(error.localizedDescription))
        }
        
        handleWQError(wqError, context: ErrorContext(userAction: "general_error", gameState: gameState.description))
    }
    
    private func handleWQError(_ error: WQError, context: ErrorContext? = nil) {
        logger?.error("GameViewModel error: \(error.errorDescription ?? "Unknown")", category: .game)
        
        // Throttle similar errors to prevent spam
        if shouldThrottleError(error) {
            logger?.debug("Error throttled: \(error.category.rawValue)", category: .game)
            return
        }
        
        lastErrorTime = Date()
        
        Task {
            let result = await errorHandler.handle(error, context: context)
            
            if result.shouldRetry {
                if let retryDelay = result.retryDelay {
                    isRetrying = true
                    try? await Task.sleep(nanoseconds: UInt64(retryDelay * 1_000_000_000))
                    isRetrying = false
                }
                
                // Attempt recovery based on error type
                await attemptErrorRecovery(error)
            }
        }
    }
    
    private func handleServiceError(_ error: WQError, context: ErrorContext?) {
        handleWQError(error, context: context)
    }
    
    private func shouldThrottleError(_ error: WQError) -> Bool {
        guard let lastTime = lastErrorTime else { return false }
        return Date().timeIntervalSince(lastTime) < errorThrottleWindow
    }
    
    private func attemptErrorRecovery(_ error: WQError) async {
        logger?.info("Attempting error recovery for: \(error.category.rawValue)", category: .game)
        
        do {
            let result = await errorRecovery.attemptRecovery(from: error, context: ErrorContext(userAction: "error_recovery", gameState: gameState.description))
            
            if result.wasSuccessful {
                logger?.info("Error recovery successful", category: .game)
                clearError()
                
                if result.fallbackPerformed {
                    // Show user that we've recovered with fallback
                    errorMessage = result.userMessage ?? "Recovered with backup data"
                }
            } else {
                logger?.warning("Error recovery failed", category: .game)
                errorMessage = result.userMessage ?? "Recovery failed, please restart the app"
            }
        } catch {
            logger?.error("Error recovery threw exception: \(error.localizedDescription)", category: .game)
            errorMessage = "Recovery failed, please restart the app"
        }
    }
    
    // MARK: - Public Error Interface
    
    func clearError() {
        errorMessage = nil
        currentError = nil
        isShowingError = false
        errorRecoveryOptions = []
        errorHandler.clearError()
    }
    
    func executeRecoveryOption(_ option: RecoveryOption) {
        switch option {
        case .retry:
            if let error = currentError {
                Task {
                    await attemptErrorRecovery(error)
                }
            }
            
        case .goToOnboarding:
            resetOnboarding()
            
        case .restart:
            // This would typically trigger app restart
            logger?.info("App restart requested", category: .game)
            
        default:
            errorHandler.executeRecoveryOption(option)
        }
    }
    
    func validateGameState() -> Bool {
        // Validate current game state for consistency
        switch gameState {
        case .mainMenu, .inventory, .journal, .settings:
            return currentPlayer != nil
        case .activeQuest(let quest):
            return currentPlayer != nil && !quest.title.isEmpty
        case .encounter(let encounter):
            return currentPlayer != nil && !encounter.description.isEmpty
        default:
            return true
        }
    }
    
    private func handleHealthDataUpdate(_ healthData: HealthData) {
        guard var player = currentPlayer else { return }
        
        let previousSteps = player.stepsToday
        player.stepsToday = healthData.steps
        currentPlayer = player
        
        // Track significant step milestones
        if healthData.steps > 0 && healthData.steps % 1000 == 0 && healthData.steps > previousSteps {
            analytics?.trackGameAction(.healthPermissionGranted, parameters: ["steps_milestone": healthData.steps])
        }
        
        Task {
            do {
                try await persistenceService.savePlayer(player)
            } catch {
                handleError(error)
            }
        }
    }
    
    // MARK: - Active Quest Support
    var activeQuest: Quest? {
        // This would be loaded from persistence or game state
        // For now, returning nil - implement based on your quest system
        return nil
    }
    
    // MARK: - Debug Methods
    func addDebugXP(_ amount: Int) {
        guard var player = currentPlayer else { return }
        
        player.xp += amount
        
        // Check for level up
        let newLevel = (player.xp / 100) + 1
        if newLevel > player.level {
            player.level = newLevel
            // Could trigger level up celebration here
        }
        
        currentPlayer = player
        
        Task {
            do {
                try await persistenceService.savePlayer(player)
            } catch {
                handleError(error)
            }
        }
    }
    
    func resetOnboarding() {
        logger?.info("Resetting onboarding - clearing player data", category: .game)
        analytics?.trackGameAction(.settingsChanged, parameters: ["action": "reset_onboarding"])
        
        currentPlayer = nil
        gameState = .onboarding
        resetFantasyState()
        
        Task {
            do {
                try await persistenceService.clearPlayerData()
            } catch {
                handleError(error)
            }
        }
    }
    
    // MARK: - Fantasy Game State Management
    
    private func generateRealmWelcome(for player: Player) {
        let welcomeMessages: [HeroClass: String] = [
            .warrior: "The realm trembles as a new warrior rises. Your legend of valor begins, \(player.name).",
            .mage: "Ancient magics stir as the arcane arts call to you, \(player.name). Reality bends to your will.",
            .rogue: "Shadows embrace their new master. The hidden paths await your footsteps, \(player.name).",
            .ranger: "The wild places sing your name, \(player.name). Nature itself shall be your ally.",
            .cleric: "Divine light shines upon the realm. You are blessed and chosen, \(player.name)."
        ]
        
        realmWelcomeMessage = welcomeMessages[player.activeClass] ?? "The realm welcomes its newest hero, \(player.name)."
    }
    
    private func animateHeroAscension(completion: @escaping () -> Void) {
        let animationDuration: TimeInterval = WQC.UI.heroAscensionDuration
        let steps = 10
        let stepDuration = animationDuration / Double(steps)
        
        var currentStep = 0
        
        Timer.scheduledTimer(withTimeInterval: stepDuration, repeats: true) { timer in
            currentStep += 1
            let progress = Double(currentStep) / Double(steps)
            
            DispatchQueue.main.async {
                self.heroAscensionProgress = progress
                
                if currentStep >= steps {
                    timer.invalidate()
                    completion()
                }
            }
        }
    }
    
    private func completeGameStart(with player: Player) {
        // Final transition to main menu
        DispatchQueue.main.asyncAfter(deadline: .now() + WQC.UI.gameStartTransitionDelay) {
            self.gameState = .mainMenu
            self.isPlayingIntroSequence = false
        }
        
        // Save player data
        Task {
            do {
                try await persistenceService.savePlayer(player)
                logger?.info("Player data saved successfully", category: .game)
            } catch {
                logger?.error("Failed to save player: \(error.localizedDescription)", category: .game)
                analytics?.trackError(error, context: "GameViewModel.completeGameStart")
                errorMessage = "Failed to save player: \(error.localizedDescription)"
            }
        }
    }
    
    private func resetFantasyState() {
        isPlayingIntroSequence = false
        heroAscensionProgress = 0.0
        realmWelcomeMessage = ""
        legendBeginning = false
    }
    
    // MARK: - Startup Health Check
    
    private func performStartupHealthCheck() {
        print("🔍 GameViewModel: Performing startup health check")
        logger?.info("Performing startup health check due to timeout", category: .game)
        
        Task {
            var healthCheckPassed = true
            var failureReasons: [String] = []
            
            // Check if persistence service is responsive
            do {
                print("🔍 GameViewModel: Testing persistence service")
                _ = try await withTimeout(seconds: 2) {
                    // Try a simple operation to test if persistence is working
                    try await self.persistenceService.loadPlayer()
                }
                print("🔍 GameViewModel: Persistence service check passed")
            } catch {
                print("🔍 GameViewModel: Persistence service check failed: \(error)")
                healthCheckPassed = false
                failureReasons.append("Persistence service unresponsive")
            }
            
            // Check if health service is responsive
            do {
                print("🔍 GameViewModel: Testing health service")
                _ = await healthService.checkAuthorizationStatus()
                print("🔍 GameViewModel: Health service check passed")
            } catch {
                print("🔍 GameViewModel: Health service check failed: \(error)")
                // Health service failure is not critical for startup
                logger?.warning("Health service check failed but continuing startup", category: .game)
            }
            
            await MainActor.run {
                if healthCheckPassed {
                    print("🔍 GameViewModel: Health check passed, retrying game state load")
                    logger?.info("Health check passed, retrying game state load", category: .game)
                    // Reset loading state and try a simplified load
                    performSimplifiedStartup()
                } else {
                    print("🔍 GameViewModel: Health check failed, going to onboarding with fallback")
                    logger?.error("Health check failed: \(failureReasons.joined(separator: ", "))", category: .game)
                    analytics?.trackError(
                        NSError(domain: "GameViewModel", code: 1001, userInfo: [
                            NSLocalizedDescriptionKey: "Startup health check failed: \(failureReasons.joined(separator: ", "))"
                        ]),
                        context: "GameViewModel.performStartupHealthCheck"
                    )
                    
                    // Go to onboarding with error state
                    isLoading = false
                    gameState = .onboarding
                    errorMessage = "Some services are unavailable, but you can still play. Data may not save properly."
                }
            }
        }
    }
    
    private func performSimplifiedStartup() {
        print("🔍 GameViewModel: Performing simplified startup")
        logger?.info("Performing simplified startup", category: .game)
        
        Task {
            do {
                // Try one more time with a very short timeout
                let savedPlayer = try await withTimeout(seconds: 1) {
                    try await self.persistenceService.loadPlayer()
                }
                
                await MainActor.run {
                    if let savedPlayer = savedPlayer {
                        print("🔍 GameViewModel: Simplified startup found player: \(savedPlayer.name)")
                        currentPlayer = savedPlayer
                        gameState = .mainMenu
                    } else {
                        print("🔍 GameViewModel: Simplified startup - no player found")
                        gameState = .onboarding
                    }
                    isLoading = false
                }
            } catch {
                print("🔍 GameViewModel: Simplified startup failed: \(error)")
                await MainActor.run {
                    gameState = .onboarding
                    isLoading = false
                    errorMessage = "Unable to load saved data, starting fresh"
                }
            }
        }
    }
    
    // MARK: - Epic Moments Support
    
    func triggerEpicGameMoment(_ moment: GameEpicMoment) {
        switch moment {
        case .firstQuestBegin:
            // Handle first quest epic moment
            break
        case .levelUp(let newLevel):
            // Handle level up celebration
            break
        case .rareLootFound(let item):
            // Handle rare loot discovery
            break
        case .questComplete(let quest):
            // Handle quest completion ceremony
            break
        }
    }
}

// MARK: - Supporting Types

enum GameEpicMoment {
    case firstQuestBegin
    case levelUp(Int)
    case rareLootFound(String) // Item name
    case questComplete(String) // Quest name
}

// MARK: - GameState Extension

extension GameState {
    var description: String {
        switch self {
        case .onboarding:
            return "onboarding"
        case .mysticalTransition:
            return "mystical_transition"
        case .mainMenu:
            return "main_menu"
        case .activeQuest:
            return "active_quest"
        case .encounter:
            return "encounter"
        case .inventory:
            return "inventory"
        case .journal:
            return "journal"
        case .settings:
            return "settings"
        }
    }
}

// MARK: - Utility Functions

func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
    return try await withThrowingTaskGroup(of: T.self) { group in
        group.addTask {
            try await operation()
        }
        
        group.addTask {
            try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            throw WQError.persistence(.loadFailed("Operation timed out after \(seconds) seconds"))
        }
        
        let result = try await group.next()!
        group.cancelAll()
        return result
    }
}
