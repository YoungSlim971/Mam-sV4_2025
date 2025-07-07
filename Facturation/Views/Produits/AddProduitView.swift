import UniformTypeIdentifiers
import SwiftUI


struct AddProduitView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataService: DataService

    var produitToEdit: ProduitDTO?

    @State private var designation: String = ""
    @State private var details: String = ""
    @State private var prixUnitaire: Double = 0.0
    @State private var icon: String = "🍍"
    @State private var showEmojiPicker: Bool = false
    @State private var iconImageData: Data? = nil
    let emojiOptions = ["🍍","🍌","🥭","🍉","🍊","🍋","🍈","🍎","🍏","🍒","🥥","🍅","🥑","🍠","🍆","🥕","🌽","🥒","🫑","🥦"]

    init(produitToEdit: ProduitDTO? = nil) {
        self.produitToEdit = produitToEdit
    }

    var isEditing: Bool { produitToEdit != nil }

    var body: some View {
        NavigationStack {
            ZStack {
                // Effet carte Apple natif
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .shadow(radius: 12)
                    .ignoresSafeArea()
                VStack(spacing: 36) {
                    // Icone en haut centrée dans un cercle blur + bouton emoji picker
                    ZStack {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 72, height: 72)
                            .shadow(radius: 8)
                            .onDrop(of: [.image], isTargeted: nil) { providers in
                                if let provider = providers.first {
                                    _ = provider.loadObject(ofClass: NSImage.self) { object, _ in
                                        if let nsImage = object as? NSImage,
                                           let data = nsImage.tiffRepresentation {
                                            DispatchQueue.main.async {
                                                self.iconImageData = data
                                            }
                                        }
                                    }
                                    return true
                                }
                                return false
                            }
                        if let iconImageData = iconImageData, let nsImage = NSImage(data: iconImageData) {
                            Image(nsImage: nsImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 54, height: 54)
                        } else {
                            Text(icon)
                                .font(.system(size: 38))
                                .animation(.spring(), value: icon)
                        }
                    }
                    Button("Importer une image…") {
                        let panel = NSOpenPanel()
                        panel.allowedContentTypes = [
                            .png, .jpeg, .heic
                        ]
                        panel.begin { response in
                            if response == .OK, let url = panel.url, let data = try? Data(contentsOf: url) {
                                self.iconImageData = data
                            }
                        }
                    }
                    .font(.caption)
                    .padding(6)
                    .background(.thinMaterial)
                    .cornerRadius(6)
                    Button(action: { showEmojiPicker.toggle() }) {
                        Text("Changer l’icône")
                            .font(.caption)
                            .padding(6)
                            .background(.thinMaterial)
                            .cornerRadius(6)
                    }
                    .popover(isPresented: $showEmojiPicker) {
                        VStack {
                            Text("Choisis un emoji")
                                .font(.headline)
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 5), spacing: 12) {
                                ForEach(emojiOptions, id: \.self) { emoji in
                                    Button(action: {
                                        icon = emoji
                                        showEmojiPicker = false
                                    }) {
                                        Text(emoji).font(.largeTitle)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding()
                        }
                        .frame(width: 280, height: 150)
                    }
                    .padding(.top, 8)
                    VStack(spacing: 24) {
                        TextField("Désignation", text: $designation)
                            .font(.title2.bold())
                            .multilineTextAlignment(.center)
                            .padding(.vertical, 14)
                            .padding(.horizontal, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.thickMaterial)
                            )
                        TextField("Description", text: $details)
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .padding(.vertical, 14)
                            .padding(.horizontal, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.regularMaterial)
                            )
                        HStack {
                            Text("Prix Unitaire :")
                                .font(.body)
                            Spacer()
                            TextField("0", value: $prixUnitaire, format: .number)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 80)
                                .font(.body)
                        }
                        .padding(.vertical, 14)
                        .padding(.horizontal, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.regularMaterial)
                        )
                    }
                    .padding(.horizontal, 28)
                    Spacer()

                    HStack(spacing: 12) {
                        Button("Annuler") { dismiss() }
                            .buttonStyle(.bordered)
                        Button(isEditing ? "Enregistrer" : "Ajouter") {
                            Task { @MainActor in
                                if var produit = produitToEdit {
                                    produit.designation = designation.trimmingCharacters(in: .whitespacesAndNewlines)
                                    produit.details = details.trimmingCharacters(in: .whitespacesAndNewlines)
                                    produit.prixUnitaire = prixUnitaire
                                    produit.icon = icon
                                    produit.iconImageData = iconImageData
                                    await dataService.updateProduitDTO(produit)
                                } else {
                                    let newProduit = ProduitDTO(
                                        id: UUID(),
                                        designation: designation.trimmingCharacters(in: .whitespacesAndNewlines),
                                        details: details.trimmingCharacters(in: .whitespacesAndNewlines),
                                        prixUnitaire: prixUnitaire,
                                        icon: icon,
                                        iconImageData: iconImageData
                                    )
                                    await dataService.addProduitDTO(newProduit)
                                }
                                dismiss()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.accentColor)
                        .disabled(designation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || prixUnitaire <= 0)
                    }
                    .padding(.bottom, 18)
                }
                .padding(.top, 48)
            }
            .navigationTitle(isEditing ? "Modifier Produit" : "Nouveau Produit")
            .onAppear {
                if let produit = produitToEdit {
                    designation = produit.designation
                    details = produit.details ?? ""
                    prixUnitaire = produit.prixUnitaire
                    icon = produit.icon ?? "🍍"
                    iconImageData = produit.iconImageData
                }
            }
        }
    }
}

#Preview {
    AddProduitView()
        .environmentObject(DataService.shared)
}
#Preview("Edition") {
    let produit = ProduitDTO(id: UUID(), designation: "Produit Test", details: "Un détail", prixUnitaire: 49.99, icon: "🍋", iconImageData: nil)
    AddProduitView(produitToEdit: produit)
        .environmentObject(DataService.shared)
}
