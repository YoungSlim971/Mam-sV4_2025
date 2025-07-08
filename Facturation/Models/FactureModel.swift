import Foundation
import SwiftData
import DataLayer

@Model
final class FactureModel {

    init(numero: String,
         tva: Double = 20.0,
         conditionsPaiement: ConditionsPaiement = .virement,
         remisePourcentage: Double = 0.0,
         statut: StatutFacture = .brouillon,
         notes: String = "",
         client: ClientModel? = nil) {
        self.id = UUID()
        self.numero = numero
        self.dateFacture = Date()
        self.dateEcheance = Calendar.current.date(byAdding: .day, value: 30, to: Date())
        self.datePaiement = nil
        self.tva = tva
        self.conditionsPaiement = conditionsPaiement
        self.remisePourcentage = remisePourcentage
        self.statut = statut
        self.notes = notes
        self.notesCommentaireFacture = nil
        self.client = client
        self.lignes = []
    }
    @Attribute(.unique) var id: UUID = UUID()
    var numero: String = ""
    var dateFacture: Date = Date()
    var dateEcheance: Date?
    var datePaiement: Date? {
        didSet {
            if let paiement = datePaiement, paiement <= Date() {
                statut = .payee
            }
        }
    }
    var tva: Double = 0.0
    var conditionsPaiement: ConditionsPaiement = ConditionsPaiement.virement
    var remisePourcentage: Double = 0.0
    var statut: StatutFacture = StatutFacture.brouillon
    var notes: String = ""
    var notesCommentaireFacture: String?
    
    // Relation avec Client
    @Relationship var client: ClientModel?

    // Relation avec lignes avec cascade delete
    @Relationship(deleteRule: .cascade)
    var lignes: [LigneFacture] = []

    init() {
        self.id = UUID()
        self.numero = ""
        self.dateFacture = Date()
        self.dateEcheance = Calendar.current.date(byAdding: .day, value: 30, to: Date())
        self.datePaiement = nil
        self.tva = 20.0
        self.conditionsPaiement = .virement
        self.remisePourcentage = 0.0
        self.statut = .brouillon
        self.notes = ""
        self.notesCommentaireFacture = nil
        self.client = nil
        self.lignes = []
    }
    
    init(client: ClientModel,
         numero: String,
         conditionsPaiement: ConditionsPaiement = ConditionsPaiement.virement,
         remisePourcentage: Double = 0.0) {
        self.numero = numero
        self.dateFacture = Date()
        self.dateEcheance = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
        self.datePaiement = nil
        self.client = client
        self.lignes = []
        self.tva = 20.0
        self.conditionsPaiement = conditionsPaiement
        self.remisePourcentage = remisePourcentage
        self.statut = .brouillon
        self.notes = ""
    }

    var sousTotal: Double {
        lignes.reduce(0) { $0 + $1.total }
    }

    var montantTVA: Double {
        sousTotal * (tva / 100)
    }

    var totalTTC: Double {
        let brut = sousTotal + montantTVA
        let remise = brut * (remisePourcentage / 100)
        return brut - remise
    }
}

// MARK: - Validation
extension FactureModel {
    var isValidModel: Bool {
        guard let client = client else { return false }
        return !numero.isEmpty && totalTTC > 0 && client.isValidModel
    }
}

// MARK: - Extension de conversion FactureModel <-> FactureDTO
extension FactureModel {
    func toDTO() -> FactureDTO {
        return FactureDTO(
            id: self.id,
            numero: self.numero,
            dateFacture: self.dateFacture,
            dateEcheance: self.dateEcheance,
            datePaiement: self.datePaiement,
            tva: self.tva,
            conditionsPaiement: self.conditionsPaiement.rawValue,
            remisePourcentage: self.remisePourcentage,
            statut: self.statut.rawValue,
            notes: self.notes,
            notesCommentaireFacture: self.notesCommentaireFacture,
            clientId: self.client?.id ?? UUID(),
            ligneIds: self.lignes.map { $0.id }
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
