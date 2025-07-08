import SwiftUI
import Foundation

struct StatsColorProvider {
    
    // MARK: - Chart Colors
    
    static let chartPrimary = Color.blue
    static let chartSecondary = Color.green
    static let chartTertiary = Color.orange
    static let chartQuaternary = Color.purple
    static let chartError = Color.red
    
    // MARK: - Client Color Palette (12 colors)
    
    static let clientColorPalette: [Color] = [
        Color(red: 0.2, green: 0.6, blue: 1.0),      // Blue
        Color(red: 0.3, green: 0.8, blue: 0.4),      // Green
        Color(red: 1.0, green: 0.6, blue: 0.2),      // Orange
        Color(red: 0.8, green: 0.3, blue: 0.8),      // Purple
        Color(red: 1.0, green: 0.4, blue: 0.4),      // Red
        Color(red: 0.4, green: 0.8, blue: 0.8),      // Cyan
        Color(red: 1.0, green: 0.8, blue: 0.2),      // Yellow
        Color(red: 0.6, green: 0.4, blue: 0.8),      // Indigo
        Color(red: 1.0, green: 0.5, blue: 0.8),      // Pink
        Color(red: 0.5, green: 0.7, blue: 0.3),      // Lime
        Color(red: 0.7, green: 0.5, blue: 0.3),      // Brown
        Color(red: 0.5, green: 0.5, blue: 0.7)       // Gray-Blue
    ]
    
    // MARK: - Product Color Palette (12 colors)
    
    static let productColorPalette: [Color] = [
        Color(red: 0.9, green: 0.3, blue: 0.3),      // Bright Red
        Color(red: 0.2, green: 0.7, blue: 0.9),      // Sky Blue
        Color(red: 0.9, green: 0.7, blue: 0.2),      // Golden
        Color(red: 0.4, green: 0.9, blue: 0.4),      // Bright Green
        Color(red: 0.8, green: 0.4, blue: 0.9),      // Violet
        Color(red: 0.9, green: 0.5, blue: 0.2),      // Coral
        Color(red: 0.3, green: 0.8, blue: 0.7),      // Teal
        Color(red: 0.9, green: 0.6, blue: 0.7),      // Rose
        Color(red: 0.6, green: 0.8, blue: 0.3),      // Light Green
        Color(red: 0.7, green: 0.3, blue: 0.6),      // Magenta
        Color(red: 0.5, green: 0.6, blue: 0.9),      // Periwinkle
        Color(red: 0.8, green: 0.6, blue: 0.4)       // Tan
    ]
    
    // MARK: - High Contrast Color Palettes
    
    static let clientColorPaletteHighContrast: [Color] = [
        Color.black,
        Color.white,
        Color.red,
        Color.blue,
        Color.green,
        Color.yellow,
        Color.purple,
        Color.orange,
        Color.pink,
        Color.cyan,
        Color.brown,
        Color.gray
    ]
    
    static let productColorPaletteHighContrast: [Color] = [
        Color.red,
        Color.blue,
        Color.green,
        Color.yellow,
        Color.purple,
        Color.orange,
        Color.black,
        Color.white,
        Color.pink,
        Color.cyan,
        Color.brown,
        Color.gray
    ]
    
    // MARK: - Color Functions
    
    /// Returns a consistent color for a client based on their UUID
    /// - Parameters:
    ///   - id: The client's UUID
    ///   - highContrast: Whether to use high contrast colors (default: false)
    ///   - environment: Optional EnvironmentValues for accessibility settings
    /// - Returns: A Color from the client palette
    static func colorForClient(id: UUID, highContrast: Bool = false, environment: EnvironmentValues? = nil) -> Color {
        let palette = highContrast ? clientColorPaletteHighContrast : clientColorPalette
        let hash = abs(id.hashValue)
        let index = hash % palette.count
        var color = palette[index]
        
        // Réduire l'opacité si differentiate without color est activé
        if let env = environment, env.accessibilityDifferentiateWithoutColor {
            color = color.opacity(0.7)
        }
        
        return color
    }
    
    /// Returns a consistent color for a product based on their UUID
    /// - Parameters:
    ///   - id: The product's UUID
    ///   - highContrast: Whether to use high contrast colors (default: false)
    ///   - environment: Optional EnvironmentValues for accessibility settings
    /// - Returns: A Color from the product palette
    static func colorForProduct(id: UUID, highContrast: Bool = false, environment: EnvironmentValues? = nil) -> Color {
        let palette = highContrast ? productColorPaletteHighContrast : productColorPalette
        let hash = abs(id.hashValue)
        let index = hash % palette.count
        var color = palette[index]
        
        // Réduire l'opacité si differentiate without color est activé
        if let env = environment, env.accessibilityDifferentiateWithoutColor {
            color = color.opacity(0.7)
        }
        
        return color
    }
    
    // MARK: - Accessibility Support
    
    /// Returns whether high contrast mode should be used based on system accessibility settings
    static var shouldUseHighContrast: Bool {
        #if os(macOS)
        return NSWorkspace.shared.accessibilityDisplayShouldIncreaseContrast
        #else
        return UIAccessibility.isDarkerSystemColorsEnabled
        #endif
    }
    
    /// Returns the appropriate client color with automatic high contrast detection
    /// - Parameters:
    ///   - id: The client's UUID
    ///   - environment: Optional EnvironmentValues for accessibility settings
    /// - Returns: A Color from the appropriate client palette
    static func accessibleColorForClient(id: UUID, environment: EnvironmentValues? = nil) -> Color {
        return colorForClient(id: id, highContrast: shouldUseHighContrast, environment: environment)
    }
    
    /// Returns the appropriate product color with automatic high contrast detection
    /// - Parameters:
    ///   - id: The product's UUID
    ///   - environment: Optional EnvironmentValues for accessibility settings
    /// - Returns: A Color from the appropriate product palette
    static func accessibleColorForProduct(id: UUID, environment: EnvironmentValues? = nil) -> Color {
        return colorForProduct(id: id, highContrast: shouldUseHighContrast, environment: environment)
    }
}

// MARK: - Preview Helpers

#if DEBUG
extension StatsColorProvider {
    /// Returns a preview of all client colors
    static var clientColorPreview: [Color] {
        return clientColorPalette
    }
    
    /// Returns a preview of all product colors
    static var productColorPreview: [Color] {
        return productColorPalette
    }
    
    /// Returns a preview of high contrast client colors
    static var clientColorHighContrastPreview: [Color] {
        return clientColorPaletteHighContrast
    }
    
    /// Returns a preview of high contrast product colors
    static var productColorHighContrastPreview: [Color] {
        return productColorPaletteHighContrast
    }
}
#endif