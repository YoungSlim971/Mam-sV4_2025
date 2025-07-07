// Views/Produits/EditProduitView.swift
import SwiftUI

struct EditProduitView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataService: DataService
    @State var produit: ProduitDTO
    var onClose: (() -> Void)? = nil

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Désignation")
                        .font(.headline)
                    TextField("Désignation", text: $produit.designation)
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal, 4)
                }
                VStack(alignment: .leading, spacing: 12) {
                    Text("Description")
                        .font(.headline)
                    TextField("Description", text: Binding(
                        get: { produit.details ?? "" },
                        set: { produit.details = $0 }
                    ))
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal, 4)
                }
                VStack(alignment: .leading, spacing: 12) {
                    Text("Icône")
                        .font(.headline)
                    HStack {
                        TextField("🍌", text: Binding(
                            get: { produit.icon ?? "" },
                            set: { produit.icon = $0 }
                        ))
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 60)
                        Menu {
                            ForEach(["🍌", "🥭", "🍍", "🍉", "🥑", "🍆", "🥕", "🥬", "🍅", "🍠", "🍊", "🍋", "🍈", "🍑"], id: \.self) { emoji in
                                Button(emoji) { produit.icon = emoji }
                            }
                        } label: {
                            Image(systemName: "sparkle.magnifyingglass")
                                .font(.title3)
                                .padding(.leading, 6)
                        }
                    }
                    .padding(.horizontal, 4)
                }
                VStack(alignment: .leading, spacing: 12) {
                    Text("Prix Unitaire")
                        .font(.headline)
                    TextField("Prix Unitaire", value: $produit.prixUnitaire, format: .number)
                        
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal, 4)
                }
                Spacer()
                HStack {
                    Button("Annuler") {
                        if let onClose = onClose {
                            onClose()
                        } else {
                            dismiss()
                        }
                    }
                    .buttonStyle(.bordered)
                    Spacer()
                    Button("Enregistrer") {
                        Task {
                            await dataService.updateProduitDTO(produit)
                            dismiss()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(produit.designation.isEmpty || produit.prixUnitaire <= 0)
                }
                .padding(.horizontal)
            }
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .padding()
            .navigationTitle("Modifier Produit")
        }
    }
}

#Preview {
    EditProduitView(produit: ProduitDTO(id: UUID(), designation: "Produit à modifier", details: "Description à modifier", prixUnitaire: 99.99, icon: nil, iconImageData: nil), onClose: { })
        .environmentObject(DataService.shared)
}
