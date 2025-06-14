import SwiftUI

struct MainMenuView: View {
    @EnvironmentObject private var gameViewModel: GameViewModel
    @EnvironmentObject private var playerViewModel: PlayerViewModel
    @EnvironmentObject private var healthViewModel: HealthViewModel
    @EnvironmentObject private var navigationCoordinator: NavigationCoordinator
    
    var body: some View {
        ScrollView {
            VStack(spacing: WQDesignSystem.Spacing.md) {
                if let player = gameViewModel.currentPlayer {
                    PlayerHeaderView(player: player)
                    
                    ActivitySummaryView()
                    
                    QuickActionsView()
                    
                    if let activeQuest = questViewModel?.activeQuest {
                        ActiveQuestCardView(quest: activeQuest)
                    } else {
                        QuestPromptView()
                    }
                } else {
                    WQLoadingView("Loading your adventure...")
                }
            }
            .padding(WQDesignSystem.Spacing.md)
        }
        .navigationTitle("Wrist Quest")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var questViewModel: QuestViewModel? {
        guard let player = gameViewModel.currentPlayer else { return nil }
        return QuestViewModel(playerViewModel: PlayerViewModel(player: player))
    }
}

struct PlayerHeaderView: View {
    let player: Player
    @EnvironmentObject private var healthViewModel: HealthViewModel
    
    var body: some View {
        WQCard {
            VStack(spacing: WQDesignSystem.Spacing.sm) {
                HStack {
                    Image(systemName: player.activeClass.iconName)
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(
                            LinearGradient(
                                colors: player.activeClass.gradientColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(WQDesignSystem.CornerRadius.md)
                    
                    VStack(alignment: .leading, spacing: WQDesignSystem.Spacing.xs) {
                        Text(player.name)
                            .font(WQDesignSystem.Typography.headline)
                            .foregroundColor(WQDesignSystem.Colors.primaryText)
                        
                        Text("Level \(player.level) \(player.activeClass.displayName)")
                            .font(WQDesignSystem.Typography.caption)
                            .foregroundColor(WQDesignSystem.Colors.secondaryText)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: WQDesignSystem.Spacing.xs) {
                        HStack(spacing: WQDesignSystem.Spacing.xs) {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                                .font(.caption)
                            Text("\(player.xp)")
                                .font(WQDesignSystem.Typography.caption)
                                .foregroundColor(WQDesignSystem.Colors.primaryText)
                        }
                        
                        HStack(spacing: WQDesignSystem.Spacing.xs) {
                            Image(systemName: "dollarsign.circle.fill")
                                .foregroundColor(.yellow)
                                .font(.caption)
                            Text("\(player.gold)")
                                .font(WQDesignSystem.Typography.caption)
                                .foregroundColor(WQDesignSystem.Colors.primaryText)
                        }
                    }
                }
                
                // XP Progress Bar
                VStack(alignment: .leading, spacing: WQDesignSystem.Spacing.xs) {
                    HStack {
                        Text("XP Progress")
                            .font(WQDesignSystem.Typography.caption)
                            .foregroundColor(WQDesignSystem.Colors.secondaryText)
                        
                        Spacer()
                        
                        Text("\(player.xp) / \(xpForNextLevel(player.level + 1))")
                            .font(WQDesignSystem.Typography.caption)
                            .foregroundColor(WQDesignSystem.Colors.secondaryText)
                    }
                    
                    WQProgressBar(
                        progress: xpProgress(for: player),
                        color: player.activeClass.gradientColors.first ?? WQDesignSystem.Colors.accent,
                        height: 6
                    )
                }
            }
        }
    }
    
    private func xpForNextLevel(_ level: Int) -> Int {
        if level <= 1 { return 0 }
        return Int(pow(Double(level - 1), 1.5) * 100)
    }
    
    private func xpProgress(for player: Player) -> Double {
        let currentLevelXP = xpForNextLevel(player.level)
        let nextLevelXP = xpForNextLevel(player.level + 1)
        let progressXP = player.xp - currentLevelXP
        let requiredXP = nextLevelXP - currentLevelXP
        
        guard requiredXP > 0 else { return 1.0 }
        return Double(progressXP) / Double(requiredXP)
    }
}

struct ActivitySummaryView: View {
    @EnvironmentObject private var healthViewModel: HealthViewModel
    
    var body: some View {
        WQCard {
            VStack(spacing: WQDesignSystem.Spacing.md) {
                HStack {
                    Text("Today's Activity")
                        .font(WQDesignSystem.Typography.headline)
                        .foregroundColor(WQDesignSystem.Colors.primaryText)
                    
                    Spacer()
                    
                    Text("Score: \(healthViewModel.dailyActivityScore)")
                        .font(WQDesignSystem.Typography.caption)
                        .foregroundColor(WQDesignSystem.Colors.accent)
                        .padding(.horizontal, WQDesignSystem.Spacing.sm)
                        .padding(.vertical, WQDesignSystem.Spacing.xs)
                        .background(WQDesignSystem.Colors.accent.opacity(0.1))
                        .cornerRadius(WQDesignSystem.CornerRadius.sm)
                }
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: WQDesignSystem.Spacing.sm) {
                    ActivityStatView(
                        icon: "figure.walk",
                        title: "Steps",
                        value: "\(healthViewModel.currentHealthData.steps)",
                        color: WQDesignSystem.Colors.questBlue
                    )
                    
                    ActivityStatView(
                        icon: "heart.fill",
                        title: "Heart Rate",
                        value: "\(Int(healthViewModel.currentHealthData.heartRate)) BPM",
                        color: WQDesignSystem.Colors.questRed
                    )
                    
                    ActivityStatView(
                        icon: "figure.stand",
                        title: "Stand Hours",
                        value: "\(healthViewModel.currentHealthData.standingHours)",
                        color: WQDesignSystem.Colors.questGreen
                    )
                    
                    ActivityStatView(
                        icon: "flame.fill",
                        title: "Exercise",
                        value: "\(healthViewModel.currentHealthData.exerciseMinutes) min",
                        color: WQDesignSystem.Colors.questOrange
                    )
                }
                
                if healthViewModel.isInCombatMode {
                    HStack {
                        Image(systemName: "bolt.fill")
                            .foregroundColor(WQDesignSystem.Colors.questRed)
                            .font(.caption)
                        
                        Text("Combat Mode Active!")
                            .font(WQDesignSystem.Typography.caption)
                            .foregroundColor(WQDesignSystem.Colors.questRed)
                    }
                    .padding(.horizontal, WQDesignSystem.Spacing.sm)
                    .padding(.vertical, WQDesignSystem.Spacing.xs)
                    .background(WQDesignSystem.Colors.questRed.opacity(0.1))
                    .cornerRadius(WQDesignSystem.CornerRadius.sm)
                }
            }
        }
    }
}

struct ActivityStatView: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: WQDesignSystem.Spacing.xs) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(value)
                .font(WQDesignSystem.Typography.headline)
                .foregroundColor(WQDesignSystem.Colors.primaryText)
            
