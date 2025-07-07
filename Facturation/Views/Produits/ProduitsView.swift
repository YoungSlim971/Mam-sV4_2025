import SwiftUI
struct ProduitsView: View {
    @EnvironmentObject var dataService: DataService
    @Binding var searchText: String
    @State private var showingAddProduitSheet = false
    @State private var editingProduit: ProduitDTO?
    @State private var selectedProduitDetail: ProduitDTO?

    var filteredProduits: [ProduitDTO] {
        guard !searchText.isEmpty else { return dataService.produits }
        return dataService.searchProduits(searchText: searchText)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(filteredProduits) { produit in
                        ProduitCard(
                            produit: produit,
                            onEdit: {
                                editingProduit = produit
                            },
                            onDelete: {
                                deleteProduit(produit)
                            },
                            onTap: {
                                selectedProduitDetail = produit
                            }
                        )
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Produits")
            .toolbar {
                ProduitToolbarContent(showingAddProduitSheet: $showingAddProduitSheet)
            }
            .sheet(isPresented: $showingAddProduitSheet) {
                AddProduitView()
            }
            .sheet(item: $editingProduit) { produit in
                AddProduitView(produitToEdit: produit)
            }
            .sheet(item: $selectedProduitDetail) { produit in
                ProductDetailsView(produit: produit, onClose: { selectedProduitDetail = nil })
            }
        }
    }

    private func deleteProduit(_ produit: ProduitDTO) {
        Task {
            await dataService.deleteProduitDTO(id: produit.id)
        }
    }
}
