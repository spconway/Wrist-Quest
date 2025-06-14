import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var gameViewModel: GameViewModel
    @EnvironmentObject private var healthViewModel: HealthViewModel
    @EnvironmentObject private var navigationCoordinator: NavigationCoordinator
    
    var body: some View {
        List {
            Section {
                HealthSettingsView()
            } header: {
                Text("Health & Privacy")
                    .font(WQDesignSystem.Typography.caption)
                    .foregroundColor(WQDesignSystem.Colors.secondaryText)
            }
            
            Section {
                GameSettingsView()
            } header: {
                Text("Game Settings")
                    .font(WQDesignSystem.Typography.caption)
                    .foregroundColor(WQDesignSystem.Colors.secondaryText)
            }
            
            Section {
                AccessibilitySettingsView()
            } header: {
                Text("Accessibility")
                    .font(WQDesignSystem.Typography.caption)
                    .foregroundColor(WQDesignSystem.Colors.secondaryText)
            }
            
            Section {
                AboutView()
            } header: {
                Text("About")
                    .font(WQDesignSystem.Typography.caption)
                    .foregroundColor(WQDesignSystem.Colors.secondaryText)
            }
            
            #if DEBUG
            Section {
                DebugSettingsView()
            } header: {
                Text("Debug")
                    .font(WQDesignSystem.Typography.caption)
                    .foregroundColor(WQDesignSystem.Colors.secondaryText)
            }
            #endif
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct HealthSettingsView: View {
    @EnvironmentObject private var healthViewModel: HealthViewModel
    @State private var showingHealthApp = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: WQDesignSystem.Spacing.sm) {
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundColor(healthStatusColor)
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: WQDesignSystem.Spacing.xs) {
                    Text("Health Data Access")
                        .font(WQDesignSystem.Typography.body)
                        .foregroundColor(WQDesignSystem.Colors.primaryText)
                    
                    Text(healthStatusText)
                        .font(WQDesignSystem.Typography.caption)
                        .foregroundColor(WQDesignSystem.Colors.secondaryText)
                }
                
                Spacer()
                
                Button("Manage") {
                    showingHealthApp = true
                }
                .font(WQDesignSystem.Typography.caption)
                .foregroundColor(WQDesignSystem.Colors.accent)
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: WQDesignSystem.Spacing.xs) {
                Text("Data Usage")
                    .font(WQDesignSystem.Typography.caption.weight(.medium))
                    .foregroundColor(WQDesignSystem.Colors.primaryText)
                
                Text("Wrist Quest uses your health data to:")
                    .font(WQDesignSystem.Typography.footnote)
                    .foregroundColor(WQDesignSystem.Colors.secondaryText)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("• Convert steps to quest progress")
                    Text("• Use heart rate for combat encounters")
                    Text("• Apply stand hours as XP bonuses")
                    Text("• Transform exercise into game resources")
                }
                .font(WQDesignSystem.Typography.footnote)
                .foregroundColor(WQDesignSystem.Colors.tertiaryText)
            }
        }
        .padding(WQDesignSystem.Spacing.md)
        .background(WQDesignSystem.Colors.secondaryBackground)
        .cornerRadius(WQDesignSystem.CornerRadius.lg)
        .sheet(isPresented: $showingHealthApp) {
            Text("Open Health app to manage permissions")
                .padding()
        }
    }
    
    private var healthStatusColor: Color {
        switch healthViewModel.authorizationStatus {
        case .authorized: return WQDesignSystem.Colors.success
        case .denied: return WQDesignSystem.Colors.error
        case .restricted: return WQDesignSystem.Colors.warning
        case .notDetermined: return WQDesignSystem.Colors.accent
        }
    }
    
    private var healthStatusText: String {
        switch healthViewModel.authorizationStatus {
        case .authorized: return "Connected and active"
        case .denied: return "Access denied - limited functionality"
        case .restricted: return "Health data restricted"
        case .notDetermined: return "Tap Manage to grant access"
        }
    }
}

struct GameSettingsView: View {
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("hapticFeedbackEnabled") private var hapticFeedbackEnabled = true
    @AppStorage("autoStartQuests") private var autoStartQuests = false
    @AppStorage("combatModeThreshold") private var combatModeThreshold = 120.0
    
