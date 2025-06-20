import Foundation
import Combine
@testable import WristQuest_Watch_App

/// Mock implementation of HealthService for testing
class MockHealthService: HealthServiceProtocol {
    
    // MARK: - Publishers
    
    private let healthDataSubject = CurrentValueSubject<HealthData, Never>(HealthData())
    private let authStatusSubject = CurrentValueSubject<HealthAuthorizationStatus, Never>(.notDetermined)
    private let errorSubject = PassthroughSubject<WQError, Never>()
    
    var healthDataPublisher: AnyPublisher<HealthData, Never> {
        healthDataSubject.eraseToAnyPublisher()
    }
    
    var authorizationStatusPublisher: AnyPublisher<HealthAuthorizationStatus, Never> {
        authStatusSubject.eraseToAnyPublisher()
    }
    
    var errorPublisher: AnyPublisher<WQError, Never> {
        errorSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Mock Control Properties
    
    /// Control whether health data is available
    var healthDataAvailable = true
    
    /// Control authorization status responses
    var authorizationStatus: HealthAuthorizationStatus = .notDetermined {
        didSet {
            authStatusSubject.send(authorizationStatus)
        }
    }
    
    /// Control whether authorization should fail
    var shouldFailAuthorization = false
    var authorizationError: WQError?
    
    /// Control whether monitoring should fail
    var shouldFailMonitoring = false
    var monitoringError: WQError?
    
    /// Track method calls for verification
    var authorizationCallCount = 0
    var checkAuthorizationCallCount = 0
    var startMonitoringCallCount = 0
    var stopMonitoringCallCount = 0
    
    /// Current mock health data
    var currentHealthData: HealthData = HealthData() {
        didSet {
            healthDataSubject.send(currentHealthData)
        }
    }
    
    /// Control delay simulation for async operations
    var simulateNetworkDelay = false
    var networkDelayDuration: TimeInterval = 0.1
    
    /// Control whether the service is currently monitoring
    private var isCurrentlyMonitoring = false
    
    // MARK: - Protocol Implementation
    
    func requestAuthorization() async throws {
        authorizationCallCount += 1
        
        if simulateNetworkDelay {
            try await Task.sleep(nanoseconds: UInt64(networkDelayDuration * 1_000_000_000))
        }
        
        if shouldFailAuthorization {
            let error = authorizationError ?? WQError.health(.authorizationDenied)
            errorSubject.send(error)
            throw error
        }
        
        // Simulate successful authorization
        authorizationStatus = .authorized
    }
    
    func checkAuthorizationStatus() async -> HealthAuthorizationStatus {
        checkAuthorizationCallCount += 1
        
        if simulateNetworkDelay {
            try? await Task.sleep(nanoseconds: UInt64(networkDelayDuration * 1_000_000_000))
        }
        
        return authorizationStatus
    }
    
    func startMonitoring() async throws {
        startMonitoringCallCount += 1
        
        if simulateNetworkDelay {
            try await Task.sleep(nanoseconds: UInt64(networkDelayDuration * 1_000_000_000))
        }
        
        if shouldFailMonitoring {
            let error = monitoringError ?? WQError.health(.queryFailed("Mock monitoring failed"))
            errorSubject.send(error)
            throw error
        }
        
        isCurrentlyMonitoring = true
        
        // Start sending health data updates
        startMockDataUpdates()
    }
    
    func stopMonitoring() {
        stopMonitoringCallCount += 1
        isCurrentlyMonitoring = false
    }
    
    func isHealthDataAvailable() -> Bool {
        return healthDataAvailable
    }
    
    // MARK: - Mock Control Methods
    
    /// Reset all mock state to default values
    func reset() {
        healthDataAvailable = true
        authorizationStatus = .notDetermined
        shouldFailAuthorization = false
        shouldFailMonitoring = false
        authorizationError = nil
        monitoringError = nil
        simulateNetworkDelay = false
        networkDelayDuration = 0.1
        isCurrentlyMonitoring = false
        
        // Reset call counts
        authorizationCallCount = 0
        checkAuthorizationCallCount = 0
        startMonitoringCallCount = 0
        stopMonitoringCallCount = 0
        
        // Reset to default health data
        currentHealthData = HealthData()
    }
    
    /// Simulate health data update
    func simulateHealthDataUpdate(_ healthData: HealthData) {
        currentHealthData = healthData
    }
    
    /// Simulate health data updates with realistic progression
    func simulateRealisticHealthData(steps: Int = 5000, duration: TimeInterval = 1.0) {
        Task {
            let baseHealthData = HealthData(
                steps: steps,
                standingHours: 8,
                heartRate: 75.0,
                exerciseMinutes: 30,
                mindfulMinutes: 10
            )
            
            simulateHealthDataUpdate(baseHealthData)
            
            // Simulate gradual step increase
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            
            let updatedHealthData = HealthData(
                steps: steps + 500,
                standingHours: 8,
                heartRate: 80.0,
                exerciseMinutes: 35,
                mindfulMinutes: 10
            )
            
            simulateHealthDataUpdate(updatedHealthData)
        }
    }
    
    /// Simulate combat mode (high heart rate)
    func simulateCombatMode() {
        let combatHealthData = TestDataFactory.createCombatModeHealthData()
        simulateHealthDataUpdate(combatHealthData)
    }
    
    /// Simulate low activity period
    func simulateLowActivity() {
        let lowActivityData = TestDataFactory.createLowActivityHealthData()
        simulateHealthDataUpdate(lowActivityData)
    }
    
    /// Simulate high activity period
    func simulateHighActivity() {
        let highActivityData = TestDataFactory.createHighActivityHealthData()
        simulateHealthDataUpdate(highActivityData)
    }
    
    /// Trigger specific error for testing error handling
    func triggerError(_ error: WQError) {
        errorSubject.send(error)
    }
    
    /// Simulate authorization flow from denied to authorized
    func simulateAuthorizationFlow() {
        Task {
            authorizationStatus = .denied
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            authorizationStatus = .authorized
        }
    }
    
    /// Verify that monitoring is active
    var isMonitoring: Bool {
        return isCurrentlyMonitoring
    }
    
    // MARK: - Private Methods
    
    private func startMockDataUpdates() {
        guard isCurrentlyMonitoring else { return }
        
        // Simulate periodic health data updates
        Task {
            while isCurrentlyMonitoring {
                try? await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
                
                if isCurrentlyMonitoring {
                    let steps = currentHealthData.steps + Int.random(in: 0...100)
                    let heartRate = currentHealthData.heartRate + Double.random(in: -5.0...5.0)
                    
                    let updatedData = HealthData(
                        steps: max(0, steps),
                        standingHours: currentHealthData.standingHours,
                        heartRate: max(60.0, min(180.0, heartRate)),
                        exerciseMinutes: currentHealthData.exerciseMinutes,
                        mindfulMinutes: currentHealthData.mindfulMinutes
                    )
                    
                    simulateHealthDataUpdate(updatedData)
                }
            }
        }
    }
}

// MARK: - Test Helper Extensions

extension MockHealthService {
    /// Create pre-configured mock with authorization granted
    static func authorizedMock() -> MockHealthService {
        let mock = MockHealthService()
        mock.authorizationStatus = .authorized
        return mock
    }
    
