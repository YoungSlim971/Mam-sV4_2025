// Extensions/Extensions.swift
import SwiftUI
import Foundation
import DataLayer

// MARK: - Double Extensions
extension Double {
    /// Formate un nombre en euros selon le format français
    var euroFormatted: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "EUR"
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.string(from: NSNumber(value: self)) ?? "0,00 €"
    }

    /// Formate un nombre avec 2 décimales
    var formatted: String {
        return String(format: "%.2f", self)
    }

    /// Formate un pourcentage
    var percentFormatted: String {
        return String(format: "%.1f%%", self)
    }
}

// MARK: - Date Extensions
extension Date {
    /// Formate une date selon le format français (jj/mm/aaaa)
    var frenchFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.string(from: self)
    }

    /// Formate une date en format court (jj/mm/aa)
    var shortFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.string(from: self)
    }

    /// Formate une date avec l'heure
    var fullFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.string(from: self)
    }

    /// Vérifie si la date est en retard par rapport à aujourd'hui
    var isOverdue: Bool {
        return self < Date()
    }

    /// Nombre de jours entre cette date et aujourd'hui
    var daysFromNow: Int {
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: Date(), to: self).day ?? 0
        return days
    }

    /// Description relative de la date (dans X jours, il y a X jours)
    var relativeDescription: String {
        let days = daysFromNow

        if days == 0 {
            return "Aujourd'hui"
        } else if days == 1 {
            return "Demain"
        } else if days == -1 {
            return "Hier"
        } else if days > 1 {
            return "Dans \(days) jours"
        } else {
            return "Il y a \(abs(days)) jours"
        }
    }

    func moisEtAnnee() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.string(from: self)
    }
    
    /// Formate la date en chaîne pour groupement par mois
    func formatToMonthString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        return formatter.string(from: self)
    }
    
    /// Calcule le nombre de jours entre cette date et une autre
    func daysBetween(_ date: Date) -> Double {
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: self, to: date).day ?? 0
        return Double(days)
    }
}

// MARK: - String Extensions
extension String {
    /// Capitalise la première lettre
    var capitalizedFirst: String {
        return prefix(1).capitalized + dropFirst()
    }

    /// Supprime les espaces en début et fin
    var trimmed: String {
        return trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Vérifie si la chaîne est un email valide
    var isValidEmail: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: self)
    }

    /// Vérifie si la chaîne est un numéro SIRET valide (14 chiffres)
    var isValidSIRET: Bool {
        return count == 14 && allSatisfy { $0.isNumber }
    }

    /// Formate un numéro de téléphone français
    var formattedPhoneNumber: String {
        let cleaned = replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)

        guard cleaned.count == 10, cleaned.hasPrefix("0") else {
            return self
        }

        let formatted = cleaned.enumerated().compactMap { index, character in
            if index > 0 && index % 2 == 0 {
                return " \(character)"
            }
            return String(character)
        }.joined()

        return formatted
    }
}

// MARK: - Color Extensions
extension Color {
    /// Couleurs personnalisées de l'application
    static let appBlue = Color(red: 0.0, green: 0.48, blue: 1.0)
    static let appGreen = Color(red: 0.0, green: 0.78, blue: 0.0)
    static let appOrange = Color(red: 1.0, green: 0.58, blue: 0.0)
    static let appRed = Color(red: 1.0, green: 0.23, blue: 0.19)
    static let appGray = Color(red: 0.55, green: 0.55, blue: 0.57)

    /// Initialise une couleur à partir d'un hex
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
            case 3: // RGB (12-bit)
                (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
            case 6: // RGB (24-bit)
                (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
            case 8: // ARGB (32-bit)
                (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
            default:
                (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Array Extensions
extension Array {
    /// Accès sécurisé aux éléments du tableau
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

// MARK: - NumberFormatter Extensions
extension NumberFormatter {
    /// Formatter pour les euros français
    static let euroFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "EUR"
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter
    }()

    /// Formatter pour les pourcentages
    static let percentFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 1
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter
    }()

    /// Formatter pour les nombres entiers
    static let integerFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter
    }()
}

// MARK: - Calendar Extensions
extension Calendar {
    /// Calendrier français
    static let french: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "fr_FR")
        calendar.firstWeekday = 2 // Lundi
        return calendar
    }()
}

// MARK: - View Extensions
extension View {
    /// Applique un modificateur conditionnel
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }

