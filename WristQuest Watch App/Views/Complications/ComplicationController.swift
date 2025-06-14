import ClockKit
import SwiftUI

class ComplicationController: NSObject, CLKComplicationDataSource {
    
    // MARK: - Complication Configuration
    
    func getComplicationDescriptors(handler: @escaping ([CLKComplicationDescriptor]) -> Void) {
        let descriptors = [
            CLKComplicationDescriptor(identifier: "wrist_quest_main", displayName: "Wrist Quest", supportedFamilies: CLKComplicationFamily.allCases)
        ]
        
        handler(descriptors)
    }
    
    func handleSharedComplicationDescriptors(_ complicationDescriptors: [CLKComplicationDescriptor]) {
        // Do any necessary work to support these newly shared complication descriptors
    }
    
    // MARK: - Timeline Configuration
    
    func getTimelineEndDate(for complication: CLKComplication, withHandler handler: @escaping (Date?) -> Void) {
        // Call the handler with the last entry date you can provide or nil if you can't support future timelines
        handler(Date().addingTimeInterval(24 * 60 * 60)) // 24 hours from now
    }
    
    func getPrivacyBehavior(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationPrivacyBehavior) -> Void) {
        // Call the handler with your desired behavior when the device is locked
        handler(.showOnLockScreen)
    }
    
    // MARK: - Timeline Population
    
    func getCurrentTimelineEntry(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Void) {
        guard let template = createTemplate(for: complication.family) else {
            handler(nil)
            return
        }
        
        let entry = CLKComplicationTimelineEntry(date: Date(), complicationTemplate: template)
        handler(entry)
    }
    
    func getTimelineEntries(for complication: CLKComplication, after date: Date, limit: Int, withHandler handler: @escaping ([CLKComplicationTimelineEntry]?) -> Void) {
        var entries: [CLKComplicationTimelineEntry] = []
        
        // Create timeline entries for the next few hours
        for hour in 1...min(limit, 12) {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hour, to: date) ?? date
            if let template = createTemplate(for: complication.family) {
                let entry = CLKComplicationTimelineEntry(date: entryDate, complicationTemplate: template)
                entries.append(entry)
            }
        }
        
        handler(entries)
    }
    
    // MARK: - Sample Templates
    
    func getLocalizableSampleTemplate(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTemplate?) -> Void) {
        let template = createSampleTemplate(for: complication.family)
        handler(template)
    }
    
    // MARK: - Template Creation
    
    private func createTemplate(for family: CLKComplicationFamily) -> CLKComplicationTemplate? {
        let gameData = getCurrentGameData()
        
        switch family {
        case .modularSmall:
            return createModularSmallTemplate(gameData: gameData)
        case .modularLarge:
            return createModularLargeTemplate(gameData: gameData)
        case .utilitarianSmall:
            return createUtilitarianSmallTemplate(gameData: gameData)
        case .utilitarianSmallFlat:
            return createUtilitarianSmallFlatTemplate(gameData: gameData)
        case .utilitarianLarge:
            return createUtilitarianLargeTemplate(gameData: gameData)
        case .circularSmall:
            return createCircularSmallTemplate(gameData: gameData)
        case .extraLarge:
            return createExtraLargeTemplate(gameData: gameData)
        case .graphicCorner:
            return createGraphicCornerTemplate(gameData: gameData)
        case .graphicBezel:
            return createGraphicBezelTemplate(gameData: gameData)
        case .graphicCircular:
            return createGraphicCircularTemplate(gameData: gameData)
        case .graphicRectangular:
            return createGraphicRectangularTemplate(gameData: gameData)
        case .graphicExtraLarge:
            if #available(watchOS 7.0, *) {
                return createGraphicExtraLargeTemplate(gameData: gameData)
            }
            return nil
        @unknown default:
            return nil
        }
    }
    
    private func createSampleTemplate(for family: CLKComplicationFamily) -> CLKComplicationTemplate? {
        let sampleData = GameData(playerLevel: 5, xpProgress: 0.65, gold: 150, stepsToday: 2450, activeQuestName: "Goblin Caves")
        
        switch family {
        case .modularSmall:
            return createModularSmallTemplate(gameData: sampleData)
        case .modularLarge:
            return createModularLargeTemplate(gameData: sampleData)
        case .utilitarianSmall:
            return createUtilitarianSmallTemplate(gameData: sampleData)
        case .utilitarianSmallFlat:
            return createUtilitarianSmallFlatTemplate(gameData: sampleData)
        case .utilitarianLarge:
            return createUtilitarianLargeTemplate(gameData: sampleData)
        case .circularSmall:
            return createCircularSmallTemplate(gameData: sampleData)
        case .extraLarge:
            return createExtraLargeTemplate(gameData: sampleData)
        case .graphicCorner:
            return createGraphicCornerTemplate(gameData: sampleData)
        case .graphicBezel:
            return createGraphicBezelTemplate(gameData: sampleData)
        case .graphicCircular:
            return createGraphicCircularTemplate(gameData: sampleData)
        case .graphicRectangular:
            return createGraphicRectangularTemplate(gameData: sampleData)
        case .graphicExtraLarge:
            if #available(watchOS 7.0, *) {
                return createGraphicExtraLargeTemplate(gameData: sampleData)
            }
            return nil
        @unknown default:
            return nil
        }
    }
    
    // MARK: - Individual Template Creators
    
    private func createModularSmallTemplate(gameData: GameData) -> CLKComplicationTemplateModularSmallStackText {
        let template = CLKComplicationTemplateModularSmallStackText()
        template.line1TextProvider = CLKSimpleTextProvider(text: "L\(gameData.playerLevel)")
        template.line2TextProvider = CLKSimpleTextProvider(text: "\(Int(gameData.xpProgress * 100))%")
        return template
    }
    
    private func createModularLargeTemplate(gameData: GameData) -> CLKComplicationTemplateModularLargeStandardBody {
        let template = CLKComplicationTemplateModularLargeStandardBody()
        template.headerTextProvider = CLKSimpleTextProvider(text: "Wrist Quest")
        template.body1TextProvider = CLKSimpleTextProvider(text: "Level \(gameData.playerLevel) • \(gameData.gold)g")
        template.body2TextProvider = CLKSimpleTextProvider(text: "\(gameData.stepsToday) steps today")
        return template
    }
    
    private func createUtilitarianSmallTemplate(gameData: GameData) -> CLKComplicationTemplateUtilitarianSmallFlat {
        let template = CLKComplicationTemplateUtilitarianSmallFlat()
        template.textProvider = CLKSimpleTextProvider(text: "L\(gameData.playerLevel)")
        return template
    }
    
    private func createUtilitarianSmallFlatTemplate(gameData: GameData) -> CLKComplicationTemplateUtilitarianSmallFlat {
        let template = CLKComplicationTemplateUtilitarianSmallFlat()
        template.textProvider = CLKSimpleTextProvider(text: "\(gameData.stepsToday)")
        return template
    }
    
    private func createUtilitarianLargeTemplate(gameData: GameData) -> CLKComplicationTemplateUtilitarianLargeFlat {
        let template = CLKComplicationTemplateUtilitarianLargeFlat()
        template.textProvider = CLKSimpleTextProvider(text: "WQ: L\(gameData.playerLevel) • \(gameData.stepsToday) steps")
        return template
    }
    
    private func createCircularSmallTemplate(gameData: GameData) -> CLKComplicationTemplateCircularSmallStackText {
        let template = CLKComplicationTemplateCircularSmallStackText()
        template.line1TextProvider = CLKSimpleTextProvider(text: "\(gameData.playerLevel)")
        template.line2TextProvider = CLKSimpleTextProvider(text: "LVL")
        return template
    }
    
    private func createExtraLargeTemplate(gameData: GameData) -> CLKComplicationTemplateExtraLargeStackText {
        let template = CLKComplicationTemplateExtraLargeStackText()
        template.line1TextProvider = CLKSimpleTextProvider(text: "Level \(gameData.playerLevel)")
        template.line2TextProvider = CLKSimpleTextProvider(text: "\(Int(gameData.xpProgress * 100))% XP")
        return template
    }
    
    private func createGraphicCornerTemplate(gameData: GameData) -> CLKComplicationTemplateGraphicCornerStackText {
        let template = CLKComplicationTemplateGraphicCornerStackText()
        template.outerTextProvider = CLKSimpleTextProvider(text: "WQ")
        template.innerTextProvider = CLKSimpleTextProvider(text: "\(gameData.playerLevel)")
        return template
    }
    
    private func createGraphicBezelTemplate(gameData: GameData) -> CLKComplicationTemplateGraphicBezelCircularText {
        let template = CLKComplicationTemplateGraphicBezelCircularText()
        template.textProvider = CLKSimpleTextProvider(text: "Level \(gameData.playerLevel) • \(gameData.gold) Gold")
        template.circularTemplate = createGraphicCircularTemplate(gameData: gameData) as! CLKComplicationTemplateGraphicCircular
        return template
    }
    
    private func createGraphicCircularTemplate(gameData: GameData) -> CLKComplicationTemplateGraphicCircularStackText {
        let template = CLKComplicationTemplateGraphicCircularStackText()
        template.line1TextProvider = CLKSimpleTextProvider(text: "L\(gameData.playerLevel)")
        template.line2TextProvider = CLKSimpleTextProvider(text: "\(Int(gameData.xpProgress * 100))%")
        return template
    }
    
    private func createGraphicRectangularTemplate(gameData: GameData) -> CLKComplicationTemplateGraphicRectangularStandardBody {
        let template = CLKComplicationTemplateGraphicRectangularStandardBody()
        template.headerTextProvider = CLKSimpleTextProvider(text: "Wrist Quest")
        template.body1TextProvider = CLKSimpleTextProvider(text: "Level \(gameData.playerLevel)")
        template.body2TextProvider = CLKSimpleTextProvider(text: gameData.activeQuestName ?? "No active quest")
        return template
    }
    
    @available(watchOS 7.0, *)
    private func createGraphicExtraLargeTemplate(gameData: GameData) -> CLKComplicationTemplateGraphicExtraLargeCircularStackText {
        let template = CLKComplicationTemplateGraphicExtraLargeCircularStackText()
        template.line1TextProvider = CLKSimpleTextProvider(text: "Level \(gameData.playerLevel)")
        template.line2TextProvider = CLKSimpleTextProvider(text: "\(Int(gameData.xpProgress * 100))% XP")
        return template
    }
    
    // MARK: - Data Helpers
    
    private func getCurrentGameData() -> GameData {
        // In a real implementation, this would fetch current game state
        // For now, return sample data
        return GameData(
            playerLevel: 3,
            xpProgress: 0.45,
            gold: 85,
            stepsToday: 1234,
            activeQuestName: "Village Outskirts"
        )
    }
}

struct GameData {
    let playerLevel: Int
    let xpProgress: Double
    let gold: Int
    let stepsToday: Int
    let activeQuestName: String?
}

extension CLKComplicationFamily: CaseIterable {
    public static var allCases: [CLKComplicationFamily] {
        var cases: [CLKComplicationFamily] = [
            .modularSmall,
            .modularLarge,
            .utilitarianSmall,
            .utilitarianSmallFlat,
            .utilitarianLarge,
            .circularSmall,
            .extraLarge,
            .graphicCorner,
            .graphicBezel,
            .graphicCircular,
            .graphicRectangular
        ]
        
        if #available(watchOS 7.0, *) {
            cases.append(.graphicExtraLarge)
        }
        
        return cases
    }
}