            Text(title)
                .font(WQDesignSystem.Typography.caption)
                .foregroundColor(WQDesignSystem.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(WQDesignSystem.Spacing.sm)
        .background(color.opacity(0.1))
        .cornerRadius(WQDesignSystem.CornerRadius.md)
    }
}

struct QuickActionsView: View {
    @EnvironmentObject private var navigationCoordinator: NavigationCoordinator
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: WQDesignSystem.Spacing.sm) {
            QuickActionButton(
                icon: "map.fill",
                title: "Quests",
                color: WQDesignSystem.Colors.questBlue
            ) {
                // Navigate to quest list
            }
            
            QuickActionButton(
                icon: "person.fill",
                title: "Character",
                color: WQDesignSystem.Colors.questPurple
            ) {
                navigationCoordinator.navigate(to: .characterDetail)
            }
            
            QuickActionButton(
                icon: "bag.fill",
                title: "Inventory",
                color: WQDesignSystem.Colors.questGreen
            ) {
                navigationCoordinator.navigate(to: .inventory)
            }
            
            QuickActionButton(
                icon: "book.fill",
                title: "Journal",
                color: WQDesignSystem.Colors.questOrange
            ) {
                navigationCoordinator.navigate(to: .journal)
            }
        }
    }
}

struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: WQDesignSystem.Spacing.sm) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(color)
                    .cornerRadius(WQDesignSystem.CornerRadius.md)
                
                Text(title)
                    .font(WQDesignSystem.Typography.caption)
                    .foregroundColor(WQDesignSystem.Colors.primaryText)
            }
            .frame(maxWidth: .infinity)
            .padding(WQDesignSystem.Spacing.md)
            .background(WQDesignSystem.Colors.secondaryBackground)
            .cornerRadius(WQDesignSystem.CornerRadius.lg)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct ActiveQuestCardView: View {
    let quest: Quest
    
    var body: some View {
        WQCard {
            VStack(alignment: .leading, spacing: WQDesignSystem.Spacing.sm) {
                HStack {
                    Text("Active Quest")
                        .font(WQDesignSystem.Typography.caption)
                        .foregroundColor(WQDesignSystem.Colors.secondaryText)
                    
                    Spacer()
                    
                    Text("\(Int(quest.progressPercentage * 100))%")
                        .font(WQDesignSystem.Typography.caption)
                        .foregroundColor(WQDesignSystem.Colors.accent)
                }
                
                Text(quest.title)
                    .font(WQDesignSystem.Typography.headline)
                    .foregroundColor(WQDesignSystem.Colors.primaryText)
                
                Text(quest.description)
                    .font(WQDesignSystem.Typography.caption)
                    .foregroundColor(WQDesignSystem.Colors.secondaryText)
                    .lineLimit(2)
                
                WQProgressBar(
                    progress: quest.progressPercentage,
                    color: WQDesignSystem.Colors.accent,
                    height: 8
                )
                
                HStack {
                    Text("Distance: \(quest.currentProgress.formatted(decimalPlaces: 1)) / \(quest.totalDistance.formatted(decimalPlaces: 1)) miles")
                        .font(WQDesignSystem.Typography.footnote)
                        .foregroundColor(WQDesignSystem.Colors.secondaryText)
                    
                    Spacer()
                    
                    if quest.isCompleted {
                        Text("Complete!")
                            .font(WQDesignSystem.Typography.caption)
                            .foregroundColor(WQDesignSystem.Colors.success)
                    }
                }
            }
        }
    }
}

struct QuestPromptView: View {
    var body: some View {
        WQCard {
            VStack(spacing: WQDesignSystem.Spacing.md) {
                Image(systemName: "map")
                    .font(.largeTitle)
                    .foregroundColor(WQDesignSystem.Colors.accent)
                
                Text("Ready for Adventure?")
                    .font(WQDesignSystem.Typography.headline)
                    .foregroundColor(WQDesignSystem.Colors.primaryText)
                
                Text("Start a quest to begin earning XP and rewards for your activity")
                    .font(WQDesignSystem.Typography.caption)
                    .foregroundColor(WQDesignSystem.Colors.secondaryText)
                    .multilineTextAlignment(.center)
                
                WQButton("Browse Quests", icon: "arrow.right") {
                    // Navigate to quest list
                }
            }
        }
    }
}