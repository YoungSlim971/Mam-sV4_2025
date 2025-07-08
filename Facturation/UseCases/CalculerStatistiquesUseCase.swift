//
//  CalculerStatistiquesUseCase.swift
//  Facturation
//
//  Created by Young Slim on 06/07/2025.
//



import Foundation
import DataLayer

final class CalculerStatistiquesUseCase {

    private let dataService: DataService

    init(dataService: DataService) {
        self.dataService = dataService
    }

    func executer() async -> StatistiquesDTO {
        let factures = await dataService.fetchFactureDTOs()
        let lignes = await dataService.fetchLignesFactures()

        let chiffreAffairesMensuel = calculerChiffreAffairesMensuel(factures: factures, lignes: lignes)
        let delaiPaiementMoyen = calculerDelaiPaiementMoyen(factures: factures)
        let repartitionParStatut = calculerRépartitionParStatut(factures: factures)

        return StatistiquesDTO(
            chiffreAffairesMensuel: chiffreAffairesMensuel,
            delaiPaiementMoyen: delaiPaiementMoyen,
            repartitionParStatut: repartitionParStatut
        )
    }

    private func calculerChiffreAffairesMensuel(factures: [FactureDTO], lignes: [LigneFactureDTO]) -> [StatistiqueMensuelle] {
        var result: [String: Double] = [:]

        for facture in factures where facture.statut == "Payée" {
            let mois = facture.dateFacture.formatToMonthString()
            let total = facture.calculateTotalTTC(with: lignes)
            result[mois, default: 0.0] += total
        }

        return result.map { mois, total in
            StatistiqueMensuelle(id: UUID(), mois: mois, total: total)
        }.sorted { $0.mois < $1.mois }
    }

    private func calculerDelaiPaiementMoyen(factures: [FactureDTO]) -> Double {
        let payees = factures.filter { $0.statut == "Payée" && $0.datePaiement != nil }
        guard !payees.isEmpty else { return 0 }

        let totalJours = payees.reduce(0.0) { acc, facture in
            acc + facture.dateFacture.daysBetween(facture.datePaiement!)
        }

        return totalJours / Double(payees.count)
    }

    private func calculerRépartitionParStatut(factures: [FactureDTO]) -> [String: Int] {
        var repartition: [String: Int] = [:]
        for facture in factures {
            repartition[facture.statut, default: 0] += 1
        }
        return repartition
    }
}
