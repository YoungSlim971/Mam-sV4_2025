//
//  ProduitDTO.swift
//  Facturation
//
//  Created by Young Slim on 06/07/2025.
//
import Foundation


struct ProduitDTO: Codable, Sendable, Identifiable, Hashable {
    let id: UUID
    var designation: String
    var details: String?
    var prixUnitaire: Double
    var icon: String?
    var iconImageData: Data?
}

// MARK: - Extension de conversion ProduitModel <-> ProduitDTO
extension ProduitModel {
    func toDTO() -> ProduitDTO {
        ProduitDTO(
            id: id,
            designation: designation,
            details: details,
            prixUnitaire: prixUnitaire,
            icon: icon,
            iconImageData: iconImageData
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