    /// Ajoute un border conditionnel
    func border(_ color: Color, width: CGFloat, condition: Bool) -> some View {
        overlay(
            RoundedRectangle(cornerRadius: 0)
                .stroke(condition ? color : Color.clear, lineWidth: width)
        )
    }

    /// Style de carte avec ombre
    func cardStyle() -> some View {
        self
            .background(Color.systemBackground)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 1)
    }

    /// Applique un effet de survol
    func hoverEffect() -> some View {
        self
            .scaleEffect(1.0)
            .animation(.easeInOut(duration: 0.2), value: false)
    }
}

// MARK: - Binding Extensions
extension Binding {
    /// Crée un binding qui transforme la valeur
    func map<T>(
        get: @escaping (Value) -> T,
        set: @escaping (T) -> Value
    ) -> Binding<T> {
        Binding<T>(
            get: { get(self.wrappedValue) },
            set: { self.wrappedValue = set($0) }
        )
    }
}

// MARK: - Locale Extensions
extension Locale {
    /// Locale français
    static let french = Locale(identifier: "fr_FR")
}

// MARK: - StatutFacture Extensions
extension StatutFacture {
    /// Description détaillée du statut
    var description: String {
        switch self {
            case .brouillon:
                return "Facture en cours de rédaction"
            case .envoyee:
                return "Facture envoyée au client"
            case .payee:
                return "Facture payée par le client"
        case .enRetard:
            return "Facture En Retard"
        case .annulee:
            return "Facture annulée"
        }
    }

    /// Actions disponibles pour ce statut
    var availableActions: [FactureAction] {
        switch self {
            case .brouillon:
                return [.edit, .send, .delete]
            case .envoyee:
                return [.markAsPaid, .duplicate, .exportPDF,.cancel]
            case .payee:
                return [.duplicate, .exportPDF]
            case .annulee:
                return [.duplicate, .delete]
        case .enRetard:
            return [.markAsPaid, .duplicate, .delete]
        }
    }
}

// MARK: - Facture Action Enum
enum FactureAction: String, CaseIterable {
    case edit = "Modifier"
    case send = "Envoyer"
    case markAsPaid = "Marquer comme payée"
    case cancel = "Annuler"
    case duplicate = "Dupliquer"
    case exportPDF = "Exporter PDF"
    case delete = "Supprimer"

    var systemImage: String {
        switch self {
            case .edit: return "pencil"
            case .send: return "paperplane"
            case .markAsPaid: return "checkmark.circle"
            case .cancel: return "xmark.circle"
            case .duplicate: return "doc.on.doc"
            case .exportPDF: return "square.and.arrow.up"
            case .delete: return "trash"
        }
    }

    var isDestructive: Bool {
        return self == .delete || self == .cancel
    }
}

// MARK: - Validation Helpers
struct ValidationHelper {
    /// Valide un email
    static func isValidEmail(_ email: String) -> Bool {
        return email.isValidEmail
    }

    /// Valide un SIRET
    static func isValidSIRET(_ siret: String) -> Bool {
        return siret.isValidSIRET
    }

    /// Valide un numéro de TVA français
    static func isValidFrenchVAT(_ vat: String) -> Bool {
        let pattern = "^FR[0-9]{11}$"
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(location: 0, length: vat.count)
        return regex?.firstMatch(in: vat, options: [], range: range) != nil
    }

    /// Valide un IBAN
    static func isValidIBAN(_ iban: String) -> Bool {
        let cleaned = iban.replacingOccurrences(of: " ", with: "")
        return cleaned.count >= 15 && cleaned.count <= 34 && cleaned.hasPrefix("FR")
    }

    /// Valide un BIC
    static func isValidBIC(_ bic: String) -> Bool {
        let pattern = "^[A-Z]{6}[A-Z0-9]{2}([A-Z0-9]{3})?$"
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(location: 0, length: bic.count)
        return regex?.firstMatch(in: bic, options: [], range: range) != nil
    }
}

