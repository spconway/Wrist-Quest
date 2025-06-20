import SwiftUI

struct ErrorDialogView: View {
    let error: WQError
    let recoveryOptions: [RecoveryOption]
    let onRecoveryAction: (RecoveryOption) -> Void
    let onDismiss: () -> Void
    
    @State private var isVisible = false
    
    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    if canDismissOnTap {
                        dismissDialog()
                    }
                }
            
            // Dialog content
            VStack(spacing: 16) {
                // Error icon and title
                VStack(spacing: 8) {
                    Image(systemName: iconForError)
                        .font(.title)
                        .foregroundColor(colorForSeverity)
                    
                    Text(titleForError)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                }
                
                // Error message
                Text(error.userMessage)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                
                // Additional details for critical errors
                if error.severity == .critical && shouldShowDetails {
                    VStack(spacing: 4) {
                        Text("Error Details")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Text(error.category.rawValue.capitalized)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(8)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(8)
                }
                
                // Recovery actions
                if !recoveryOptions.isEmpty {
                    VStack(spacing: 8) {
                        ForEach(Array(recoveryOptions.enumerated()), id: \.offset) { index, option in
                            Button(action: {
                                onRecoveryAction(option)
                                if shouldDismissAfterAction(option) {
                                    dismissDialog()
                                }
                            }) {
                                HStack {
                                    Image(systemName: iconForRecoveryOption(option))
                                        .font(.caption)
                                    
                                    Text(option.title)
                                        .font(.body)
                                        .fontWeight(.medium)
                                    
                                    Spacer()
                                }
                                .foregroundColor(colorForRecoveryOption(option))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(backgroundForRecoveryOption(option))
                                .cornerRadius(10)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                } else {
                    // Default dismiss button if no recovery options
                    Button("OK") {
                        dismissDialog()
                    }
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.accentColor)
                    .cornerRadius(10)
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(20)
            .background(Color.black.opacity(0.9))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
            .scaleEffect(isVisible ? 1.0 : 0.8)
            .opacity(isVisible ? 1.0 : 0.0)
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: isVisible)
        }
        .onAppear {
            isVisible = true
        }
    }
    
    private func dismissDialog() {
        withAnimation(.easeOut(duration: 0.3)) {
            isVisible = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onDismiss()
        }
    }
    
    private var titleForError: String {
        switch error.category {
        case .healthKit:
            return "Health Data Issue"
        case .persistence:
            return "Data Save Issue"
        case .quest:
            return "Quest Problem"
        case .gameState:
            return "Game State Error"
        case .network:
            return "Connection Issue"
        case .validation:
            return "Invalid Input"
        case .system:
            return "System Error"
        }
    }
    
    private var iconForError: String {
        switch error.category {
        case .healthKit:
            return "heart.fill"
        case .persistence:
            return "internaldrive.fill"
        case .quest:
            return "map.fill"
        case .gameState:
            return "gamecontroller.fill"
        case .network:
            return "wifi.slash"
        case .validation:
            return "exclamationmark.triangle.fill"
        case .system:
            return "gear.badge.xmark"
        }
    }
    
    private var colorForSeverity: Color {
        switch error.severity {
        case .critical:
            return .red
        case .high:
            return .orange
        case .medium:
            return .yellow
        case .low:
            return .blue
        }
    }
    
    private var canDismissOnTap: Bool {
        error.severity != .critical
    }
    
    private var shouldShowDetails: Bool {
        error.severity == .critical
    }
    
    private func shouldDismissAfterAction(_ option: RecoveryOption) -> Bool {
        switch option {
        case .retry, .retryWithDelay:
            return false // Keep dialog open during retry
        case .openSettings, .contactSupport:
            return false // Keep dialog open as user will return
        default:
            return true
        }
    }
    
    private func iconForRecoveryOption(_ option: RecoveryOption) -> String {
        switch option {
        case .retry, .retryWithDelay:
            return "arrow.clockwise"
        case .openSettings:
            return "gearshape"
        case .restart:
            return "restart"
        case .skip:
            return "forward.fill"
        case .goToOnboarding:
            return "arrowshape.turn.up.left.fill"
        case .contactSupport:
            return "questionmark.circle.fill"
        case .fallback, .custom:
            return "checkmark.circle.fill"
        }
    }
    
    private func colorForRecoveryOption(_ option: RecoveryOption) -> Color {
        switch option {
        case .retry, .retryWithDelay:
            return .accentColor
        case .openSettings:
            return .blue
        case .restart:
            return .orange
        case .skip:
            return .secondary
        case .goToOnboarding:
            return .purple
        case .contactSupport:
            return .green
        case .fallback, .custom:
            return .accentColor
        }
    }
    
    private func backgroundForRecoveryOption(_ option: RecoveryOption) -> Color {
        switch option {
        case .restart:
            return .orange.opacity(0.15)
        case .skip:
            return .secondary.opacity(0.1)
        default:
            return colorForRecoveryOption(option).opacity(0.15)
        }
    }
}

// MARK: - Convenience Initializers

extension ErrorDialogView {
    init(error: WQError, onDismiss: @escaping () -> Void) {
        self.error = error
        self.recoveryOptions = []
        self.onRecoveryAction = { _ in }
        self.onDismiss = onDismiss
    }
}

// MARK: - Preview

#Preview {
    ErrorDialogView(
        error: WQError.healthKit(.authorizationDenied),
        recoveryOptions: [
            .openSettings("Privacy & Security"),
            .skip,
            .contactSupport
        ],
        onRecoveryAction: { option in
            print("Recovery action: \(option.title)")
        },
        onDismiss: {
            print("Dialog dismissed")
        }
    )
}