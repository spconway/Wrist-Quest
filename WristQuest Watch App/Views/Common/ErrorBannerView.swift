import SwiftUI

struct ErrorBannerView: View {
    let error: WQError
    let recoveryOptions: [RecoveryOption]
    let onRecoveryAction: (RecoveryOption) -> Void
    let onDismiss: () -> Void
    
    @State private var isExpanded = false
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 8) {
            // Main error message
            HStack {
                Image(systemName: iconForError)
                    .foregroundColor(colorForSeverity)
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(error.userMessage)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    if !error.category.rawValue.isEmpty {
                        Text(error.category.rawValue.capitalized)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if !recoveryOptions.isEmpty {
                    Button(action: { 
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isExpanded.toggle()
                        }
                    }) {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // Recovery options
            if isExpanded && !recoveryOptions.isEmpty {
                VStack(spacing: 4) {
                    ForEach(Array(recoveryOptions.enumerated()), id: \.offset) { index, option in
                        Button(action: {
                            onRecoveryAction(option)
                        }) {
                            HStack {
                                Image(systemName: iconForRecoveryOption(option))
                                    .font(.caption2)
                                    .foregroundColor(.accentColor)
                                
                                Text(option.title)
                                    .font(.caption2)
                                    .foregroundColor(.accentColor)
                                
                                Spacer()
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.accentColor.opacity(0.1))
                            .cornerRadius(6)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .padding(12)
        .background(backgroundColorForSeverity)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(colorForSeverity.opacity(0.3), lineWidth: 1)
        )
        .scaleEffect(isAnimating ? 1.05 : 1.0)
        .onAppear {
            withAnimation(.easeOut(duration: 0.3)) {
                isAnimating = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isAnimating = false
                }
            }
        }
    }
    
    private var iconForError: String {
        switch error.severity {
        case .critical:
            return "exclamationmark.triangle.fill"
        case .high:
            return "exclamationmark.circle.fill"
        case .medium:
            return "info.circle.fill"
        case .low:
            return "info.circle"
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
    
    private var backgroundColorForSeverity: Color {
        switch error.severity {
        case .critical:
            return .red.opacity(0.1)
        case .high:
            return .orange.opacity(0.1)
        case .medium:
            return .yellow.opacity(0.1)
        case .low:
            return .blue.opacity(0.05)
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
            return "forward"
        case .goToOnboarding:
            return "arrowshape.turn.up.left"
        case .contactSupport:
            return "questionmark.circle"
        case .fallback, .custom:
            return "checkmark.circle"
        }
    }
}

// MARK: - Convenience Initializers

extension ErrorBannerView {
    init(error: WQError, onDismiss: @escaping () -> Void) {
        self.error = error
        self.recoveryOptions = []
        self.onRecoveryAction = { _ in }
        self.onDismiss = onDismiss
    }
    
    init(error: WQError, recoveryOptions: [RecoveryOption], onRecoveryAction: @escaping (RecoveryOption) -> Void) {
        self.error = error
        self.recoveryOptions = recoveryOptions
        self.onRecoveryAction = onRecoveryAction
        self.onDismiss = {}
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        ErrorBannerView(
            error: WQError.healthKit(.authorizationDenied),
            recoveryOptions: [.openSettings("Health"), .skip],
            onRecoveryAction: { _ in },
            onDismiss: {}
        )
        
        ErrorBannerView(
            error: .persistence(.saveFailed("Connection timeout")),
            recoveryOptions: [.retry, .restart],
            onRecoveryAction: { _ in },
            onDismiss: {}
        )
        
        ErrorBannerView(
            error: .network(.noConnection),
            onDismiss: {}
        )
    }
    .padding()
}