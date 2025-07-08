import Foundation

struct StatsFormatters {
    
    // MARK: - Currency Formatter (Euro)
    
    /// Formatter for Euro currency with € symbol
    static let euroFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "EUR"
        formatter.currencySymbol = "€"
        formatter.locale = Locale(identifier: "fr_FR") // French locale for proper Euro formatting
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }()
    
    // MARK: - Quantity Formatter (No decimals)
    
    /// Formatter for quantities without decimal places
    static let quantityFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        formatter.locale = Locale(identifier: "fr_FR") // French locale for proper number formatting
        return formatter
    }()
    
    // MARK: - Percentage Formatter
    
    /// Formatter for percentages
    static let percentageFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 1
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter
    }()
    
    // MARK: - Compact Number Formatter
    
    /// Formatter for large numbers (K, M, etc.)
    static let compactFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.maximumFractionDigits = 1
        return formatter
    }()
}

// MARK: - String Extensions

extension String {
    
    /// Formats a string as Euro currency
    /// - Parameter value: The numeric value to format
    /// - Returns: Formatted Euro string (e.g., "12,50 €")
    static func euroFormatted(_ value: Double) -> String {
        return StatsFormatters.euroFormatter.string(from: NSNumber(value: value)) ?? "0,00 €"
    }
    
    /// Formats a string as quantity without decimals
    /// - Parameter value: The numeric value to format
    /// - Returns: Formatted quantity string (e.g., "1 250")
    static func quantityFormatted(_ value: Double) -> String {
        return StatsFormatters.quantityFormatter.string(from: NSNumber(value: value)) ?? "0"
    }
    
    /// Formats a string as percentage
    /// - Parameter value: The numeric value to format (0.0 to 1.0)
    /// - Returns: Formatted percentage string (e.g., "12,5 %")
    static func percentageFormatted(_ value: Double) -> String {
        return StatsFormatters.percentageFormatter.string(from: NSNumber(value: value)) ?? "0,0 %"
    }
    
    /// Formats large numbers with compact notation
    /// - Parameter value: The numeric value to format
    /// - Returns: Formatted compact string (e.g., "1,2K", "2,5M")
    static func compactFormatted(_ value: Double) -> String {
        if value >= 1_000_000 {
            let millions = value / 1_000_000
            return StatsFormatters.compactFormatter.string(from: NSNumber(value: millions))! + "M"
        } else if value >= 1_000 {
            let thousands = value / 1_000
            return StatsFormatters.compactFormatter.string(from: NSNumber(value: thousands))! + "K"
        } else {
            return StatsFormatters.quantityFormatter.string(from: NSNumber(value: value)) ?? "0"
        }
    }
}

// MARK: - Accessibility Helpers

extension String {
    
    /// Provides accessibility description for Euro amounts
    /// - Parameter value: The Euro amount
    /// - Returns: Accessibility-friendly description (e.g., "12 euros et 50 centimes")
    static func accessibilityEuroDescription(_ value: Double) -> String {
        let euros = Int(value)
        let centimes = Int((value - Double(euros)) * 100)
        
        if centimes == 0 {
            return euros == 1 ? "1 euro" : "\(euros) euros"
        } else {
            let euroText = euros == 1 ? "1 euro" : "\(euros) euros"
            let centimeText = centimes == 1 ? "1 centime" : "\(centimes) centimes"
            return "\(euroText) et \(centimeText)"
        }
    }
    
    /// Provides accessibility description for quantities
    /// - Parameter value: The quantity value
    /// - Returns: Accessibility-friendly description (e.g., "1 250 unités")
    static func accessibilityQuantityDescription(_ value: Double) -> String {
        let formatted = String.quantityFormatted(value)
        return value == 1.0 ? "\(formatted) unité" : "\(formatted) unités"
    }
    
    /// Provides accessibility description for percentages
    /// - Parameter value: The percentage value (0.0 to 1.0)
    /// - Returns: Accessibility-friendly description (e.g., "12,5 pour cent")
    static func accessibilityPercentageDescription(_ value: Double) -> String {
        let percentage = value * 100
        let formatted = StatsFormatters.compactFormatter.string(from: NSNumber(value: percentage)) ?? "0"
        return "\(formatted) pour cent"
    }
}

// MARK: - Double Accessibility Extensions

extension Double {
    
    /// Provides accessibility description for Euro amounts
    /// - Returns: Accessibility-friendly Euro description
    var accessibilityEuroDescription: String {
        return String.accessibilityEuroDescription(self)
    }
    
    /// Provides accessibility description for quantities
    /// - Returns: Accessibility-friendly quantity description
    var accessibilityQuantityDescription: String {
        return String.accessibilityQuantityDescription(self)
    }
    
    /// Provides accessibility description for percentages
    /// - Returns: Accessibility-friendly percentage description
    var accessibilityPercentageDescription: String {
        return String.accessibilityPercentageDescription(self)
    }
}

// MARK: - Formatting Utilities

extension StatsFormatters {
    
    /// Safely formats a number as Euro, handling nil values
    /// - Parameter value: Optional Double value
    /// - Returns: Formatted Euro string or default
    static func safeEuroFormat(_ value: Double?) -> String {
        guard let value = value else { return "0,00 €" }
        return String.euroFormatted(value)
    }
    
    /// Safely formats a number as quantity, handling nil values
    /// - Parameter value: Optional Double value
    /// - Returns: Formatted quantity string or default
    static func safeQuantityFormat(_ value: Double?) -> String {
        guard let value = value else { return "0" }
        return String.quantityFormatted(value)
    }
    
    /// Safely formats a number as percentage, handling nil values
    /// - Parameter value: Optional Double value
    /// - Returns: Formatted percentage string or default
    static func safePercentageFormat(_ value: Double?) -> String {
        guard let value = value else { return "0,0 %" }
        return String.percentageFormatted(value)
    }
    
    /// Formats a time interval in a human-readable way
    /// - Parameter interval: TimeInterval in seconds
    /// - Returns: Human-readable duration (e.g., "2j 3h", "1h 30m")
    static func durationFormat(_ interval: TimeInterval) -> String {
        let days = Int(interval) / 86400
        let hours = (Int(interval) % 86400) / 3600
        let minutes = (Int(interval) % 3600) / 60
        
        if days > 0 {
            return hours > 0 ? "\(days)j \(hours)h" : "\(days)j"
        } else if hours > 0 {
            return minutes > 0 ? "\(hours)h \(minutes)m" : "\(hours)h"
        } else {
            return "\(minutes)m"
        }
    }
}

#if DEBUG
// MARK: - Preview Helpers
extension StatsFormatters {
    static let sampleValues: [Double] = [0.0, 1.5, 25.99, 1250.75, 15000.0, 1500000.50]
    
    static var euroSamples: [String] {
        return sampleValues.map { String.euroFormatted($0) }
    }
    
    static var quantitySamples: [String] {
        return sampleValues.map { String.quantityFormatted($0) }
    }
    
    static var percentageSamples: [String] {
        return [0.0, 0.125, 0.5, 0.875, 1.0].map { String.percentageFormatted($0) }
    }
    
    static var compactSamples: [String] {
        return sampleValues.map { String.compactFormatted($0) }
    }
}
#endif
