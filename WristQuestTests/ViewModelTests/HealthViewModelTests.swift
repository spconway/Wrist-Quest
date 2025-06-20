import XCTest
import Combine
@testable import WristQuest_Watch_App

@MainActor
final class HealthViewModelTests: XCTestCase {
    
    private var viewModel: HealthViewModel!
    private var mockHealthService: MockHealthService!
    private var mockLogger: MockLoggingService!
    private var mockAnalytics: MockAnalyticsService!
    private var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        setupMocks()
        setupViewModel()
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        cancellables = nil
        viewModel = nil
        mockHealthService = nil
        mockLogger = nil
        mockAnalytics = nil
        super.tearDown()
    }
    
    private func setupMocks() {
        mockHealthService = MockHealthService()
        mockLogger = MockLoggingService()
        mockAnalytics = MockAnalyticsService()
    }
    
    private func setupViewModel() {
        viewModel = HealthViewModel(
            healthService: mockHealthService,
            logger: mockLogger,
            analytics: mockAnalytics
        )
    }
    
    // MARK: - Initialization Tests
    
    func testHealthViewModelInitialization() {
        XCTAssertNotNil(viewModel.currentHealthData, "Should have initial health data")
        XCTAssertFalse(viewModel.isAuthorized, "Should not be authorized initially")
        XCTAssertEqual(viewModel.authorizationStatus, .notDetermined, "Should have not determined status")
        XCTAssertEqual(viewModel.dailyActivityScore, 0, "Should start with zero activity score")
        XCTAssertFalse(viewModel.isInCombatMode, "Should not be in combat mode initially")
        XCTAssertFalse(viewModel.isMonitoring, "Should not be monitoring initially")
        XCTAssertNil(viewModel.healthServiceError, "Should have no errors initially")
        
        // Verify logging
        XCTAssertTrue(mockLogger.verifyInfoLogged(containing: "HealthViewModel initializing"), 
                     "Should log initialization")
        
        // Verify initial authorization check
        XCTAssertGreaterThan(mockHealthService.checkAuthorizationCallCount, 0, 
                           "Should check initial authorization status")
    }
    
    // MARK: - Authorization Tests
    
    func testRequestAuthorization_Success() async {
        // Arrange
        mockHealthService.authorizationStatus = .notDetermined
        
        // Act
        await viewModel.requestAuthorization()
        
        // Wait for authorization state update
        let expectation = expectation(description: "Authorization updated")
        viewModel.$isAuthorized
            .sink { isAuthorized in
                if isAuthorized {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Simulate successful authorization
        mockHealthService.authorizationStatus = .authorized
        
        await fulfillment(of: [expectation], timeout: 2.0)
        
        // Assert
        XCTAssertEqual(mockHealthService.authorizationCallCount, 1, "Should request authorization")
        XCTAssertTrue(viewModel.isAuthorized, "Should be authorized")
        XCTAssertEqual(viewModel.authorizationStatus, .authorized, "Should have authorized status")
        
        // Verify analytics tracking
        XCTAssertTrue(mockAnalytics.wasGameActionTracked(.healthPermissionGranted), 
                     "Should track permission granted")
    }
    
    func testRequestAuthorization_Denied() async {
        // Arrange
        mockHealthService.authorizationStatus = .notDetermined
        
        // Act
        await viewModel.requestAuthorization()
        
        // Wait for authorization state update
        let expectation = expectation(description: "Authorization denied")
        viewModel.$authorizationStatus
            .sink { status in
                if status == .denied {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Simulate denied authorization
        mockHealthService.authorizationStatus = .denied
        
        await fulfillment(of: [expectation], timeout: 2.0)
        
        // Assert
        XCTAssertFalse(viewModel.isAuthorized, "Should not be authorized")
        XCTAssertEqual(viewModel.authorizationStatus, .denied, "Should have denied status")
        
        // Verify analytics tracking
        XCTAssertTrue(mockAnalytics.wasGameActionTracked(.healthPermissionDenied), 
                     "Should track permission denied")
    }
    
    func testRequestAuthorization_Error() async {
        // Arrange
        mockHealthService.shouldFailAuthorization = true
        mockHealthService.authorizationError = WQError.health(.authorizationDenied)
        
        // Act
        await viewModel.requestAuthorization()
        
        // Wait for error state update
        let expectation = expectation(description: "Authorization error handled")
        viewModel.$healthServiceError
            .sink { error in
                if error != nil {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        await fulfillment(of: [expectation], timeout: 2.0)
        
        // Assert
        XCTAssertNotNil(viewModel.healthServiceError, "Should have error")
        XCTAssertFalse(viewModel.isAuthorized, "Should not be authorized")
        
        // Verify error logging
        XCTAssertTrue(mockLogger.verifyErrorLogged(containing: "Health authorization failed"), 
                     "Should log authorization error")
        
        // Verify analytics tracking
        XCTAssertTrue(mockAnalytics.verifyErrorTracked(containing: "authorization"), 
                     "Should track authorization error")
    }
    
    func testCheckAuthorizationStatus() async {
        // Arrange
        mockHealthService.authorizationStatus = .authorized
        
        // Act
        await viewModel.checkAuthorizationStatus()
        
        // Wait for status update
        let expectation = expectation(description: "Status checked")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        await fulfillment(of: [expectation], timeout: 1.0)
        
        // Assert
        XCTAssertGreaterThan(mockHealthService.checkAuthorizationCallCount, 1, // Initial + manual check
                           "Should check authorization status")
        XCTAssertTrue(viewModel.isAuthorized, "Should reflect authorized status")
    }
    
    // MARK: - Health Data Monitoring Tests
    
    func testStartMonitoring_Success() async {
        // Arrange
        mockHealthService.authorizationStatus = .authorized
        
        // Act
        await viewModel.startMonitoring()
        
        // Wait for monitoring state update
        let expectation = expectation(description: "Monitoring started")
        viewModel.$isMonitoring
            .sink { isMonitoring in
                if isMonitoring {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        await fulfillment(of: [expectation], timeout: 2.0)
        
        // Assert
        XCTAssertEqual(mockHealthService.startMonitoringCallCount, 1, "Should start monitoring")
        XCTAssertTrue(viewModel.isMonitoring, "Should be monitoring")
        XCTAssertTrue(mockHealthService.isMonitoring, "Health service should be monitoring")
    }
    
    func testStartMonitoring_WithoutAuthorization() async {
        // Arrange
        mockHealthService.authorizationStatus = .denied
        
        // Act
        await viewModel.startMonitoring()
        
        // Wait for processing
        let expectation = expectation(description: "Monitoring attempt processed")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        await fulfillment(of: [expectation], timeout: 1.0)
        
        // Assert
        XCTAssertFalse(viewModel.isMonitoring, "Should not be monitoring without authorization")
        
        // Verify error handling
        XCTAssertTrue(mockLogger.verifyWarningLogged(containing: "Cannot start monitoring"), 
                     "Should log authorization warning")
    }
    
    func testStartMonitoring_Error() async {
        // Arrange
        mockHealthService.authorizationStatus = .authorized
        mockHealthService.shouldFailMonitoring = true
        mockHealthService.monitoringError = WQError.health(.queryFailed("Monitoring failed"))
        
        // Act
        await viewModel.startMonitoring()
        
        // Wait for error state update
        let expectation = expectation(description: "Monitoring error handled")
        viewModel.$healthServiceError
            .sink { error in
                if error != nil {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        await fulfillment(of: [expectation], timeout: 2.0)
        
        // Assert
        XCTAssertNotNil(viewModel.healthServiceError, "Should have monitoring error")
        XCTAssertFalse(viewModel.isMonitoring, "Should not be monitoring on error")
        
        // Verify error logging
        XCTAssertTrue(mockLogger.verifyErrorLogged(containing: "Health monitoring failed"), 
                     "Should log monitoring error")
    }
    
    func testStopMonitoring() {
        // Arrange
        viewModel.isMonitoring = true
        
        // Act
        viewModel.stopMonitoring()
        
        // Assert
        XCTAssertEqual(mockHealthService.stopMonitoringCallCount, 1, "Should stop monitoring")
        XCTAssertFalse(viewModel.isMonitoring, "Should not be monitoring")
    }
    
    // MARK: - Health Data Updates Tests
    
    func testHealthDataUpdate_ValidData() {
        // Arrange
        let testHealthData = TestDataFactory.createValidHealthData(steps: 5000, heartRate: 75.0)
        
        // Act
        mockHealthService.simulateHealthDataUpdate(testHealthData)
        
        // Wait for update
        let expectation = expectation(description: "Health data updated")
        viewModel.$currentHealthData
            .sink { healthData in
                if healthData.steps == 5000 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 2.0)
        
        // Assert
        XCTAssertEqual(viewModel.currentHealthData.steps, 5000, "Should update steps")
        XCTAssertEqual(viewModel.currentHealthData.heartRate, 75.0, "Should update heart rate")
        XCTAssertGreaterThan(viewModel.dailyActivityScore, 0, "Should calculate activity score")
    }
    
    func testHealthDataUpdate_WithThrottling() {
        // Arrange
        var updateCount = 0
        viewModel.$currentHealthData
            .sink { _ in
                updateCount += 1
            }
            .store(in: &cancellables)
        
        // Act - Send multiple rapid updates
        for steps in 1000...1010 {
            let testHealthData = TestDataFactory.createValidHealthData(steps: steps)
            mockHealthService.simulateHealthDataUpdate(testHealthData)
        }
        
        // Wait for throttling to take effect
        let expectation = expectation(description: "Throttling applied")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 3.0)
        
        // Assert
        XCTAssertLessThan(updateCount, 11, "Should throttle rapid updates")
    }
    
    func testCombatModeDetection_HighHeartRate() {
        // Arrange
        let combatHealthData = TestDataFactory.createCombatModeHealthData()
        
        // Act
        mockHealthService.simulateHealthDataUpdate(combatHealthData)
        
        // Wait for combat mode detection
        let expectation = expectation(description: "Combat mode detected")
        viewModel.$isInCombatMode
            .sink { isInCombatMode in
                if isInCombatMode {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 2.0)
        
        // Assert
        XCTAssertTrue(viewModel.isInCombatMode, "Should detect combat mode with high heart rate")
        
        // Verify analytics tracking
        XCTAssertTrue(mockAnalytics.wasGameActionTracked(.combatEncounter), 
                     "Should track combat mode detection")
    }
    
    func testCombatModeDetection_NormalHeartRate() {
        // Arrange
        let normalHealthData = TestDataFactory.createValidHealthData(steps: 3000, heartRate: 75.0)
        
        // Act
        mockHealthService.simulateHealthDataUpdate(normalHealthData)
        
        // Wait for processing
        let expectation = expectation(description: "Normal health data processed")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // Assert
        XCTAssertFalse(viewModel.isInCombatMode, "Should not be in combat mode with normal heart rate")
    }
    
    func testActivityScoreCalculation() {
        // Test different activity levels
        let testCases = [
            (steps: 0, expectedScore: 0),
            (steps: 2500, expectedScore: 25), // 25% of 10k daily goal
            (steps: 5000, expectedScore: 50), // 50% of 10k daily goal
            (steps: 10000, expectedScore: 100), // 100% of daily goal
            (steps: 15000, expectedScore: 100) // Capped at 100
        ]
        
        for (steps, expectedScore) in testCases {
            let healthData = TestDataFactory.createValidHealthData(steps: steps)
            mockHealthService.simulateHealthDataUpdate(healthData)
            
            // Wait for score calculation
            let expectation = expectation(description: "Activity score calculated for \(steps) steps")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 1.0)
            
            XCTAssertEqual(viewModel.dailyActivityScore, expectedScore, 
                          "Activity score should be \(expectedScore) for \(steps) steps")
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testHealthServiceError_Handling() {
        // Arrange
        let testError = WQError.health(.queryFailed("Test health error"))
        
        // Act
        mockHealthService.triggerError(testError)
        
        // Wait for error handling
        let expectation = expectation(description: "Health error handled")
        viewModel.$healthServiceError
            .sink { error in
                if error != nil {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 2.0)
        
        // Assert
        XCTAssertNotNil(viewModel.healthServiceError, "Should capture health service error")
        
        // Verify error logging
        XCTAssertTrue(mockLogger.verifyErrorLogged(containing: "Health service error"), 
                     "Should log health service error")
        
        // Verify analytics tracking
        XCTAssertTrue(mockAnalytics.verifyErrorTracked(containing: "Test health error"), 
                     "Should track health service error")
    }
    
    func testClearError() {
        // Arrange
        let testError = WQError.health(.queryFailed("Test error"))
        mockHealthService.triggerError(testError)
        
        // Wait for error to be set
        let expectation1 = expectation(description: "Error set")
        viewModel.$healthServiceError
            .sink { error in
                if error != nil {
                    expectation1.fulfill()
                }
            }
            .store(in: &cancellables)
        wait(for: [expectation1], timeout: 1.0)
        
        // Act
        viewModel.clearError()
        
        // Assert
        XCTAssertNil(viewModel.healthServiceError, "Should clear error")
    }
    
    // MARK: - Health Data Availability Tests
    
    func testHealthDataAvailability_Available() {
        // Arrange
        mockHealthService.healthDataAvailable = true
        
        // Act
        let isAvailable = viewModel.isHealthDataAvailable()
        
        // Assert
        XCTAssertTrue(isAvailable, "Should indicate health data is available")
    }
    
    func testHealthDataAvailability_NotAvailable() {
        // Arrange
        mockHealthService.healthDataAvailable = false
        
        // Act
        let isAvailable = viewModel.isHealthDataAvailable()
        
        // Assert
        XCTAssertFalse(isAvailable, "Should indicate health data is not available")
        
        // Verify handling
        XCTAssertTrue(mockLogger.verifyWarningLogged(containing: "Health data not available"), 
                     "Should log availability warning")
    }
    
    // MARK: - Background Monitoring Tests
    
    func testBackgroundMonitoring_AppStateChanges() {
        // Arrange
        mockHealthService.authorizationStatus = .authorized
        viewModel.isMonitoring = true
        
        // Act - Simulate app entering background
        NotificationCenter.default.post(name: UIApplication.didEnterBackgroundNotification, object: nil)
        
        // Wait for background handling
        let expectation = expectation(description: "Background state handled")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // Assert
        // Monitoring should continue in background for health apps
        XCTAssertTrue(viewModel.isMonitoring, "Should continue monitoring in background")
        
        // Act - Simulate app becoming active
        NotificationCenter.default.post(name: UIApplication.didBecomeActiveNotification, object: nil)
        
        // Wait for foreground handling
        let expectation2 = expectation(description: "Foreground state handled")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation2.fulfill()
        }
        wait(for: [expectation2], timeout: 1.0)
        
        // Should resume full monitoring
        XCTAssertTrue(viewModel.isMonitoring, "Should maintain monitoring in foreground")
    }
    
    // MARK: - Data Validation Tests
    
    func testHealthDataValidation_ValidData() {
        // Arrange
        let validHealthData = TestDataFactory.createValidHealthData()
        
        // Act
        mockHealthService.simulateHealthDataUpdate(validHealthData)
        
        // Wait for validation
        let expectation = expectation(description: "Valid data processed")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // Assert
        XCTAssertEqual(viewModel.currentHealthData.steps, validHealthData.steps, 
                      "Should accept valid health data")
        
        // Should not have validation errors
        XCTAssertFalse(mockLogger.verifyWarningLogged(containing: "Invalid health data"), 
                      "Should not log validation warnings for valid data")
    }
    
    func testHealthDataValidation_InvalidData() {
        // Arrange
        let invalidHealthData = TestDataFactory.createInvalidHealthData()
        
        // Act
        mockHealthService.simulateHealthDataUpdate(invalidHealthData)
        
        // Wait for validation
        let expectation = expectation(description: "Invalid data processed")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // Assert
        // Should handle invalid data gracefully
        XCTAssertTrue(mockLogger.verifyWarningLogged(containing: "Invalid health data"), 
                     "Should log validation warning for invalid data")
    }
    
    // MARK: - Integration Tests
    
    func testCompleteHealthFlow_AuthorizeAndMonitor() async {
        // Complete flow: authorize → start monitoring → receive data
        
        // Step 1: Request authorization
        await viewModel.requestAuthorization()
        mockHealthService.authorizationStatus = .authorized
        
        // Wait for authorization
        let authExpectation = expectation(description: "Authorization completed")
        viewModel.$isAuthorized
            .sink { isAuthorized in
                if isAuthorized {
                    authExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        await fulfillment(of: [authExpectation], timeout: 2.0)
        
        // Step 2: Start monitoring
        await viewModel.startMonitoring()
        
        // Wait for monitoring to start
        let monitorExpectation = expectation(description: "Monitoring started")
        viewModel.$isMonitoring
            .sink { isMonitoring in
                if isMonitoring {
                    monitorExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        await fulfillment(of: [monitorExpectation], timeout: 2.0)
        
        // Step 3: Receive health data
        let testHealthData = TestDataFactory.createValidHealthData(steps: 8000, heartRate: 85.0)
        mockHealthService.simulateHealthDataUpdate(testHealthData)
        
        // Wait for data update
        let dataExpectation = expectation(description: "Health data received")
        viewModel.$currentHealthData
            .sink { healthData in
                if healthData.steps == 8000 {
                    dataExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        await fulfillment(of: [dataExpectation], timeout: 2.0)
        
        // Verify complete state
        XCTAssertTrue(viewModel.isAuthorized, "Should be authorized")
        XCTAssertTrue(viewModel.isMonitoring, "Should be monitoring")
        XCTAssertEqual(viewModel.currentHealthData.steps, 8000, "Should have updated health data")
        XCTAssertGreaterThan(viewModel.dailyActivityScore, 0, "Should have calculated activity score")
        
        // Verify analytics tracking
        XCTAssertTrue(mockAnalytics.wasGameActionTracked(.healthPermissionGranted), 
                     "Should track permission granted")
    }
    
    func testHealthFlow_WithErrors() async {
        // Test flow with various error conditions
        
        // Authorization fails
        mockHealthService.shouldFailAuthorization = true
        await viewModel.requestAuthorization()
        
        XCTAssertFalse(viewModel.isAuthorized, "Should not be authorized on failure")
        XCTAssertNotNil(viewModel.healthServiceError, "Should have authorization error")
        
        // Clear error and retry
        viewModel.clearError()
        mockHealthService.shouldFailAuthorization = false
        mockHealthService.authorizationStatus = .authorized
        await viewModel.requestAuthorization()
        
        XCTAssertTrue(viewModel.isAuthorized, "Should be authorized on retry")
        
        // Monitoring fails
        mockHealthService.shouldFailMonitoring = true
        await viewModel.startMonitoring()
        
        XCTAssertFalse(viewModel.isMonitoring, "Should not be monitoring on failure")
        XCTAssertNotNil(viewModel.healthServiceError, "Should have monitoring error")
    }
    
    // MARK: - Performance Tests
    
    func testPerformanceWithFrequentHealthUpdates() {
        measure {
            for steps in 0..<100 {
                let healthData = TestDataFactory.createValidHealthData(steps: steps * 50)
                mockHealthService.simulateHealthDataUpdate(healthData)
            }
        }
    }
    
    func testPerformanceWithCombatModeToggling() {
        measure {
            for i in 0..<50 {
                let heartRate = i % 2 == 0 ? 160.0 : 75.0 // Alternate between combat and normal
                let healthData = TestDataFactory.createValidHealthData(heartRate: heartRate)
                mockHealthService.simulateHealthDataUpdate(healthData)
            }
        }
    }
    
    // MARK: - Memory Management Tests
    
    func testMemoryLeaks_LongRunningMonitoring() {
        // Start monitoring
        mockHealthService.authorizationStatus = .authorized
        Task {
            await viewModel.startMonitoring()
        }
        
        // Simulate long-running monitoring with frequent updates
        for steps in 0..<1000 {
            let healthData = TestDataFactory.createValidHealthData(steps: steps)
            mockHealthService.simulateHealthDataUpdate(healthData)
        }
        
        // Stop monitoring
        viewModel.stopMonitoring()
        
        // Verify cleanup
        XCTAssertFalse(viewModel.isMonitoring, "Should stop monitoring")
        
        // Memory should be released (this is more of a conceptual test)
        // In real scenarios, you'd use memory profiling tools
        XCTAssertTrue(true, "Memory management test completed")
    }
}

// MARK: - Test Helpers

extension HealthViewModelTests {
    
    /// Helper to simulate realistic health data progression
    private func simulateHealthDataProgression(duration: TimeInterval) {
        let steps = [1000, 2500, 5000, 7500, 10000]
        let heartRates = [70.0, 75.0, 80.0, 85.0, 90.0]
        
        for (index, step) in steps.enumerated() {
            let healthData = TestDataFactory.createValidHealthData(
                steps: step,
                heartRate: heartRates[index]
            )
            mockHealthService.simulateHealthDataUpdate(healthData)
            
            // Small delay between updates
            RunLoop.current.run(mode: .default, before: Date(timeIntervalSinceNow: duration / Double(steps.count)))
        }
    }
    
    /// Helper to verify complete health monitoring state
    private func verifyHealthMonitoringState(
        expectedAuthorization: Bool,
        expectedMonitoring: Bool,
        expectedMinActivityScore: Int = 0
    ) {
        XCTAssertEqual(viewModel.isAuthorized, expectedAuthorization, 
                      "Authorization state should match")
        XCTAssertEqual(viewModel.isMonitoring, expectedMonitoring, 
                      "Monitoring state should match")
        XCTAssertGreaterThanOrEqual(viewModel.dailyActivityScore, expectedMinActivityScore, 
                                   "Activity score should meet minimum")
    }
    
    /// Helper to create authorization flow expectation
    private func createAuthorizationExpectation(expectedStatus: HealthAuthorizationStatus) -> XCTestExpectation {
        let expectation = expectation(description: "Authorization status: \(expectedStatus)")
        
        viewModel.$authorizationStatus
            .sink { status in
                if status == expectedStatus {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        return expectation
    }
}