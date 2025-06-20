import SwiftUI

// MARK: - Validated Text Field

/// A text field component with real-time validation and user-friendly error feedback
struct ValidatedTextField: View {
    // MARK: - Properties
    
    @Binding var text: String
    let placeholder: String
    let validator: (String) -> ValidationResult
    let showValidationState: Bool
    let isSecure: Bool
    
    @State private var validationResult: ValidationResult = .valid
    @State private var hasUserInteracted: Bool = false
    @FocusState private var isFocused: Bool
    
    // MARK: - Initialization
    
    init(
        text: Binding<String>,
        placeholder: String,
        validator: @escaping (String) -> ValidationResult,
        showValidationState: Bool = true,
        isSecure: Bool = false
    ) {
        self._text = text
        self.placeholder = placeholder
        self.validator = validator
        self.showValidationState = showValidationState
        self.isSecure = isSecure
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: WQDesignSystem.Spacing.xs) {
            // Text field with validation styling
            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                        .textFieldStyle(ValidatedTextFieldStyle(validationResult: validationResult, showValidation: shouldShowValidation))
                } else {
                    TextField(placeholder, text: $text)
                        .textFieldStyle(ValidatedTextFieldStyle(validationResult: validationResult, showValidation: shouldShowValidation))
                }
            }
            .focused($isFocused)
            .onChange(of: text) { newValue in
                validateInput(newValue)
                hasUserInteracted = true
            }
            .onChange(of: isFocused) { focused in
                if !focused && hasUserInteracted {
                    validateInput(text)
                }
            }
            .onAppear {
                validateInput(text)
            }
            
            // Validation message
            if shouldShowValidation && !validationResult.isValid {
                ValidationMessageView(
                    message: validationResult.message ?? "Invalid input",
                    severity: validationResult.severity
                )
            }
        }
    }
    
    // MARK: - Private Methods
    
    private var shouldShowValidation: Bool {
        return showValidationState && hasUserInteracted && !validationResult.isValid
    }
    
    private func validateInput(_ input: String) {
        validationResult = validator(input)
        
        // Log validation event for analytics
        ValidationLogger.shared.logValidationEvent(
            ValidationEvent(
                context: .settingsContext,
                validationType: .formInput,
                input: input,
                result: validationResult
            )
        )
    }
}

// MARK: - Validated Text Field Style

struct ValidatedTextFieldStyle: TextFieldStyle {
    let validationResult: ValidationResult
    let showValidation: Bool
    
    func _body(configuration: TextField<_Label>) -> some View {
        configuration
            .padding(WQDesignSystem.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: WQC.UI.buttonCornerRadius)
                    .fill(WQDesignSystem.Colors.secondaryBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: WQC.UI.buttonCornerRadius)
                    .stroke(borderColor, lineWidth: borderLineWidth)
            )
            .foregroundColor(WQDesignSystem.Colors.primaryText)
    }
    
    private var borderColor: Color {
        if !showValidation {
            return WQDesignSystem.Colors.accent.opacity(0.3)
        }
        
        switch validationResult.severity {
        case .info:
            return WQDesignSystem.Colors.accent.opacity(0.3)
        case .warning:
            return .orange
        case .error, .critical:
            return .red
        }
    }
    
    private var borderLineWidth: CGFloat {
        return showValidation && !validationResult.isValid ? 2 : 1
    }
}

// MARK: - Validation Message View

struct ValidationMessageView: View {
    let message: String
    let severity: ValidationSeverity
    
    var body: some View {
        HStack(spacing: WQDesignSystem.Spacing.xs) {
            Image(systemName: iconName)
                .font(.caption)
                .foregroundColor(iconColor)
            
            Text(message)
                .font(WQDesignSystem.Typography.caption)
                .foregroundColor(messageColor)
                .multilineTextAlignment(.leading)
        }
        .padding(.horizontal, WQDesignSystem.Spacing.xs)
        .animation(WQDesignSystem.Animation.fast, value: message)
    }
    
    private var iconName: String {
        switch severity {
        case .info:
            return "info.circle"
        case .warning:
            return "exclamationmark.triangle"
        case .error, .critical:
            return "xmark.circle"
        }
    }
    
    private var iconColor: Color {
        switch severity {
        case .info:
            return .blue
        case .warning:
            return .orange
        case .error, .critical:
            return .red
        }
    }
    
    private var messageColor: Color {
        switch severity {
        case .info:
            return WQDesignSystem.Colors.secondaryText
        case .warning:
            return .orange
        case .error, .critical:
            return .red
        }
    }
}

// MARK: - Validation Summary View

/// A view that displays a summary of validation errors for a form
struct ValidationSummaryView: View {
    let validationErrors: ValidationErrorCollection
    let showOnlyBlocking: Bool
    
    init(validationErrors: ValidationErrorCollection, showOnlyBlocking: Bool = false) {
        self.validationErrors = validationErrors
        self.showOnlyBlocking = showOnlyBlocking
    }
    
