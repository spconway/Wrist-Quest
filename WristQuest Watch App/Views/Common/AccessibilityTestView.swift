import SwiftUI

/// Accessibility test view for WristQuest
/// Use this view to test and validate accessibility features
/// ONLY available in DEBUG builds for development and testing
#if DEBUG
struct AccessibilityTestView: View {
    @State private var testResults: [AccessibilityTestResult] = []
    @State private var isRunningTests = false
    @State private var currentTestIndex = 0
    @State private var dynamicTypeSize: DynamicTypeSize = .medium
    @State private var voiceOverTestActive = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: WQDesignSystem.Spacing.lg) {
                    AccessibilitySettingsSection()
                    
                    AccessibilityTestControlsSection(
                        isRunningTests: $isRunningTests,
                        onRunTests: runAccessibilityTests,
                        onClearResults: clearTestResults
                    )
                    
                    if !testResults.isEmpty {
                        AccessibilityTestResultsSection(results: testResults)
                    }
                    
                    AccessibilityFeatureDemoSection()
                }
                .padding(WQDesignSystem.Spacing.md)
            }
            .navigationTitle("Accessibility Testing")
            .navigationBarTitleDisplayMode(.inline)
            .environment(\.dynamicTypeSize, dynamicTypeSize)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Accessibility testing and validation interface")
    }
    
    private func runAccessibilityTests() {
        isRunningTests = true
        testResults.removeAll()
        currentTestIndex = 0
        
        let tests: [AccessibilityTest] = [
            AccessibilityTest(
                name: "VoiceOver Status Check",
                description: "Verify VoiceOver running status detection",
                test: { await testVoiceOverStatus() }
            ),
            AccessibilityTest(
                name: "Dynamic Type Support",
                description: "Test dynamic type size detection and scaling",
                test: { await testDynamicTypeSupport() }
            ),
            AccessibilityTest(
                name: "Accessibility Constants",
                description: "Verify accessibility constants are properly defined",
                test: { await testAccessibilityConstants() }
            ),
            AccessibilityTest(
                name: "Custom Modifiers",
                description: "Test custom accessibility modifiers",
                test: { await testCustomModifiers() }
            ),
            AccessibilityTest(
                name: "Announcement System",
                description: "Test VoiceOver announcement functionality",
                test: { await testAnnouncementSystem() }
            )
        ]
        
        Task {
            for test in tests {
                let result = await runSingleTest(test)
                await MainActor.run {
                    testResults.append(result)
                    currentTestIndex += 1
                }
                
                // Small delay between tests
                try? await Task.sleep(nanoseconds: 500_000_000)
            }
            
            await MainActor.run {
                isRunningTests = false
                AccessibilityHelpers.announce("Accessibility tests completed. \(testResults.filter { $0.passed }.count) of \(testResults.count) tests passed.")
            }
        }
    }
    
    private func runSingleTest(_ test: AccessibilityTest) async -> AccessibilityTestResult {
        let success = await test.test()
        return AccessibilityTestResult(
            testName: test.name,
            description: test.description,
            passed: success,
            message: success ? "Test passed" : "Test failed",
            timestamp: Date()
        )
    }
    
    private func clearTestResults() {
        testResults.removeAll()
        AccessibilityHelpers.announce("Test results cleared")
    }
    
    // MARK: - Test Implementations
    
    private func testVoiceOverStatus() async -> Bool {
        let _ = AccessibilityHelpers.isVoiceOverRunning
        let _ = AccessibilityHelpers.isSwitchControlRunning
        let _ = AccessibilityHelpers.isAssistiveTechnologyRunning
        
        AccessibilityHelpers.debugAccessibility(
            for: "VoiceOver Status Test",
            context: "Testing"
        )
        
        // Test passes if we can detect the status (even if false)
        return true
    }
    
    private func testDynamicTypeSupport() async -> Bool {
        let testSizes: [DynamicTypeSize] = [
            .medium, .large, .xLarge, .accessibility1, .accessibility5
        ]
        
        for size in testSizes {
            let scaleFactor = AccessibilityHelpers.dynamicTypeScaleFactor(for: size)
            let isAccessibility = AccessibilityHelpers.isAccessibilitySize(size)
            let scaledValue = AccessibilityHelpers.scaledValue(16.0, for: size)
            
            // Verify scaling works correctly
            guard scaleFactor > 0 && scaledValue > 0 else {
                return false
            }
        }
        
        return true
    }
    
    private func testAccessibilityConstants() async -> Bool {
        // Test that key constants are not empty
        let constantsToTest = [
            AccessibilityConstants.Navigation.mainMenu,
            AccessibilityConstants.Onboarding.welcomeTitle,
            AccessibilityConstants.Quests.activeQuestTitle,
            AccessibilityConstants.Health.activityTracking,
            AccessibilityConstants.Player.experienceLabel
        ]
        
        for constant in constantsToTest {
            guard !constant.isEmpty else {
                return false
            }
        }
        
        return true
    }
    
    private func testCustomModifiers() async -> Bool {
        // Test that modifier helpers work correctly
        let questInfo = WQQuestAccessibilityInfo(
            title: "Test Quest",
            description: "Test Description",
            isActive: true,
            isCompleted: false,
            progress: 0.5,
            rewardXP: 100,
            rewardGold: 50
        )
        
        let rewardInfo = WQRewardInfo(type: .experience, amount: 100)
        
        // Verify info structures work correctly
        return !questInfo.title.isEmpty && !rewardInfo.description.isEmpty
    }
    
    private func testAnnouncementSystem() async -> Bool {
        // Test announcements (these should not crash)
        AccessibilityHelpers.announce("Test announcement")
        AccessibilityHelpers.announceQuestProgress("Test Quest", progress: 0.5)
        AccessibilityHelpers.announceLevelUp(newLevel: 5, className: "Warrior")
        AccessibilityHelpers.announceQuestCompletion(questTitle: "Test", xpReward: 100, goldReward: 50)
        AccessibilityHelpers.announceCombatMode()
        AccessibilityHelpers.announceActivityMilestone(activityType: "steps", value: "1000")
        
        // Test passes if no crashes occur
        return true
    }
}

