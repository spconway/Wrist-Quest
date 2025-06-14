import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var gameViewModel: GameViewModel
    @EnvironmentObject private var navigationCoordinator: NavigationCoordinator
    @State private var onboardingViewModel: OnboardingViewModel?
    
    var body: some View {
        ZStack {
            WQDesignSystem.Colors.primaryBackground
                .ignoresSafeArea(.all)
            
            if let onboardingViewModel = onboardingViewModel {
                TabView(selection: .constant(onboardingViewModel.currentStep)) {
                    ForEach(OnboardingViewModel.OnboardingStep.allCases, id: \.self) { step in
                        onboardingStepView(for: step)
                            .tag(step)
                            .environmentObject(onboardingViewModel)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(WQDesignSystem.Animation.medium, value: onboardingViewModel.currentStep)
                .alert("Error", isPresented: .constant(onboardingViewModel.showingError)) {
                    Button("OK") {
                        onboardingViewModel.dismissError()
                    }
                } message: {
                    Text(onboardingViewModel.errorMessage)
                }
            } else {
                WQLoadingView("Setting up...")
            }
        }
        .onAppear {
            if onboardingViewModel == nil {
                onboardingViewModel = OnboardingViewModel(gameViewModel: gameViewModel)
            }
        }
        .onReceive(gameViewModel.$gameState) { gameState in
            if case .mainMenu = gameState {
                navigationCoordinator.dismissFullScreenCover()
            }
        }
    }
    
    @ViewBuilder
    private func onboardingStepView(for step: OnboardingViewModel.OnboardingStep) -> some View {
        switch step {
        case .welcome:
            WelcomeStepView()
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
}

struct WelcomeStepView: View {
    @EnvironmentObject private var onboardingViewModel: OnboardingViewModel
    
    var body: some View {
        VStack(spacing: WQDesignSystem.Spacing.lg) {
            Spacer()
            
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
            
            Spacer()
            
            VStack(spacing: WQDesignSystem.Spacing.sm) {
                FeatureRow(icon: "figure.walk", title: "Steps become travel", description: "Every step moves you forward on quests")
                FeatureRow(icon: "heart.fill", title: "Heart rate triggers combat", description: "High activity unlocks battle encounters")
                FeatureRow(icon: "trophy.fill", title: "Real rewards", description: "Earn XP, gold, and loot for activity")
            }
            
            Spacer()
            
            WQButton("Get Started", icon: "arrow.right") {
                onboardingViewModel.nextStep()
            }
            .padding(.horizontal, WQDesignSystem.Spacing.md)
        }
        .padding(WQDesignSystem.Spacing.lg)
    }
}

struct HealthPermissionStepView: View {
    @EnvironmentObject private var onboardingViewModel: OnboardingViewModel
    
    var body: some View {
        VStack(spacing: WQDesignSystem.Spacing.lg) {
            VStack(spacing: WQDesignSystem.Spacing.md) {
                Image(systemName: "heart.text.square")
                    .font(.largeTitle)
                    .foregroundColor(WQDesignSystem.Colors.success)
                
                Text("Health Integration")
                    .font(WQDesignSystem.Typography.title)
                    .foregroundColor(WQDesignSystem.Colors.primaryText)
                
                Text("Wrist Quest uses your health data to power your adventure")
                    .font(WQDesignSystem.Typography.body)
                    .foregroundColor(WQDesignSystem.Colors.secondaryText)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: WQDesignSystem.Spacing.md) {
                HealthDataRow(type: "Steps", icon: "figure.walk", purpose: "Travel distance on quests")
                HealthDataRow(type: "Heart Rate", icon: "heart.fill", purpose: "Trigger combat encounters")
                HealthDataRow(type: "Stand Hours", icon: "figure.stand", purpose: "Bonus XP multipliers")
                HealthDataRow(type: "Exercise", icon: "flame.fill", purpose: "Crafting materials")
            }
            
            Spacer()
            
            VStack(spacing: WQDesignSystem.Spacing.sm) {
                if onboardingViewModel.healthPermissionStatus == .authorized {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(WQDesignSystem.Colors.success)
                        Text("Health access granted")
                            .font(WQDesignSystem.Typography.body)
                            .foregroundColor(WQDesignSystem.Colors.success)
                    }
                    
                    WQButton("Continue", icon: "arrow.right") {
                        onboardingViewModel.nextStep()
                    }
                } else {
                    WQButton("Grant Health Access", icon: "heart.fill") {
                        onboardingViewModel.requestHealthPermission()
                    }
                    .disabled(onboardingViewModel.isRequestingPermission)
                    
                    if onboardingViewModel.isRequestingPermission {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Requesting permissions...")
                                .font(WQDesignSystem.Typography.caption)
                                .foregroundColor(WQDesignSystem.Colors.secondaryText)
                        }
                    }
                }
                
                WQButton("Back", style: .tertiary) {
                    onboardingViewModel.previousStep()
                }
            }
            .padding(.horizontal, WQDesignSystem.Spacing.md)
        }
        .padding(WQDesignSystem.Spacing.lg)
    }
}

struct CharacterCreationStepView: View {
    @EnvironmentObject private var onboardingViewModel: OnboardingViewModel
    @State private var playerName = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: WQDesignSystem.Spacing.lg) {
                VStack(spacing: WQDesignSystem.Spacing.md) {
                    Text("Choose Your Hero")
                        .font(WQDesignSystem.Typography.title)
                        .foregroundColor(WQDesignSystem.Colors.primaryText)
                    
                    Text("Select your character class and abilities")
                        .font(WQDesignSystem.Typography.body)
                        .foregroundColor(WQDesignSystem.Colors.secondaryText)
                        .multilineTextAlignment(.center)
                }
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: WQDesignSystem.Spacing.sm) {
                    ForEach(HeroClass.allCases, id: \.self) { heroClass in
                        WQHeroClassCard(
                            heroClass: heroClass,
                            isSelected: onboardingViewModel.selectedClass == heroClass
                        ) {
                            onboardingViewModel.selectClass(heroClass)
                        }
                    }
                }
                
                if let selectedClass = onboardingViewModel.selectedClass {
                    VStack(spacing: WQDesignSystem.Spacing.sm) {
                        Text("Hero Name")
                            .font(WQDesignSystem.Typography.headline)
                            .foregroundColor(WQDesignSystem.Colors.primaryText)
                        
                        TextField("Enter your name", text: $playerName)
                            .onChange(of: playerName) { newValue in
                                onboardingViewModel.updatePlayerName(newValue)
                            }
                    }
                    
                    WQCard {
                        VStack(alignment: .leading, spacing: WQDesignSystem.Spacing.xs) {
                            Text("\(selectedClass.displayName) Abilities")
                                .font(WQDesignSystem.Typography.headline)
                                .foregroundColor(WQDesignSystem.Colors.primaryText)
                            
                            Text("Passive: \(selectedClass.passivePerk)")
                                .font(WQDesignSystem.Typography.caption)
                                .foregroundColor(WQDesignSystem.Colors.secondaryText)
                            
                            Text("Active: \(selectedClass.activeAbility)")
                                .font(WQDesignSystem.Typography.caption)
                                .foregroundColor(WQDesignSystem.Colors.secondaryText)
                            
                            Text("Trait: \(selectedClass.specialTrait)")
                                .font(WQDesignSystem.Typography.caption)
                                .foregroundColor(WQDesignSystem.Colors.secondaryText)
                        }
                    }
                }
                
                Spacer(minLength: WQDesignSystem.Spacing.lg)
                
                VStack(spacing: WQDesignSystem.Spacing.sm) {
                    WQButton("Continue", icon: "arrow.right") {
                        onboardingViewModel.nextStep()
                    }
                    .disabled(!onboardingViewModel.canProceed)
                    
                    WQButton("Back", style: .tertiary) {
                        onboardingViewModel.previousStep()
                    }
                }
                .padding(.horizontal, WQDesignSystem.Spacing.md)
            }
            .padding(WQDesignSystem.Spacing.lg)
        }
    }
}

