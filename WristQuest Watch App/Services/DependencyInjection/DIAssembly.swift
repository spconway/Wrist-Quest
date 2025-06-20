import Foundation

// MARK: - DI Assembly Protocol

protocol DIAssemblyProtocol {
    func configure(_ container: DIContainerProtocol)
}

// MARK: - Main App Assembly

class AppDIAssembly: DIAssemblyProtocol {
    func configure(_ container: DIContainerProtocol) {
        // Configure all services and dependencies
        configureServices(container)
        configureViewModels(container)
    }
    
    private func configureServices(_ container: DIContainerProtocol) {
        // Register lightweight services first
        container.register(LoggingServiceProtocol.self, scope: .singleton) {
            LoggingService()
        }
        
        container.register(AnalyticsServiceProtocol.self, scope: .singleton) { container in
            let logger: LoggingServiceProtocol = container.resolve(LoggingServiceProtocol.self)
            return AnalyticsService(logger: logger)
        }
        
        // Register heavy services with explicit dependency injection (no lazy initialization)
        print("🔧 DIAssembly: Registering heavy services with explicit dependency injection")
        
        container.register(HealthServiceProtocol.self, scope: .singleton) { container in
            print("🔧 DIAssembly: Creating HealthService with explicit dependencies")
            let logger: LoggingServiceProtocol = container.resolve(LoggingServiceProtocol.self)
            let analytics: AnalyticsServiceProtocol = container.resolve(AnalyticsServiceProtocol.self)
            return HealthService(logger: logger, analytics: analytics)
        }
        
        container.register(PersistenceServiceProtocol.self, scope: .singleton) { container in
            print("🔧 DIAssembly: Creating PersistenceService with explicit dependencies")
            let logger: LoggingServiceProtocol = container.resolve(LoggingServiceProtocol.self)
            let analytics: AnalyticsServiceProtocol = container.resolve(AnalyticsServiceProtocol.self)
            return PersistenceService(logger: logger, analytics: analytics)
        }
        
        container.register(TutorialServiceProtocol.self, scope: .singleton) { container in
            print("🔧 DIAssembly: Creating TutorialService with explicit dependencies")
            let logger: LoggingServiceProtocol = container.resolve(LoggingServiceProtocol.self)
            return TutorialService(logger: logger)
        }
        
        container.register(QuestGenerationServiceProtocol.self, scope: .singleton) { container in
            print("🔧 DIAssembly: Creating QuestGenerationService with explicit dependencies")
            let logger: LoggingServiceProtocol = container.resolve(LoggingServiceProtocol.self)
            return QuestGenerationService(logger: logger)
        }
    }
    
    private func registerHeavyServices(_ container: DIContainerProtocol) {
        // Fallback registration for heavy services
        container.register(HealthServiceProtocol.self, scope: .singleton) {
            HealthService()
        }
        
        container.register(PersistenceServiceProtocol.self, scope: .singleton) {
            PersistenceService()
        }
        
        container.register(TutorialServiceProtocol.self, scope: .singleton) { container in
            let logger: LoggingServiceProtocol = container.resolve(LoggingServiceProtocol.self)
            return TutorialService(logger: logger)
        }
        
        container.register(QuestGenerationServiceProtocol.self, scope: .singleton) { container in
            let logger: LoggingServiceProtocol = container.resolve(LoggingServiceProtocol.self)
            return QuestGenerationService(logger: logger)
        }
    }
    
    private func configureViewModels(_ container: DIContainerProtocol) {
        // Note: ViewModels are @MainActor so they need to be created on the main thread
        // We'll handle this in the ViewModelFactory instead
        // This section is kept for future reference but not currently used
    }
}

// MARK: - Test Assembly

class TestDIAssembly: DIAssemblyProtocol {
    func configure(_ container: DIContainerProtocol) {
        // Register mock services for testing
        container.register(LoggingServiceProtocol.self, scope: .singleton) {
            MockLoggingService()
        }
        
        container.register(AnalyticsServiceProtocol.self, scope: .singleton) {
            MockAnalyticsService()
        }
        
        // Note: For testing, you might want to create mock versions of HealthService and PersistenceService
        // For now, we'll use the real implementations
        container.register(HealthServiceProtocol.self, scope: .singleton) {
            HealthService()
        }
        
        container.register(PersistenceServiceProtocol.self, scope: .singleton) {
            PersistenceService()
        }
        
        // Register tutorial and quest generation services for testing
        container.register(TutorialServiceProtocol.self, scope: .singleton) {
            TutorialService() // Could be replaced with MockTutorialService
        }
        
        container.register(QuestGenerationServiceProtocol.self, scope: .singleton) {
            QuestGenerationService() // Could be replaced with MockQuestGenerationService
        }
    }
}