    var body: some View {
        VStack(spacing: WQDesignSystem.Spacing.md) {
            SettingToggleRow(
                icon: "bell.fill",
                title: "Notifications",
                description: "Quest updates and achievements",
                isOn: $notificationsEnabled
            )
            
            SettingToggleRow(
                icon: "hand.tap.fill",
                title: "Haptic Feedback",
                description: "Vibrations for game events",
                isOn: $hapticFeedbackEnabled
            )
            
            SettingToggleRow(
                icon: "play.fill",
                title: "Auto-Start Quests",
                description: "Begin new quests automatically",
                isOn: $autoStartQuests
            )
            
            VStack(alignment: .leading, spacing: WQDesignSystem.Spacing.sm) {
                HStack {
                    Image(systemName: "bolt.heart.fill")
                        .foregroundColor(WQDesignSystem.Colors.questRed)
                        .font(.title3)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: WQDesignSystem.Spacing.xs) {
                        Text("Combat Mode Threshold")
                            .font(WQDesignSystem.Typography.body)
                            .foregroundColor(WQDesignSystem.Colors.primaryText)
                        
                        Text("\(Int(combatModeThreshold)) BPM")
                            .font(WQDesignSystem.Typography.caption)
                            .foregroundColor(WQDesignSystem.Colors.secondaryText)
                    }
                    
                    Spacer()
                }
                
                Slider(value: $combatModeThreshold, in: 100...160, step: 5)
                    .accentColor(WQDesignSystem.Colors.questRed)
            }
        }
        .padding(WQDesignSystem.Spacing.md)
        .background(WQDesignSystem.Colors.secondaryBackground)
        .cornerRadius(WQDesignSystem.CornerRadius.lg)
    }
}

struct AccessibilitySettingsView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    var body: some View {
        VStack(spacing: WQDesignSystem.Spacing.md) {
            AccessibilityInfoRow(
                icon: "textformat.size",
                title: "Text Size",
                value: dynamicTypeSize.description,
                action: {
                    // Open Settings app
                }
            )
            
            AccessibilityInfoRow(
                icon: "motion.badge.minus",
                title: "Reduce Motion",
                value: reduceMotion ? "On" : "Off",
                action: {
                    // Open Settings app
                }
            )
            
            AccessibilityInfoRow(
                icon: "speaker.wave.3.fill",
                title: "VoiceOver",
                value: "Supported",
                action: nil
            )
        }
        .padding(WQDesignSystem.Spacing.md)
        .background(WQDesignSystem.Colors.secondaryBackground)
        .cornerRadius(WQDesignSystem.CornerRadius.lg)
    }
}

struct AboutView: View {
    var body: some View {
        VStack(spacing: WQDesignSystem.Spacing.md) {
            HStack {
                Image(systemName: "applewatch")
                    .font(.largeTitle)
                    .foregroundColor(WQDesignSystem.Colors.accent)
                
                VStack(alignment: .leading, spacing: WQDesignSystem.Spacing.xs) {
                    Text("Wrist Quest")
                        .font(WQDesignSystem.Typography.headline)
                        .foregroundColor(WQDesignSystem.Colors.primaryText)
                    
                    Text("Version 1.0.0")
                        .font(WQDesignSystem.Typography.caption)
                        .foregroundColor(WQDesignSystem.Colors.secondaryText)
                }
                
                Spacer()
            }
            
            Text("Turn your daily activity into epic fantasy adventures. Every step becomes a journey, every heartbeat powers your quest.")
                .font(WQDesignSystem.Typography.caption)
                .foregroundColor(WQDesignSystem.Colors.secondaryText)
                .multilineTextAlignment(.leading)
            
            VStack(alignment: .leading, spacing: WQDesignSystem.Spacing.xs) {
                Text("Features:")
                    .font(WQDesignSystem.Typography.caption.weight(.medium))
                    .foregroundColor(WQDesignSystem.Colors.primaryText)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("• Real-time HealthKit integration")
                    Text("• 5 unique character classes")
                    Text("• Dynamic quest generation")
                    Text("• Apple Watch complications")
                    Text("• Full accessibility support")
                }
                .font(WQDesignSystem.Typography.footnote)
                .foregroundColor(WQDesignSystem.Colors.tertiaryText)
            }
        }
        .padding(WQDesignSystem.Spacing.md)
        .background(WQDesignSystem.Colors.secondaryBackground)
        .cornerRadius(WQDesignSystem.CornerRadius.lg)
    }
}

