// Extensions/MacOSColors.swift
import SwiftUI
import AppKit

extension Color {
	// MARK: - Couleurs système macOS

	/// Couleur de fond principal compatible macOS
	static let systemBackground = Color(NSColor.controlBackgroundColor)

	/// Couleur de fond secondaire compatible macOS
	static let secondarySystemBackground = Color(NSColor.controlColor)

	/// Couleur de fond tertiaire compatible macOS
	static let tertiarySystemBackground = Color(NSColor.windowBackgroundColor)

	/// Couleur de texte principal compatible macOS
	static let label = Color(NSColor.labelColor)

	/// Couleur de texte secondaire compatible macOS
	static let secondaryLabel = Color(NSColor.secondaryLabelColor)

	/// Couleur de texte tertiaire compatible macOS
	static let tertiaryLabel = Color(NSColor.tertiaryLabelColor)

	/// Couleur de séparateur compatible macOS
	static let separator = Color(NSColor.separatorColor)

	/// Couleur de lien compatible macOS
	static let link = Color(NSColor.linkColor)

	// MARK: - Couleurs de contrôle macOS

	/// Couleur de fond de contrôle
	static let controlBackground = Color(NSColor.controlBackgroundColor)

	/// Couleur de contrôle
	static let control = Color(NSColor.controlColor)

	/// Couleur de texte de contrôle
	static let controlText = Color(NSColor.controlTextColor)

	/// Couleur de contrôle désactivé
	static let disabledControlText = Color(NSColor.disabledControlTextColor)

	/// Couleur de sélection
	static let selectedControl = Color(NSColor.selectedControlColor)

	/// Couleur de texte sélectionné
	static let selectedControlText = Color(NSColor.selectedControlTextColor)

	// MARK: - Couleurs alternatives pour les anciens Color.systemGrayX

	/// Équivalent de systemGray6 pour macOS
	static let systemGray6 = Color(NSColor.controlBackgroundColor)

	/// Équivalent de systemGray5 pour macOS
	static let systemGray5 = Color(NSColor.controlColor)

	/// Équivalent de systemGray4 pour macOS
	static let systemGray4 = Color(NSColor.separatorColor)

	/// Équivalent de systemGray3 pour macOS
	static let systemGray3 = Color(NSColor.tertiaryLabelColor)

	/// Équivalent de systemGray2 pour macOS
	static let systemGray2 = Color(NSColor.secondaryLabelColor)

	/// Équivalent de systemGray pour macOS
	static let systemGray = Color(NSColor.labelColor).opacity(0.6)

	// MARK: - Couleurs thématiques de l'application

	/// Couleur principale de l'application
	static let appPrimary = Color.blue

	/// Couleur secondaire de l'application
	static let appSecondary = Color.gray

	/// Couleur d'accent de l'application
	static let appAccent = Color.blue

	/// Couleur de succès
	static let appSuccess = Color.green

	/// Couleur d'avertissement
	static let appWarning = Color.orange

	/// Couleur d'erreur
	static let appError = Color.red

	/// Couleur d'information
	static let appInfo = Color.blue

	// MARK: - Couleurs de statut de facture

	/// Couleur pour statut brouillon
	static let statusDraft = Color.gray

	/// Couleur pour statut envoyée
	static let statusSent = Color.blue

	/// Couleur pour statut payée
	static let statusPaid = Color.green

	/// Couleur pour statut annulée
	static let statusCancelled = Color.red

	// MARK: - Couleurs de fond adaptatives

	/// Couleur de fond de carte
	static let cardBackground = Color(NSColor.controlBackgroundColor)

	/// Couleur de fond de section
	static let sectionBackground = Color(NSColor.windowBackgroundColor)

	/// Couleur de fond de liste
	static let listBackground = Color(NSColor.controlBackgroundColor)

	/// Couleur de fond de rangée
	static let rowBackground = Color(NSColor.controlColor)

	// MARK: - Méthodes utilitaires

	/// Crée une couleur avec opacité adaptée au thème
	static func adaptiveColor(light: Color, dark: Color, opacity: Double = 1.0) -> Color {
		// Sur macOS, on peut utiliser les couleurs système qui s'adaptent automatiquement
		// ou créer une logique basée sur l'apparence système
		return light.opacity(opacity)
	}

	/// Couleur de bordure adaptative
	static var adaptiveBorder: Color {
		Color(NSColor.separatorColor)
	}

	/// Couleur d'ombre adaptative
	static var adaptiveShadow: Color {
		Color.black.opacity(0.05)
	}
}

// MARK: - Extension NSColor pour compatibilité
extension NSColor {
	/// Convertit vers SwiftUI Color
	var swiftUIColor: Color {
		Color(self)
	}

	/// Couleurs personnalisées pour l'application
	static let appBlue = NSColor.systemBlue
	static let appGreen = NSColor.systemGreen
	static let appRed = NSColor.systemRed
	static let appOrange = NSColor.systemOrange
	static let appGray = NSColor.systemGray
}

// MARK: - Modificateurs de couleur pour les vues
extension View {
	/// Applique une couleur de fond adaptative
	func adaptiveBackground() -> some View {
		self.background(Color.systemBackground)
	}

	/// Applique une couleur de fond de carte
	func cardBackground() -> some View {
		self.background(Color.cardBackground)
	}

	/// Applique une couleur de bordure adaptative
	func adaptiveBorder(width: CGFloat = 1) -> some View {
		self.overlay(
			RoundedRectangle(cornerRadius: 8)
				.stroke(Color.adaptiveBorder, lineWidth: width)
		)
	}
}
