import Foundation

// MARK: - Dependency Injection Container Protocol

protocol DIContainerProtocol {
    func register<T>(_ type: T.Type, scope: DIScope, factory: @escaping () -> T)
    func register<T>(_ type: T.Type, scope: DIScope, factory: @escaping (DIContainerProtocol) -> T)
    func resolve<T>(_ type: T.Type) -> T
    func resolve<T>(_ type: T.Type) -> T?
}

// MARK: - Dependency Injection Scope

enum DIScope {
    case singleton
    case transient
}

// MARK: - DI Container Error Types

enum DIError: Error, LocalizedError {
    case serviceNotRegistered(String)
    case circularDependency(String)
    case factoryFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .serviceNotRegistered(let type):
            return "Service not registered: \(type)"
        case .circularDependency(let type):
            return "Circular dependency detected for: \(type)"
        case .factoryFailed(let type):
            return "Factory failed to create instance of: \(type)"
        }
    }
}

// MARK: - Service Factory Types

private protocol ServiceFactory {
    func create(container: DIContainerProtocol) -> Any
    var scope: DIScope { get }
}

private struct SimpleServiceFactory<T>: ServiceFactory {
    let factory: () -> T
    let scope: DIScope
    
    func create(container: DIContainerProtocol) -> Any {
        return factory()
    }
}

private struct ContainerServiceFactory<T>: ServiceFactory {
    let factory: (DIContainerProtocol) -> T
    let scope: DIScope
    
    func create(container: DIContainerProtocol) -> Any {
        return factory(container)
    }
}

// MARK: - DI Container Implementation

final class DIContainer: DIContainerProtocol {
    private var factories: [String: ServiceFactory] = [:]
    private var singletonInstances: [String: Any] = [:]
    private var lazyInstances: [String: () -> Any] = [:]
    private var resolutionStack: Set<String> = []
    
    private let lock = NSLock()
    
    init() {}
    
    private init(private: Bool) {}
    
    // Private singleton instance
    private static let _shared = DIContainer(private: true)
    
    // MARK: - Registration Methods
    
    func register<T>(_ type: T.Type, scope: DIScope = .singleton, factory: @escaping () -> T) {
        let key = String(describing: type)
        lock.lock()
        defer { lock.unlock() }
        
        factories[key] = SimpleServiceFactory(factory: factory, scope: scope)
        
        // Clear any existing instances if re-registering
        if singletonInstances[key] != nil {
            singletonInstances.removeValue(forKey: key)
        }
        lazyInstances.removeValue(forKey: key)
    }
    
    func registerLazy<T>(_ type: T.Type, scope: DIScope = .singleton, factory: @escaping () -> T) {
        let key = String(describing: type)
        lock.lock()
        defer { lock.unlock() }
        
        // Store the factory for lazy initialization
        lazyInstances[key] = factory
        factories[key] = SimpleServiceFactory(factory: factory, scope: scope)
        
        print("🔧 DIContainer: Registered lazy service: \(key)")
    }
    
    func register<T>(_ type: T.Type, scope: DIScope = .singleton, factory: @escaping (DIContainerProtocol) -> T) {
        let key = String(describing: type)
        lock.lock()
        defer { lock.unlock() }
        
        factories[key] = ContainerServiceFactory(factory: factory, scope: scope)
        
        // Clear singleton instance if re-registering
        if singletonInstances[key] != nil {
            singletonInstances.removeValue(forKey: key)
        }
    }
    
    // MARK: - Resolution Methods
    
    func resolve<T>(_ type: T.Type) -> T {
        guard let instance: T = resolve(type) else {
            fatalError(DIError.serviceNotRegistered(String(describing: type)).localizedDescription)
        }
        return instance
    }
    
    func resolve<T>(_ type: T.Type) -> T? {
        let key = String(describing: type)
        
        lock.lock()
        defer { lock.unlock() }
        
        // Check for circular dependency
        guard !resolutionStack.contains(key) else {
            print("⚠️ DIContainer: Circular dependency detected for \(key)")
            return nil
        }
        
        // Get factory
        guard let factory = factories[key] else {
            print("⚠️ DIContainer: Service not registered: \(key)")
            return nil
        }
        
        // Return singleton instance if exists
        if factory.scope == .singleton, let instance = singletonInstances[key] as? T {
            return instance
        }
        
        // Create new instance
        resolutionStack.insert(key)
        defer { resolutionStack.remove(key) }
        
        guard let instance = factory.create(container: self) as? T else {
            print("⚠️ DIContainer: Factory failed to create instance of \(key)")
            return nil
        }
        
        // Store singleton instance
        if factory.scope == .singleton {
            singletonInstances[key] = instance
        }
        
        return instance
    }
    
    // MARK: - Utility Methods
    
    func isRegistered<T>(_ type: T.Type) -> Bool {
        let key = String(describing: type)
        lock.lock()
        defer { lock.unlock() }
        return factories[key] != nil
    }
    
    func unregister<T>(_ type: T.Type) {
        let key = String(describing: type)
        lock.lock()
        defer { lock.unlock() }
        
        factories.removeValue(forKey: key)
        singletonInstances.removeValue(forKey: key)
    }
    
    func clear() {
        lock.lock()
        defer { lock.unlock() }
        
        factories.removeAll()
        singletonInstances.removeAll()
        resolutionStack.removeAll()
    }
    
    // MARK: - Debug Methods
    
    func debugPrintRegistrations() {
        lock.lock()
        defer { lock.unlock() }
        
        print("📦 DIContainer Registrations:")
        for (key, factory) in factories {
            let scopeText = factory.scope == .singleton ? "Singleton" : "Transient"
            let instanceText = singletonInstances[key] != nil ? " (Instance Cached)" : ""
            print("  - \(key): \(scopeText)\(instanceText)")
        }
    }
}

// MARK: - Convenience Extensions

extension DIContainer {
    // Protocol-based registration for common service patterns
    // Note: Removing this method as it has type constraint issues
    // Use the standard register methods instead
    
    // Register with manual instance creation
    func registerInstance<T>(_ type: T.Type, instance: T) {
        let key = String(describing: type)
        lock.lock()
        defer { lock.unlock() }
        
        factories[key] = SimpleServiceFactory(factory: { instance }, scope: .singleton)
        singletonInstances[key] = instance
    }
}

// MARK: - Thread-Safe Singleton Access

extension DIContainer {
    static var shared: DIContainer {
        return _shared
    }
}