
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
    @EnvironmentObject private var dataService: DataService

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
                Text("Montant total : \(facture.calculateTotalTTC(with: dataService.lignes).formatted(.currency(code: "EUR")))")
                Text("Statut : \(facture.statutDisplay)")
            }

            Divider()

            Text("Lignes de facture")
                .font(.headline)

            List(dataService.lignes.filter { facture.ligneIds.contains($0.id) }) { ligne in
                VStack(alignment: .leading) {
                    Text(ligne.designation)
                        .font(.subheadline)
                    Text("\(ligne.quantite, specifier: "%.2f") x \(ligne.prixUnitaire.formatted(.currency(code: "EUR")))")
                        .font(.caption)
                }
            }
        }
        .padding()
        .navigationTitle("Facture \(facture.numero)")
    }
}

