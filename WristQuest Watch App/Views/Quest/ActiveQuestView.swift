import SwiftUI

// Note: WQConstants are accessed globally via WQC typealias

struct ActiveQuestView: View {
    @StateObject private var questViewModel: QuestViewModel
    @EnvironmentObject private var navigationCoordinator: NavigationCoordinator
    @EnvironmentObject private var healthViewModel: HealthViewModel
    @EnvironmentObject private var gameViewModel: GameViewModel
    @State private var showingCancelConfirmation = false
    @State private var showingQuestComplete = false
    
    init(playerViewModel: PlayerViewModel) {
        self._questViewModel = StateObject(wrappedValue: QuestViewModel(playerViewModel: playerViewModel))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: WQDesignSystem.Spacing.lg) {
                if let activeQuest = questViewModel.activeQuest {
                    if activeQuest.isCompleted {
                        QuestCompletedView(quest: activeQuest)
                    } else {
                        ActiveQuestProgressView(quest: activeQuest)
                        
                        ActivityTrackingView()
                        
                        if healthViewModel.isInCombatMode {
                            CombatModeIndicator()
                        }
                        
                        QuestTipsView()
                    }
                } else {
                    NoActiveQuestView()
                }
            }
            .padding(WQDesignSystem.Spacing.md)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(AccessibilityConstants.Quests.activeQuestTitle)
        .navigationTitle("Active Quest")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if questViewModel.activeQuest != nil && !questViewModel.activeQuest!.isCompleted {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") {
                        showingCancelConfirmation = true
                    }
                    .foregroundColor(WQDesignSystem.Colors.error)
                    .accessibleActionButton(
                        actionName: AccessibilityConstants.Quests.cancelQuestButton,
                        description: AccessibilityConstants.Quests.cancelQuestHint
                    )
                }
            }
        }
        .confirmationDialog("Cancel Quest", isPresented: $showingCancelConfirmation) {
            Button("Cancel Quest", role: .destructive) {
                questViewModel.cancelQuest()
                navigationCoordinator.pop()
            }
            
            Button("Keep Going", role: .cancel) { }
        } message: {
            Text("Are you sure you want to cancel this quest? Your progress will be lost.")
        }
        .onReceive(questViewModel.$activeQuest) { quest in
            if let quest = quest, quest.isCompleted {
                AccessibilityHelpers.announceQuestCompletion(
                    questTitle: quest.title,
                    xpReward: quest.rewardXP,
                    goldReward: quest.rewardGold
                )
                DispatchQueue.main.asyncAfter(deadline: .now() + WQC.UI.questCompletionDelay) {
                    showingQuestComplete = true
                }
            }
        }
        .sheet(isPresented: $showingQuestComplete) {
            if let completedQuest = questViewModel.activeQuest {
                QuestCompletionSheet(quest: completedQuest) {
                    navigationCoordinator.popToRoot()
                }
            }
        }
    }
}

struct ActiveQuestProgressView: View {
    let quest: Quest
    
