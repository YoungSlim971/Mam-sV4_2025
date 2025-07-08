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

// MARK: - Extension de conversion ProduitModel <-> ProduitDTO
extension ProduitModel {
    func toDTO() -> ProduitDTO {
        return ProduitDTO(
            id: self.id,
            designation: self.designation,
            details: self.details,
            prixUnitaire: self.prixUnitaire,
            icon: self.icon,
            iconImageData: self.iconImageData
        )
    }

    static func fromDTO(_ dto: ProduitDTO) -> ProduitModel {
        let produit = ProduitModel()
        produit.id = dto.id
        produit.designation = dto.designation
        produit.details = dto.details
        produit.prixUnitaire = dto.prixUnitaire
        produit.icon = dto.icon
        produit.iconImageData = dto.iconImageData
        return produit
    }

    func updateFromDTO(_ dto: ProduitDTO) {
        designation = dto.designation
        details = dto.details
        prixUnitaire = dto.prixUnitaire
        icon = dto.icon
        iconImageData = dto.iconImageData
    }
}

