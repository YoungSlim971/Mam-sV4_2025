
//
//  AppTheme.swift
//  Facturation
//
//  Created by Okba on 05/07/2025.
//

import SwiftUI
import AppKit

/// Un système de design global pour l'application, fournissant des couleurs, des polices, des espacements et d'autres constantes de style.
///
/// `AppTheme` centralise toutes les valeurs de style, ce qui permet une cohérence visuelle à travers toute l'application
/// et facilite les mises à jour de style. Les valeurs sont accessibles via des propriétés statiques.
///
/// ## Organisation
/// Le thème est divisé en plusieurs sous-structures pour une meilleure organisation :
/// - `Colors`: Définit la palette de couleurs de l'application.
/// - `Typography`: Contient les styles de police pour les titres, le corps de texte, etc.
/// - `Spacing`: Fournit des valeurs d'espacement standardisées.
/// - `CornerRadius`: Définit les rayons de coin pour les éléments d'interface.
/// - `Shadows`: Contient des styles d'ombre prédéfinis.
/// - `Animation`: Fournit des animations standard pour les transitions d'interface.
///
/// ## Utilisation
/// Pour utiliser une valeur du thème, appelez simplement la propriété statique correspondante.
///
/// ```swift
/// Text("Hello, World!")
///     .font(AppTheme.Typography.title1)
///     .foregroundColor(AppTheme.Colors.textPrimary)
///     .padding(AppTheme.Spacing.md)
///     .background(AppTheme.Colors.background)
///     .cornerRadius(AppTheme.CornerRadius.medium)
///     .shadow(
///         color: AppTheme.Shadows.small.color,
///         radius: AppTheme.Shadows.small.radius,
///         x: AppTheme.Shadows.small.x,
///         y: AppTheme.Shadows.small.y
///     )
/// ```
///
/// Des extensions sur `View`, `Font`, et `Color` sont également fournies pour une application plus concise des styles.
///
public enum AppTheme {

    // MARK: - Couleurs
    /// Contient la palette de couleurs de l'application, organisée par fonction.
    public enum Colors {
        
        // MARK: Couleurs de base
        /// La couleur principale utilisée pour les éléments interactifs et l'image de marque.
        public static let primary = Color.blue
        /// Une version plus claire de la couleur principale, utile pour les états survolés ou les arrière-plans subtils.
        public static let primaryLight = Color.blue.opacity(0.1)
        /// Une version plus sombre de la couleur principale, pour les états pressés ou les accents.
        public static let primaryDark = Color.blue.opacity(0.8)
        
        // MARK: Couleurs sémantiques
        /// Utilisée pour indiquer le succès, la validation ou un état positif.
        public static let success = Color.green
        /// Utilisée pour les avertissements ou les informations qui nécessitent une attention.
        public static let warning = Color.orange
        /// Utilisée pour les erreurs, les actions destructrices ou les états critiques.
        public static let error = Color.red
        /// Utilisée pour les messages d'information ou les conseils.
        public static let info = Color.cyan

        // MARK: Couleurs de fond
        /// La couleur de fond principale pour la plupart des écrans. S'adapte au mode clair/sombre.
        public static let background = Color(NSColor.windowBackgroundColor)
        /// Couleur de fond pour les éléments de surface comme les cartes, les modales.
        public static let surfacePrimary = Color(NSColor.controlBackgroundColor)
        /// Couleur de fond secondaire pour les surfaces, comme les barres latérales ou les sections groupées.
        public static let surfaceSecondary = Color(NSColor.controlColor)
        /// Une couleur de surface subtile pour les arrière-plans tertiaires.
        public static let surfaceTertiary = Color.gray.opacity(0.05)

        // MARK: Couleurs de texte
        /// La couleur de texte principale pour le contenu standard.
        public static let textPrimary = Color(NSColor.labelColor)
        /// Couleur de texte secondaire pour les sous-titres, les descriptions.
        public static let textSecondary = Color(NSColor.secondaryLabelColor)
        /// Couleur de texte tertiaire pour les informations moins importantes, les placeholders.
        public static let textTertiary = Color(NSColor.tertiaryLabelColor)
        /// Couleur de texte pour les éléments désactivés.
        public static let textDisabled = Color(NSColor.disabledControlTextColor)
        /// Couleur pour les liens hypertextes.
        public static let textLink = Color(NSColor.linkColor)

        // MARK: Couleurs de bordure
        /// La couleur de bordure par défaut pour les séparateurs et les contours.
        public static let border = Color(NSColor.separatorColor)
        /// Une bordure plus claire, pour les séparations subtiles.
        public static let borderLight = Color.gray.opacity(0.1)
        /// Couleur de bordure pour les éléments ayant le focus, comme les champs de texte actifs.
        public static let borderFocus = Color.blue.opacity(0.5)

        // MARK: Couleurs de statut de facture
        /// Statut "Brouillon".
        public static let statusDraft = Color.gray
        /// Statut "Envoyée".
        public static let statusSent = Color.blue
        /// Statut "Payée".
        public static let statusPaid = Color.green
        /// Statut "En retard".
        public static let statusOverdue = Color.orange
        /// Statut "Annulée".
        public static let statusCancelled = Color.red

