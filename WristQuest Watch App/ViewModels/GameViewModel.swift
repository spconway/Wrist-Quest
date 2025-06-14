import Foundation
import SwiftUI
import Combine

enum GameState: Equatable {
    case onboarding
    case characterCreation
    case mainMenu
    case activeQuest(Quest)
    case encounter(Encounter)
    case inventory
    case journal
    case settings
    
    static func == (lhs: GameState, rhs: GameState) -> Bool {
        switch (lhs, rhs) {
        case (.onboarding, .onboarding),
             (.characterCreation, .characterCreation),
             (.mainMenu, .mainMenu),
             (.inventory, .inventory),
             (.journal, .journal),
             (.settings, .settings):
            return true
        case (.activeQuest(let lQuest), .activeQuest(let rQuest)):
            return lQuest.id == rQuest.id
        case (.encounter(let lEncounter), .encounter(let rEncounter)):
            return lEncounter.id == rEncounter.id
        default:
            return false
        }
    }
}

@MainActor
class GameViewModel: ObservableObject {
    @Published var gameState: GameState = .onboarding
    @Published var currentPlayer: Player?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    
    // Services
    private let persistenceService: PersistenceServiceProtocol
    private let healthService: HealthServiceProtocol
    
    init(persistenceService: PersistenceServiceProtocol = PersistenceService(),
         healthService: HealthServiceProtocol = HealthService()) {
        self.persistenceService = persistenceService
        self.healthService = healthService
        
        setupSubscriptions()
        loadGameState()
    }
    
    private func setupSubscriptions() {
        healthService.healthDataPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] healthData in
                self?.handleHealthDataUpdate(healthData)
            }
            .store(in: &cancellables)
    }
    
    private func loadGameState() {
        isLoading = true
        
        Task {
            do {
                if let savedPlayer = try await persistenceService.loadPlayer() {
                    currentPlayer = savedPlayer
                    gameState = .mainMenu
                } else {
                    gameState = .onboarding
                }
            } catch {
                errorMessage = "Failed to load game: \(error.localizedDescription)"
                gameState = .onboarding
            }
            
            isLoading = false
        }
    }
    
    func startGame(with player: Player) {
        currentPlayer = player
        gameState = .mainMenu
        
        Task {
            do {
                try await persistenceService.savePlayer(player)
            } catch {
                errorMessage = "Failed to save player: \(error.localizedDescription)"
            }
        }
    }
    
    func transitionTo(_ newState: GameState) {
        gameState = newState
    }
    
    func handleError(_ error: Error) {
        errorMessage = error.localizedDescription
    }
    
    func clearError() {
        errorMessage = nil
    }
    
    private func handleHealthDataUpdate(_ healthData: HealthData) {
        guard var player = currentPlayer else { return }
        
        player.stepsToday = healthData.steps
        currentPlayer = player
        
        Task {
            do {
                try await persistenceService.savePlayer(player)
            } catch {
                handleError(error)
            }
        }
    }
    
    // MARK: - Active Quest Support
    var activeQuest: Quest? {
        // This would be loaded from persistence or game state
        // For now, returning nil - implement based on your quest system
        return nil
    }
    
    // MARK: - Debug Methods
    func addDebugXP(_ amount: Int) {
        guard var player = currentPlayer else { return }
        
        player.xp += amount
        
        // Check for level up
        let newLevel = (player.xp / 100) + 1
        if newLevel > player.level {
            player.level = newLevel
            // Could trigger level up celebration here
        }
        
        currentPlayer = player
        
        Task {
            do {
                try await persistenceService.savePlayer(player)
            } catch {
                handleError(error)
            }
        }
    }
    
    func resetOnboarding() {
        currentPlayer = nil
        gameState = .onboarding
        
        Task {
            do {
                try await persistenceService.clearPlayerData()
            } catch {
                handleError(error)
            }
        }
    }
}