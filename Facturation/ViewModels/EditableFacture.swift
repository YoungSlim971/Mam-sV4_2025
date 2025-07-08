import Foundation
import DataLayer

struct EditableFacture {
    var dateFacture: Date
    var dateEcheance: Date
    var datePaiement: Date?
    var conditionsPaiement: ConditionsPaiement
    var remisePourcentage: Double
    var statut: StatutFacture
    var notes: String
    var notesCommentaireFacture: String?
    var tva: Double
    var lignes: [EditableLigneFacture]

    // Properties for invoice numbering
    var numerotationAutomatique: Bool
    var numeroPersonnalise: String?

    init() {
        self.dateFacture = Date()
        self.dateEcheance = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
        self.datePaiement = nil
        self.conditionsPaiement = .virement
        self.remisePourcentage = 0.0
        self.statut = .brouillon
        self.notes = ""
        self.notesCommentaireFacture = nil
        self.tva = 20.0
        self.lignes = []
        
        // Default to automatic numbering
        self.numerotationAutomatique = true
        self.numeroPersonnalise = nil
    }

    init(from facture: FactureModel) {
        self.dateFacture = facture.dateFacture
        self.dateEcheance = facture.dateEcheance ?? Date()
        self.datePaiement = facture.datePaiement
        self.conditionsPaiement = facture.conditionsPaiement
        self.remisePourcentage = facture.remisePourcentage
        self.statut = facture.statut
        self.notes = facture.notes
        self.notesCommentaireFacture = facture.notesCommentaireFacture
        self.tva = facture.tva
        self.lignes = facture.lignes.map { EditableLigneFacture(from: $0) }

        // When editing, the number is already set.
        // We can consider it "manual" with the existing number.
        self.numerotationAutomatique = false
        self.numeroPersonnalise = facture.numero
    }

    init(fromDTO factureDTO: FactureDTO, lignes: [LigneFactureDTO] = []) {
        self.dateFacture = factureDTO.dateFacture
        self.dateEcheance = factureDTO.dateEcheance ?? Date()
        self.datePaiement = factureDTO.datePaiement
        self.conditionsPaiement = ConditionsPaiement(rawValue: factureDTO.conditionsPaiement) ?? .virement
        self.remisePourcentage = factureDTO.remisePourcentage
        self.statut = StatutFacture(rawValue: factureDTO.statut) ?? .brouillon
        self.notes = factureDTO.notes
        self.notesCommentaireFacture = factureDTO.notesCommentaireFacture
        self.tva = factureDTO.tva
        
        // Filter lignes for this facture
        let factureLignes = lignes.filter { factureDTO.ligneIds.contains($0.id) }
        self.lignes = factureLignes.map { EditableLigneFacture(fromDTO: $0) }

        // When editing, the number is already set
        self.numerotationAutomatique = false
        self.numeroPersonnalise = factureDTO.numero
    }

    func applyTo(_ facture: FactureModel) {
        facture.dateFacture = dateFacture
        facture.dateEcheance = dateEcheance
        facture.datePaiement = datePaiement
        facture.conditionsPaiement = conditionsPaiement
        facture.remisePourcentage = remisePourcentage
        facture.statut = statut
        facture.notes = notes
        facture.notesCommentaireFacture = notesCommentaireFacture
        facture.tva = tva

        // Sync lines
        for (index, editable) in lignes.enumerated() {
            if index < facture.lignes.count {
                editable.applyTo(facture.lignes[index])
            } else {
                let newLine = LigneFacture()
                editable.applyTo(newLine)
                newLine.facture = facture
                facture.lignes.append(newLine)
            }
        }
        // Remove extra lines if any
        if facture.lignes.count > lignes.count {
            facture.lignes.removeLast(facture.lignes.count - lignes.count)
        }
    }
    
    // MARK: - Computed Properties
    var sousTotal: Double {
        return lignes.reduce(0) { $0 + $1.total }
    }
    
    var montantTVA: Double {
        return sousTotal * (tva / 100)
    }
    
    var totalTTC: Double {
        let totalAvantRemise = sousTotal + montantTVA
        let remise = totalAvantRemise * (remisePourcentage / 100)
        return totalAvantRemise - remise
    }
}
