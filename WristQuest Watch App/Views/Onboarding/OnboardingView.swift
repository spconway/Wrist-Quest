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
            checkHealthPermissionStatus()
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
            HealthPermissionStepView(
                status: healthPermissionStatus,
                isRequesting: isRequestingPermission,
                onRequest: requestHealthPermission,
                onNext: nextStep
            )
        case .characterCreation:
            CharacterCreationStepView(
                selectedClass: $selectedClass,
                playerName: $playerName,
                onNext: nextStep
            )
        case .tutorialQuest:
            TutorialQuestStepView(onNext: nextStep)
        case .complete:
            CompletionStepView(onComplete: completeOnboarding)
        }
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
    
    func nextStep() {
        guard canProceed else { return }
        
        switch currentStep {
        case .welcome:
            currentStep = .healthPermission
        case .healthPermission:
            currentStep = .characterCreation
        case .characterCreation:
            currentStep = .tutorialQuest
        case .tutorialQuest:
            currentStep = .complete
        case .complete:
            completeOnboarding()
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

// MARK: - Individual Step Views

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
                    onNext()
                }
                .padding(.horizontal, WQDesignSystem.Spacing.md)
            }
            .padding(WQDesignSystem.Spacing.lg)
        }
    }
}

struct HealthPermissionStepView: View {
    let status: HealthAuthorizationStatus
    let isRequesting: Bool
    let onRequest: () -> Void
    let onNext: () -> Void
    
    var body: some View {
        VStack(spacing: WQDesignSystem.Spacing.lg) {
            Text("Health Permission")
                .font(WQDesignSystem.Typography.title)
                .foregroundColor(WQDesignSystem.Colors.primaryText)
            
            Text("To power your quests with real activity, Wrist Quest needs access to your health data.")
                .font(WQDesignSystem.Typography.body)
                .foregroundColor(WQDesignSystem.Colors.secondaryText)
                .multilineTextAlignment(.center)
            
            if status == .authorized {
                VStack {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.largeTitle)
                        .foregroundColor(.green)
                    Text("Health access granted!")
                        .foregroundColor(.green)
                }
                
                WQButton("Continue", icon: "arrow.right") {
                    onNext()
                }
            } else {
                WQButton(isRequesting ? "Requesting..." : "Grant Health Access", icon: "heart.fill") {
                    onRequest()
                }
                .disabled(isRequesting)
            }
        }
        .padding(WQDesignSystem.Spacing.lg)
    }
}

struct CharacterCreationStepView: View {
    @Binding var selectedClass: HeroClass?
    @Binding var playerName: String
    let onNext: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: WQDesignSystem.Spacing.lg) {
                Text("Choose Your Hero")
                    .font(WQDesignSystem.Typography.title)
                    .foregroundColor(WQDesignSystem.Colors.primaryText)
                
                TextField("Hero Name", text: $playerName)
                
                Text("Select your class:")
                    .font(WQDesignSystem.Typography.headline)
                    .foregroundColor(WQDesignSystem.Colors.primaryText)
                
                LazyVGrid(columns: [GridItem(.flexible())], spacing: WQDesignSystem.Spacing.sm) {
                    ForEach(HeroClass.allCases, id: \.self) { heroClass in
                        ClassSelectionCard(
                            heroClass: heroClass,
                            isSelected: selectedClass == heroClass
                        ) {
                            selectedClass = heroClass
                        }
                    }
                }
                
                if selectedClass != nil && !playerName.isEmpty {
                    WQButton("Continue", icon: "arrow.right") {
                        onNext()
                    }
                }
            }
            .padding(WQDesignSystem.Spacing.md)
        }
    }
}

struct ClassSelectionCard: View {
    let heroClass: HeroClass
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        WQCard {
            VStack(spacing: WQDesignSystem.Spacing.sm) {
                HStack {
                    Image(systemName: heroClass.iconName)
                        .font(.title2)
                        .foregroundColor(heroClass.color)
                    
                    Text(heroClass.displayName)
                        .font(WQDesignSystem.Typography.headline)
                        .foregroundColor(WQDesignSystem.Colors.primaryText)
                    
                    Spacer()
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                }
                
                Text(heroClass.shortDescription)
                    .font(WQDesignSystem.Typography.caption)
                    .foregroundColor(WQDesignSystem.Colors.secondaryText)
                    .multilineTextAlignment(.leading)
            }
        }
        .onTapGesture {
            onTap()
        }
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? .green : Color.clear, lineWidth: 2)
        )
    }
}

struct TutorialQuestStepView: View {
    let onNext: () -> Void
    
    var body: some View {
        VStack(spacing: WQDesignSystem.Spacing.lg) {
            Text("Your First Quest")
                .font(WQDesignSystem.Typography.title)
                .foregroundColor(WQDesignSystem.Colors.primaryText)
            
            Text("Time to learn the basics! Your first quest awaits.")
                .font(WQDesignSystem.Typography.body)
                .foregroundColor(WQDesignSystem.Colors.secondaryText)
                .multilineTextAlignment(.center)
            
            WQButton("Start Tutorial Quest", icon: "play.fill") {
                onNext()
            }
        }
        .padding(WQDesignSystem.Spacing.lg)
    }
}

struct CompletionStepView: View {
    let onComplete: () -> Void
    
    var body: some View {
        VStack(spacing: WQDesignSystem.Spacing.lg) {
            Image(systemName: "crown.fill")
                .font(.largeTitle)
                .foregroundColor(WQDesignSystem.Colors.accent)
                .scaleEffect(1.5)
            
            Text("Ready to Adventure!")
                .font(WQDesignSystem.Typography.title)
                .foregroundColor(WQDesignSystem.Colors.primaryText)
            
            Text("Your hero is ready to begin their legendary journey.")
                .font(WQDesignSystem.Typography.body)
                .foregroundColor(WQDesignSystem.Colors.secondaryText)
                .multilineTextAlignment(.center)
            
            WQButton("Begin Adventure", icon: "arrow.right") {
                onComplete()
            }
        }
        .padding(WQDesignSystem.Spacing.lg)
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