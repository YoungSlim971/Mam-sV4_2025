
import SwiftUI


// MARK: - App TextField Component
struct AppTextField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    let icon: String?
    let isSecure: Bool
    let isDisabled: Bool
    let errorMessage: String?
    let helpText: String?
    let maxLength: Int?
    let onCommit: (() -> Void)?
    
    @FocusState private var isFocused: Bool
    
    init(
        _ title: String,
        text: Binding<String>,
        placeholder: String = "",
        icon: String? = nil,
        isSecure: Bool = false,
        isDisabled: Bool = false,
        errorMessage: String? = nil,
        helpText: String? = nil,
        maxLength: Int? = nil,
        onCommit: (() -> Void)? = nil
    ) {
        self.title = title
        self._text = text
        self.placeholder = placeholder
        self.icon = icon
        self.isSecure = isSecure
        self.isDisabled = isDisabled
        self.errorMessage = errorMessage
        self.helpText = helpText
        self.maxLength = maxLength
        self.onCommit = onCommit
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            // Title
            if !title.isEmpty {
                Text(title)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.textPrimary)
            }
            
            // Input Field
            HStack(spacing: AppTheme.Spacing.md) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.body)
                        .foregroundColor(iconColor)
                        .frame(width: 16)
                }
                
                Group {
                    if isSecure {
                        SecureField(placeholder, text: $text)
                    } else {
                        TextField(placeholder, text: $text)
                    }
                }
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.Colors.textPrimary)
                .focused($isFocused)
                .disabled(isDisabled)
                .onSubmit {
                    onCommit?()
                }
                .onChange(of: text) { _, newValue in
                    if let maxLength = maxLength, newValue.count > maxLength {
                        text = String(newValue.prefix(maxLength))
                    }
                }
                
                // Character count for maxLength
                if let maxLength = maxLength {
                    Text("\(text.count)/\(maxLength)")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(text.count >= maxLength ? AppTheme.Colors.error : AppTheme.Colors.textTertiary)
                }
            }
            .padding(AppTheme.Spacing.md)
            .background(backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
            .animation(AppTheme.Animation.fast, value: isFocused)
            .animation(AppTheme.Animation.fast, value: errorMessage != nil)
            
            // Help Text or Error Message
            if let errorMessage = errorMessage {
                HStack(spacing: AppTheme.Spacing.xs) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(AppTheme.Colors.error)
                    
                    Text(errorMessage)
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.error)
                }
            } else if let helpText = helpText {
                Text(helpText)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
        }
    }
    
    private var backgroundColor: Color {
        if isDisabled {
            return AppTheme.Colors.surfaceTertiary
        }
        return AppTheme.Colors.surfacePrimary
    }
    
    private var borderColor: Color {
        if errorMessage != nil {
            return AppTheme.Colors.error
        } else if isFocused {
            return AppTheme.Colors.borderFocus
        } else {
            return AppTheme.Colors.border
        }
    }
    
    private var borderWidth: CGFloat {
        isFocused || errorMessage != nil ? 2 : 1
    }
    
    private var iconColor: Color {
        if errorMessage != nil {
            return AppTheme.Colors.error
        } else if isFocused {
            return AppTheme.Colors.primary
        } else {
            return AppTheme.Colors.textSecondary
        }
    }
}

// MARK: - App TextEditor Component
struct AppTextEditor: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    let minHeight: CGFloat
    let maxHeight: CGFloat?
    let isDisabled: Bool
    let errorMessage: String?
    let helpText: String?
    let maxLength: Int?
    
    @FocusState private var isFocused: Bool
    
    init(
        _ title: String,
        text: Binding<String>,
        placeholder: String = "",
        minHeight: CGFloat = 80,
        maxHeight: CGFloat? = 200,
        isDisabled: Bool = false,
        errorMessage: String? = nil,
        helpText: String? = nil,
        maxLength: Int? = nil
    ) {
        self.title = title
        self._text = text
        self.placeholder = placeholder
        self.minHeight = minHeight
        self.maxHeight = maxHeight
        self.isDisabled = isDisabled
        self.errorMessage = errorMessage
        self.helpText = helpText
        self.maxLength = maxLength
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            // Title
            if !title.isEmpty {
                HStack {
                    Text(title)
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    Spacer()
                    
                    if let maxLength = maxLength {
                        Text("\(text.count)/\(maxLength)")
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(text.count >= maxLength ? AppTheme.Colors.error : AppTheme.Colors.textTertiary)
                    }
                }
            }
            
            // TextEditor
            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text(placeholder)
                        .font(AppTheme.Typography.body)
                        .foregroundColor(AppTheme.Colors.textTertiary)
                        .padding(.top, AppTheme.Spacing.sm)
                        .padding(.leading, AppTheme.Spacing.xs)
                        .allowsHitTesting(false)
                }
                
                TextEditor(text: $text)
                    .font(AppTheme.Typography.body)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                    .focused($isFocused)
                    .disabled(isDisabled)
                    .onChange(of: text) { _, newValue in
                        if let maxLength = maxLength, newValue.count > maxLength {
                            text = String(newValue.prefix(maxLength))
                        }
                    }
            }
            .frame(minHeight: minHeight, maxHeight: maxHeight)
            .padding(AppTheme.Spacing.md)
            .background(backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
            .animation(AppTheme.Animation.fast, value: isFocused)
            .animation(AppTheme.Animation.fast, value: errorMessage != nil)
            
            // Help Text or Error Message
            if let errorMessage = errorMessage {
                HStack(spacing: AppTheme.Spacing.xs) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(AppTheme.Colors.error)
                    
                    Text(errorMessage)
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.error)
                }
            } else if let helpText = helpText {
                Text(helpText)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
        }
    }
    
    private var backgroundColor: Color {
        if isDisabled {
            return AppTheme.Colors.surfaceTertiary
        }
        return AppTheme.Colors.surfacePrimary
    }
    
    private var borderColor: Color {
        if errorMessage != nil {
            return AppTheme.Colors.error
        } else if isFocused {
            return AppTheme.Colors.borderFocus
        } else {
            return AppTheme.Colors.border
        }
    }
    
    private var borderWidth: CGFloat {
        isFocused || errorMessage != nil ? 2 : 1
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: AppTheme.Spacing.xl) {
        AppTextField(
            "Email",
            text: .constant(""),
            placeholder: "Enter your email",
            icon: "envelope",
            helpText: "We'll never share your email"
        )
        
        AppTextField(
            "Password",
            text: .constant(""),
            placeholder: "Enter your password",
            icon: "lock",
            isSecure: true,
            errorMessage: "Password must be at least 8 characters"
        )
        
        AppTextField(
            "Phone",
            text: .constant(""),
            placeholder: "Phone number",
            icon: "phone",
            maxLength: 15
        )
        
        AppTextEditor(
            "Description",
            text: .constant(""),
            placeholder: "Enter description...",
            helpText: "Describe your product or service",
            maxLength: 500
        )
    }
    .padding()
    .background(AppTheme.Colors.background)
}
