import SwiftUI

struct QuestDetailView: View {
    let quest: Quest
    @StateObject private var questViewModel: QuestViewModel
    @EnvironmentObject private var navigationCoordinator: NavigationCoordinator
    @EnvironmentObject private var gameViewModel: GameViewModel
    @State private var showingStartConfirmation = false
    
    init(quest: Quest, playerViewModel: PlayerViewModel) {
        self.quest = quest
        self._questViewModel = StateObject(wrappedValue: QuestViewModel(playerViewModel: playerViewModel))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: WQDesignSystem.Spacing.lg) {
                QuestHeaderView(quest: quest)
                
                QuestStatsView(quest: quest)
                
                QuestDescriptionView(quest: quest)
                
                QuestRequirementsView(quest: quest)
                
                Spacer(minLength: WQDesignSystem.Spacing.xl)
            }
            .padding(WQDesignSystem.Spacing.md)
        }
        .navigationTitle(quest.title)
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            QuestActionButton(quest: quest) {
                showingStartConfirmation = true
            }
            .padding(WQDesignSystem.Spacing.md)
        }
        .confirmationDialog("Start Quest", isPresented: $showingStartConfirmation) {
            Button("Start Adventure") {
                startQuest()
            }
            
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Begin \(quest.title)? Your progress will be tracked through your daily activity.")
        }
    }
    
    private func startQuest() {
        questViewModel.startQuest(quest)
        navigationCoordinator.navigate(to: .activeQuest)
    }
}

struct QuestHeaderView: View {
    let quest: Quest
    
    var body: some View {
        WQCard {
            VStack(spacing: WQDesignSystem.Spacing.md) {
                // Quest Icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [WQDesignSystem.Colors.questBlue, WQDesignSystem.Colors.questPurple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: questIcon(for: quest))
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(.white)
                }
                
                VStack(spacing: WQDesignSystem.Spacing.xs) {
                    Text(quest.title)
                        .font(WQDesignSystem.Typography.title)
                        .foregroundColor(WQDesignSystem.Colors.primaryText)
                        .multilineTextAlignment(.center)
                    
                    Text(questDifficulty(for: quest))
                        .font(WQDesignSystem.Typography.caption)
                        .foregroundColor(difficultyColor(for: quest))
                        .padding(.horizontal, WQDesignSystem.Spacing.sm)
                        .padding(.vertical, WQDesignSystem.Spacing.xs)
                        .background(difficultyColor(for: quest).opacity(0.1))
                        .cornerRadius(WQDesignSystem.CornerRadius.sm)
                }
            }
        }
    }
    
    private func questIcon(for quest: Quest) -> String {
        switch quest.title.lowercased() {
        case let title where title.contains("dragon"):
            return "flame"
        case let title where title.contains("cave") || title.contains("goblin"):
            return "mountain.2"
        case let title where title.contains("caravan") || title.contains("escort"):
            return "figure.walk"
        case let title where title.contains("ruins"):
            return "building.columns"
        case let title where title.contains("bandit"):
            return "sword.fill"
        case let title where title.contains("grove") || title.contains("mystic"):
            return "leaf"
        default:
            return "map"
        }
    }
    
    private func questDifficulty(for quest: Quest) -> String {
        switch quest.totalDistance {
        case 0..<50:
            return "Easy"
        case 50..<100:
            return "Medium"
        case 100..<150:
            return "Hard"
        default:
            return "Epic"
        }
    }
    
    private func difficultyColor(for quest: Quest) -> Color {
        switch quest.totalDistance {
        case 0..<50:
            return WQDesignSystem.Colors.questGreen
        case 50..<100:
            return WQDesignSystem.Colors.questGold
        case 100..<150:
            return WQDesignSystem.Colors.questRed
        default:
            return WQDesignSystem.Colors.questPurple
        }
    }
}

struct QuestStatsView: View {
    let quest: Quest
    
    var body: some View {
        WQCard {
            VStack(spacing: WQDesignSystem.Spacing.md) {
                HStack {
                    Text("Quest Details")
                        .font(WQDesignSystem.Typography.headline)
                        .foregroundColor(WQDesignSystem.Colors.primaryText)
                    
                    Spacer()
                }
                
                HStack(spacing: WQDesignSystem.Spacing.lg) {
                    QuestDetailStatView(
                        icon: "figure.walk",
                        title: "Distance",
                        value: "\(quest.totalDistance.formatted(decimalPlaces: 1)) miles",
                        subtitle: "≈ \(Int(quest.totalDistance * 2000)) steps",
                        color: WQDesignSystem.Colors.questBlue
                    )
                    
                    Spacer()
                    
                    VStack(spacing: WQDesignSystem.Spacing.sm) {
                        QuestDetailStatView(
                            icon: "star.fill",
                            title: "XP Reward",
                            value: "\(quest.rewardXP)",
                            subtitle: "",
                            color: WQDesignSystem.Colors.questGold
                        )
                        
                        QuestDetailStatView(
                            icon: "dollarsign.circle.fill",
                            title: "Gold Reward",
                            value: "\(quest.rewardGold)",
                            subtitle: "",
                            color: WQDesignSystem.Colors.questGold
                        )
                    }
                }
            }
        }
    }
}

