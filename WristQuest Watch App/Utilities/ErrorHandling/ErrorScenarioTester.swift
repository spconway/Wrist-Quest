import Foundation
import SwiftUI

// MARK: - Error Scenario Tester

/// A utility class for testing various error scenarios and recovery mechanisms
/// This is useful for development and debugging to ensure error handling works correctly
@MainActor
class ErrorScenarioTester: ObservableObject {
    private let errorHandler: ErrorHandler
    private let errorRecovery: ErrorRecoveryManager
    private let logger: LoggingServiceProtocol?
    
    @Published var testResults: [ErrorTestResult] = []
    @Published var isRunningTests = false
    @Published var currentTestDescription = ""
    
    init(errorHandler: ErrorHandler, errorRecovery: ErrorRecoveryManager, logger: LoggingServiceProtocol? = nil) {
        self.errorHandler = errorHandler
        self.errorRecovery = errorRecovery
        self.logger = logger
    }
    
    // MARK: - Test Scenarios
    
    func runAllErrorScenarios() async {
        isRunningTests = true
        testResults.removeAll()
        
        await testHealthKitErrors()
        await testPersistenceErrors()
        await testQuestErrors()
        await testGameStateErrors()
        await testNetworkErrors()
        await testValidationErrors()
        await testSystemErrors()
        await testRecoveryMechanisms()
        
        isRunningTests = false
        currentTestDescription = "All tests completed"
        
        // Generate summary report
        generateTestSummary()
    }
    
    // MARK: - Individual Error Category Tests
    
    private func testHealthKitErrors() async {
        currentTestDescription = "Testing HealthKit errors..."
        
        let scenarios: [(WQError, String)] = [
            (.healthKit(.healthDataNotAvailable), "Health data not available"),
            (.healthKit(.authorizationDenied), "Authorization denied"),
            (.healthKit(.permissionRequired), "Permission required"),
            (.healthKit(.queryFailed("Test query error")), "Query failed"),
            (.healthKit(.dataCorrupted), "Data corrupted"),
            (.healthKit(.rateLimited), "Rate limited"),
            (.healthKit(.deviceNotSupported), "Device not supported"),
            (.healthKit(.backgroundQueryFailed), "Background query failed")
        ]
        
        for (error, description) in scenarios {
            await testErrorScenario(error: error, description: description)
        }
    }
    
    private func testPersistenceErrors() async {
        currentTestDescription = "Testing Persistence errors..."
        
        let scenarios: [(WQError, String)] = [
            (.persistence(.coreDataUnavailable), "Core Data unavailable"),
            (.persistence(.saveFailed("Test save error")), "Save failed"),
            (.persistence(.loadFailed("Test load error")), "Load failed"),
            (.persistence(.migrationFailed("Test migration error")), "Migration failed"),
            (.persistence(.dataCorrupted), "Data corrupted"),
            (.persistence(.storageFullError), "Storage full"),
            (.persistence(.concurrencyConflict), "Concurrency conflict"),
            (.persistence(.constraintViolation("Test constraint")), "Constraint violation"),
            (.persistence(.entityNotFound("TestEntity")), "Entity not found")
        ]
        
        for (error, description) in scenarios {
            await testErrorScenario(error: error, description: description)
        }
    }
    
    private func testQuestErrors() async {
        currentTestDescription = "Testing Quest errors..."
        
        let scenarios: [(WQError, String)] = [
            (.quest(.questNotFound(UUID())), "Quest not found"),
            (.quest(.invalidQuestState("test_state")), "Invalid quest state"),
            (.quest(.progressionFailed("test_progression")), "Progression failed"),
            (.quest(.completionFailed("test_completion")), "Completion failed"),
            (.quest(.prerequisiteNotMet("test_prerequisite")), "Prerequisite not met"),
            (.quest(.rewardCalculationFailed), "Reward calculation failed"),
            (.quest(.encounterGenerationFailed), "Encounter generation failed"),
            (.quest(.questDataCorrupted(UUID())), "Quest data corrupted")
        ]
        
        for (error, description) in scenarios {
            await testErrorScenario(error: error, description: description)
        }
    }
    
    private func testGameStateErrors() async {
        currentTestDescription = "Testing Game State errors..."
        
        let scenarios: [(WQError, String)] = [
            (.gameState(.invalidTransition(from: "menu", to: "quest")), "Invalid transition"),
            (.gameState(.missingRequiredData("player")), "Missing required data"),
            (.gameState(.stateCorrupted("test_state")), "State corrupted"),
            (.gameState(.synchronizationFailed), "Synchronization failed"),
            (.gameState(.initializationFailed("test_init")), "Initialization failed"),
            (.gameState(.playerNotLoaded), "Player not loaded"),
            (.gameState(.concurrentStateChange), "Concurrent state change")
        ]
        
        for (error, description) in scenarios {
            await testErrorScenario(error: error, description: description)
        }
    }
    
