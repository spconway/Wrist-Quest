import SwiftUI

enum OnboardingStep: String, CaseIterable {
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

struct OnboardingView: View {
    @EnvironmentObject private var gameViewModel: GameViewModel
    @EnvironmentObject private var navigationCoordinator: NavigationCoordinator
    @State private var currentStep: OnboardingStep = .welcome
    @State private var selectedClass: HeroClass?
    @State private var playerName = ""
    @State private var healthPermissionStatus: HealthAuthorizationStatus = .notDetermined
    @State private var isRequestingPermission = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    private let healthService: HealthServiceProtocol = HealthService()
    
    var body: some View {
        ZStack {
            WQDesignSystem.Colors.primaryBackground
                .ignoresSafeArea(.all)
            
            TabView(selection: .constant(currentStep)) {
                ForEach(OnboardingStep.allCases, id: \.self) { step in
                    onboardingStepView(for: step)
                        .tag(step)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(WQDesignSystem.Animation.medium, value: currentStep)
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") {
                dismissError()
            }
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            print("🎮 OnboardingView: onAppear called")
            print("🎮 OnboardingView: Current step: \(currentStep.rawValue)")
            checkHealthPermissionStatus()
        }
        .onChange(of: currentStep) { newValue in
            print("🎮 OnboardingView: currentStep changed to \(newValue.rawValue)")
        }
        .onReceive(gameViewModel.$gameState) { gameState in
            if case .mainMenu = gameState {
                navigationCoordinator.dismissFullScreenCover()
            }
        }
    }
    
    @ViewBuilder
    private func onboardingStepView(for step: OnboardingStep) -> some View {
        switch step {
        case .welcome:
            WelcomeStepView(onNext: nextStep)
        case .healthPermission:
            HealthPermissionStepView()
        case .characterCreation:
            CharacterCreationStepView()
        case .tutorialQuest:
            TutorialQuestStepView()
        case .complete:
            CompletionStepView()
        }
    }
    
    // MARK: - Helper Methods
    
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
    
    func nextStep() {
        print("🎮 OnboardingView: nextStep() called")
        print("🎮 OnboardingView: currentStep = \(currentStep)")
        print("🎮 OnboardingView: canProceed = \(canProceed)")
        
        guard canProceed else { 
            print("🎮 OnboardingView: Cannot proceed, returning early")
            return 
        }
        
        let oldStep = currentStep
        
        switch currentStep {
        case .welcome:
            print("🎮 OnboardingView: Moving from welcome to healthPermission")
            currentStep = .healthPermission
        case .healthPermission:
            print("🎮 OnboardingView: Moving from healthPermission to characterCreation")
            currentStep = .characterCreation
        case .characterCreation:
            print("🎮 OnboardingView: Moving from characterCreation to tutorialQuest")
            currentStep = .tutorialQuest
        case .tutorialQuest:
            print("🎮 OnboardingView: Moving from tutorialQuest to complete")
            currentStep = .complete
        case .complete:
            print("🎮 OnboardingView: Completing onboarding")
            completeOnboarding()
        }
        
        print("🎮 OnboardingView: Step changed from \(oldStep) to \(currentStep)")
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
}

struct WelcomeStepView: View {
    let onNext: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: WQDesignSystem.Spacing.lg) {
                VStack(spacing: WQDesignSystem.Spacing.md) {
                    Image(systemName: "applewatch")
                        .font(.largeTitle)
                        .foregroundColor(WQDesignSystem.Colors.accent)
                        .scaleEffect(1.5)
                    
                    Text("Wrist Quest")
                        .font(WQDesignSystem.Typography.largeTitle)
                        .foregroundColor(WQDesignSystem.Colors.primaryText)
                    
                    Text("Turn your daily activity into epic adventures")
                        .font(WQDesignSystem.Typography.body)
                        .foregroundColor(WQDesignSystem.Colors.secondaryText)
                        .multilineTextAlignment(.center)
                }
                
                VStack(spacing: WQDesignSystem.Spacing.sm) {
                    FeatureRow(icon: "figure.walk", title: "Steps become travel", description: "Every step moves you forward on quests")
                    FeatureRow(icon: "heart.fill", title: "Heart rate triggers combat", description: "High activity unlocks battle encounters")
                    FeatureRow(icon: "trophy.fill", title: "Real rewards", description: "Earn XP, gold, and loot for activity")
                }
                
                Spacer(minLength: WQDesignSystem.Spacing.lg)
                
                WQButton("Get Started", icon: "arrow.right") {
                    print("🎮 WelcomeStepView: Button tapped!")
                    onNext()
                }
                .padding(.horizontal, WQDesignSystem.Spacing.md)
            }
            .padding(WQDesignSystem.Spacing.lg)
        }
    }
}

struct HealthPermissionStepView: View {
    var body: some View {
        Text("Health Permission Step")
    }
}

struct CharacterCreationStepView: View {
    var body: some View {
        Text("Character Creation Step")
    }
}

struct TutorialQuestStepView: View {
    var body: some View {
        Text("Tutorial Quest Step")
    }
}

struct CompletionStepView: View {
    var body: some View {
        Text("Completion Step")
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: WQDesignSystem.Spacing.sm) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(WQDesignSystem.Colors.accent)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: WQDesignSystem.Spacing.xs) {
                Text(title)
                    .font(WQDesignSystem.Typography.caption.weight(.medium))
                    .foregroundColor(WQDesignSystem.Colors.primaryText)
                
                Text(description)
                    .font(WQDesignSystem.Typography.footnote)
                    .foregroundColor(WQDesignSystem.Colors.secondaryText)
            }
            
            Spacer()
        }
    }
}