struct QuestDetailStatView: View {
    let icon: String
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        VStack(spacing: WQDesignSystem.Spacing.xs) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(title)
                .font(WQDesignSystem.Typography.caption)
                .foregroundColor(WQDesignSystem.Colors.secondaryText)
            
            Text(value)
                .font(WQDesignSystem.Typography.headline)
                .foregroundColor(WQDesignSystem.Colors.primaryText)
                .fontWeight(.semibold)
            
            if !subtitle.isEmpty {
                Text(subtitle)
                    .font(WQDesignSystem.Typography.footnote)
                    .foregroundColor(WQDesignSystem.Colors.secondaryText)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct QuestDescriptionView: View {
    let quest: Quest
    
    var body: some View {
        WQCard {
            VStack(alignment: .leading, spacing: WQDesignSystem.Spacing.md) {
                Text("Description")
                    .font(WQDesignSystem.Typography.headline)
                    .foregroundColor(WQDesignSystem.Colors.primaryText)
                
                Text(quest.description)
                    .font(WQDesignSystem.Typography.body)
                    .foregroundColor(WQDesignSystem.Colors.secondaryText)
                    .lineSpacing(4)
                
                if !questLore(for: quest).isEmpty {
                    Divider()
                        .background(WQDesignSystem.Colors.border)
                    
                    Text(questLore(for: quest))
                        .font(WQDesignSystem.Typography.caption)
                        .foregroundColor(WQDesignSystem.Colors.secondaryText)
                        .italic()
                        .lineSpacing(2)
                }
            }
        }
    }
    
    private func questLore(for quest: Quest) -> String {
        switch quest.title.lowercased() {
        case let title where title.contains("dragon"):
            return "The ancient wyrm has terrorized the countryside for generations. Many heroes have tried, few have returned."
        case let title where title.contains("cave") || title.contains("goblin"):
            return "Strange lights have been seen in the depths. The goblins whisper of treasures beyond imagination."
        case let title where title.contains("caravan"):
            return "The trade routes grow dangerous. Your protection could mean the difference between profit and ruin."
        case let title where title.contains("ruins"):
            return "Lost civilizations leave behind more than stone and mortar. Some secrets are worth the journey."
        case let title where title.contains("bandit"):
            return "The roads must be safe for all travelers. Sometimes justice requires a firm hand."
        case let title where title.contains("grove"):
            return "Nature itself seems disturbed. The trees whisper warnings to those who listen."
        default:
            return ""
        }
    }
}

struct QuestRequirementsView: View {
    let quest: Quest
    
    var body: some View {
        WQCard {
            VStack(alignment: .leading, spacing: WQDesignSystem.Spacing.md) {
                Text("How It Works")
                    .font(WQDesignSystem.Typography.headline)
                    .foregroundColor(WQDesignSystem.Colors.primaryText)
                
                VStack(alignment: .leading, spacing: WQDesignSystem.Spacing.sm) {
                    RequirementRow(
                        icon: "figure.walk",
                        text: "Walk or run to progress your quest",
                        color: WQDesignSystem.Colors.questBlue
                    )
                    
                    RequirementRow(
                        icon: "heart.fill",
                        text: "Elevated heart rate may trigger encounters",
                        color: WQDesignSystem.Colors.questRed
                    )
                    
                    RequirementRow(
                        icon: "checkmark.circle.fill",
                        text: "Complete the distance to finish the quest",
                        color: WQDesignSystem.Colors.questGreen
                    )
                }
            }
        }
    }
}

struct RequirementRow: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: WQDesignSystem.Spacing.sm) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
                .frame(width: 20)
            
            Text(text)
                .font(WQDesignSystem.Typography.caption)
                .foregroundColor(WQDesignSystem.Colors.secondaryText)
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
    }
}

struct QuestActionButton: View {
    let quest: Quest
    let action: () -> Void
    
    var body: some View {
        WQButton("Start Quest", icon: "play.fill") {
            action()
        }
    }
}

#Preview {
    NavigationStack {
        QuestDetailView(
            quest: Quest(
                title: "Explore the Goblin Caves",
                description: "Venture into the dark caverns beneath the forest to discover ancient treasures and face the goblin clans.",
                totalDistance: 50.0,
                rewardXP: 100,
                rewardGold: 25
            ),
            playerViewModel: PlayerViewModel(player: Player.preview)
        )
        .environmentObject(NavigationCoordinator())
        .environmentObject(GameViewModel())
    }
}