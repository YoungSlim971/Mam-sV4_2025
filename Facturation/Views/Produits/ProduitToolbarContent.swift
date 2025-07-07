// Views/Produits/ProduitToolbarContent.swift
import SwiftUI

struct ProduitToolbarContent: ToolbarContent {
    @Binding var showingAddProduitSheet: Bool

    var body: some ToolbarContent {
        ToolbarItem(placement: .automatic) {
            Button(action: { showingAddProduitSheet.toggle() }) {
                Label("Ajouter Produit", systemImage: "plus")
            }
        }
    }
}
