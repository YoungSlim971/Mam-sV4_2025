import Foundation
import SwiftData

// Extensions providing model <-> DTO conversion
// Moved from main app models to DataLayer

// MARK: - ClientModel
public extension ClientModel {
    func toDTO() -> ClientDTO {
        ClientDTO(
            id: id,
            nom: nom,
            entreprise: entreprise,
            email: email,
            telephone: telephone,
            siret: siret,
            numeroTVA: numeroTVA,
            adresse: adresse,
            adresseRue: adresseRue,
            adresseCodePostal: adresseCodePostal,
            adresseVille: adresseVille,
            adressePays: adressePays
        )
    }

    static func fromDTO(_ dto: ClientDTO) -> ClientModel {
        let client = ClientModel()
        client.id = dto.id
        client.nom = dto.nom
        client.entreprise = dto.entreprise
        client.email = dto.email
        client.telephone = dto.telephone
        client.siret = dto.siret
        client.numeroTVA = dto.numeroTVA
        client.adresse = dto.adresse
        client.adresseRue = dto.adresseRue
        client.adresseCodePostal = dto.adresseCodePostal
        client.adresseVille = dto.adresseVille
        client.adressePays = dto.adressePays
        return client
    }

    func updateFromDTO(_ dto: ClientDTO) {
        nom = dto.nom
        entreprise = dto.entreprise
        email = dto.email
        telephone = dto.telephone
        siret = dto.siret
        numeroTVA = dto.numeroTVA
        adresse = dto.adresse
        adresseRue = dto.adresseRue
        adresseCodePostal = dto.adresseCodePostal
        adresseVille = dto.adresseVille
        adressePays = dto.adressePays
    }
}

// MARK: - ProduitModel
public extension ProduitModel {
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

// MARK: - LigneFacture
public extension LigneFacture {
    func toDTO() -> LigneFactureDTO {
        LigneFactureDTO(
            id: id,
            designation: designation,
            quantite: quantite,
            prixUnitaire: prixUnitaire,
            referenceCommande: referenceCommande,
            dateCommande: dateCommande,
            produitId: produit?.id,
            factureId: facture?.id
        )
    }

    static func fromDTO(_ dto: LigneFactureDTO) -> LigneFacture {
        let ligne = LigneFacture()
        ligne.id = dto.id
        ligne.designation = dto.designation
        ligne.quantite = dto.quantite
        ligne.prixUnitaire = dto.prixUnitaire
        ligne.referenceCommande = dto.referenceCommande
        ligne.dateCommande = dto.dateCommande
        return ligne
    }

    func updateFromDTO(_ dto: LigneFactureDTO) {
        designation = dto.designation
        quantite = dto.quantite
        prixUnitaire = dto.prixUnitaire
        referenceCommande = dto.referenceCommande
        dateCommande = dto.dateCommande
    }
}

// MARK: - FactureModel
public extension FactureModel {
    func toDTO() -> FactureDTO {
        FactureDTO(
            id: id,
            numero: numero,
            dateFacture: dateFacture,
            dateEcheance: dateEcheance,
            datePaiement: datePaiement,
            tva: tva,
            conditionsPaiement: conditionsPaiement.rawValue,
            remisePourcentage: remisePourcentage,
            statut: statut.rawValue,
            notes: notes,
            notesCommentaireFacture: notesCommentaireFacture,
            clientId: client?.id ?? UUID(),
            ligneIds: lignes.map { $0.id }
        )
    }

    static func fromDTO(_ dto: FactureDTO, context: ModelContext, client: ClientModel?, lignes: [LigneFacture]) -> FactureModel {
        let facture = FactureModel()
        facture.id = dto.id
        facture.numero = dto.numero
        facture.dateFacture = dto.dateFacture
        facture.dateEcheance = dto.dateEcheance
        facture.datePaiement = dto.datePaiement
        facture.client = client
        facture.lignes = lignes
        facture.tva = dto.tva
        facture.conditionsPaiement = ConditionsPaiement(rawValue: dto.conditionsPaiement) ?? .virement
        facture.remisePourcentage = dto.remisePourcentage
        facture.statut = StatutFacture(rawValue: dto.statut) ?? .brouillon
        facture.notes = dto.notes
        facture.notesCommentaireFacture = dto.notesCommentaireFacture
        context.insert(facture)
        return facture
    }

    func updateFromDTO(_ dto: FactureDTO) {
        numero = dto.numero
        dateFacture = dto.dateFacture
        dateEcheance = dto.dateEcheance
        datePaiement = dto.datePaiement
        tva = dto.tva
        conditionsPaiement = ConditionsPaiement(rawValue: dto.conditionsPaiement) ?? .virement
        remisePourcentage = dto.remisePourcentage
        statut = StatutFacture(rawValue: dto.statut) ?? .brouillon
        notes = dto.notes
        notesCommentaireFacture = dto.notesCommentaireFacture
    }
}

// MARK: - EntrepriseModel
public extension EntrepriseModel {
    func toDTO() -> EntrepriseDTO {
        EntrepriseDTO(
            id: id,
            nom: nom,
            nomContact: nomContact,
            nomDirigeant: nomDirigeant,
            telephone: telephone,
            email: email,
            siret: siret,
            numeroTVA: numeroTVA,
            iban: iban,
            bic: bic,
            adresseRue: adresseRue,
            adresseCodePostal: adresseCodePostal,
            adresseVille: adresseVille,
            adressePays: adressePays,
            certificationTexte: certificationTexte,
            logo: logo,
            prefixeFacture: prefixeFacture,
            prochainNumero: prochainNumero,
            tvaTauxDefaut: tvaTauxDefaut,
            delaiPaiementDefaut: delaiPaiementDefaut,
            domaine: domaine
        )
    }

    static func fromDTO(_ dto: EntrepriseDTO) -> EntrepriseModel {
        let entreprise = EntrepriseModel()
        entreprise.id = dto.id
        entreprise.nom = dto.nom
        entreprise.adresseRue = dto.adresseRue
        entreprise.adresseCodePostal = dto.adresseCodePostal
        entreprise.adresseVille = dto.adresseVille
        entreprise.adressePays = dto.adressePays
        entreprise.email = dto.email
        entreprise.telephone = dto.telephone
        entreprise.siret = dto.siret
        entreprise.numeroTVA = dto.numeroTVA
        entreprise.prefixeFacture = dto.prefixeFacture
        entreprise.iban = dto.iban
        entreprise.bic = dto.bic
        entreprise.logo = dto.logo
        entreprise.domaine = dto.domaine
        return entreprise
    }

    func updateFromDTO(_ dto: EntrepriseDTO) {
        nom = dto.nom
        adresseRue = dto.adresseRue
        adresseCodePostal = dto.adresseCodePostal
        adresseVille = dto.adresseVille
        adressePays = dto.adressePays
        email = dto.email
        telephone = dto.telephone
        siret = dto.siret
        numeroTVA = dto.numeroTVA
        prefixeFacture = dto.prefixeFacture
        iban = dto.iban
        bic = dto.bic
        logo = dto.logo
        domaine = dto.domaine
    }
}
