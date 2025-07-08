import Foundation
import SwiftData

@Model
public final class ProduitModel {
    @Attribute(.unique) public var id: UUID = UUID()
    public var designation: String = ""
    public var details: String?
    public var prixUnitaire: Double = 0.0
    public var icon: String? = nil
    public var iconImageData: Data? = nil

    public init() {}
    
    public init(designation: String, details: String? = nil, prixUnitaire: Double, icon: String? = nil, iconImageData: Data? = nil) {
        self.designation = designation
        self.details = details
        self.prixUnitaire = prixUnitaire
        self.icon = icon
        self.iconImageData = iconImageData
    }
    public var isValidModel: Bool {
        !designation.isEmpty && prixUnitaire >= 0
    }
}