// MARK: - Supporting Views

struct AccessibilitySettingsSection: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    
    var body: some View {
        WQCard {
            VStack(alignment: .leading, spacing: WQDesignSystem.Spacing.md) {
                Text("Accessibility Settings")
                    .font(WQDesignSystem.Typography.headline)
                    .accessibilityAddTraits(.isHeader)
                
                VStack(alignment: .leading, spacing: WQDesignSystem.Spacing.sm) {
                    AccessibilityInfoRow(
                        label: "VoiceOver",
                        value: AccessibilityHelpers.isVoiceOverRunning ? "Running" : "Not Running",
                        isActive: AccessibilityHelpers.isVoiceOverRunning
                    )
                    
                    AccessibilityInfoRow(
                        label: "Switch Control",
                        value: AccessibilityHelpers.isSwitchControlRunning ? "Running" : "Not Running",
                        isActive: AccessibilityHelpers.isSwitchControlRunning
                    )
                    
                    AccessibilityInfoRow(
                        label: "Reduce Motion",
                        value: AccessibilityHelpers.isReduceMotionEnabled ? "Enabled" : "Disabled",
                        isActive: AccessibilityHelpers.isReduceMotionEnabled
                    )
                    
                    AccessibilityInfoRow(
                        label: "High Contrast",
                        value: AccessibilityHelpers.isIncreasedContrastEnabled ? "Enabled" : "Disabled",
                        isActive: AccessibilityHelpers.isIncreasedContrastEnabled
                    )
                    
                    AccessibilityInfoRow(
                        label: "Dynamic Type",
                        value: "\(dynamicTypeSize)",
                        isActive: AccessibilityHelpers.isAccessibilitySize(dynamicTypeSize)
                    )
                }
            }
        }
    }
}

struct AccessibilityInfoRow: View {
    let label: String
    let value: String
    let isActive: Bool
    
