import Foundation
import SwiftData
import DataLayer

@Model
final class ProduitModel {
    @Attribute(.unique) var id: UUID = UUID()
    var designation: String = ""
    var details: String?
    var prixUnitaire: Double = 0.0
    var icon: String? = nil
    var iconImageData: Data? = nil

    init() {}
    
    init(designation: String, details: String? = nil, prixUnitaire: Double, icon: String? = nil, iconImageData: Data? = nil) {
        self.designation = designation
        self.details = details
        self.prixUnitaire = prixUnitaire
        self.icon = icon
        self.iconImageData = iconImageData
    }
    var isValidModel: Bool {
        !designation.isEmpty && prixUnitaire >= 0
    }
}

