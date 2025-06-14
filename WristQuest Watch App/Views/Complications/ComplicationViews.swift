import SwiftUI
import ClockKit
import WidgetKit

// MARK: - Complication View Builder
struct WristQuestComplicationView: View {
	let entry: WristQuestComplicationEntry
	let family: CLKComplicationFamily
	
	var body: some View {
		Group {
			switch family {
			case .modularSmall:
				ModularSmallView(entry: entry)
			case .modularLarge:
				ModularLargeView(entry: entry)
			case .utilitarianSmall:
				UtilitarianSmallView(entry: entry)
			case .utilitarianSmallFlat:
				UtilitarianSmallFlatView(entry: entry)
			case .utilitarianLarge:
				UtilitarianLargeView(entry: entry)
			case .circularSmall:
				CircularSmallView(entry: entry)
			case .extraLarge:
				ExtraLargeView(entry: entry)
			case .graphicCorner:
				GraphicCornerView(entry: entry)
			case .graphicBezel:
				GraphicBezelView(entry: entry)
			case .graphicCircular:
				GraphicCircularView(entry: entry)
			case .graphicRectangular:
				GraphicRectangularView(entry: entry)
			case .graphicExtraLarge:
				GraphicExtraLargeView(entry: entry)
			@unknown default:
				Text("Unsupported")
					.font(.caption2)
					.foregroundColor(.white)
			}
		}
	}
	
	// MARK: - Complication Data Model
	struct WristQuestComplicationEntry: TimelineEntry {
		let date: Date
		let playerLevel: Int
		let xpProgress: Double
		let currentSteps: Int
		let questName: String?
		let questProgress: Double
		let hasActiveQuest: Bool
		
		static let placeholder = WristQuestComplicationEntry(
			date: Date(),
			playerLevel: 5,
			xpProgress: 0.75,
			currentSteps: 6500,
			questName: "Goblin Caves",
			questProgress: 0.6,
			hasActiveQuest: true
		)
	}
	
	// MARK: - Small Complications
	struct ModularSmallView: View {
		let entry: WristQuestComplicationEntry
		
		var body: some View {
			VStack(spacing: 1) {
				HStack {
					Text("Lv")
						.font(.caption2)
						.foregroundColor(.white.opacity(0.7))
					
					Text("\(entry.playerLevel)")
						.font(.headline)
						.fontWeight(.bold)
						.foregroundColor(WQDesignSystem.Colors.primary)
				}
				
				ProgressView(value: entry.xpProgress)
					.progressViewStyle(LinearProgressViewStyle(tint: WQDesignSystem.Colors.primary))
					.scaleEffect(y: 0.5)
			}
			.padding(4)
		}
	}
	
	struct CircularSmallView: View {
		let entry: WristQuestComplicationEntry
		
		var body: some View {
			ZStack {
				Circle()
					.stroke(WQDesignSystem.Colors.primary.opacity(0.3), lineWidth: 3)
				
				Circle()
					.trim(from: 0, to: entry.xpProgress)
					.stroke(WQDesignSystem.Colors.primary, style: StrokeStyle(lineWidth: 3, lineCap: .round))
					.rotationEffect(.degrees(-90))
				
				VStack(spacing: 0) {
					Text("\(entry.playerLevel)")
						.font(.title3)
						.fontWeight(.bold)
						.foregroundColor(.white)
					
					Text("LV")
						.font(.caption2)
						.foregroundColor(.white.opacity(0.7))
				}
			}
			.padding(4)
		}
	}
	
	struct UtilitarianSmallView: View {
		let entry: WristQuestComplicationEntry
		
		var body: some View {
			HStack(spacing: 2) {
				Image(systemName: "star.fill")
					.foregroundColor(WQDesignSystem.Colors.primary)
					.font(.caption)
				
				Text("L\(entry.playerLevel)")
					.font(.system(.caption, design: .rounded))
					.fontWeight(.semibold)
					.foregroundColor(.white)
			}
		}
	}
	
	struct UtilitarianSmallFlatView: View {
		let entry: WristQuestComplicationEntry
		
		var body: some View {
			HStack(spacing: 3) {
				Image(systemName: "figure.walk")
					.foregroundColor(WQDesignSystem.Colors.success)
					.font(.caption2)
				
				Text("\(entry.currentSteps)")
					.font(.system(.caption, design: .rounded))
					.fontWeight(.medium)
					.foregroundColor(.white)
			}
		}
	}
	
