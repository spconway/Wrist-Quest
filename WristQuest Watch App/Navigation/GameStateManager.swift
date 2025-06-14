import Foundation
import SwiftUI
import Combine

@MainActor
class GameStateManager: ObservableObject {
    @Published var currentState: GameState = .onboarding
    @Published var isTransitioning = false
    
    private let navigationCoordinator: NavigationCoordinator
    private var cancellables = Set<AnyCancellable>()
    
    init(navigationCoordinator: NavigationCoordinator) {
        self.navigationCoordinator = navigationCoordinator
        setupStateObservation()
    }
    
    private func setupStateObservation() {
        $currentState
            .dropFirst()
            .sink { [weak self] newState in
                self?.handleStateTransition(to: newState)
            }
            .store(in: &cancellables)
    }
    
    func transitionTo(_ newState: GameState) {
        guard !isTransitioning else { return }
        
        isTransitioning = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.currentState = newState
            self.isTransitioning = false
        }
    }
    
    private func handleStateTransition(to newState: GameState) {
        switch newState {
        case .onboarding:
            navigationCoordinator.presentFullScreenCover(.onboarding)
            
        case .characterCreation:
            navigationCoordinator.presentFullScreenCover(.characterCreation)
            
        case .mainMenu:
            navigationCoordinator.dismissFullScreenCover()
            navigationCoordinator.popToRoot()
            
        case .activeQuest(let quest):
            navigationCoordinator.navigate(to: .questDetail(quest))
            
        case .encounter(let encounter):
            navigationCoordinator.navigate(to: .encounter(encounter))
            
        case .inventory:
            navigationCoordinator.navigate(to: .inventory)
            
        case .journal:
            navigationCoordinator.navigate(to: .journal)
            
        case .settings:
            navigationCoordinator.navigate(to: .settings)
        }
    }
    
    func handleDeepLink(_ url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let host = components.host else { return }
        
        switch host {
        case "quest":
            // For now, just transition to main menu - would need actual quest data
            transitionTo(.mainMenu)
        case "character":
            transitionTo(.inventory)
        case "journal":
            transitionTo(.journal)
        default:
            break
        }
    }
    
    func canTransition(to newState: GameState) -> Bool {
        switch (currentState, newState) {
        case (.onboarding, .characterCreation),
             (.characterCreation, .mainMenu),
             (.mainMenu, _),
             (_, .onboarding):
            return true
        default:
            return currentState == newState
        }
    }
}
