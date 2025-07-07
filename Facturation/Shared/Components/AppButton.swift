import SwiftUI

// MARK: - App Button Styles
enum AppButtonStyle {
    case primary
    case secondary
    case success
    case warning
    case danger
    case ghost
    case outline
}

enum AppButtonSize {
    case small
    case medium
    case large
    
    var padding: EdgeInsets {
        switch self {
        case .small:
            return EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12)
        case .medium:
            return EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16)
        case .large:
            return EdgeInsets(top: 14, leading: 20, bottom: 14, trailing: 20)
        }
    }
    
    var font: Font {
        switch self {
        case .small:
            return AppTheme.Typography.caption
        case .medium:
            return AppTheme.Typography.body
        case .large:
            return AppTheme.Typography.bodyMedium
        }
    }
}

// MARK: - AppButton Component
struct AppButton: View {
    let title: String
    let icon: String?
    let style: AppButtonStyle
    let size: AppButtonSize
    let action: () -> Void
    let isLoading: Bool
    let isDisabled: Bool
    
    init(
        _ title: String,
        icon: String? = nil,
        style: AppButtonStyle = .primary,
        size: AppButtonSize = .medium,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.size = size
        self.action = action
        self.isLoading = isLoading
        self.isDisabled = isDisabled
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: AppTheme.Spacing.sm) {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .frame(width: 16, height: 16)
                } else if let icon = icon {
                    Image(systemName: icon)
                        .font(size.font)
                }
                
                if !title.isEmpty {
                    Text(title)
                        .font(size.font)
                        .fontWeight(.medium)
                }
            }
            .padding(size.padding)
            .frame(minHeight: minHeight)
            .background(backgroundView)
            .foregroundColor(foregroundColor)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
            .overlay(borderOverlay)
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(AppTheme.Animation.fast, value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isDisabled || isLoading)
        .opacity(isDisabled ? 0.6 : 1.0)
    }
    
    @State private var isPressed = false
    
    private var minHeight: CGFloat {
        switch size {
        case .small: return 28
        case .medium: return 36
        case .large: return 44
        }
    }
    
    @ViewBuilder
    private var backgroundView: some View {
        switch style {
        case .primary:
            AppTheme.Colors.primaryGradient
        case .secondary:
            AppTheme.Colors.surfaceSecondary
        case .success:
            AppTheme.Colors.successGradient
        case .warning:
            AppTheme.Colors.warning
        case .danger:
            Color.red
        case .ghost:
            Color.clear
        case .outline:
            Color.clear
        }
    }
    
    private var foregroundColor: Color {
        switch style {
        case .primary, .success, .warning, .danger:
            return .white
        case .secondary:
            return AppTheme.Colors.textPrimary
        case .ghost, .outline:
            return AppTheme.Colors.primary
        }
    }
    
    @ViewBuilder
    private var borderOverlay: some View {
        if style == .outline {
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                .stroke(AppTheme.Colors.primary, lineWidth: 1.5)
        }
    }
}

// MARK: - Convenient Button Variants
extension AppButton {
    static func primary(
        _ title: String,
        icon: String? = nil,
        size: AppButtonSize = .medium,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) -> AppButton {
        AppButton(title, icon: icon, style: .primary, size: size, isLoading: isLoading, isDisabled: isDisabled, action: action)
    }
    
    static func secondary(
        _ title: String,
        icon: String? = nil,
        size: AppButtonSize = .medium,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) -> AppButton {
        AppButton(title, icon: icon, style: .secondary, size: size, isLoading: isLoading, isDisabled: isDisabled, action: action)
    }
    
    static func success(
        _ title: String,
        icon: String? = nil,
        size: AppButtonSize = .medium,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) -> AppButton {
        AppButton(title, icon: icon, style: .success, size: size, isLoading: isLoading, isDisabled: isDisabled, action: action)
    }
    
    static func danger(
        _ title: String,
        icon: String? = nil,
        size: AppButtonSize = .medium,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) -> AppButton {
        AppButton(title, icon: icon, style: .danger, size: size, isLoading: isLoading, isDisabled: isDisabled, action: action)
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: AppTheme.Spacing.lg) {
        // Different styles
        HStack(spacing: AppTheme.Spacing.md) {
            AppButton.primary("Primary", icon: "checkmark", action: {})
            AppButton.secondary("Secondary", icon: "star", action: {})
            AppButton("Success", icon: "heart.fill", style: .success, action: {})
        }
        
        HStack(spacing: AppTheme.Spacing.md) {
            AppButton("Warning", style: .warning, action: {})
            AppButton("Danger", style: .danger, action: {})
            AppButton("Ghost", style: .ghost, action: {})
        }
        
        HStack(spacing: AppTheme.Spacing.md) {
            AppButton("Outline", style: .outline, action: {})
            AppButton("Loading", isLoading: true, action: {})
            AppButton("Disabled", isDisabled: true, action: {})
        }
        
        // Different sizes
        VStack(spacing: AppTheme.Spacing.md) {
            AppButton("Small Button", size: .small, action: {})
            AppButton("Medium Button", size: .medium, action: {})
            AppButton("Large Button", size: .large, action: {})
        }
    }
    .padding()
    .background(AppTheme.Colors.background)
}