// MARK: - DI Configuration Manager

class DIConfiguration {
    static let shared = DIConfiguration()
    private let container = DIContainer.shared
    
    private init() {}
    
    func configure(for environment: AppEnvironment = .production) {
        let assembly: DIAssemblyProtocol
        
        switch environment {
        case .production:
            assembly = AppDIAssembly()
        case .testing:
            assembly = TestDIAssembly()
        case .development:
            assembly = AppDIAssembly() // Could create a DevDIAssembly with additional debug services
        }
        
        assembly.configure(container)
    }
    
    func resolve<T>(_ type: T.Type) -> T {
        return container.resolve(type)
    }
    
    func resolve<T>(_ type: T.Type) -> T? {
        return container.resolve(type)
    }
    
    // Convenience methods for common resolutions
    func resolveLoggingService() -> LoggingServiceProtocol {
        return container.resolve(LoggingServiceProtocol.self)
    }
    
    func resolveAnalyticsService() -> AnalyticsServiceProtocol {
        return container.resolve(AnalyticsServiceProtocol.self)
    }
    
    func resolveHealthService() -> HealthServiceProtocol {
        return container.resolve(HealthServiceProtocol.self)
    }
    
    func resolvePersistenceService() -> PersistenceServiceProtocol {
        return container.resolve(PersistenceServiceProtocol.self)
    }
    
    // Debug methods
    func debugPrintRegistrations() {
        container.debugPrintRegistrations()
    }
}

// MARK: - App Environment

enum AppEnvironment {
    case production
    case development
    case testing
}

// MARK: - ViewModels Factory

@MainActor
struct ViewModelFactory {
    private let container = DIContainer.shared
    
    func createPlayerViewModel(with player: Player) -> PlayerViewModel {
        let persistenceService: PersistenceServiceProtocol = container.resolve(PersistenceServiceProtocol.self)
        let logger: LoggingServiceProtocol = container.resolve(LoggingServiceProtocol.self)
        let analytics: AnalyticsServiceProtocol = container.resolve(AnalyticsServiceProtocol.self)
        return PlayerViewModel(player: player, persistenceService: persistenceService, logger: logger, analytics: analytics)
    }
    
    func createQuestViewModel(with playerViewModel: PlayerViewModel) -> QuestViewModel {
        let persistenceService: PersistenceServiceProtocol = container.resolve(PersistenceServiceProtocol.self)
        let healthService: HealthServiceProtocol = container.resolve(HealthServiceProtocol.self)
        let tutorialService: TutorialServiceProtocol = container.resolve(TutorialServiceProtocol.self)
        let questGenerationService: QuestGenerationServiceProtocol = container.resolve(QuestGenerationServiceProtocol.self)
        let logger: LoggingServiceProtocol = container.resolve(LoggingServiceProtocol.self)
        let analytics: AnalyticsServiceProtocol = container.resolve(AnalyticsServiceProtocol.self)
        return QuestViewModel(playerViewModel: playerViewModel, persistenceService: persistenceService, healthService: healthService, tutorialService: tutorialService, questGenerationService: questGenerationService, logger: logger, analytics: analytics)
    }
    
    func createGameViewModel() -> GameViewModel {
        return container.resolve(GameViewModel.self)
    }
    
    func createHealthViewModel() -> HealthViewModel {
        return container.resolve(HealthViewModel.self)
    }
}

// MARK: - DI Property Wrapper

@propertyWrapper
struct Injected<T> {
    private let keyPath: KeyPath<DIConfiguration, T>
    
    var wrappedValue: T {
        DIConfiguration.shared[keyPath: keyPath]
    }
    
    init(_ keyPath: KeyPath<DIConfiguration, T>) {
        self.keyPath = keyPath
    }
}

// MARK: - Convenience Property Wrappers

@propertyWrapper
struct InjectLogger {
    var wrappedValue: LoggingServiceProtocol {
        DIConfiguration.shared.resolveLoggingService()
    }
}

@propertyWrapper
struct InjectAnalytics {
    var wrappedValue: AnalyticsServiceProtocol {
        DIConfiguration.shared.resolveAnalyticsService()
    }
}

@propertyWrapper
struct InjectHealthService {
    var wrappedValue: HealthServiceProtocol {
        DIConfiguration.shared.resolveHealthService()
    }
}

@propertyWrapper
struct InjectPersistenceService {
    var wrappedValue: PersistenceServiceProtocol {
        DIConfiguration.shared.resolvePersistenceService()
    }
}