// MARK: - Format Helpers
struct FormatHelper {
    /// Formate un numéro SIRET avec espaces
    static func formatSIRET(_ siret: String) -> String {
        let cleaned = siret.replacingOccurrences(of: " ", with: "")
        guard cleaned.count == 14 else { return siret }

        let first = String(cleaned.prefix(3))
        let second = String(cleaned.dropFirst(3).prefix(3))
        let third = String(cleaned.dropFirst(6).prefix(3))
        let fourth = String(cleaned.dropFirst(9).prefix(5))

        return "\(first) \(second) \(third) \(fourth)"
    }

    /// Formate un IBAN avec espaces
    static func formatIBAN(_ iban: String) -> String {
        let cleaned = iban.replacingOccurrences(of: " ", with: "")
        var formatted = ""

        for (index, character) in cleaned.enumerated() {
            if index > 0 && index % 4 == 0 {
                formatted += " "
            }
            formatted += String(character)
        }

        return formatted
    }

    /// Formate un numéro de facture
    static func formatFactureNumber(prefix: String, year: Int, number: Int) -> String {
        return "\(prefix)\(year)-\(String(format: "%04d", number))"
    }
}

// MARK: - Constants
struct AppConstants {
    /// Délai de paiement par défaut (en jours)
    static let defaultPaymentDelay = 30

    /// Taux de TVA par défaut
    static let defaultVATRate = 20.0

    /// Préfixe de facture par défaut
    static let defaultInvoicePrefix = "F"

    /// Mentions légales obligatoires
    static let legalMentions = [
        "TVA non applicable, art. 293 B du CGI (si micro-entreprise)",
        "Pénalités de retard: taux d'intérêt légal + 10 points",
        "Indemnité forfaitaire pour frais de recouvrement: 40 €",
        "Escompte pour paiement anticipé: néant",
        "Règlement par chèque non accepté"
    ]

    /// Formats de fichier supportés pour l'export
    static let supportedExportFormats = ["PDF", "CSV", "JSON"]
}

// MARK: - Error Types
enum FacturationError: LocalizedError {
    case invalidClient
    case invalidFacture
    case invalidAmount
    case databaseError(String)
    case validationError(String)
    case exportError(String)

    var errorDescription: String? {
        switch self {
            case .invalidClient:
                return "Client invalide"
            case .invalidFacture:
                return "Facture invalide"
            case .invalidAmount:
                return "Montant invalide"
            case .databaseError(let message):
                return "Erreur de base de données: \(message)"
            case .validationError(let message):
                return "Erreur de validation: \(message)"
            case .exportError(let message):
                return "Erreur d'export: \(message)"
        }
    }

    var recoverySuggestion: String? {
        switch self {
            case .invalidClient:
                return "Vérifiez les informations du client"
            case .invalidFacture:
                return "Vérifiez les données de la facture"
            case .invalidAmount:
                return "Saisissez un montant valide"
            case .databaseError:
                return "Contactez le support technique"
            case .validationError:
                return "Corrigez les erreurs de saisie"
            case .exportError:
                return "Réessayez l'export"
        }
    }
}

// MARK: - Utility Functions
struct UtilityFunctions {
    /// Génère un UUID sous forme de chaîne courte
    static func generateShortID() -> String {
        return UUID().uuidString.prefix(8).uppercased()
    }

    /// Calcule l'âge d'une facture en jours
    static func invoiceAgeInDays(from date: Date) -> Int {
        return Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 0
    }

    /// Détermine si une facture est en retard
    static func isInvoiceOverdue(_ facture: FactureModel) -> Bool {
        return facture.statut == .envoyee && (facture.dateEcheance ?? Date.distantFuture) < Date()
    }

    /// Calcule le prochain numéro de facture pour une année donnée
    static func calculateNextInvoiceNumber(for year: Int, existing: [FactureModel]) -> Int {
        let yearFactures = existing.filter { Calendar.current.component(.year, from: $0.dateFacture) == year }
        return yearFactures.count + 1
    }

