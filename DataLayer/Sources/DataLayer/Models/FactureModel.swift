import Foundation
import SwiftData

@Model
public final class FactureModel {

    public init(numero: String,
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
    @Attribute(.unique) public var id: UUID = UUID()
    public var numero: String = ""
    public var dateFacture: Date = Date()
    public var dateEcheance: Date?
    public var datePaiement: Date? {
        didSet {
            if let paiement = datePaiement, paiement <= Date() {
                statut = .payee
            }
        }
    }
    public var tva: Double = 0.0
    public var conditionsPaiement: ConditionsPaiement = ConditionsPaiement.virement
    public var remisePourcentage: Double = 0.0
    public var statut: StatutFacture = StatutFacture.brouillon
    public var notes: String = ""
    public var notesCommentaireFacture: String?
    
    // Relation avec Client
    @Relationship public var client: ClientModel?

    // Relation avec lignes avec cascade delete
    @Relationship(deleteRule: .cascade) public var lignes: [LigneFacture] = []

    public init() {
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
    
    public init(client: ClientModel,
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

    public var sousTotal: Double {
        lignes.reduce(0) { $0 + $1.total }
    }

    public var montantTVA: Double {
        sousTotal * (tva / 100)
    }

    public var totalTTC: Double {
        let brut = sousTotal + montantTVA
        let remise = brut * (remisePourcentage / 100)
        return brut - remise
    }
}

// MARK: - Validation
public extension FactureModel {
    public var isValidModel: Bool {
        guard let client = client else { return false }
        return !numero.isEmpty && totalTTC > 0 && client.isValidModel
    }
}