    var body: some View {
        HStack {
            Text(label)
                .font(WQDesignSystem.Typography.caption)
                .foregroundColor(WQDesignSystem.Colors.secondaryText)
            
            Spacer()
            
            Text(value)
                .font(WQDesignSystem.Typography.caption)
                .foregroundColor(isActive ? WQDesignSystem.Colors.success : WQDesignSystem.Colors.primaryText)
                .fontWeight(isActive ? .medium : .regular)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

struct AccessibilityTestControlsSection: View {
    @Binding var isRunningTests: Bool
    let onRunTests: () -> Void
    let onClearResults: () -> Void
    
    var body: some View {
        WQCard {
            VStack(spacing: WQDesignSystem.Spacing.md) {
                Text("Test Controls")
                    .font(WQDesignSystem.Typography.headline)
                    .accessibilityAddTraits(.isHeader)
                
                HStack(spacing: WQDesignSystem.Spacing.md) {
                    WQButton(
                        isRunningTests ? "Running Tests..." : "Run Tests",
                        icon: isRunningTests ? "clock" : "play.fill"
                    ) {
                        onRunTests()
                    }
                    .disabled(isRunningTests)
                    .accessibleActionButton(
                        actionName: "Run accessibility tests",
                        description: "Start comprehensive accessibility validation",
                        isEnabled: !isRunningTests
                    )
                    
                    WQButton("Clear Results", icon: "trash") {
                        onClearResults()
                    }
                    .disabled(isRunningTests)
                    .accessibleActionButton(
                        actionName: "Clear test results",
                        description: "Remove all test results from display"
                    )
                }
            }
        }
    }
}

struct AccessibilityTestResultsSection: View {
    let results: [AccessibilityTestResult]
    
    var body: some View {
        WQCard {
            VStack(alignment: .leading, spacing: WQDesignSystem.Spacing.md) {
                Text("Test Results")
                    .font(WQDesignSystem.Typography.headline)
                    .accessibilityAddTraits(.isHeader)
                
                VStack(spacing: WQDesignSystem.Spacing.sm) {
                    ForEach(results, id: \.testName) { result in
                        AccessibilityTestResultRow(result: result)
                    }
                }
                
                // Summary
                let passedCount = results.filter { $0.passed }.count
                let totalCount = results.count
                
                HStack {
                    Text("Summary:")
                        .font(WQDesignSystem.Typography.caption)
                        .foregroundColor(WQDesignSystem.Colors.secondaryText)
                    
                    Spacer()
                    
                    Text("\(passedCount)/\(totalCount) Passed")
                        .font(WQDesignSystem.Typography.caption)
                        .foregroundColor(passedCount == totalCount ? WQDesignSystem.Colors.success : WQDesignSystem.Colors.error)
                        .fontWeight(.medium)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Test summary: \(passedCount) of \(totalCount) tests passed")
            }
        }
    }
}

struct AccessibilityTestResultRow: View {
    let result: AccessibilityTestResult
    
    var body: some View {
        HStack(spacing: WQDesignSystem.Spacing.sm) {
            Image(systemName: result.passed ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(result.passed ? WQDesignSystem.Colors.success : WQDesignSystem.Colors.error)
                .accessibilityLabel(result.passed ? "Test passed" : "Test failed")
            
            VStack(alignment: .leading, spacing: WQDesignSystem.Spacing.xs) {
                Text(result.testName)
                    .font(WQDesignSystem.Typography.caption)
                    .foregroundColor(WQDesignSystem.Colors.primaryText)
                    .fontWeight(.medium)
                
                Text(result.message)
                    .font(WQDesignSystem.Typography.footnote)
                    .foregroundColor(WQDesignSystem.Colors.secondaryText)
            }
            
            Spacer()
        }
        .padding(WQDesignSystem.Spacing.sm)
        .background(result.passed ? WQDesignSystem.Colors.success.opacity(0.1) : WQDesignSystem.Colors.error.opacity(0.1))
        .cornerRadius(WQDesignSystem.CornerRadius.sm)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Test: \(result.testName), \(result.passed ? "passed" : "failed"), \(result.message)")
    }
}

struct AccessibilityFeatureDemoSection: View {
    var body: some View {
        WQCard {
            VStack(alignment: .leading, spacing: WQDesignSystem.Spacing.md) {
                Text("Feature Demonstrations")
                    .font(WQDesignSystem.Typography.headline)
                    .accessibilityAddTraits(.isHeader)
                
                VStack(spacing: WQDesignSystem.Spacing.sm) {
                    WQButton("Test Quest Progress Announcement") {
                        AccessibilityHelpers.announceQuestProgress("Test Quest", progress: 0.75)
                    }
                    .accessibleActionButton(
                        actionName: "Test quest progress announcement",
                        description: "Trigger a sample quest progress VoiceOver announcement"
                    )
                    
                    WQButton("Test Level Up Announcement") {
                        AccessibilityHelpers.announceLevelUp(newLevel: 5, className: "Warrior")
                    }
                    .accessibleActionButton(
                        actionName: "Test level up announcement",
                        description: "Trigger a sample level up VoiceOver announcement"
                    )
                    
                    WQButton("Test Quest Completion") {
                        AccessibilityHelpers.announceQuestCompletion(questTitle: "Demo Quest", xpReward: 150, goldReward: 75)
                    }
                    .accessibleActionButton(
                        actionName: "Test quest completion announcement",
                        description: "Trigger a sample quest completion VoiceOver announcement"
                    )
                    
                    WQButton("Test Combat Mode") {
                        AccessibilityHelpers.announceCombatMode()
                    }
                    .accessibleActionButton(
                        actionName: "Test combat mode announcement",
                        description: "Trigger a sample combat mode VoiceOver announcement"
                    )
                }
            }
        }
    }
}

// MARK: - Supporting Types

struct AccessibilityTest {
    let name: String
    let description: String
    let test: () async -> Bool
}

struct AccessibilityTestResult {
    let testName: String
    let description: String
    let passed: Bool
    let message: String
    let timestamp: Date
}

// MARK: - Preview

#Preview {
    AccessibilityTestView()
}

#endif