    private func testNetworkErrors() async {
        currentTestDescription = "Testing Network errors..."
        
        let scenarios: [(WQError, String)] = [
            (.network(.noConnection), "No connection"),
            (.network(.timeout), "Timeout"),
            (.network(.serverError(500)), "Server error"),
            (.network(.invalidResponse), "Invalid response"),
            (.network(.rateLimited), "Rate limited"),
            (.network(.authenticationFailed), "Authentication failed"),
            (.network(.badRequest("test_request")), "Bad request")
        ]
        
        for (error, description) in scenarios {
            await testErrorScenario(error: error, description: description)
        }
    }
    
    private func testValidationErrors() async {
        currentTestDescription = "Testing Validation errors..."
        
        let scenarios: [(WQError, String)] = [
            (.validation(.invalidPlayerName("x")), "Invalid player name"),
            (.validation(.invalidHeroClass), "Invalid hero class"),
            (.validation(.invalidQuestData("test_data")), "Invalid quest data"),
            (.validation(.constraintViolation("test_constraint")), "Constraint violation"),
            (.validation(.dataFormatError("test_format")), "Data format error"),
            (.validation(.rangeError("test_range")), "Range error")
        ]
        
        for (error, description) in scenarios {
            await testErrorScenario(error: error, description: description)
        }
    }
    
    private func testSystemErrors() async {
        currentTestDescription = "Testing System errors..."
        
        let scenarios: [(WQError, String)] = [
            (.system(.insufficientMemory), "Insufficient memory"),
            (.system(.diskSpaceError), "Disk space error"),
            (.system(.permissionDenied("test_permission")), "Permission denied"),
            (.system(.deviceCompatibility("test_compatibility")), "Device compatibility"),
            (.system(.osVersionNotSupported), "OS version not supported"),
            (.system(.backgroundProcessingFailed), "Background processing failed"),
            (.system(.resourceUnavailable("test_resource")), "Resource unavailable")
        ]
        
        for (error, description) in scenarios {
            await testErrorScenario(error: error, description: description)
        }
    }
    
    // MARK: - Recovery Mechanism Tests
    
    private func testRecoveryMechanisms() async {
        currentTestDescription = "Testing recovery mechanisms..."
        
        // Test recovery for retryable errors
        await testRecoveryScenario(
            error: .healthKit(.queryFailed("Test recovery")),
            description: "Recovery for retryable HealthKit error"
        )
        
        await testRecoveryScenario(
            error: .persistence(.saveFailed("Test recovery")),
            description: "Recovery for retryable persistence error"
        )
        
        await testRecoveryScenario(
            error: .network(.timeout),
            description: "Recovery for network timeout"
        )
        
        // Test recovery for non-retryable errors
        await testRecoveryScenario(
            error: .healthKit(.healthDataNotAvailable),
            description: "Recovery for non-retryable HealthKit error"
        )
        
        await testRecoveryScenario(
            error: .validation(.invalidPlayerName("x")),
            description: "Recovery for validation error"
        )
    }
    
    // MARK: - Test Execution
    
    private func testErrorScenario(error: WQError, description: String) async {
        let startTime = Date()
        
        do {
            let result = await errorHandler.handle(error, context: ErrorContext(
                userAction: "test_scenario",
                gameState: "testing",
                additionalInfo: ["test_description": description]
            ))
            
            let duration = Date().timeIntervalSince(startTime)
            let testResult = ErrorTestResult(
                errorType: (error as? WQError)?.category.rawValue ?? "unknown",
                description: description,
                severity: (error as? WQError)?.severity.rawValue ?? "unknown",
                wasHandled: result.wasHandled,
                shouldRetry: result.shouldRetry,
                recoveryOptionsCount: result.recoveryOptions.count,
                userMessage: result.userMessage,
                duration: duration,
                success: true,
                failureReason: nil
            )
            
            testResults.append(testResult)
            logger?.debug("Test passed: \(description)", category: .system)
            
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            let testResult = ErrorTestResult(
                errorType: (error as? WQError)?.category.rawValue ?? "unknown",
                description: description,
                severity: (error as? WQError)?.severity.rawValue ?? "unknown",
                wasHandled: false,
                shouldRetry: false,
                recoveryOptionsCount: 0,
                userMessage: nil,
                duration: duration,
                success: false,
                failureReason: error.localizedDescription
            )
            
            testResults.append(testResult)
            logger?.error("Test failed: \(description) - \(error.localizedDescription)", category: .system)
        }
        
        // Small delay between tests
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
    }
    
