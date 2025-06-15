import Foundation
import SwiftUI

@MainActor
class NavigationCoordinator: ObservableObject {
    @Published var navigationPath = NavigationPath()
    @Published var presentedSheet: SheetDestination?
    @Published var presentedFullScreenCover: FullScreenDestination?
    
    enum Destination: Hashable {
        case questList
        case questDetail(Quest)
        case activeQuest
        case encounter(Encounter)
        case characterDetail
        case inventory
        case journal
        case settings
    }
    
    enum SheetDestination: Identifiable {
        case itemDetail(Item)
        case questLog(QuestLog)
        case levelUpReward([String])
        case error(String)
        
        var id: String {
            switch self {
            case .itemDetail(let item):
                return "item-\(item.id)"
            case .questLog(let log):
                return "log-\(log.id)"
            case .levelUpReward:
                return "levelup"
            case .error:
                return "error"
            }
        }
    }
    
    enum FullScreenDestination: Identifiable {
        case onboarding
        case characterCreation
        
        var id: String {
            switch self {
            case .onboarding:
                return "onboarding"
            case .characterCreation:
                return "characterCreation"
            }
        }
    }
    
    func navigate(to destination: Destination) {
        navigationPath.append(destination)
    }
    
    func popToRoot() {
        navigationPath.removeLast(navigationPath.count)
    }
    
    func pop() {
        guard !navigationPath.isEmpty else { return }
        navigationPath.removeLast()
    }
    
    func presentSheet(_ sheet: SheetDestination) {
        presentedSheet = sheet
    }
    
    func presentFullScreenCover(_ cover: FullScreenDestination) {
        presentedFullScreenCover = cover
    }
    
    func dismissSheet() {
        presentedSheet = nil
    }
    
    func dismissFullScreenCover() {
        presentedFullScreenCover = nil
    }
}
