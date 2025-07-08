import Foundation

public struct ProduitDTO: Codable, Sendable, Identifiable, Hashable {
    public let id: UUID
    public var designation: String
    public var details: String?
    public var prixUnitaire: Double
    public var icon: String?
    public var iconImageData: Data?
    
    public init(id: UUID, designation: String, details: String? = nil, prixUnitaire: Double, icon: String? = nil, iconImageData: Data? = nil) {
        self.id = id
        self.designation = designation
        self.details = details
        self.prixUnitaire = prixUnitaire
        self.icon = icon
        self.iconImageData = iconImageData
    }
}