        // MARK: Dégradés
        /// Un dégradé principal pour les arrière-plans ou les éléments décoratifs.
        public static let primaryGradient = LinearGradient(
            gradient: Gradient(colors: [primary, primary.opacity(0.7)]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        /// Un dégradé de succès pour les éléments confirmés ou validés.
        public static let successGradient = LinearGradient(
            gradient: Gradient(colors: [success, success.opacity(0.7)]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Typographie
    /// Définit les styles de police pour une hiérarchie de texte cohérente.
    public enum Typography {
        private static func font(for style: Font.TextStyle, weight: NSFont.Weight) -> Font {
            .system(style, design: .default).weight(weightMapping(weight))
        }
        
        private static func weightMapping(_ weight: NSFont.Weight) -> Font.Weight {
            switch weight {
                case .ultraLight: return .ultraLight
                case .thin: return .thin
                case .light: return .light
                case .regular: return .regular
                case .medium: return .medium
                case .semibold: return .semibold
                case .bold: return .bold
                case .heavy: return .heavy
                case .black: return .black
                default: return .regular
            }
        }

        // Titres
        public static let largeTitle = font(for: .largeTitle, weight: .bold)
        public static let title = font(for: .title, weight: .bold)
        public static let title2 = font(for: .title2, weight: .semibold)
        public static let title3 = font(for: .title3, weight: .medium)

        // Corps de texte
        public static let body = font(for: .body, weight: .regular)
        public static let bodyMedium = font(for: .body, weight: .medium)
        public static let bodyBold = font(for: .body, weight: .bold)

        // Styles de support
        public static let callout = font(for: .callout, weight: .regular)
        public static let subheadline = font(for: .subheadline, weight: .regular)
        public static let footnote = font(for: .footnote, weight: .regular)
        public static let caption1 = font(for: .caption, weight: .regular)
        public static let caption2 = font(for: .caption2, weight: .regular)

        // Styles personnalisés
        public static let button = font(for: .body, weight: .medium)

        // Ajout du style caption (accès simplifié)
        public static let caption = font(for: .caption, weight: .regular)
    }

    // MARK: - Espacement
    /// Fournit une échelle d'espacement cohérente pour les paddings, les marges, etc.
    public enum Spacing {
        public static let xxs: CGFloat = 2
        public static let xs: CGFloat = 4
        public static let sm: CGFloat = 8
        public static let md: CGFloat = 12
        public static let lg: CGFloat = 16
        public static let xl: CGFloat = 24
        public static let xxl: CGFloat = 32
        public static let xxxl: CGFloat = 48
    }

    // MARK: - Rayons de coin
    /// Définit les rayons de coin pour créer une apparence visuelle unifiée.
    public enum CornerRadius {
        public static let small: CGFloat = 4
        public static let medium: CGFloat = 8
        public static let large: CGFloat = 12
        public static let xlarge: CGFloat = 16
        /// Pour créer des formes de pilule ou des cercles parfaits.
        public static let pill: CGFloat = 9999
    }

    // MARK: - Ombres
    /// Contient des styles d'ombre prédéfinis pour donner de la profondeur à l'interface.
    public enum Shadows {
        public static let small = (color: Color.black.opacity(0.08), radius: 4.0, x: 0.0, y: 2.0)
        public static let medium = (color: Color.black.opacity(0.12), radius: 8.0, x: 0.0, y: 4.0)
        public static let large = (color: Color.black.opacity(0.16), radius: 16.0, x: 0.0, y: 8.0)
    }
    
    // MARK: - Animation
    /// Fournit des animations standard pour les transitions d'interface.
    public enum Animation {
        public static let fast = SwiftUI.Animation.easeInOut(duration: 0.2)
        public static let normal = SwiftUI.Animation.easeInOut(duration: 0.3)
        public static let slow = SwiftUI.Animation.easeInOut(duration: 0.5)
        public static let spring = SwiftUI.Animation.spring(response: 0.5, dampingFraction: 0.8)
    }
}

// MARK: - Modificateurs de vue
/// Des modificateurs de vue pour appliquer facilement les styles du `AppTheme`.
public extension View {
    func appCard(padding: CGFloat = AppTheme.Spacing.md) -> some View {
        self
            .padding(padding)
            .background(AppTheme.Colors.surfacePrimary)
            .cornerRadius(AppTheme.CornerRadius.large)
            .shadow(
                color: AppTheme.Shadows.small.color,
                radius: AppTheme.Shadows.small.radius,
                x: AppTheme.Shadows.small.x,
                y: AppTheme.Shadows.small.y
            )
    }
    
    /// Applique un style de carte standard à une vue.
    /// - Parameters:
    ///   - padding: Le padding intérieur de la carte.
    ///   - cornerRadius: Le rayon de coin de la carte.
    /// - Returns: Une vue stylisée comme une carte.
    func appCardStyle(padding: CGFloat = AppTheme.Spacing.lg, cornerRadius: CGFloat = AppTheme.CornerRadius.large) -> some View {
        self
            .padding(padding)
            .background(AppTheme.Colors.surfacePrimary)
            .cornerRadius(cornerRadius)
            .shadow(
                color: AppTheme.Shadows.small.color,
                radius: AppTheme.Shadows.small.radius,
                x: AppTheme.Shadows.small.x,
                y: AppTheme.Shadows.small.y
            )
    }
    
    /// Applique une bordure standard à une vue.
    /// - Parameters:
    ///   - color: La couleur de la bordure.
    ///   - width: La largeur de la bordure.
    ///   - cornerRadius: Le rayon de coin de la bordure.
    /// - Returns: Une vue avec une bordure stylisée.
    func appBorderStyle(
        color: Color = AppTheme.Colors.border,
        width: CGFloat = 1.0,
        cornerRadius: CGFloat = AppTheme.CornerRadius.medium
    ) -> some View {
        self.overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(color, lineWidth: width)
        )
    }
}