#if DEBUG
struct DebugSettingsView: View {
    @EnvironmentObject private var gameViewModel: GameViewModel
    @EnvironmentObject private var healthViewModel: HealthViewModel
    @State private var showingResetAlert = false
    
    var body: some View {
        VStack(spacing: WQDesignSystem.Spacing.md) {
            DebugInfoRow(title: "Game State", value: "\(gameViewModel.gameState)")
            DebugInfoRow(title: "Health Status", value: "\(healthViewModel.authorizationStatus)")
            DebugInfoRow(title: "Activity Score", value: "\(healthViewModel.dailyActivityScore)")
            
            Divider()
            
            VStack(spacing: WQDesignSystem.Spacing.sm) {
                WQButton("Simulate Steps +100", style: .secondary) {
                    // Simulate step increase
                }
                
                WQButton("Trigger Combat Mode", style: .secondary) {
                    // Simulate high heart rate
                }
                
                WQButton("Reset All Data", style: .tertiary) {
                    showingResetAlert = true
                }
            }
        }
        .padding(WQDesignSystem.Spacing.md)
        .background(WQDesignSystem.Colors.secondaryBackground)
        .cornerRadius(WQDesignSystem.CornerRadius.lg)
        .alert("Reset All Data", isPresented: $showingResetAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                // Reset game data
            }
        } message: {
            Text("This will delete all game progress and return to onboarding.")
        }
    }
}
#endif

struct SettingToggleRow: View {
    let icon: String
    let title: String
    let description: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(isOn ? WQDesignSystem.Colors.accent : WQDesignSystem.Colors.secondaryText)
                .font(.title3)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: WQDesignSystem.Spacing.xs) {
                Text(title)
                    .font(WQDesignSystem.Typography.body)
                    .foregroundColor(WQDesignSystem.Colors.primaryText)
                
                Text(description)
                    .font(WQDesignSystem.Typography.caption)
                    .foregroundColor(WQDesignSystem.Colors.secondaryText)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
    }
}

struct AccessibilityInfoRow: View {
    let icon: String
    let title: String
    let value: String
    let action: (() -> Void)?
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(WQDesignSystem.Colors.accent)
                .font(.title3)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: WQDesignSystem.Spacing.xs) {
                Text(title)
                    .font(WQDesignSystem.Typography.body)
                    .foregroundColor(WQDesignSystem.Colors.primaryText)
                
                Text(value)
                    .font(WQDesignSystem.Typography.caption)
                    .foregroundColor(WQDesignSystem.Colors.secondaryText)
            }
            
            Spacer()
            
            if let action = action {
                Button("Adjust") {
                    action()
                }
                .font(WQDesignSystem.Typography.caption)
                .foregroundColor(WQDesignSystem.Colors.accent)
            }
        }
    }
}

#if DEBUG
struct DebugInfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(WQDesignSystem.Typography.caption)
                .foregroundColor(WQDesignSystem.Colors.primaryText)
            
            Spacer()
            
            Text(value)
                .font(WQDesignSystem.Typography.caption)
                .foregroundColor(WQDesignSystem.Colors.secondaryText)
        }
    }
}
#endif

extension DynamicTypeSize {
    var description: String {
        switch self {
        case .xSmall: return "Extra Small"
        case .small: return "Small"
        case .medium: return "Medium"
        case .large: return "Large"
        case .xLarge: return "Extra Large"
        case .xxLarge: return "Extra Extra Large"
        case .xxxLarge: return "Accessibility Large"
        case .accessibility1: return "Accessibility Extra Large"
        case .accessibility2: return "Accessibility Extra Extra Large"
        case .accessibility3: return "Accessibility Extra Extra Extra Large"
        case .accessibility4: return "Accessibility Extra Extra Extra Extra Large"
        case .accessibility5: return "Accessibility Largest"
        @unknown default: return "Unknown"
        }
    }
}