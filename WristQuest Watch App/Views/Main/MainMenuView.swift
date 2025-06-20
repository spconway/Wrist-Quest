import SwiftUI

struct MainMenuView: View {
    @EnvironmentObject private var gameViewModel: GameViewModel
    @EnvironmentObject private var playerViewModel: PlayerViewModel
    @EnvironmentObject private var healthViewModel: HealthViewModel
    @EnvironmentObject private var navigationCoordinator: NavigationCoordinator
    @State private var questViewModel: QuestViewModel?
    
    var body: some View {
        ScrollView {
            VStack(spacing: WQDesignSystem.Spacing.md) {
                if let player = gameViewModel.currentPlayer {
                    PlayerHeaderView(player: player)
                    
                    ActivitySummaryView()
                    
                    QuickActionsView()
                    
                    if let questVM = questViewModel, let activeQuest = questVM.activeQuest {
                        ActiveQuestCardView(quest: activeQuest) {
                            navigationCoordinator.navigate(to: .activeQuest)
                        }
                    } else {
                        QuestPromptView()
                    }
                } else {
                    WQLoadingView("Loading your adventure...")
                        .accessibilityLabel("Loading your adventure. Please wait.")
                }
            }
            .padding(WQDesignSystem.Spacing.md)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(AccessibilityConstants.Navigation.mainMenu)
        .navigationTitle("Wrist Quest")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let player = gameViewModel.currentPlayer, questViewModel == nil {
                questViewModel = QuestViewModel(playerViewModel: PlayerViewModel(player: player))
            }
        }
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
                        .accessibilityLabel("Character class: \(player.activeClass.displayName)")
                        .accessibilityHidden(true)
                    
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
                                .accessibilityHidden(true)
                            Text("\(player.xp)")
                                .font(WQDesignSystem.Typography.caption)
                                .foregroundColor(WQDesignSystem.Colors.primaryText)
                        }
                        .wqStatAccessible(
                            statType: .experience,
                            value: "\(player.xp)"
                        )
                        