    var body: some View {
        if validationErrors.hasErrors {
            VStack(alignment: .leading, spacing: WQDesignSystem.Spacing.sm) {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    
                    Text("Validation Issues")
                        .font(WQDesignSystem.Typography.headline)
                        .foregroundColor(WQDesignSystem.Colors.primaryText)
                }
                
                VStack(alignment: .leading, spacing: WQDesignSystem.Spacing.xs) {
                    ForEach(errorsToShow, id: \.id) { error in
                        ValidationErrorRowView(error: error)
                    }
                }
                
                if !showOnlyBlocking && validationErrors.hasOnlyWarnings {
                    Text("You can proceed with warnings, but it's recommended to fix them.")
                        .font(WQDesignSystem.Typography.caption)
                        .foregroundColor(WQDesignSystem.Colors.secondaryText)
                        .italic()
                }
            }
            .padding(WQDesignSystem.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: WQC.UI.cardCornerRadius)
                    .fill(backgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: WQC.UI.cardCornerRadius)
                    .stroke(borderColor, lineWidth: 1)
            )
        }
    }
    
    private var errorsToShow: [ValidationError] {
        if showOnlyBlocking {
            return validationErrors.errors.filter { $0.isBlocking }
        } else {
            return validationErrors.errors
        }
    }
    
    private var backgroundColor: Color {
        if validationErrors.hasBlockingErrors {
            return .red.opacity(0.1)
        } else {
            return .orange.opacity(0.1)
        }
    }
    
    private var borderColor: Color {
        if validationErrors.hasBlockingErrors {
            return .red.opacity(0.3)
        } else {
            return .orange.opacity(0.3)
        }
    }
}

// MARK: - Validation Error Row View

struct ValidationErrorRowView: View {
    let error: ValidationError
    
    var body: some View {
        HStack(alignment: .top, spacing: WQDesignSystem.Spacing.xs) {
            Image(systemName: iconName)
                .font(.caption)
                .foregroundColor(iconColor)
                .frame(width: 12, height: 12)
            
            VStack(alignment: .leading, spacing: 2) {
                if !error.field.isEmpty {
                    Text(error.field.capitalized)
                        .font(WQDesignSystem.Typography.caption.weight(.medium))
                        .foregroundColor(WQDesignSystem.Colors.primaryText)
                }
                
                Text(error.message)
                    .font(WQDesignSystem.Typography.caption)
                    .foregroundColor(messageColor)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
        }
    }
    
    private var iconName: String {
        switch error.severity {
        case .info:
            return "info.circle.fill"
        case .warning:
            return "exclamationmark.triangle.fill"
        case .error, .critical:
            return "xmark.circle.fill"
        }
    }
    
    private var iconColor: Color {
        switch error.severity {
        case .info:
            return .blue
        case .warning:
            return .orange
        case .error, .critical:
            return .red
        }
    }
    
    private var messageColor: Color {
        switch error.severity {
        case .info:
            return WQDesignSystem.Colors.secondaryText
        case .warning:
            return .orange
        case .error, .critical:
            return .red
        }
    }
}

// MARK: - Validated Form Container

/// A container view that provides validation context for form fields
struct ValidatedFormContainer<Content: View>: View {
    @State private var validationErrors: ValidationErrorCollection = ValidationErrorCollection([])
    let content: Content
    let onValidationChange: ((ValidationErrorCollection) -> Void)?
    
    init(
        onValidationChange: ((ValidationErrorCollection) -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.onValidationChange = onValidationChange
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: WQDesignSystem.Spacing.md) {
            content
                .environment(\.validationContext, ValidationFormContext(
                    addError: addValidationError,
                    removeError: removeValidationError,
                    clearErrors: clearValidationErrors
                ))
            
            if validationErrors.hasErrors {
                ValidationSummaryView(validationErrors: validationErrors)
            }
        }
        .onChange(of: validationErrors.errors) { _ in
            onValidationChange?(validationErrors)
        }
    }
    
    private func addValidationError(_ error: ValidationError) {
        var errors = validationErrors.errors
        // Remove existing error for the same field
        errors.removeAll { $0.field == error.field }
        // Add new error
        errors.append(error)
        validationErrors = ValidationErrorCollection(errors)
    }
    
    private func removeValidationError(field: String) {
        let errors = validationErrors.errors.filter { $0.field != field }
        validationErrors = ValidationErrorCollection(errors)
    }
    
    private func clearValidationErrors() {
        validationErrors = ValidationErrorCollection([])
    }
}

// MARK: - Validation Form Context

struct ValidationFormContext {
    let addError: (ValidationError) -> Void
    let removeError: (String) -> Void
    let clearErrors: () -> Void
}

// MARK: - Environment Extension

private struct ValidationContextKey: EnvironmentKey {
    static let defaultValue: ValidationFormContext? = nil
}

extension EnvironmentValues {
    var validationContext: ValidationFormContext? {
        get { self[ValidationContextKey.self] }
        set { self[ValidationContextKey.self] = newValue }
    }
}

// MARK: - Preview Helpers

#if DEBUG
struct ValidatedTextField_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: WQDesignSystem.Spacing.lg) {
            ValidatedTextField(
                text: .constant(""),
                placeholder: "Hero Name",
                validator: { InputValidator.shared.validatePlayerName($0) }
            )
            
            ValidatedTextField(
                text: .constant("InvalidNameThatIsTooLongForValidation"),
                placeholder: "Hero Name",
                validator: { InputValidator.shared.validatePlayerName($0) }
            )
            
            ValidatedTextField(
                text: .constant("ValidName"),
                placeholder: "Hero Name",
                validator: { InputValidator.shared.validatePlayerName($0) }
            )
        }
        .padding()
        .background(WQDesignSystem.Colors.primaryBackground)
    }
}
#endif