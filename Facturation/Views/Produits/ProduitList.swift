// Views/Produits/ProduitList.swift
import SwiftUI
import DataLayer

struct ProduitList: View {
    @EnvironmentObject var dataService: DataService
    let produits: [ProduitDTO]
    let onDelete: (UUID) -> Void
    let onEdit: (UUID) -> Void
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(produits) { produit in
                    ProduitCard(produit: produit, onEdit: {
                        onEdit(produit.id)
                    }, onDelete: {
                        onDelete(produit.id)
                    }, onTap: {
                        // Navigation est gérée dans ProduitCard si besoin
                    })
                    .animation(.easeInOut, value: UUID()) // animation pour les changements d'état
                }
                .padding(.top)
            }
            .background(Color(nsColor: .windowBackgroundColor))
        }
    }
}

// MARK: - Preview
#Preview {
    // Création de produits fictifs pour la preview
    let produitsMock = [
        ProduitDTO(id: UUID(), designation: "Bananes Plantain", details: "Banane douce mûre", prixUnitaire: 2.5, icon: nil, iconImageData: nil),
        ProduitDTO(id: UUID(), designation: "Giraumon", details: "Potiron antillais", prixUnitaire: 3.0, icon: nil, iconImageData: nil),
        ProduitDTO(id: UUID(), designation: "Christophine", details: "Légume croquant", prixUnitaire: 1.8, icon: nil, iconImageData: nil)
    ]

    // Preview avec mock DataService
    ProduitList(
        produits: produitsMock,
        onDelete: { id in print("Suppression mock: \(id)") },
        onEdit: { id in print("Édition mock: \(id)") }
    )
    .environmentObject(DataService.shared) // si besoin pour le context
    .frame(width: 400, height: 400)
}