    /// Génère une couleur basée sur une chaîne de caractères
    static func colorFromString(_ string: String) -> Color {
        let hash = string.hashValue
        let red = Double((hash & 0xFF0000) >> 16) / 255.0
        let green = Double((hash & 0x00FF00) >> 8) / 255.0
        let blue = Double(hash & 0x0000FF) / 255.0
        return Color(red: red, green: green, blue: blue)
    }
}

// MARK: - Debug Helpers
#if DEBUG
struct DebugHelper {
    /// Crée des données de test pour les factures
    static func createSampleFactures() -> [FactureModel] {
        // Implémentation pour les tests
        return []
    }

    /// Crée des données de test pour les clients
    static func createSampleClients() -> [ClientDTO] {
        // Implémentation pour les tests
        return []
    }

    /// Log personnalisé pour le développement
    static func log(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let filename = (file as NSString).lastPathComponent
        print("🐛 [\(filename):\(line)] \(function): \(message)")
    }
}
#endif

// MARK: - Performance Helpers
struct PerformanceHelper {
    /// Mesure le temps d'exécution d'une closure
    static func measureTime<T>(operation: () throws -> T) rethrows -> (result: T, time: TimeInterval) {
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = try operation()
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        return (result, timeElapsed)
    }

    /// Exécute une opération avec un délai
    static func delay(_ seconds: Double, execute: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds, execute: execute)
    }
}

// MARK: - File Management Helpers
struct FileManager {
    /// Répertoire de documents de l'application
    static var documentsDirectory: URL {
        let paths = Foundation.FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }

    /// Répertoire de cache de l'application
    static var cacheDirectory: URL {
        let paths = Foundation.FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        return paths[0]
    }

    /// Crée un répertoire s'il n'existe pas
    static func createDirectoryIfNeeded(at url: URL) throws {
        if !Foundation.FileManager.default.fileExists(atPath: url.path) {
            try Foundation.FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        }
    }

    /// Sauvegarde des données JSON dans un fichier
    static func saveJSON<T: Codable>(_ data: T, to fileName: String) throws {
        let url = documentsDirectory.appendingPathComponent(fileName)
        let encoded = try JSONEncoder().encode(data)
        try encoded.write(to: url)
    }

    /// Charge des données JSON depuis un fichier
    static func loadJSON<T: Codable>(_ type: T.Type, from fileName: String) throws -> T {
        let url = documentsDirectory.appendingPathComponent(fileName)
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(type, from: data)
    }
}

// MARK: - Notification Center Extensions
extension NotificationCenter {
    /// Poste une notification personnalisée
    static func postFactureUpdated(_ facture: FactureModel) {
        NotificationCenter.default.post(
            name: .factureDidUpdate,
            object: facture
        )
    }

    /// Poste une notification de mise à jour client
    static func postClientUpdated(_ client: ClientModel) {
        NotificationCenter.default.post(
            name: .clientDidUpdate,
            object: client
        )
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let factureDidUpdate = Notification.Name("factureDidUpdate")
    static let clientDidUpdate = Notification.Name("clientDidUpdate")
    static let dataDidRefresh = Notification.Name("dataDidRefresh")
    static let exportDidComplete = Notification.Name("exportDidComplete")
}

// MARK: - UserDefaults Extensions
extension UserDefaults {
    /// Clés pour les préférences utilisateur
    enum Keys: String, CaseIterable {
        case lastBackupDate = "lastBackupDate"
        case preferredExportFormat = "preferredExportFormat"
        case showAdvancedFeatures = "showAdvancedFeatures"
        case autoSaveInterval = "autoSaveInterval"
        case defaultCurrency = "defaultCurrency"
        case themeName = "themeName"
    }

    /// Sauvegarde la date du dernier backup
    var lastBackupDate: Date? {
        get { object(forKey: Keys.lastBackupDate.rawValue) as? Date }
        set { set(newValue, forKey: Keys.lastBackupDate.rawValue) }
    }

    /// Format d'export préféré
    var preferredExportFormat: String {
        get { string(forKey: Keys.preferredExportFormat.rawValue) ?? "PDF" }
        set { set(newValue, forKey: Keys.preferredExportFormat.rawValue) }
    }

