import SwiftUI

struct AppRootView: View {
    @EnvironmentObject var navigationCoordinator: NavigationCoordinator
    @EnvironmentObject var gameViewModel: GameViewModel
    
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
        .onReceive(gameViewModel.$gameState) { gameState in
            // Sync GameViewModel state with navigation
            print("🎮 AppRootView: GameState changed to \(gameState), isLoading: \(gameViewModel.isLoading)")
            switch gameState {
            case .onboarding:
                print("🎮 AppRootView: Presenting onboarding fullScreenCover")
                navigationCoordinator.presentFullScreenCover(.onboarding)
            case .mainMenu:
                print("🎮 AppRootView: Dismissing fullScreenCover for mainMenu")
                navigationCoordinator.dismissFullScreenCover()
            default:
                break
            }
        }
        .onReceive(gameViewModel.$isLoading) { isLoading in
            print("🎮 AppRootView: isLoading changed to \(isLoading)")
        }
    }
    
    @ViewBuilder
    private func destinationView(for destination: NavigationCoordinator.Destination) -> some View {
        if let player = gameViewModel.currentPlayer {
            let playerViewModel = PlayerViewModel(player: player)
            
            switch destination {
            case .questList:
                QuestListView(playerViewModel: playerViewModel)
            case .questDetail(let quest):
                QuestDetailView(quest: quest, playerViewModel: playerViewModel)
            case .activeQuest:
                ActiveQuestView(playerViewModel: playerViewModel)
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
        } else {
            WQLoadingView("Loading...")
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
        if gameViewModel.isLoading {
            LoadingView()
        } else {
            switch gameViewModel.gameState {
            case .mainMenu:
                MainMenuView()
            case .activeQuest:
                if let player = gameViewModel.currentPlayer {
                    ActiveQuestView(playerViewModel: PlayerViewModel(player: player))
                } else {
                    MainMenuView()
                }
            case .encounter(let encounter):
                EncounterView(encounter: encounter)
            default:
                MainMenuView()
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