                        HStack(spacing: WQDesignSystem.Spacing.xs) {
                            Image(systemName: "dollarsign.circle.fill")
                                .foregroundColor(.yellow)
                                .font(.caption)
                                .accessibilityHidden(true)
                            Text("\(player.gold)")
                                .font(WQDesignSystem.Typography.caption)
                                .foregroundColor(WQDesignSystem.Colors.primaryText)
                        }
                        .wqStatAccessible(
                            statType: .gold,
                            value: "\(player.gold)"
                        )
                    }
                }
                .accessibilityElement(children: .contain)
                .accessibilityLabel("Player info: \(player.name), \(AccessibilityConstants.Player.levelDescription(player.level, player.activeClass.displayName))")
                
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
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(AccessibilityConstants.Player.experienceDescription(player.xp, xpForNextLevel(player.level + 1)))
                    
                    WQProgressBar(
                        progress: xpProgress(for: player),
                        color: player.activeClass.gradientColors.first ?? WQDesignSystem.Colors.accent,
                        height: 6
                    )
                    .wqProgressAccessible(
                        type: .experienceProgress,
                        current: Double(player.xp - xpForNextLevel(player.level)),
                        total: Double(xpForNextLevel(player.level + 1) - xpForNextLevel(player.level)),
                        unit: "experience points"
                    )
                }
                .accessibilityElement(children: .contain)
                .accessibilityLabel(AccessibilityConstants.Player.experienceProgressHint)
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
                        .accessibilityAddTraits(.isHeader)
                    
                    Spacer()
                    
                    Text("Score: \(healthViewModel.dailyActivityScore)")
                        .font(WQDesignSystem.Typography.caption)
                        .foregroundColor(WQDesignSystem.Colors.accent)
                        .padding(.horizontal, WQDesignSystem.Spacing.sm)
                        .padding(.vertical, WQDesignSystem.Spacing.xs)
                        .background(WQDesignSystem.Colors.accent.opacity(0.1))
                        .cornerRadius(WQDesignSystem.CornerRadius.sm)
                        .accessibilityLabel("Daily activity score: \(healthViewModel.dailyActivityScore)")
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(AccessibilityConstants.Health.activitySummary)
                
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
                    .wqHealthMetricAccessible(
                        metric: .steps,
                        value: AccessibilityConstants.Health.stepsValue(healthViewModel.currentHealthData.steps)
                    )
                    
                    ActivityStatView(
                        icon: "heart.fill",
                        title: "Heart Rate",
                        value: "\(Int(healthViewModel.currentHealthData.heartRate)) BPM",
                        color: WQDesignSystem.Colors.questRed
                    )
                    .wqHealthMetricAccessible(
                        metric: .heartRate,
                        value: AccessibilityConstants.Health.heartRateValue(Int(healthViewModel.currentHealthData.heartRate)),
                        isActive: healthViewModel.isInCombatMode
                    )
                    
                    ActivityStatView(
                        icon: "figure.stand",
                        title: "Stand Hours",
                        value: "\(healthViewModel.currentHealthData.standingHours)",
                        color: WQDesignSystem.Colors.questGreen
                    )
                    .wqHealthMetricAccessible(
                        metric: .standHours,
                        value: AccessibilityConstants.Health.standHoursValue(healthViewModel.currentHealthData.standingHours)
                    )
                    
                    ActivityStatView(
                        icon: "flame.fill",
                        title: "Exercise",
                        value: "\(healthViewModel.currentHealthData.exerciseMinutes) min",
                        color: WQDesignSystem.Colors.questOrange
                    )
                    .wqHealthMetricAccessible(
                        metric: .exerciseMinutes,
                        value: AccessibilityConstants.Health.exerciseMinutesValue(healthViewModel.currentHealthData.exerciseMinutes)
                    )
                }
                .accessibilityElement(children: .contain)
                .accessibilityLabel("Activity metrics for today")
                
                if healthViewModel.isInCombatMode {
                    HStack {
                        Image(systemName: "bolt.fill")
                            .foregroundColor(WQDesignSystem.Colors.questRed)
                            .font(.caption)
                            .accessibilityHidden(true)
                        
                        Text("Combat Mode Active!")
                            .font(WQDesignSystem.Typography.caption)
                            .foregroundColor(WQDesignSystem.Colors.questRed)
                    }
                    .padding(.horizontal, WQDesignSystem.Spacing.sm)
                    .padding(.vertical, WQDesignSystem.Spacing.xs)
                    .background(WQDesignSystem.Colors.questRed.opacity(0.1))
                    .cornerRadius(WQDesignSystem.CornerRadius.sm)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(AccessibilityConstants.Health.combatModeActive)
                    .accessibilityAddTraits(.startsMediaSession)
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
                navigationCoordinator.navigate(to: .questList)
            }
            .wqNavigationAccessible(
                destination: .questList
            )
            
            QuickActionButton(
                icon: "person.fill",
                title: "Character",
                color: WQDesignSystem.Colors.questPurple
            ) {
                navigationCoordinator.navigate(to: .characterDetail)
            }
            .wqNavigationAccessible(
                destination: .character
            )
            
            QuickActionButton(
                icon: "bag.fill",
                title: "Inventory",
                color: WQDesignSystem.Colors.questGreen
            ) {
                navigationCoordinator.navigate(to: .inventory)
            }
            .wqNavigationAccessible(
                destination: .inventory
            )
            
            QuickActionButton(
                icon: "book.fill",
                title: "Journal",
                color: WQDesignSystem.Colors.questOrange
            ) {
                navigationCoordinator.navigate(to: .journal)
            }
            .wqNavigationAccessible(
                destination: .journal
            )
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Quick navigation actions")
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
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
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
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(WQDesignSystem.Colors.accent)
                            .font(.caption)
                            .accessibilityHidden(true)
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
                    .accessibilityHidden(true)
                    
                    HStack {
                        Text("Distance: \(String(format: "%.1f", quest.currentProgress)) / \(String(format: "%.1f", quest.totalDistance)) miles")
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
        .buttonStyle(PlainButtonStyle())
        .wqQuestAccessible(
            quest: WQQuestAccessibilityInfo(
                title: quest.title,
                description: quest.description,
                isActive: true,
                isCompleted: quest.isCompleted,
                progress: quest.progressPercentage,
                rewardXP: quest.rewardXP,
                rewardGold: quest.rewardGold
            ),
            action: .view
        )
    }
}

struct QuestPromptView: View {
    @EnvironmentObject private var navigationCoordinator: NavigationCoordinator
    
    var body: some View {
        WQCard {
            VStack(spacing: WQDesignSystem.Spacing.md) {
                Image(systemName: "map")
                    .font(.largeTitle)
                    .foregroundColor(WQDesignSystem.Colors.accent)
                    .accessibilityLabel("Map icon")
                    .accessibilityHidden(true)
                
                Text("Ready for Adventure?")
                    .font(WQDesignSystem.Typography.headline)
                    .foregroundColor(WQDesignSystem.Colors.primaryText)
                    .accessibilityAddTraits(.isHeader)
                
                Text("Start a quest to begin earning XP and rewards for your activity")
                    .font(WQDesignSystem.Typography.caption)
                    .foregroundColor(WQDesignSystem.Colors.secondaryText)
                    .multilineTextAlignment(.center)
                
                WQButton("Browse Quests", icon: "arrow.right") {
                    navigationCoordinator.navigate(to: .questList)
                }
                .accessibleActionButton(
                    actionName: AccessibilityConstants.Quests.browseQuestsButton,
                    description: AccessibilityConstants.Quests.browseQuestsHint
                )
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Quest prompt: Ready for adventure? Start a quest to begin earning experience and rewards")
        }
    }
}