	// MARK: - Medium Complications
	struct UtilitarianLargeView: View {
		let entry: WristQuestComplicationEntry
		
		var body: some View {
			HStack {
				VStack(alignment: .leading, spacing: 1) {
					Text("Level \(entry.playerLevel)")
						.font(.caption)
						.fontWeight(.semibold)
						.foregroundColor(.white)
					
					Text("\(Int(entry.xpProgress * 100))% XP")
						.font(.caption2)
						.foregroundColor(.white.opacity(0.7))
				}
				
				Spacer()
				
				if entry.hasActiveQuest {
					VStack(alignment: .trailing, spacing: 1) {
						Text("Quest")
							.font(.caption2)
							.foregroundColor(.white.opacity(0.7))
						
						Text("\(Int(entry.questProgress * 100))%")
							.font(.caption)
							.fontWeight(.semibold)
							.foregroundColor(WQDesignSystem.Colors.questGold)
					}
				} else {
					Image(systemName: "figure.walk")
						.foregroundColor(WQDesignSystem.Colors.success)
						.font(.title3)
				}
			}
			.padding(.horizontal, 4)
		}
	}
	
	struct ModularLargeView: View {
		let entry: WristQuestComplicationEntry
		
		var body: some View {
			VStack(spacing: 4) {
				// Header
				HStack {
					HStack(spacing: 3) {
						Image(systemName: "star.fill")
							.foregroundColor(WQDesignSystem.Colors.primary)
							.font(.caption)
						
						Text("Level \(entry.playerLevel)")
							.font(.caption)
							.fontWeight(.semibold)
							.foregroundColor(.white)
					}
					
					Spacer()
					
					HStack(spacing: 3) {
						Image(systemName: "figure.walk")
							.foregroundColor(WQDesignSystem.Colors.success)
							.font(.caption)
						
						Text("\(entry.currentSteps)")
							.font(.caption)
							.fontWeight(.medium)
							.foregroundColor(.white)
					}
				}
				
				// XP Progress
				VStack(alignment: .leading, spacing: 2) {
					HStack {
						Text("XP Progress")
							.font(.caption2)
							.foregroundColor(.white.opacity(0.7))
						
						Spacer()
						
						Text("\(Int(entry.xpProgress * 100))%")
							.font(.caption2)
							.foregroundColor(WQDesignSystem.Colors.primary)
					}
					
					ProgressView(value: entry.xpProgress)
						.progressViewStyle(LinearProgressViewStyle(tint: WQDesignSystem.Colors.primary))
						.scaleEffect(y: 0.7)
				}
				
				// Quest Progress (if active)
				if entry.hasActiveQuest, let questName = entry.questName {
					VStack(alignment: .leading, spacing: 2) {
						HStack {
							Text(questName)
								.font(.caption2)
								.foregroundColor(.white.opacity(0.7))
								.lineLimit(1)
							
							Spacer()
							
							Text("\(Int(entry.questProgress * 100))%")
								.font(.caption2)
								.foregroundColor(WQDesignSystem.Colors.questGold)
						}
						
						ProgressView(value: entry.questProgress)
							.progressViewStyle(LinearProgressViewStyle(tint: WQDesignSystem.Colors.questGold))
							.scaleEffect(y: 0.7)
					}
				}
			}
			.padding(6)
		}
	}
	
	// MARK: - Large Complications
	struct ExtraLargeView: View {
		let entry: WristQuestComplicationEntry
		
