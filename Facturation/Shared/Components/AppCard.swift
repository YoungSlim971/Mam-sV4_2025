import SwiftUI

// MARK: - App Card Component
struct AppCard<Content: View>: View {
    let content: Content
    let padding: CGFloat
    let shadow: Bool
    let border: Bool
    let backgroundColor: Color
    
    init(
        padding: CGFloat = AppTheme.Spacing.lg,
        shadow: Bool = true,
        border: Bool = false,
        backgroundColor: Color = AppTheme.Colors.surfacePrimary,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.padding = padding
        self.shadow = shadow
        self.border = border
        self.backgroundColor = backgroundColor
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large))
            .modifier(ConditionalShadow(shadow: shadow))
            .modifier(ConditionalBorder(border: border))
    }
}

// MARK: - Conditional Modifiers
struct ConditionalShadow: ViewModifier {
    let shadow: Bool
    
    func body(content: Content) -> some View {
        if shadow {
            content
                .shadow(
                    color: AppTheme.Shadows.medium.color,
                    radius: AppTheme.Shadows.medium.radius,
                    x: AppTheme.Shadows.medium.x,
                    y: AppTheme.Shadows.medium.y
                )
        } else {
            content
        }
    }
}

struct ConditionalBorder: ViewModifier {
    let border: Bool
    
    func body(content: Content) -> some View {
        if border {
            content
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large)
                        .stroke(AppTheme.Colors.border, lineWidth: 1)
                )
        } else {
            content
        }
    }
}

// MARK: - Status Card
struct StatusCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let trend: String?
    let trendDirection: TrendDirection?
    
    enum TrendDirection {
        case up, down, neutral
        
        var icon: String {
            switch self {
            case .up: return "arrow.up.right"
            case .down: return "arrow.down.right"
            case .neutral: return "minus"
            }
        }
        
        var color: Color {
            switch self {
            case .up: return AppTheme.Colors.success
            case .down: return AppTheme.Colors.error
            case .neutral: return AppTheme.Colors.textSecondary
            }
        }
    }
    
    init(
        title: String,
        value: String,
        icon: String,
        color: Color = AppTheme.Colors.primary,
        trend: String? = nil,
        trendDirection: TrendDirection? = nil
    ) {
        self.title = title
        self.value = value
        self.icon = icon
        self.color = color
        self.trend = trend
        self.trendDirection = trendDirection
    }
    
    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                HStack {
                    HStack(spacing: AppTheme.Spacing.sm) {
                        Image(systemName: icon)
                            .font(.title3)
                            .foregroundColor(color)
                            .frame(width: 24, height: 24)
                        
                        Text(title)
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                    
                    Spacer()
                    
                    if let trend = trend, let direction = trendDirection {
                        HStack(spacing: AppTheme.Spacing.xs) {
                            Image(systemName: direction.icon)
                                .font(.caption2)
                                .foregroundColor(direction.color)
                            
                            Text(trend)
                                .font(AppTheme.Typography.caption)
                                .foregroundColor(direction.color)
                        }
                    }
                }
                
                Text(value)
                    .font(AppTheme.Typography.title2)
                    .foregroundColor(AppTheme.Colors.textPrimary)
            }
        }
    }
}

// MARK: - Info Card
struct InfoCard: View {
    let title: String
    let subtitle: String?
    let icon: String?
    let color: Color
    let action: (() -> Void)?
    
    init(
        title: String,
        subtitle: String? = nil,
        icon: String? = nil,
        color: Color = AppTheme.Colors.primary,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.color = color
        self.action = action
    }
    
    var body: some View {
        AppCard {
            HStack(spacing: AppTheme.Spacing.md) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(color)
                        .frame(width: 32, height: 32)
                }
                
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text(title)
                        .font(AppTheme.Typography.title)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                }
                
                Spacer()
                
                if action != nil {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(AppTheme.Colors.textTertiary)
                }
            }
        }
        .onTapGesture {
            action?()
        }
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: AppTheme.Spacing.lg) {
        StatusCard(
            title: "Revenus Total",
            value: "€45,280",
            icon: "eurosign.circle.fill",
            color: AppTheme.Colors.success,
            trend: "+12.5%",
            trendDirection: .up
        )
        
        StatusCard(
            title: "Factures en Retard",
            value: "3",
            icon: "exclamationmark.triangle.fill",
            color: AppTheme.Colors.warning,
            trend: "-2",
            trendDirection: .down
        )
        
        InfoCard(
            title: "Nouveau Client",
            subtitle: "Ajouter un nouveau client à votre base",
            icon: "person.badge.plus",
            color: AppTheme.Colors.primary
        ) {
            print("Nouveau client tapped")
        }
        
        AppCard {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                Text("Custom Card")
                    .font(AppTheme.Typography.title)
                
                Text("Contenu personnalisé dans une carte")
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                
                AppButton.primary("Action", icon: "star.fill") {}
            }
        }
    }
    .padding()
    .background(AppTheme.Colors.background)
}
