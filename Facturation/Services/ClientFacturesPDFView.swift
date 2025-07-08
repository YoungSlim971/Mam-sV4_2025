
import SwiftUI
import DataLayer

struct ClientFacturesPDFView: View {
    let client: ClientModel
    let factures: [FactureModel]
    let entreprise: EntrepriseModel

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // En-tête du document
            HStack {
                VStack(alignment: .leading) {
                    Text(entreprise.nom)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text(entreprise.adresseComplete)
                   
                    Text("SIRET: " + entreprise.siret)
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("Factures de")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text(client.nomCompletClient)
                    Text(client.adresseComplete)
                    
                }
            }
            .padding(.bottom, 30)

            Text("Liste des factures")
                .font(.title)
                .fontWeight(.bold)
                .padding(.bottom, 10)

            // Tableau des factures
            VStack(spacing: 0) {
                // En-tête du tableau
                HStack {
                    Text("Numéro")
                        .font(.headline)
                        .frame(width: 100, alignment: .leading)
                    Text("Date")
                        .font(.headline)
                        .frame(width: 100, alignment: .leading)
                    Text("Statut")
                        .font(.headline)
                        .frame(width: 100, alignment: .leading)
                    Text("Total TTC")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .padding(.vertical, 5)
                .background(Color.gray.opacity(0.2))

                // Lignes de factures
                ForEach(factures.sorted(by: { $0.dateFacture > $1.dateFacture })) { facture in
                    HStack {
                        Text(facture.numero)
                            .frame(width: 100, alignment: .leading)
                        Text(facture.dateFacture, style: .date)
                            .frame(width: 100, alignment: .leading)
                        Text(facture.statut.rawValue)
                            .frame(width: 100, alignment: .leading)
                        Text(facture.totalTTC.euroFormatted)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    .padding(.vertical, 3)
                    Divider()
                }
            }
            .font(.subheadline)

            Spacer()

            // Pied de page (optionnel)
            Text("Généré par Mam's Facture le \(Date(), formatter: DateFormatter.shortDate)")
                .font(.caption)
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(50) // Marges pour le PDF
    }
}

extension DateFormatter {
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter
    }()
}
