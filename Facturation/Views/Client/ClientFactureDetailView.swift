
//
//  ClientFactureDetailView.swift
//  Facturation
//
//  Created by Young Slim on 07/07/2025.
//

import SwiftUI

struct ClientFactureDetailView: View {
    let facture: FactureModel

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
                Text("Montant total : \(facture.totalTTC.formatted(.currency(code: "EUR")))")
                Text("Statut : \(facture.statut.description)")
            }

            Divider()

            Text("Lignes de facture")
                .font(.headline)

            List(facture.lignes) { ligne in
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

