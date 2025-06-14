import SwiftUI

struct AppRootView: View {
    @EnvironmentObject var navigationCoordinator: NavigationCoordinator
    @EnvironmentObject var gameViewModel: GameViewModel
    @EnvironmentObject var gameStateManager: GameStateManager
    
    var body: some View {
        NavigationStack(path: $navigationCoordinator.navigationPath) {
            MainContentView()
                .navigationDestination(for: NavigationCoordinator.Destination.self) { destination in
                    destinationView(for: destination)
                }
        }
        .sheet(item: $navigationCoordinator.presentedSheet) { sheet in
            sheetView(for: sheet)
        }
        .fullScreenCover(item: $navigationCoordinator.presentedFullScreenCover) { cover in
            fullScreenCoverView(for: cover)
        }
        .alert("Error", isPresented: .constant(gameViewModel.errorMessage != nil)) {
            Button("OK") {
                gameViewModel.clearError()
            }
        } message: {
            if let errorMessage = gameViewModel.errorMessage {
                Text(errorMessage)
            }
        }
        .onOpenURL { url in
            gameStateManager.handleDeepLink(url)
        }
    }
    
    @ViewBuilder
    private func destinationView(for destination: NavigationCoordinator.Destination) -> some View {
        switch destination {
        case .questDetail(let quest):
            QuestDetailView(quest: quest)
        case .activeQuest:
            ActiveQuestView()
        case .encounter(let encounter):
            EncounterView(encounter: encounter)
        case .characterDetail:
            CharacterDetailView()
        case .inventory:
            InventoryView()
        case .journal:
            JournalView()
        case .settings:
            SettingsView()
        }
    }
    
    @ViewBuilder
    private func sheetView(for sheet: NavigationCoordinator.SheetDestination) -> some View {
        switch sheet {
        case .itemDetail(let item):
            ItemDetailView(item: item)
        case .questLog(let log):
            QuestLogDetailView(questLog: log)
        case .levelUpReward(let rewards):
            LevelUpRewardView(rewards: rewards)
        case .error(let message):
            ErrorView(message: message)
        }
    }
    
    @ViewBuilder
    private func fullScreenCoverView(for cover: NavigationCoordinator.FullScreenDestination) -> some View {
        switch cover {
        case .onboarding:
            OnboardingView()
        case .characterCreation:
            CharacterCreationView()
        }
    }
}

struct MainContentView: View {
    @EnvironmentObject var gameViewModel: GameViewModel
    
    var body: some View {
        Group {
            if gameViewModel.isLoading {
                LoadingView()
            } else {
                switch gameViewModel.gameState {
                case .mainMenu:
                    MainMenuView()
                case .activeQuest(let quest):
                    ActiveQuestView(quest: quest)
                case .encounter(let encounter):
                    EncounterView(encounter: encounter)
                default:
                    MainMenuView()
                }
            }
        }
    }
}

struct LoadingView: View {
    var body: some View {
        WQLoadingView("Loading Adventure...")
    }
}

struct ErrorView: View {
    let message: String
    @EnvironmentObject var navigationCoordinator: NavigationCoordinator
    
    var body: some View {
        WQErrorView(message: message) {
            navigationCoordinator.dismissSheet()
        }
    }
}

struct QuestDetailView: View {
    let quest: Quest
    
    var body: some View {
        WQCard {
            VStack(alignment: .leading, spacing: WQDesignSystem.Spacing.md) {
                Text(quest.title)
                    .font(WQDesignSystem.Typography.title)
                    .foregroundColor(WQDesignSystem.Colors.primaryText)
                
                Text(quest.description)
                    .font(WQDesignSystem.Typography.body)
                    .foregroundColor(WQDesignSystem.Colors.secondaryText)
                
                HStack {
                    WQStatDisplay(title: "Distance", value: "\(quest.totalDistance.formatted(decimalPlaces: 1)) mi", icon: "location.fill")
                    Spacer()
                    WQStatDisplay(title: "Reward", value: "\(quest.rewardXP) XP", icon: "star.fill")
                }
                
                WQButton("Start Quest", icon: "play.fill") {
                    // Quest start logic would go here
                }
            }
        }
        .padding()
        .navigationTitle("Quest Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ActiveQuestView: View {
    let quest: Quest?
    
    init(quest: Quest? = nil) {
        self.quest = quest
    }
    
    var body: some View {
        if let quest = quest {
            Text("Active Quest: \(quest.title)")
        } else {
            Text("No Active Quest")
        }
    }
}

struct EncounterView: View {
    let encounter: Encounter
    
    var body: some View {
        Text("Encounter: \(encounter.description)")
    }
}

struct CharacterDetailView: View {
    var body: some View {
        Text("Character Detail")
    }
}

struct InventoryView: View {
    var body: some View {
        Text("Inventory")
    }
}

struct JournalView: View {
    var body: some View {
        Text("Journal")
    }
}

// SettingsView is now in its own file

struct ItemDetailView: View {
    let item: Item
    
    var body: some View {
        Text("Item: \(item.name)")
    }
}

struct QuestLogDetailView: View {
    let questLog: QuestLog
    
    var body: some View {
        Text("Quest Log: \(questLog.questName)")
    }
}

struct LevelUpRewardView: View {
    let rewards: [String]
    
    var body: some View {
        VStack {
            ForEach(rewards, id: \.self) { reward in
                Text(reward)
            }
        }
    }
}

// OnboardingView is now in its own file

struct CharacterCreationView: View {
    var body: some View {
        WQLoadingView("Setting up character...")
    }
}

// MainMenuView is now in its own file