    /// Affichage des fonctionnalités avancées
    var showAdvancedFeatures: Bool {
        get { bool(forKey: Keys.showAdvancedFeatures.rawValue) }
        set { set(newValue, forKey: Keys.showAdvancedFeatures.rawValue) }
    }

    /// Intervalle de sauvegarde automatique (en minutes)
    var autoSaveInterval: Int {
        get { integer(forKey: Keys.autoSaveInterval.rawValue) != 0 ? integer(forKey: Keys.autoSaveInterval.rawValue) : 5 }
        set { set(newValue, forKey: Keys.autoSaveInterval.rawValue) }
    }
}

// MARK: - Environment Values
struct ShowAdvancedFeaturesKey: EnvironmentKey {
    static let defaultValue = false
}

struct AutoSaveIntervalKey: EnvironmentKey {
    static let defaultValue = 5
}

extension EnvironmentValues {
    var showAdvancedFeatures: Bool {
        get { self[ShowAdvancedFeaturesKey.self] }
        set { self[ShowAdvancedFeaturesKey.self] = newValue }
    }

    var autoSaveInterval: Int {
        get { self[AutoSaveIntervalKey.self] }
        set { self[AutoSaveIntervalKey.self] = newValue }
    }
}

// MARK: - Custom View Modifiers
struct CardModifier: ViewModifier {
    let cornerRadius: CGFloat
    let shadowRadius: CGFloat

    init(cornerRadius: CGFloat = 12, shadowRadius: CGFloat = 3) {
        self.cornerRadius = cornerRadius
        self.shadowRadius = shadowRadius
    }

    func body(content: Content) -> some View {
        content
            .background(Color.systemBackground)
            .cornerRadius(cornerRadius)
            .shadow(color: .black.opacity(0.05), radius: shadowRadius, x: 0, y: 1)
    }
}

struct HoverEffectModifier: ViewModifier {
    @State private var isHovered = false
    let scale: CGFloat

    init(scale: CGFloat = 1.02) {
        self.scale = scale
    }

    func body(content: Content) -> some View {
        content
            .scaleEffect(isHovered ? scale : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isHovered)
            .onHover { hovering in
                isHovered = hovering
            }
    }
}

struct LoadingModifier: ViewModifier {
    let isLoading: Bool

    func body(content: Content) -> some View {
        ZStack {
            content
                .opacity(isLoading ? 0.5 : 1.0)

            if isLoading {
                ProgressView()
                    .scaleEffect(1.2)
                    .progressViewStyle(CircularProgressViewStyle())
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isLoading)
    }
}

// Extensions des View Modifiers
extension View {
    func cardStyle(cornerRadius: CGFloat = 12, shadowRadius: CGFloat = 3) -> some View {
        modifier(CardModifier(cornerRadius: cornerRadius, shadowRadius: shadowRadius))
    }

    func hoverEffect(scale: CGFloat = 1.02) -> some View {
        modifier(HoverEffectModifier(scale: scale))
    }

    func loading(_ isLoading: Bool) -> some View {
        modifier(LoadingModifier(isLoading: isLoading))
    }
}

// MARK: - Math Helpers
struct MathHelper {
    /// Arrondit un nombre à n décimales
    static func round(_ value: Double, to places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (value * divisor).rounded() / divisor
    }

    /// Calcule le pourcentage entre deux valeurs
    static func percentage(of value: Double, from total: Double) -> Double {
        guard total != 0 else { return 0 }
        return (value / total) * 100
    }

    /// Calcule la TVA sur un montant HT
    static func calculateVAT(on amount: Double, rate: Double) -> Double {
        return amount * (rate / 100)
    }

    /// Calcule le montant TTC à partir du HT et du taux de TVA
    static func calculateTTC(from ht: Double, vatRate: Double) -> Double {
        return ht + calculateVAT(on: ht, rate: vatRate)
    }

    /// Calcule le montant HT à partir du TTC et du taux de TVA
    static func calculateHT(from ttc: Double, vatRate: Double) -> Double {
        return ttc / (1 + vatRate / 100)
    }
}

// MARK: - Theme Support
struct LegacyAppTheme {
    let name: String
    let primaryColor: Color
    let secondaryColor: Color
    let backgroundColor: Color
    let textColor: Color

