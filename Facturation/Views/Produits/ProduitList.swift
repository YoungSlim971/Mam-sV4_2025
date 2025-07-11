// Views/Produits/ProduitList.swift
import SwiftUI
import DataLayer

struct ProduitList: View {
    @EnvironmentObject private var dependencyContainer: DependencyContainer
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
            .background(Color(NSColor.windowBackgroundColor))
        }
    }
}

// MARK: - Preview
#Preview {
    // Création de produits fictifs pour la preview
    let produitsMock = [
        ProduitDTO(id: UUID(), designation: "Bananes Plantain", details: "Banane douce mûre", prixUnitaire: 2.5),
        ProduitDTO(id: UUID(), designation: "Giraumon", details: "Potiron antillais", prixUnitaire: 3.0),
        ProduitDTO(id: UUID(), designation: "Christophine", details: "Légume croquant", prixUnitaire: 1.8)
    ]

    // Preview avec mock DataService
    ProduitList(
        produits: produitsMock,
        onDelete: { id in print("Suppression mock: \(id)") },
        onEdit: { id in print("Édition mock: \(id)") }
    )
    .environmentObject(DependencyContainer.shared)
    .frame(width: 400, height: 400)
}