    var body: some View {
        WQCard {
            VStack(spacing: WQDesignSystem.Spacing.lg) {
                // Quest Header
                VStack(spacing: WQDesignSystem.Spacing.sm) {
                    Text(quest.title)
                        .font(WQDesignSystem.Typography.title)
                        .foregroundColor(WQDesignSystem.Colors.primaryText)
                        .multilineTextAlignment(.center)
                        .accessibilityAddTraits(.isHeader)
                    
                    Text("Quest in Progress")
                        .font(WQDesignSystem.Typography.caption)
                        .foregroundColor(WQDesignSystem.Colors.accent)
                        .padding(.horizontal, WQDesignSystem.Spacing.sm)
                        .padding(.vertical, WQDesignSystem.Spacing.xs)
                        .background(WQDesignSystem.Colors.accent.opacity(0.1))
                        .cornerRadius(WQDesignSystem.CornerRadius.sm)
                        .accessibilityLabel(AccessibilityConstants.Quests.questInProgress)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Active quest: \(quest.title), in progress")
                
                // Progress Circle
                ZStack {
                    Circle()
                        .stroke(WQDesignSystem.Colors.border, lineWidth: WQC.UI.progressLineWidth)
                        .frame(width: WQC.UI.progressCircleSize, height: WQC.UI.progressCircleSize)
                        .accessibilityHidden(true)
                    
                    Circle()
                        .trim(from: 0, to: quest.progressPercentage)
                        .stroke(
                            LinearGradient(
                                colors: [WQDesignSystem.Colors.questBlue, WQDesignSystem.Colors.questPurple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: WQC.UI.progressCircleSize, height: WQC.UI.progressCircleSize)
                        .rotationEffect(.degrees(-90))
                        .accessibleAnimation(.easeInOut(duration: WQC.UI.questProgressAnimationDuration), value: quest.progressPercentage)
                        .accessibilityHidden(true)
                    
                    VStack(spacing: WQDesignSystem.Spacing.xs) {
                        Text("\(Int(quest.progressPercentage * 100))%")
                            .font(WQDesignSystem.Typography.title)
                            .foregroundColor(WQDesignSystem.Colors.primaryText)
                            .fontWeight(.bold)
                        
                        Text("Complete")
                            .font(WQDesignSystem.Typography.footnote)
                            .foregroundColor(WQDesignSystem.Colors.secondaryText)
                    }
                    .accessibilityHidden(true)
                }
                .wqProgressAccessible(
                    type: .questProgress,
                    current: quest.currentProgress,
                    total: quest.totalDistance,
                    unit: "miles"
                )
                
                // Progress Details
                VStack(spacing: WQDesignSystem.Spacing.sm) {
                    HStack {
                        Text("Distance Progress")
                            .font(WQDesignSystem.Typography.caption)
                            .foregroundColor(WQDesignSystem.Colors.secondaryText)
                        
                        Spacer()
                        
                        Text("\(quest.currentProgress.formatted(decimalPlaces: 1)) / \(quest.totalDistance.formatted(decimalPlaces: 1)) miles")
                            .font(WQDesignSystem.Typography.caption)
                            .foregroundColor(WQDesignSystem.Colors.primaryText)
                            .fontWeight(.medium)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Distance progress: \(quest.currentProgress.formatted(decimalPlaces: 1)) of \(quest.totalDistance.formatted(decimalPlaces: 1)) miles")
                    
                    WQProgressBar(
                        progress: quest.progressPercentage,
                        color: WQDesignSystem.Colors.questBlue,
                        height: WQC.UI.progressBarHeight
                    )
                    .wqProgressAccessible(
                        type: .questProgress,
                        current: quest.currentProgress,
                        total: quest.totalDistance,
                        unit: "miles"
                    )
                }
                
                // Rewards Preview
                HStack(spacing: WQDesignSystem.Spacing.lg) {
                    RewardPreview(
                        icon: "star.fill",
                        value: "\(quest.rewardXP) XP",
                        color: WQDesignSystem.Colors.questGold
                    )
                    .wqRewardAccessible(
                        reward: WQRewardInfo(type: .experience, amount: quest.rewardXP)
                    )
                    
                    RewardPreview(
                        icon: "dollarsign.circle.fill",
                        value: "\(quest.rewardGold) Gold",
                        color: WQDesignSystem.Colors.questGold
                    )
                    .wqRewardAccessible(
                        reward: WQRewardInfo(type: .gold, amount: quest.rewardGold)
                    )
                }
                .accessibilityElement(children: .contain)
                .accessibilityLabel("Quest rewards: \(quest.rewardXP) experience points and \(quest.rewardGold) gold")
            }
        }
        .wqQuestAccessible(
            quest: WQQuestAccessibilityInfo(
                title: quest.title,
                description: nil,
                isActive: true,
                isCompleted: false,
                progress: quest.progressPercentage,
                rewardXP: quest.rewardXP,
                rewardGold: quest.rewardGold
            ),
            action: .view
        )
    }
}

struct RewardPreview: View {
    let icon: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: WQDesignSystem.Spacing.xs) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
            
            Text(value)
                .font(WQDesignSystem.Typography.caption)
                .foregroundColor(WQDesignSystem.Colors.secondaryText)
        }
        .padding(.horizontal, WQDesignSystem.Spacing.sm)
        .padding(.vertical, WQDesignSystem.Spacing.xs)
        .background(color.opacity(0.1))
        .cornerRadius(WQDesignSystem.CornerRadius.sm)
    }
}

struct ActivityTrackingView: View {
    @EnvironmentObject private var healthViewModel: HealthViewModel
    
