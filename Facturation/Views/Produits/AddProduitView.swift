import SwiftUI
import DataLayer

struct AddProduitView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject private var dependencyContainer: DependencyContainer

    var produitToEdit: ProduitDTO?

    @State private var designation: String = ""
    @State private var details: String = ""
    @State private var prixUnitaire: Double = 0.0
    @State private var isLoading = false
    @State private var errorMessage: String?

    var isEditing: Bool { produitToEdit != nil }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text(isEditing ? "Modifier le produit" : "Nouveau produit")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.top)

                VStack(spacing: 16) {
                    AppTextField(
                        "Désignation",
                        text: $designation,
                        placeholder: "Désignation du produit",
                        errorMessage: designation.isEmpty ? "La désignation est requise" : nil
                    )

                    AppTextField(
                        "Détails",
                        text: $details,
                        placeholder: "Détails"
                    )

                    HStack {
                        Text("Prix unitaire :")
                            .font(.body)
                        Spacer()
                        TextField("0.00", value: $prixUnitaire, format: .currency(code: "EUR"))
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                            .textFieldStyle(.roundedBorder)
                    }
                }
                .padding(.horizontal)

                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }

                Spacer()

                HStack(spacing: 12) {
                    Button("Annuler") {
                        dismiss()
                    }
                    .buttonStyle(.bordered)

                    Button(isEditing ? "Enregistrer" : "Ajouter") {
                        Task {
                            await saveProduit()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(designation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || prixUnitaire <= 0 || isLoading)
                }
                .padding(.bottom)
            }
            .navigationTitle(isEditing ? "Modifier Produit" : "Nouveau Produit")
            .onAppear {
                if let produit = produitToEdit {
                    designation = produit.designation
                    details = produit.details ?? ""
                    prixUnitaire = produit.prixUnitaire
                }
            }
        }
    }

    private func saveProduit() async {
        isLoading = true
        errorMessage = nil

        let result: Result<Bool, Error>
        if isEditing {
            let produit = ProduitDTO(
                id: produitToEdit!.id,
                designation: designation.trimmingCharacters(in: .whitespacesAndNewlines),
                details: details.trimmingCharacters(in: .whitespacesAndNewlines),
                prixUnitaire: prixUnitaire
            )
            result = await dependencyContainer.updateProduitUseCase.execute(produit: produit)
        } else {
            result = await dependencyContainer.addProduitUseCase.execute(
                designation: designation.trimmingCharacters(in: .whitespacesAndNewlines),
                details: details.trimmingCharacters(in: .whitespacesAndNewlines),
                prixUnitaire: prixUnitaire
            )
        }

        switch result {
        case .success(_):
            dismiss()
        case .failure(let error):
            errorMessage = "Erreur: \(error.localizedDescription)"
        }

        isLoading = false
    }
}

#Preview {
    AddProduitView()
        .environmentObject(DependencyContainer.shared)
}

#Preview("Edition") {
    let produit = ProduitDTO(
        id: UUID(),
        designation: "Produit Test",
        details: "Un détail",
        prixUnitaire: 49.99
    )
    AddProduitView(produitToEdit: produit)
        .environmentObject(DependencyContainer.shared)
}