		var body: some View {
			VStack(spacing: 8) {
				// Large level display
				VStack(spacing: 2) {
					Text("LEVEL")
						.font(.caption2)
						.fontWeight(.medium)
						.foregroundColor(.white.opacity(0.6))
					
					Text("\(entry.playerLevel)")
						.font(.system(size: 36, weight: .bold, design: .rounded))
						.foregroundColor(.white)
				}
				
				// XP Progress ring
				ZStack {
					Circle()
						.stroke(WQDesignSystem.Colors.primary.opacity(0.2), lineWidth: 6)
						.frame(width: 60, height: 60)
					
					Circle()
						.trim(from: 0, to: entry.xpProgress)
						.stroke(WQDesignSystem.Colors.primary, style: StrokeStyle(lineWidth: 6, lineCap: .round))
						.frame(width: 60, height: 60)
						.rotationEffect(.degrees(-90))
					
					Text("\(Int(entry.xpProgress * 100))%")
						.font(.caption)
						.fontWeight(.semibold)
						.foregroundColor(.white)
				}
				
				// Activity indicator
				HStack(spacing: 4) {
					Image(systemName: "figure.walk")
						.foregroundColor(WQDesignSystem.Colors.success)
						.font(.caption)
					
					Text("\(entry.currentSteps) steps")
						.font(.caption)
						.foregroundColor(.white.opacity(0.8))
				}
			}
		}
	}
	
	// MARK: - Graphic Complications
	struct GraphicCircularView: View {
		let entry: WristQuestComplicationEntry
		
		var body: some View {
			ZStack {
				// Background
				Circle()
					.fill(WQDesignSystem.Colors.backgroundSecondary)
				
				// XP Progress
				Circle()
					.stroke(WQDesignSystem.Colors.primary.opacity(0.3), lineWidth: 4)
					.overlay(
						Circle()
							.trim(from: 0, to: entry.xpProgress)
							.stroke(WQDesignSystem.Colors.primary, style: StrokeStyle(lineWidth: 4, lineCap: .round))
							.rotationEffect(.degrees(-90))
					)
				
				// Center content
				VStack(spacing: 1) {
					Image(systemName: "star.fill")
						.foregroundColor(WQDesignSystem.Colors.primary)
						.font(.title3)
					
					Text("\(entry.playerLevel)")
						.font(.title2)
						.fontWeight(.bold)
						.foregroundColor(.white)
				}
			}
		}
	}
	
	struct GraphicRectangularView: View {
		let entry: WristQuestComplicationEntry
		
		var body: some View {
			VStack(spacing: 4) {
				// Header with level and steps
				HStack {
					HStack(spacing: 3) {
						Image(systemName: "star.fill")
							.foregroundColor(WQDesignSystem.Colors.primary)
							.font(.caption)
						
						Text("Level \(entry.playerLevel)")
							.font(.headline)
							.fontWeight(.semibold)
							.foregroundColor(.white)
					}
					
					Spacer()
					
					HStack(spacing: 3) {
						Image(systemName: "figure.walk")
							.foregroundColor(WQDesignSystem.Colors.success)
							.font(.caption)
						
						Text("\(entry.currentSteps)")
							.font(.subheadline)
							.fontWeight(.medium)
							.foregroundColor(.white)
					}
				}
				
				// Progress indicators
				VStack(spacing: 3) {
					// XP Progress
					VStack(alignment: .leading, spacing: 1) {
						HStack {
							Text("Experience")
								.font(.caption2)
								.foregroundColor(.white.opacity(0.7))
							
							Spacer()
							
							Text("\(Int(entry.xpProgress * 100))%")
								.font(.caption2)
								.fontWeight(.semibold)
								.foregroundColor(WQDesignSystem.Colors.primary)
						}
						
						ProgressView(value: entry.xpProgress)
							.progressViewStyle(LinearProgressViewStyle(tint: WQDesignSystem.Colors.primary))
							.scaleEffect(y: 0.6)
					}
					
					// Quest Progress (if active)
					if entry.hasActiveQuest, let questName = entry.questName {
						VStack(alignment: .leading, spacing: 1) {
							HStack {
								Text(questName)
									.font(.caption2)
									.foregroundColor(.white.opacity(0.7))
									.lineLimit(1)
								
								Spacer()
								
								Text("\(Int(entry.questProgress * 100))%")
									.font(.caption2)
									.fontWeight(.semibold)
									.foregroundColor(WQDesignSystem.Colors.questGold)
							}
							
							ProgressView(value: entry.questProgress)
								.progressViewStyle(LinearProgressViewStyle(tint: WQDesignSystem.Colors.questGold))
								.scaleEffect(y: 0.6)
						}
					}
				}
			}
			.padding(6)
			.background(WQDesignSystem.Colors.backgroundSecondary)
			.clipShape(RoundedRectangle(cornerRadius: 8))
		}
	}
	
