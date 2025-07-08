import SwiftUI
import DataLayer
struct ProductDetailsView: View {
    @EnvironmentObject var dataService: DataService
    @State var produit: ProduitDTO
    @State private var showingEditProduitSheet = false
    var onClose: (() -> Void)? = nil

    var body: some View {
        ZStack {
            // Fond blur material façon carte macOS
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(radius: 12)
                .padding()
            VStack(spacing: 32) {
                VStack(spacing: 12) {
                    // Icône du produit en gros au-dessus
                    ZStack {
                        Circle()
                            .fill(.thinMaterial)
                            .frame(width: 80, height: 80)
                            .shadow(radius: 4)
                        Text(produit.icon ?? "📦")
                            .font(.system(size: 48))
                    }
                    .padding(.top, 24)
                    
                    // Titre du produit bien visible
                    Text(produit.designation)
                        .font(.largeTitle.bold())
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)

                    Divider()

                    // Détails
                    HStack {
                        Label("Désignation", systemImage: "tag.fill")
                        Spacer()
                        Text(produit.designation)
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Label("Détails", systemImage: "info.circle.fill")
                        Spacer()
                        Text(produit.details ?? "Description non disponible")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Label("Prix Unitaire", systemImage: "eurosign.circle.fill")
                        Spacer()
                        Text(produit.prixUnitaire, format: .currency(code: "EUR"))
                            .font(.body.bold())
                            .foregroundStyle(.primary)
                    }
                }
                .padding(28)

                HStack(spacing: 16) {
                    Button(action: {
                        if let onClose = onClose {
                            onClose()
                        } else if let window = NSApp.keyWindow {
                            window.performClose(nil)
                        }
                    }) {
                        Label("Retour", systemImage: "arrow.backward")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)

                    Button("Modifier le produit") {
                        showingEditProduitSheet.toggle()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
                .padding(.bottom)
            }
            .padding()
        }
        .navigationTitle("Fiche Produit")
        // Toolbar supprimée (bouton Retour déplacé dans le HStack ci-dessus)
        .sheet(isPresented: $showingEditProduitSheet) {
            EditProduitView(produit: produit)
        }
    }
}

#Preview {
    ProductDetailsView(produit: ProduitDTO(id: UUID(), designation: "Test Produit", details: "Description du produit test", prixUnitaire: 12.34, icon: nil, iconImageData: nil))
        .environmentObject(DataService.shared)
}