    var body: some View {
        WQCard {
            VStack(alignment: .leading, spacing: WQDesignSystem.Spacing.md) {
                Text("Activity Tracking")
                    .font(WQDesignSystem.Typography.headline)
                    .foregroundColor(WQDesignSystem.Colors.primaryText)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityLabel(AccessibilityConstants.Health.activityTracking)
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: WQDesignSystem.Spacing.sm) {
                    ActivityMetricView(
                        icon: "figure.walk",
                        title: "Steps Today",
                        value: "\(healthViewModel.currentHealthData.steps)",
                        color: WQDesignSystem.Colors.questBlue
                    )
                    .wqHealthMetricAccessible(
                        metric: .steps,
                        value: AccessibilityConstants.Health.stepsValue(healthViewModel.currentHealthData.steps)
                    )
                    
                    ActivityMetricView(
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
                    
                    ActivityMetricView(
                        icon: "flame.fill",
                        title: "Exercise",
                        value: "\(healthViewModel.currentHealthData.exerciseMinutes) min",
                        color: WQDesignSystem.Colors.questOrange
                    )
                    .wqHealthMetricAccessible(
                        metric: .exerciseMinutes,
                        value: AccessibilityConstants.Health.exerciseMinutesValue(healthViewModel.currentHealthData.exerciseMinutes)
                    )
                    
                    ActivityMetricView(
                        icon: "figure.stand",
                        title: "Stand Hours",
                        value: "\(healthViewModel.currentHealthData.standingHours)",
                        color: WQDesignSystem.Colors.questGreen
                    )
                    .wqHealthMetricAccessible(
                        metric: .standHours,
                        value: AccessibilityConstants.Health.standHoursValue(healthViewModel.currentHealthData.standingHours)
                    )
                }
                .accessibilityElement(children: .contain)
                .accessibilityLabel(AccessibilityConstants.Health.activitySummary)
            }
        }
    }
}

struct ActivityMetricView: View {
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
                .fontWeight(.medium)
            