struct TutorialQuestStepView: View {
    @EnvironmentObject private var onboardingViewModel: OnboardingViewModel
    @State private var tutorialProgress: Double = 0
    @State private var showingEncounter = false
    
    var body: some View {
        VStack(spacing: WQDesignSystem.Spacing.lg) {
            VStack(spacing: WQDesignSystem.Spacing.md) {
                Text("Your First Quest")
                    .font(WQDesignSystem.Typography.title)
                    .foregroundColor(WQDesignSystem.Colors.primaryText)
                
                Text("Learn the basics with a practice adventure")
                    .font(WQDesignSystem.Typography.body)
                    .foregroundColor(WQDesignSystem.Colors.secondaryText)
                    .multilineTextAlignment(.center)
            }
            
            WQCard {
                VStack(spacing: WQDesignSystem.Spacing.md) {
                    Text("Tutorial: Village Outskirts")
                        .font(WQDesignSystem.Typography.headline)
                        .foregroundColor(WQDesignSystem.Colors.primaryText)
                    
                    HStack {
                        Image(systemName: onboardingViewModel.selectedClass?.iconName ?? "person.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 30, height: 30)
                            .background(
                                LinearGradient(
                                    colors: onboardingViewModel.selectedClass?.gradientColors ?? [.blue, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .cornerRadius(WQDesignSystem.CornerRadius.sm)
                        
                        VStack(alignment: .leading, spacing: WQDesignSystem.Spacing.xs) {
                            Text("Progress: \(Int(tutorialProgress * 100))%")
                                .font(WQDesignSystem.Typography.caption)
                                .foregroundColor(WQDesignSystem.Colors.secondaryText)
                            
                            WQProgressBar(progress: tutorialProgress, height: 6)
                        }
                    }
                    
                    if tutorialProgress < 1.0 {
                        Text("Walk around or shake your watch to simulate steps!")
                            .font(WQDesignSystem.Typography.caption)
                            .foregroundColor(WQDesignSystem.Colors.secondaryText)
                            .multilineTextAlignment(.center)
                    } else {
                        Text("Quest Complete! +50 XP, +10 Gold")
                            .font(WQDesignSystem.Typography.caption)
                            .foregroundColor(WQDesignSystem.Colors.success)
                            .multilineTextAlignment(.center)
                    }
                }
            }
            
            if tutorialProgress >= 0.5 && !showingEncounter {
                WQCard {
                    VStack(spacing: WQDesignSystem.Spacing.sm) {
                        Text("Encounter Discovered!")
                            .font(WQDesignSystem.Typography.headline)
                            .foregroundColor(WQDesignSystem.Colors.primaryText)
                        
                        Text("You found a mysterious path in the forest...")
                            .font(WQDesignSystem.Typography.caption)
                            .foregroundColor(WQDesignSystem.Colors.secondaryText)
                            .multilineTextAlignment(.center)
                        
                        WQButton("Investigate", icon: "magnifyingglass") {
                            showingEncounter = true
                        }
                    }
                }
            }
            
            Spacer()
            
            VStack(spacing: WQDesignSystem.Spacing.sm) {
                WQButton("Continue", icon: "arrow.right") {
                    onboardingViewModel.nextStep()
                }
                .disabled(tutorialProgress < 1.0)
                
                WQButton("Skip Tutorial", style: .tertiary) {
                    onboardingViewModel.nextStep()
                }
            }
            .padding(.horizontal, WQDesignSystem.Spacing.md)
        }
        .padding(WQDesignSystem.Spacing.lg)
        .onAppear {
            startTutorialProgress()
        }
        .sheet(isPresented: $showingEncounter) {
            TutorialEncounterView()
        }
    }
    
    private func startTutorialProgress() {
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { timer in
            if tutorialProgress < 1.0 {
                tutorialProgress += 0.1
            } else {
                timer.invalidate()
            }
        }
    }
}

struct CompletionStepView: View {
    @EnvironmentObject private var onboardingViewModel: OnboardingViewModel
    
    var body: some View {
        VStack(spacing: WQDesignSystem.Spacing.lg) {
            Spacer()
            
            VStack(spacing: WQDesignSystem.Spacing.md) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.largeTitle)
                    .foregroundColor(WQDesignSystem.Colors.success)
                    .scaleEffect(1.5)
                
                Text("Ready to Adventure!")
                    .font(WQDesignSystem.Typography.title)
                    .foregroundColor(WQDesignSystem.Colors.primaryText)
                
                Text("Your hero is ready to begin their journey")
                    .font(WQDesignSystem.Typography.body)
                    .foregroundColor(WQDesignSystem.Colors.secondaryText)
                    .multilineTextAlignment(.center)
            }
            
            if let selectedClass = onboardingViewModel.selectedClass {
                WQCard {
                    VStack(spacing: WQDesignSystem.Spacing.sm) {
                        HStack {
                            Image(systemName: selectedClass.iconName)
                                .font(.title)
                                .foregroundColor(.white)
                                .frame(width: 40, height: 40)
                                .background(
                                    LinearGradient(
                                        colors: selectedClass.gradientColors,
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .cornerRadius(WQDesignSystem.CornerRadius.md)
                            
                            VStack(alignment: .leading, spacing: WQDesignSystem.Spacing.xs) {
                                Text(onboardingViewModel.playerName.isEmpty ? "Hero" : onboardingViewModel.playerName)
                                    .font(WQDesignSystem.Typography.headline)
                                    .foregroundColor(WQDesignSystem.Colors.primaryText)
                                
                                Text(selectedClass.displayName)
                                    .font(WQDesignSystem.Typography.caption)
                                    .foregroundColor(WQDesignSystem.Colors.secondaryText)
                            }
                            
                            Spacer()
                        }
                        
                        Text("Level 1 • 0 XP • 0 Gold")
                            .font(WQDesignSystem.Typography.caption)
                            .foregroundColor(WQDesignSystem.Colors.secondaryText)
                    }
                }
            }
            
            Spacer()
            
            WQButton("Start Adventure", icon: "play.fill") {
                onboardingViewModel.nextStep()
            }
            .padding(.horizontal, WQDesignSystem.Spacing.md)
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

struct HealthDataRow: View {
    let type: String
    let icon: String
    let purpose: String
    
    var body: some View {
        HStack(spacing: WQDesignSystem.Spacing.sm) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(WQDesignSystem.Colors.accent)
                .frame(width: 20, height: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(type)
                    .font(WQDesignSystem.Typography.caption.weight(.medium))
                    .foregroundColor(WQDesignSystem.Colors.primaryText)
                
                Text(purpose)
                    .font(WQDesignSystem.Typography.footnote)
                    .foregroundColor(WQDesignSystem.Colors.secondaryText)
            }
            
            Spacer()
        }
    }
}

struct TutorialEncounterView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedOption: Int? = nil
    @State private var showResult = false
    
    var body: some View {
        VStack(spacing: WQDesignSystem.Spacing.lg) {
            Text("Tutorial Encounter")
                .font(WQDesignSystem.Typography.title)
                .foregroundColor(WQDesignSystem.Colors.primaryText)
            
            Text("You find a fork in the road. A merchant sits by a campfire, looking worried.")
                .font(WQDesignSystem.Typography.body)
                .foregroundColor(WQDesignSystem.Colors.secondaryText)
                .multilineTextAlignment(.center)
            
            if !showResult {
                VStack(spacing: WQDesignSystem.Spacing.sm) {
                    WQButton("Approach the merchant", style: .secondary) {
                        selectedOption = 0
                        showResult = true
                    }
                    
                    WQButton("Take the other path", style: .secondary) {
                        selectedOption = 1
                        showResult = true
                    }
                }
            } else {
                WQCard {
                    VStack(spacing: WQDesignSystem.Spacing.sm) {
                        Text("Success!")
                            .font(WQDesignSystem.Typography.headline)
                            .foregroundColor(WQDesignSystem.Colors.success)
                        
                        Text(selectedOption == 0 ? 
                             "The merchant gives you a healing potion! +1 Health Potion" :
                             "You find a hidden chest! +15 Gold")
                            .font(WQDesignSystem.Typography.caption)
                            .foregroundColor(WQDesignSystem.Colors.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                }
                
                WQButton("Continue", icon: "arrow.right") {
                    dismiss()
                }
            }
        }
        .padding(WQDesignSystem.Spacing.lg)
    }
}