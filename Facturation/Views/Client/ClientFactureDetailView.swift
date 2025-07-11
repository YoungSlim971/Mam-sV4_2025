
//
//  ClientFactureDetailView.swift
//  Facturation
//
//  Created by Young Slim on 07/07/2025.
//

import SwiftUI
import DataLayer

struct ClientFactureDetailView: View {
    let facture: FactureDTO
    @EnvironmentObject private var dependencyContainer: DependencyContainer
    @State private var lignes: [LigneFactureDTO] = []
    @State private var totalTTC: Double = 0.0
    @State private var isLoading = true

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Détails de la facture")
                .font(.title)
                .bold()

            Group {
                Text("Numéro : \(facture.numero)")
                Text("Date : \(facture.dateFacture.formatted(date: .abbreviated, time: .omitted))")
                if let dateEcheance = facture.dateEcheance {
                    Text("Échéance : \(dateEcheance.formatted(date: .abbreviated, time: .omitted))")
                }
                Text("Montant total : \(totalTTC.formatted(.currency(code: "EUR")))")
                Text("Statut : \(facture.statutDisplay)")
            }

            Divider()

            Text("Lignes de facture")
                .font(.headline)

            if isLoading {
                ProgressView("Chargement...")
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                List(lignes) { ligne in
                    VStack(alignment: .leading) {
                        Text(ligne.designation)
                            .font(.subheadline)
                        Text("\(ligne.quantite, specifier: "%.2f") x \(ligne.prixUnitaire.formatted(.currency(code: "EUR")))")
                            .font(.caption)
                    }
                }
            }
        }
        .padding()
        .navigationTitle("Facture \(facture.numero)")
        .onAppear {
            Task {
                await loadFactureDetails()
            }
        }
    }
    
    private func loadFactureDetails() async {
        isLoading = true
        
        let lignesResult = await dependencyContainer.fetchLignesUseCase.execute()
        if case .success(let allLignes) = lignesResult {
            let facturesLignes = allLignes.filter { $0.factureId == facture.id }
            lignes = facturesLignes
            totalTTC = facture.calculateTotalTTC(with: facturesLignes)
        }
        
        isLoading = false
    }
}