    private func testRecoveryScenario(error: WQError, description: String) async {
        let startTime = Date()
        
        do {
            let result = await errorRecovery.attemptRecovery(from: error, context: ErrorContext(
                userAction: "test_recovery",
                gameState: "testing",
                additionalInfo: ["test_description": description]
            ))
            
            let duration = Date().timeIntervalSince(startTime)
            let testResult = ErrorTestResult(
                errorType: "\((error as? WQError)?.category.rawValue ?? "unknown")_recovery",
                description: "Recovery: \(description)",
                severity: (error as? WQError)?.severity.rawValue ?? "unknown",
                wasHandled: true,
                shouldRetry: result.shouldRetry,
                recoveryOptionsCount: 0,
                userMessage: result.userMessage,
                duration: duration,
                success: result.wasSuccessful,
                failureReason: result.wasSuccessful ? nil : "Recovery failed"
            )
            
            testResults.append(testResult)
            logger?.debug("Recovery test completed: \(description)", category: .system)
            
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            let testResult = ErrorTestResult(
                errorType: "\((error as? WQError)?.category.rawValue ?? "unknown")_recovery",
                description: "Recovery: \(description)",
                severity: (error as? WQError)?.severity.rawValue ?? "unknown",
                wasHandled: false,
                shouldRetry: false,
                recoveryOptionsCount: 0,
                userMessage: nil,
                duration: duration,
                success: false,
                failureReason: error.localizedDescription
            )
            
            testResults.append(testResult)
            logger?.error("Recovery test failed: \(description) - \(error.localizedDescription)", category: .system)
        }
    }
    
    // MARK: - Test Analysis
    
    private func generateTestSummary() {
        let totalTests = testResults.count
        let passedTests = testResults.filter { $0.success }.count
        let failedTests = totalTests - passedTests
        
        let averageDuration = testResults.reduce(0) { $0 + $1.duration } / Double(totalTests)
        
        let summary = """
        
        ERROR HANDLING TEST SUMMARY
        ===========================
        Total Tests: \(totalTests)
        Passed: \(passedTests)
        Failed: \(failedTests)
        Success Rate: \(String(format: "%.1f", Double(passedTests) / Double(totalTests) * 100))%
        Average Duration: \(String(format: "%.3f", averageDuration))s
        
        Tests by Category:
        """
        
        let categoryBreakdown = Dictionary(grouping: testResults) { $0.errorType }
            .mapValues { results in
                (passed: results.filter { $0.success }.count, total: results.count)
            }
        
        var fullSummary = summary
        for (category, counts) in categoryBreakdown.sorted(by: { $0.key < $1.key }) {
            fullSummary += "\n  \(category): \(counts.passed)/\(counts.total)"
        }
        
        logger?.info(fullSummary, category: .system)
        
        if failedTests > 0 {
            let failedTestDetails = testResults.filter { !$0.success }
                .map { "  - \($0.description): \($0.failureReason ?? "Unknown")" }
                .joined(separator: "\n")
            
            logger?.warning("Failed Tests:\n\(failedTestDetails)", category: .system)
        }
    }
}

// MARK: - Test Result Model

struct ErrorTestResult: Identifiable {
    let id = UUID()
    let errorType: String
    let description: String
    let severity: String
    let wasHandled: Bool
    let shouldRetry: Bool
    let recoveryOptionsCount: Int
    let userMessage: String?
    let duration: TimeInterval
    let success: Bool
    let failureReason: String?
}

// MARK: - Test Runner View

struct ErrorTestRunnerView: View {
    @StateObject private var tester: ErrorScenarioTester
    
    init(errorHandler: ErrorHandler, errorRecovery: ErrorRecoveryManager, logger: LoggingServiceProtocol? = nil) {
        self._tester = StateObject(wrappedValue: ErrorScenarioTester(
            errorHandler: errorHandler,
            errorRecovery: errorRecovery,
            logger: logger
        ))
    }
    
    var body: some View {
        VStack(spacing: 16) {
            if tester.isRunningTests {
                VStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.8)
                    
                    Text(tester.currentTestDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else {
                Button("Run Error Tests") {
                    Task {
                        await tester.runAllErrorScenarios()
                    }
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .background(Color.accentColor)
                .cornerRadius(10)
                .buttonStyle(PlainButtonStyle())
            }
            
            if !tester.testResults.isEmpty {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(tester.testResults) { result in
                            ErrorTestResultRow(result: result)
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Error Tests")
    }
}

struct ErrorTestResultRow: View {
    let result: ErrorTestResult
    
    var body: some View {
        HStack {
            Image(systemName: result.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(result.success ? .green : .red)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(result.description)
                    .font(.caption)
                    .fontWeight(.medium)
                
                Text("\(result.errorType) • \(result.severity)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                if let failureReason = result.failureReason {
                    Text(failureReason)
                        .font(.caption2)
                        .foregroundColor(.red)
                }
            }
            
            Spacer()
            
            Text(String(format: "%.3fs", result.duration))
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(8)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(6)
    }
}