            Text(title)
                .font(WQDesignSystem.Typography.footnote)
                .foregroundColor(WQDesignSystem.Colors.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(WQDesignSystem.Spacing.sm)
        .background(color.opacity(0.1))
        .cornerRadius(WQDesignSystem.CornerRadius.md)
    }
}

struct CombatModeIndicator: View {
    var body: some View {
        WQCard {
            HStack(spacing: WQDesignSystem.Spacing.md) {
                ZStack {
                    Circle()
                        .fill(WQDesignSystem.Colors.questRed)
                        .frame(width: 40, height: 40)
                        .accessibilityHidden(true)
                    
                    Image(systemName: "bolt.fill")
                        .font(.title3)
                        .foregroundColor(.white)
                        .accessibilityLabel("Lightning bolt icon")
                        .accessibilityHidden(true)
                }
                
                VStack(alignment: .leading, spacing: WQDesignSystem.Spacing.xs) {
                    Text("Combat Mode Active!")
                        .font(WQDesignSystem.Typography.headline)
                        .foregroundColor(WQDesignSystem.Colors.questRed)
                    
                    Text("Your elevated heart rate may trigger encounters")
                        .font(WQDesignSystem.Typography.caption)
                        .foregroundColor(WQDesignSystem.Colors.secondaryText)
                }
                
                Spacer()
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(AccessibilityConstants.Health.combatModeActive)
            .accessibilityValue(AccessibilityConstants.Health.combatModeDescription)
            .accessibilityAddTraits(.startsMediaSession)
        }
        .wqHealthMetricAccessible(
            metric: .combatMode,
            value: "Active",
            isActive: true
        )
        .onAppear {
            AccessibilityHelpers.announceCombatMode()
        }
    }
}

struct QuestTipsView: View {
    var body: some View {
        WQCard {
            VStack(alignment: .leading, spacing: WQDesignSystem.Spacing.md) {
                Text("Quest Tips")
                    .font(WQDesignSystem.Typography.headline)
                    .foregroundColor(WQDesignSystem.Colors.primaryText)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityLabel(AccessibilityConstants.Tips.questTips)
                
                VStack(alignment: .leading, spacing: WQDesignSystem.Spacing.sm) {
                    TipRow(
                        icon: "figure.walk",
                        text: "Keep walking to progress your quest"
                    )
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(AccessibilityConstants.Tips.tip1)
                    
                    TipRow(
                        icon: "heart.fill",
                        text: "Elevated heart rate may trigger events"
                    )
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(AccessibilityConstants.Tips.tip2)
                    
                    TipRow(
                        icon: "applewatch",
                        text: "Check back periodically for updates"
                    )
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(AccessibilityConstants.Tips.tip3)
                }
                .accessibilityElement(children: .contain)
                .accessibilityLabel("Helpful tips for quest completion")
            }
        }
    }
}

struct TipRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: WQDesignSystem.Spacing.sm) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(WQDesignSystem.Colors.accent)
                .frame(width: 20)
            
            Text(text)
                .font(WQDesignSystem.Typography.caption)
                .foregroundColor(WQDesignSystem.Colors.secondaryText)
            
            Spacer()
        }
    }
}

struct QuestCompletedView: View {
    let quest: Quest
    
    var body: some View {
        WQCard {
            VStack(spacing: WQDesignSystem.Spacing.lg) {
                // Success Icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [WQDesignSystem.Colors.questGreen, WQDesignSystem.Colors.questBlue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "checkmark")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                }
                
                VStack(spacing: WQDesignSystem.Spacing.sm) {
                    Text("Quest Complete!")
                        .font(WQDesignSystem.Typography.title)
                        .foregroundColor(WQDesignSystem.Colors.primaryText)
                    
                    Text(quest.title)
                        .font(WQDesignSystem.Typography.headline)
                        .foregroundColor(WQDesignSystem.Colors.secondaryText)
                        .multilineTextAlignment(.center)
                }
                
                // Rewards
                HStack(spacing: WQDesignSystem.Spacing.lg) {
                    VStack(spacing: WQDesignSystem.Spacing.xs) {
                        Image(systemName: "star.fill")
                            .font(.title2)
                            .foregroundColor(WQDesignSystem.Colors.questGold)
                        
                        Text("+\(quest.rewardXP) XP")
                            .font(WQDesignSystem.Typography.caption)
                            .foregroundColor(WQDesignSystem.Colors.primaryText)
                            .fontWeight(.medium)
                    }
                    
                    VStack(spacing: WQDesignSystem.Spacing.xs) {
                        Image(systemName: "dollarsign.circle.fill")
                            .font(.title2)
                            .foregroundColor(WQDesignSystem.Colors.questGold)
                        
                        Text("+\(quest.rewardGold) Gold")
                            .font(WQDesignSystem.Typography.caption)
                            .foregroundColor(WQDesignSystem.Colors.primaryText)
                            .fontWeight(.medium)
                    }
                }
            }
        }
    }
}

struct NoActiveQuestView: View {
    @EnvironmentObject private var navigationCoordinator: NavigationCoordinator
    
