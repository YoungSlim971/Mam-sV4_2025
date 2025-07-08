import SwiftUI
import DataLayer

struct InvoiceLineRowImproved: View {
    let ligne: LigneFactureDTO
    let isEven: Bool
    
    var body: some View {
        HStack(spacing: 0) {
            // Désignation avec détails
            VStack(alignment: .leading, spacing: 3) {
                Text(ligne.designation)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                
                if let refCommande = ligne.referenceCommande, !refCommande.isEmpty ||
                   ligne.dateCommande != nil {
                    HStack(spacing: 8) {
                        if let refCommande = ligne.referenceCommande, !refCommande.isEmpty {
                            Text("Réf: \(refCommande)")
                                .font(.caption2)
                                .foregroundColor(.blue)
                        }
                        
                        if let dateCommande = ligne.dateCommande {
                            Text(dateCommande.frenchFormatted)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Quantité
            Text(ligne.quantite, format: .number.precision(.fractionLength(0...2)))
                .font(.caption)
                .fontWeight(.medium)
                .frame(width: 60, alignment: .center)
            
            // Prix unitaire
            Text(ligne.prixUnitaire, format: .currency(code: "EUR"))
                .font(.caption)
                .frame(width: 80, alignment: .trailing)
                .padding(.trailing, 8)
            
            // Total
            Text(ligne.total, format: .currency(code: "EUR"))
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.blue)
                .frame(width: 90, alignment: .trailing)
                .padding(.trailing, 8)
        }
        .padding(.vertical, 8)
        .background(isEven ? Color.gray.opacity(0.03) : Color.clear)
    }
}
