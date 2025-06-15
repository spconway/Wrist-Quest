import SwiftUI

struct QuestListView: View {
    @StateObject private var questViewModel: QuestViewModel
    @EnvironmentObject private var navigationCoordinator: NavigationCoordinator
    @EnvironmentObject private var gameViewModel: GameViewModel
    
    init(playerViewModel: PlayerViewModel) {
        self._questViewModel = StateObject(wrappedValue: QuestViewModel(playerViewModel: playerViewModel))
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: WQDesignSystem.Spacing.md) {
                if questViewModel.isLoading {
                    WQLoadingView("Loading quests...")
                        .padding()
                } else if questViewModel.availableQuests.isEmpty {
                    NoQuestsView()
                } else {
                    ForEach(questViewModel.availableQuests) { quest in
                        QuestRowView(quest: quest) {
                            navigationCoordinator.navigate(to: .questDetail(quest))
                        }
                    }
                }
            }
            .padding(WQDesignSystem.Spacing.md)
        }
        .navigationTitle("Available Quests")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            await refreshQuests()
        }
    }
    
    @MainActor
    private func refreshQuests() async {
        // Simulate refresh - in real app might fetch from server
        try? await Task.sleep(nanoseconds: 1_000_000_000)
    }
}

struct QuestRowView: View {
    let quest: Quest
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            WQCard {
                VStack(alignment: .leading, spacing: WQDesignSystem.Spacing.sm) {
                    HStack {
                        Text(quest.title)
                            .font(WQDesignSystem.Typography.headline)
                            .foregroundColor(WQDesignSystem.Colors.primaryText)
                            .multilineTextAlignment(.leading)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(WQDesignSystem.Colors.accent)
                            .font(.caption)
                    }
                    
                    Text(quest.description)
                        .font(WQDesignSystem.Typography.body)
                        .foregroundColor(WQDesignSystem.Colors.secondaryText)
                        .multilineTextAlignment(.leading)
                        .lineLimit(3)
                    
                    Divider()
                        .background(WQDesignSystem.Colors.border)
                    
                    HStack {
                        QuestStatView(
                            icon: "figure.walk",
                            label: "Distance",
                            value: "\(quest.totalDistance.formatted(decimalPlaces: 1)) mi",
                            color: WQDesignSystem.Colors.questBlue
                        )
                        
                        Spacer()
                        
                        QuestStatView(
                            icon: "star.fill",
                            label: "XP",
                            value: "\(quest.rewardXP)",
                            color: WQDesignSystem.Colors.questGold
                        )
                        
                        Spacer()
                        
                        QuestStatView(
                            icon: "dollarsign.circle.fill",
                            label: "Gold",
                            value: "\(quest.rewardGold)",
                            color: WQDesignSystem.Colors.questGold
                        )
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct QuestStatView: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: WQDesignSystem.Spacing.xs) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
            
            Text(value)
                .font(WQDesignSystem.Typography.caption)
                .foregroundColor(WQDesignSystem.Colors.primaryText)
                .fontWeight(.medium)
            
            Text(label)
                .font(WQDesignSystem.Typography.footnote)
                .foregroundColor(WQDesignSystem.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity)
    }
}

struct NoQuestsView: View {
    var body: some View {
        VStack(spacing: WQDesignSystem.Spacing.lg) {
            Image(systemName: "map")
                .font(.system(size: 48))
                .foregroundColor(WQDesignSystem.Colors.secondaryText)
            
            VStack(spacing: WQDesignSystem.Spacing.sm) {
                Text("No Quests Available")
                    .font(WQDesignSystem.Typography.headline)
                    .foregroundColor(WQDesignSystem.Colors.primaryText)
                
                Text("Complete your current quest to unlock new adventures!")
                    .font(WQDesignSystem.Typography.body)
                    .foregroundColor(WQDesignSystem.Colors.secondaryText)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(WQDesignSystem.Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    NavigationStack {
        QuestListView(playerViewModel: PlayerViewModel(player: Player.preview))
            .environmentObject(NavigationCoordinator())
            .environmentObject(GameViewModel())
    }
}