    var body: some View {
        VStack(spacing: WQDesignSystem.Spacing.xl) {
            Image(systemName: "map")
                .font(.system(size: 48))
                .foregroundColor(WQDesignSystem.Colors.secondaryText)
                .accessibilityLabel("Map icon")
                .accessibilityHidden(true)
            
            VStack(spacing: WQDesignSystem.Spacing.sm) {
                Text("No Active Quest")
                    .font(WQDesignSystem.Typography.headline)
                    .foregroundColor(WQDesignSystem.Colors.primaryText)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityLabel(AccessibilityConstants.Quests.noActiveQuestTitle)
                
                Text("Start a quest to begin your adventure!")
                    .font(WQDesignSystem.Typography.body)
                    .foregroundColor(WQDesignSystem.Colors.secondaryText)
                    .multilineTextAlignment(.center)
                    .accessibilityLabel(AccessibilityConstants.Quests.noActiveQuestDescription)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(AccessibilityConstants.Quests.noActiveQuestTitle). \(AccessibilityConstants.Quests.noActiveQuestDescription)")
            
            WQButton("Browse Quests", icon: "arrow.right") {
                navigationCoordinator.popToRoot()
            }
            .accessibleActionButton(
                actionName: AccessibilityConstants.Quests.browseQuestsButton,
                description: AccessibilityConstants.Quests.browseQuestsHint
            )
        }
        .padding(WQDesignSystem.Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct QuestCompletionSheet: View {
    let quest: Quest
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: WQDesignSystem.Spacing.xl) {
            // Celebration Animation
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [WQDesignSystem.Colors.questGold, WQDesignSystem.Colors.questOrange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                
                Image(systemName: "crown.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: WQDesignSystem.Spacing.md) {
                Text("🎉 Victory! 🎉")
                    .font(WQDesignSystem.Typography.largeTitle)
                
                Text("Quest Completed")
                    .font(WQDesignSystem.Typography.title)
                    .foregroundColor(WQDesignSystem.Colors.primaryText)
                
                Text(quest.title)
                    .font(WQDesignSystem.Typography.headline)
                    .foregroundColor(WQDesignSystem.Colors.secondaryText)
                    .multilineTextAlignment(.center)
            }
            
            // Rewards Display
            VStack(spacing: WQDesignSystem.Spacing.md) {
                Text("Rewards Earned")
                    .font(WQDesignSystem.Typography.headline)
                    .foregroundColor(WQDesignSystem.Colors.primaryText)
                
                HStack(spacing: WQDesignSystem.Spacing.xl) {
                    VStack(spacing: WQDesignSystem.Spacing.sm) {
                        Image(systemName: "star.fill")
                            .font(.largeTitle)
                            .foregroundColor(WQDesignSystem.Colors.questGold)
                        
                        Text("+\(quest.rewardXP)")
                            .font(WQDesignSystem.Typography.title)
                            .foregroundColor(WQDesignSystem.Colors.primaryText)
                            .fontWeight(.bold)
                        
                        Text("Experience")
                            .font(WQDesignSystem.Typography.caption)
                            .foregroundColor(WQDesignSystem.Colors.secondaryText)
                    }
                    
                    VStack(spacing: WQDesignSystem.Spacing.sm) {
                        Image(systemName: "dollarsign.circle.fill")
                            .font(.largeTitle)
                            .foregroundColor(WQDesignSystem.Colors.questGold)
                        
                        Text("+\(quest.rewardGold)")
                            .font(WQDesignSystem.Typography.title)
                            .foregroundColor(WQDesignSystem.Colors.primaryText)
                            .fontWeight(.bold)
                        
                        Text("Gold")
                            .font(WQDesignSystem.Typography.caption)
                            .foregroundColor(WQDesignSystem.Colors.secondaryText)
                    }
                }
            }
            
            Spacer()
            
            WQButton("Continue Adventure", icon: "arrow.right") {
                onDismiss()
            }
        }
        .padding(WQDesignSystem.Spacing.xl)
        .background(WQDesignSystem.Colors.primaryBackground)
    }
}

#Preview {
    NavigationStack {
        ActiveQuestView(playerViewModel: PlayerViewModel(player: Player.preview))
            .environmentObject(NavigationCoordinator())
            .environmentObject(HealthViewModel())
            .environmentObject(GameViewModel())
    }
}