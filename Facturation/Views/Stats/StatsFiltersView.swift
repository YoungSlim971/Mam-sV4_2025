import SwiftUI

struct StatsFiltersView: View {
    @Binding var type: StatistiqueType
    @Binding var periode: PeriodePredefinie
    @Binding var dateDebut: Date
    @Binding var dateFin: Date
    @Binding var selectedClient: ClientDTO?
    @Binding var selectedProduit: ProduitDTO?
    let clients: [ClientDTO]
    let produits: [ProduitDTO]
    var resetAction: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            Picker("Type de Statistique", selection: $type) {
                ForEach(StatistiqueType.allCases, id: \.self) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(.segmented)

            Group {
                switch type {
                case .clients:
                    Picker("Client", selection: $selectedClient) {
                        Text("Tous les clients").tag(nil as ClientDTO?)
                        ForEach(clients, id: \.id) { client in
                            Text(client.nomCompletClient).tag(client as ClientDTO?)
                        }
                    }
                    .pickerStyle(.menu)
                case .produits:
                    Picker("Produit", selection: $selectedProduit) {
                        Text("Tous les produits").tag(ProduitDTO?.none)
                        ForEach(produits) { produit in
                            Text(produit.designation).tag(Optional(produit))
                        }
                    }
                    .pickerStyle(.menu)
                }
            }

            Picker("Période", selection: $periode) {
                ForEach(PeriodePredefinie.allCases, id: \.self) { period in
                    Text(period.rawValue).tag(period)
                }
            }

            if periode == .personnalise {
                DatePicker("Début", selection: $dateDebut, displayedComponents: .date)
                DatePicker("Fin", selection: $dateFin, displayedComponents: .date)
            }

            Button(action: resetAction) {
                Image(systemName: "arrow.clockwise")
            }
        }
    }
}