    /// Create pre-configured mock with authorization denied
    static func deniedMock() -> MockHealthService {
        let mock = MockHealthService()
        mock.authorizationStatus = .denied
        return mock
    }
    
    /// Create pre-configured mock that fails authorization
    static func failingAuthorizationMock() -> MockHealthService {
        let mock = MockHealthService()
        mock.shouldFailAuthorization = true
        return mock
    }
    
    /// Create pre-configured mock that fails monitoring
    static func failingMonitoringMock() -> MockHealthService {
        let mock = MockHealthService()
        mock.authorizationStatus = .authorized
        mock.shouldFailMonitoring = true
        return mock
    }
    
    /// Create pre-configured mock with realistic health data
    static func withRealisticData() -> MockHealthService {
        let mock = MockHealthService()
        mock.authorizationStatus = .authorized
        mock.currentHealthData = TestDataFactory.createValidHealthData()
        return mock
    }
    
    /// Create pre-configured mock for high activity testing
    static func highActivityMock() -> MockHealthService {
        let mock = MockHealthService()
        mock.authorizationStatus = .authorized
        mock.currentHealthData = TestDataFactory.createHighActivityHealthData()
        return mock
    }
}

// MARK: - HelthAuthorizationStatus for Testing

enum HealthAuthorizationStatus {
    case notDetermined
    case denied
    case authorized
    case restricted
}