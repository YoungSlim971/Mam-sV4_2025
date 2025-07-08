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
        VStack(alignment: .leading, spacing: 16) {
            // 1. Type de statistique (en haut, section distincte, segmented)
            GroupBox {
                Picker("Type de Statistique", selection: $type) {
                    ForEach(StatistiqueType.allCases, id: \.self) {
                        Text($0.rawValue).tag($0)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }
            .padding(.horizontal)

            // 2. Filtre spécifique (client ou produit)
            GroupBox {
                HStack {
                    Text("Filtre spécifique:")
                        .font(.headline)
                    Spacer()
                    switch type {
                    case .clients:
                        Picker("Client", selection: $selectedClient) {
                            Text("Tous les clients").tag(nil as ClientDTO?)
                            ForEach(clients, id: \.id) { client in
                                Text(client.nomCompletClient).tag(client as ClientDTO?)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: 250)
                    case .produits:
                        Picker("Produit", selection: $selectedProduit) {
                            Text("Tous les produits").tag(ProduitDTO?.none)
                            ForEach(produits) { produit in
                                Text(produit.designation).tag(Optional(produit))
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: 250)
                    }
                }
            }
            .padding(.horizontal)

            // 3. Période et bouton de reset
            GroupBox {
                HStack {
                    Picker("Période", selection: $periode) {
                        ForEach(PeriodePredefinie.allCases, id: \.self) { period in
                            Text(period.rawValue).tag(period)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: 200)

                    if periode == .personnalise {
                        DatePicker("Début", selection: $dateDebut, displayedComponents: .date)
                            .labelsHidden()
                        DatePicker("Fin", selection: $dateFin, displayedComponents: .date)
                            .labelsHidden()
                    }

                    Spacer()

                    Button(action: resetAction) {
                        Image(systemName: "arrow.clockwise")
                            .font(.title2)
                    }
                    .buttonStyle(.borderless)
                    .help("Réinitialiser les filtres")
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
    }
}