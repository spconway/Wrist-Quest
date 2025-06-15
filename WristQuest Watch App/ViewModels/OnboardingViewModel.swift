import Foundation
import SwiftUI

@MainActor
class OnboardingViewModel: ObservableObject {
    @Published var currentStep: OnboardingStep = .welcome
    @Published var selectedClass: HeroClass?
    @Published var playerName = ""
    @Published var healthPermissionStatus: HealthAuthorizationStatus = .notDetermined
    @Published var isRequestingPermission = false
    @Published var showingError = false
    @Published var errorMessage = ""
    
    private let healthService: HealthServiceProtocol
    private var gameViewModel: GameViewModel
    
    enum OnboardingStep: CaseIterable {
        case welcome
        case healthPermission
        case characterCreation
        case tutorialQuest
        case complete
        
        var title: String {
            switch self {
            case .welcome:
                return "Welcome to Wrist Quest"
            case .healthPermission:
                return "Health Integration"
            case .characterCreation:
                return "Choose Your Hero"
            case .tutorialQuest:
                return "Your First Quest"
            case .complete:
                return "Ready to Adventure"
            }
        }
        
        var description: String {
            switch self {
            case .welcome:
                return "Turn your daily activity into epic adventures"
            case .healthPermission:
                return "Grant health access to power your quests"
            case .characterCreation:
                return "Select your character class and abilities"
            case .tutorialQuest:
                return "Learn the basics with a guided quest"
            case .complete:
                return "Your journey begins now"
            }
        }
    }
    
    init(healthService: HealthServiceProtocol = HealthService(),
         gameViewModel: GameViewModel) {
        self.healthService = healthService
        self.gameViewModel = gameViewModel
        
        checkHealthPermissionStatus()
    }
    
    var canProceed: Bool {
        switch currentStep {
        case .welcome:
            return true
        case .healthPermission:
            return healthPermissionStatus == .authorized
        case .characterCreation:
            return selectedClass != nil && !playerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .tutorialQuest:
            return true
        case .complete:
            return true
        }
    }
    
    var progressPercentage: Double {
        let currentIndex = OnboardingStep.allCases.firstIndex(of: currentStep) ?? 0
        return Double(currentIndex) / Double(OnboardingStep.allCases.count - 1)
    }
    
    func nextStep() {
        print("🎮 OnboardingViewModel: nextStep() called")
        print("🎮 OnboardingViewModel: currentStep = \(currentStep)")
        print("🎮 OnboardingViewModel: canProceed = \(canProceed)")
        
        guard canProceed else { 
            print("🎮 OnboardingViewModel: Cannot proceed, returning early")
            return 
        }
        
        let oldStep = currentStep
        
        switch currentStep {
        case .welcome:
            print("🎮 OnboardingViewModel: Moving from welcome to healthPermission")
            currentStep = .healthPermission
        case .healthPermission:
            print("🎮 OnboardingViewModel: Moving from healthPermission to characterCreation")
            currentStep = .characterCreation
        case .characterCreation:
            print("🎮 OnboardingViewModel: Moving from characterCreation to tutorialQuest")
            currentStep = .tutorialQuest
        case .tutorialQuest:
            print("🎮 OnboardingViewModel: Moving from tutorialQuest to complete")
            currentStep = .complete
        case .complete:
            print("🎮 OnboardingViewModel: Completing onboarding")
            completeOnboarding()
        }
        
        print("🎮 OnboardingViewModel: Step changed from \(oldStep) to \(currentStep)")
    }
    
    func previousStep() {
        switch currentStep {
        case .welcome:
            break
        case .healthPermission:
            currentStep = .welcome
        case .characterCreation:
            currentStep = .healthPermission
        case .tutorialQuest:
            currentStep = .characterCreation
        case .complete:
            currentStep = .tutorialQuest
        }
    }
    
    func requestHealthPermission() {
        isRequestingPermission = true
        
        Task {
            do {
                try await healthService.requestAuthorization()
                await checkHealthPermissionStatus()
            } catch {
                await MainActor.run {
                    self.showError("Failed to request health permissions: \(error.localizedDescription)")
                }
            }
            
            await MainActor.run {
                self.isRequestingPermission = false
            }
        }
    }
    
    func selectClass(_ heroClass: HeroClass) {
        selectedClass = heroClass
    }
    
    func updatePlayerName(_ name: String) {
        playerName = name
    }
    
    private func checkHealthPermissionStatus() {
        Task {
            let status = await healthService.checkAuthorizationStatus()
            await MainActor.run {
                self.healthPermissionStatus = status
            }
        }
    }
    
    private func completeOnboarding() {
        guard let selectedClass = selectedClass else { return }
        
        let player = Player(
            name: playerName.trimmingCharacters(in: .whitespacesAndNewlines),
            activeClass: selectedClass
        )
        
        gameViewModel.startGame(with: player)
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        showingError = true
    }
    
    func dismissError() {
        showingError = false
        errorMessage = ""
    }
    
    func updateGameViewModel(_ newGameViewModel: GameViewModel) {
        print("🎮 OnboardingViewModel: Updating gameViewModel")
        gameViewModel = newGameViewModel
    }
}