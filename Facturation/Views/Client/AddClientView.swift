// Views/Clients/AddClientView.swift
import SwiftUI
import Utilities
import DataLayer


struct AddClientView: View {
    @Environment(\.dismiss) private var dismiss
    
    // Callback pour la création du client
    let onCreate: (ClientDTO) async -> Void

    @State private var client = ClientDTO(
        id: UUID(),
        nom: "",
        entreprise: "",
        email: "",
        telephone: "",
        siret: "",
        numeroTVA: "",
        adresse: "", // Déplacé ici
        adresseRue: "",
        adresseCodePostal: "",
        adresseVille: "",
        adressePays: "France"
    )
    @State private var showingValidationAlert = false
    @State private var validationMessage = ""

    // Validation states and messages for ClientDTO
    @State private var siretErrorMessage: String? = nil
    @State private var tvaErrorMessage: String? = nil
    @State private var isSiretValid: Bool = true
    @State private var isTvaValid: Bool = true

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 25) {
                    // Informations personnelles
                    PersonalInfoSectionDTO(client: $client)

                    // Adresse
                    AddressSectionDTO(client: $client)

                    // Informations légales
                    LegalInfoSectionDTO(
                        client: $client,
                        siretErrorMessage: $siretErrorMessage,
                        tvaErrorMessage: $tvaErrorMessage,
                        isSiretValid: $isSiretValid,
                        isTvaValid: $isTvaValid
                    )

                    Spacer(minLength: 100)
                }
                .padding()
            }
            .navigationTitle("Nouveau Client")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button("Annuler") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .automatic) {
                    Button("Sauvegarder") {
                        saveClient()
                    }
                    .disabled(!isClientValid)
                }
            }
        }
        .alert("Validation", isPresented: $showingValidationAlert) {
            Button("OK") { }
        } message: {
            Text(validationMessage)
        }
    }

    private var isClientValid: Bool {
        !client.nom.trimmingCharacters(in: .whitespaces).isEmpty &&
        isSiretValid &&
        isTvaValid
    }

    private func saveClient() {
        guard isClientValid else {
            validationMessage = "Veuillez corriger les erreurs de validation (SIRET, TVA, etc.)."
            showingValidationAlert = true
            return
        }

        Task {
            await onCreate(client)
            dismiss()
        }
    }
}

// MARK: - Personal Info Section
struct PersonalInfoSectionDTO: View {
    @Binding var client: ClientDTO

    var body: some View {
        VStack(spacing: 15) {
            HStack {
                Text("Informations personnelles")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
            }

            VStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Nom *")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    TextField("Nom du contact", text: $client.nom)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Entreprise")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    TextField("Nom de l'entreprise", text: $client.entreprise)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Email")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    TextField("email@exemple.com", text: $client.email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
//                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Téléphone")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    TextField("01 23 45 67 89", text: $client.telephone)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
            }
            .padding()
            .background(Color.systemBackground)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 1)
        }
    }
}

// MARK: - Address Section
struct AddressSectionDTO: View {
    @Binding var client: ClientDTO

    var body: some View {
        VStack(spacing: 15) {
            HStack {
                Text("Adresse")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
            }

            VStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Rue")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    TextField("123 rue de la Paix", text: $client.adresseRue)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }

                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Code postal")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        TextField("75001", text: $client.adresseCodePostal)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
//                            .keyboardType(.numberPad)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Ville")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        TextField("Paris", text: $client.adresseVille)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Pays")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    TextField("France", text: $client.adressePays)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
            }
            .padding()
            .background(Color.systemBackground)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 1)
        }
    }
}

// MARK: - Legal Info Section
struct LegalInfoSectionDTO: View {
    @Binding var client: ClientDTO
    @Binding var siretErrorMessage: String?
    @Binding var tvaErrorMessage: String?
    @Binding var isSiretValid: Bool
    @Binding var isTvaValid: Bool

    var body: some View {
        VStack(spacing: 15) {
            HStack {
                Text("Informations légales")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()

                Text("Optionnel")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.systemGray6)
                    .cornerRadius(4)
            }

            VStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("SIRET")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    TextField("12345678901234", text: $client.siret)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onChange(of: client.siret) {
                            isSiretValid = Validator.isValidSIRET(client.siret)
                            siretErrorMessage = isSiretValid ? nil : "Numéro SIRET invalide (14 chiffres)"
                        }
                    if let errorMessage = siretErrorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Numéro de TVA")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    TextField("FR12345678901", text: $client.numeroTVA)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
//                        .autocapitalization(.allCharacters)
                        .onChange(of: client.numeroTVA) {
                            isTvaValid = Validator.isValidTVA(client.numeroTVA)
                            tvaErrorMessage = isTvaValid ? nil : "Numéro TVA invalide (FR + 11 caractères)"
                        }
                    if let errorMessage = tvaErrorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Information")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)

                    Text("Ces informations apparaîtront sur les factures et sont utiles pour les entreprises assujetties à la TVA.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
            }
            .padding()
            .background(Color.systemBackground)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 1)
        }
    }
}

#Preview {
    AddClientView { client in
        print("Créer client: \(client.nom)")
    }
}