	struct GraphicCornerView: View {
		let entry: WristQuestComplicationEntry
		
		var body: some View {
			VStack(alignment: .trailing, spacing: 2) {
				HStack {
					Spacer()
					
					Text("L\(entry.playerLevel)")
						.font(.system(.title3, design: .rounded))
						.fontWeight(.bold)
						.foregroundColor(.white)
				}
				
				HStack {
					Spacer()
					
					VStack(alignment: .trailing, spacing: 1) {
						ProgressView(value: entry.xpProgress)
							.progressViewStyle(LinearProgressViewStyle(tint: WQDesignSystem.Colors.primary))
							.frame(width: 40)
							.scaleEffect(y: 0.5)
						
						Text("\(Int(entry.xpProgress * 100))%")
							.font(.caption2)
							.foregroundColor(WQDesignSystem.Colors.primary)
					}
				}
			}
			.padding(4)
		}
	}
	
	struct GraphicBezelView: View {
		let entry: WristQuestComplicationEntry
		
		var body: some View {
			ZStack {
				// Center circular view
				GraphicCircularView(entry: entry)
					.frame(width: 44, height: 44)
				
				// Bezel text
				VStack {
					Spacer()
					
					HStack {
						if entry.hasActiveQuest, let questName = entry.questName {
							Text("\(questName) - \(Int(entry.questProgress * 100))%")
								.font(.caption2)
								.foregroundColor(.white.opacity(0.8))
								.lineLimit(1)
						} else {
							Text("\(entry.currentSteps) steps today")
								.font(.caption2)
								.foregroundColor(.white.opacity(0.8))
						}
					}
					.padding(.bottom, 4)
				}
			}
		}
	}
	
	struct GraphicExtraLargeView: View {
		let entry: WristQuestComplicationEntry
		
		var body: some View {
			VStack(spacing: 12) {
				// Hero section
				VStack(spacing: 4) {
					HStack {
						Image(systemName: "star.fill")
							.foregroundColor(WQDesignSystem.Colors.primary)
							.font(.title2)
						
						Text("Level \(entry.playerLevel)")
							.font(.title)
							.fontWeight(.bold)
							.foregroundColor(.white)
						
						Spacer()
					}
					
					HStack {
						Text("Experience Progress")
							.font(.caption)
							.foregroundColor(.white.opacity(0.7))
						
						Spacer()
						
						Text("\(Int(entry.xpProgress * 100))%")
							.font(.caption)
							.fontWeight(.semibold)
							.foregroundColor(WQDesignSystem.Colors.primary)
					}
					
					ProgressView(value: entry.xpProgress)
						.progressViewStyle(LinearProgressViewStyle(tint: WQDesignSystem.Colors.primary))
						.scaleEffect(y: 0.8)
				}
				
				// Activity and quest section
				HStack(spacing: 16) {
					// Activity
					VStack(alignment: .leading, spacing: 2) {
						HStack {
							Image(systemName: "figure.walk")
								.foregroundColor(WQDesignSystem.Colors.success)
								.font(.caption)
							
							Text("Steps Today")
								.font(.caption2)
								.foregroundColor(.white.opacity(0.7))
						}
						
						Text("\(entry.currentSteps)")
							.font(.title3)
							.fontWeight(.semibold)
							.foregroundColor(.white)
					}
					
					Spacer()
					
					// Quest (if active)
					if entry.hasActiveQuest, let questName = entry.questName {
						VStack(alignment: .trailing, spacing: 2) {
							HStack {
								Text("Active Quest")
									.font(.caption2)
									.foregroundColor(.white.opacity(0.7))
								
								Image(systemName: "map.fill")
									.foregroundColor(WQDesignSystem.Colors.questGold)
									.font(.caption)
							}
							
							VStack(alignment: .trailing, spacing: 1) {
								Text(questName)
									.font(.caption)
									.fontWeight(.medium)
									.foregroundColor(.white)
									.lineLimit(1)
								
								Text("\(Int(entry.questProgress * 100))% complete")
									.font(.caption2)
									.foregroundColor(WQDesignSystem.Colors.questGold)
							}
						}
					}
				}
			}
			.padding(8)
			.background(WQDesignSystem.Colors.backgroundSecondary)
			.clipShape(RoundedRectangle(cornerRadius: 12))
		}
	}
}