    static let `default` = LegacyAppTheme(
        name: "Default",
        primaryColor: .blue,
        secondaryColor: .gray,
        backgroundColor: Color.systemBackground,
        textColor: Color.label
    )

    static let dark = LegacyAppTheme(
        name: "Dark",
        primaryColor: .blue,
        secondaryColor: .gray,
        backgroundColor: .black,
        textColor: .white
    )

    static let blue = LegacyAppTheme(
        name: "Blue",
        primaryColor: .appBlue,
        secondaryColor: .appGray,
        backgroundColor: Color.systemBackground,
        textColor: Color.label
    )
}

// MARK: - Export Helpers
struct ExportHelper {
    /// Types de fichiers d'export supportés
    enum ExportType: String, CaseIterable {
        case pdf = "PDF"
        case csv = "CSV"
        case json = "JSON"
        case xlsx = "Excel"

        var fileExtension: String {
            switch self {
                case .pdf: return "pdf"
                case .csv: return "csv"
                case .json: return "json"
                case .xlsx: return "xlsx"
            }
        }

        var mimeType: String {
            switch self {
                case .pdf: return "application/pdf"
                case .csv: return "text/csv"
                case .json: return "application/json"
                case .xlsx: return "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
            }
        }
    }

    /// Génère un nom de fichier avec timestamp
    static func generateFileName(prefix: String, type: ExportType) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let timestamp = formatter.string(from: Date())
        return "\(prefix)_\(timestamp).\(type.fileExtension)"
    }

    /// Prépare les données de factures pour l'export CSV
    static func prepareFacturesForCSV(_ factures: [FactureModel]) -> [[String]] {
        var data: [[String]] = []

        // En-têtes
        data.append([
            "Numéro",
            "Date",
            "Client",
            "Montant HT",
            "TVA",
            "Montant TTC",
            "Statut",
            "Date d'échéance"
        ])

        // Données
        for facture in factures {
            data.append([
                facture.numero,
                facture.dateFacture.frenchFormatted,
                facture.client?.nomCompletClient ?? "",
                String(format: "%.2f", facture.sousTotal),
                String(format: "%.2f", facture.montantTVA),
                String(format: "%.2f", facture.totalTTC),
                facture.statut.rawValue,
                facture.dateEcheance?.frenchFormatted ?? ""
            ])
        }

        return data
    }
}

// MARK: - Security Helpers
struct SecurityHelper {
    /// Génère un token de sécurité aléatoire
    static func generateSecureToken(length: Int = 32) -> String {
        let characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
        return String((0..<length).map { _ in characters.randomElement()! })
    }

    /// Hash une chaîne avec SHA256
    static func sha256(_ input: String) -> String {
        guard let data = input.data(using: .utf8) else { return "" }
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}

// Import nécessaire pour SHA256
import CryptoKit

// MARK: - Analytics Helpers
struct AnalyticsHelper {
    /// Événements d'analyse
    enum Event: String {
        case factureCreated = "facture_created"
        case factureUpdated = "facture_updated"
        case factureDeleted = "facture_deleted"
        case clientCreated = "client_created"
        case clientUpdated = "client_updated"
        case pdfExported = "pdf_exported"
        case dataExported = "data_exported"
    }

    /// Log un événement d'analyse
    static func logEvent(_ event: Event, parameters: [String: Any] = [:]) {
#if DEBUG
        print("📊 Analytics: \(event.rawValue) - \(parameters)")
#endif
        // Ici, vous pourriez intégrer une solution d'analytics réelle
    }

    /// Calcule des métriques de performance
    static func calculatePerformanceMetrics(factures: [FactureModel]) -> [String: Any] {
        let totalRevenue = factures.filter { $0.statut == .payee }.reduce(0) { $0 + $1.totalTTC }
        let avgInvoiceValue = factures.isEmpty ? 0 : totalRevenue / Double(factures.count)
        let paymentRate = factures.isEmpty ? 0 : Double(factures.filter { $0.statut == .payee }.count) / Double(factures.count)

        return [
            "total_revenue": totalRevenue,
            "average_invoice_value": avgInvoiceValue,
            "payment_rate": paymentRate,
            "total_invoices": factures.count
        ]
    }
}
