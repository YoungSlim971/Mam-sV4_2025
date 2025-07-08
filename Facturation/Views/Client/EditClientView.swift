// Views/Clients/EditClientView.swift
import SwiftUI
import Utilities
import DataLayer
struct EditClientView: View {
    @Environment(\.dismiss) private var dismiss

    let originalClient: ClientDTO
    @State private var editableClient: ClientDTO
    @State private var showingDeleteAlert = false
    @State private var showingValidationAlert = false
    @State private var validationMessage = ""
    
    // Validation states and messages for ClientDTO
    @State private var siretErrorMessage: String? = nil
    @State private var tvaErrorMessage: String? = nil
    @State private var isSiretValid: Bool = true
    @State private var isTvaValid: Bool = true
    
    // Callbacks pour les actions
    let onUpdate: (ClientDTO) async -> Void
    let onDelete: (UUID) async -> Void
    
    // Données précalculées pour l'affichage
    let clientFactures: [FactureDTO]
    let facturesLignes: [LigneFactureDTO]

    init(
        client: ClientDTO, 
        factures: [FactureDTO],
        lignes: [LigneFactureDTO],
        onUpdate: @escaping (ClientDTO) async -> Void,
        onDelete: @escaping (UUID) async -> Void
    ) {
        self.originalClient = client
        self._editableClient = State(initialValue: client)
        self.clientFactures = factures.filter { $0.clientId == client.id }
        self.facturesLignes = lignes
        self.onUpdate = onUpdate
        self.onDelete = onDelete
        
        // Initial validation
        self._isSiretValid = State(initialValue: Validator.isValidSIRET(client.siret))
        self._siretErrorMessage = State(initialValue: Validator.isValidSIRET(client.siret) ? nil : "Numéro SIRET invalide (14 chiffres)")
        self._isTvaValid = State(initialValue: Validator.isValidTVA(client.numeroTVA))
        self._tvaErrorMessage = State(initialValue: Validator.isValidTVA(client.numeroTVA) ? nil : "Numéro TVA invalide (FR + 11 caractères)")
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 25) {
                    // Informations personnelles
                    PersonalInfoSectionDTO(client: $editableClient)

                    // Adresse
                    AddressSectionDTO(client: $editableClient)

                    // Informations légales
                    LegalInfoSectionDTO(
                        client: $editableClient,
                        siretErrorMessage: $siretErrorMessage,
                        tvaErrorMessage: $tvaErrorMessage,
                        isSiretValid: $isSiretValid,
                        isTvaValid: $isTvaValid
                    )

                    // Historique des factures
                    FacturesHistorySectionDTO(
                        client: originalClient, 
                        factures: clientFactures,
                        lignes: facturesLignes
                    )

                    // Actions dangereuses
                    DangerZoneSection(onDelete: { showingDeleteAlert = true })

                    Spacer(minLength: 100)
                }
                .padding()
            }
            .navigationTitle("Modifier Client")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button("Annuler") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .automatic) {
                    Button("Sauvegarder") {
                        saveChanges()
                    }
                    .disabled(!isClientValid)
                }
            }
        }
        .alert("Supprimer le client", isPresented: $showingDeleteAlert) {
            Button("Supprimer", role: .destructive) {
                deleteClient()
            }
            Button("Annuler", role: .cancel) { }
        } message: {
            Text("Êtes-vous sûr de vouloir supprimer ce client ? Cette action supprimera également toutes ses factures et ne peut pas être annulée.")
        }
        .alert("Validation", isPresented: $showingValidationAlert) {
            Button("OK") { }
        } message: {
            Text(validationMessage)
        }
    }

    private var isClientValid: Bool {
        !editableClient.nom.trimmingCharacters(in: .whitespaces).isEmpty &&
        isSiretValid &&
        isTvaValid
    }

    private func saveChanges() {
        guard isClientValid else {
            validationMessage = "Veuillez corriger les erreurs de validation (SIRET, TVA, etc.)."
            showingValidationAlert = true
            return
        }

        Task {
            await onUpdate(editableClient)
            dismiss()
        }
    }

    private func deleteClient() {
        Task {
            await onDelete(originalClient.id)
            dismiss()
        }
    }
}

// MARK: - Factures History Section
struct FacturesHistorySectionDTO: View {
    let client: ClientDTO
    let factures: [FactureDTO]
    let lignes: [LigneFactureDTO]
    
    var body: some View {
        VStack(spacing: 15) {
            HStack {
                Text("Historique des factures")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if !factures.isEmpty {
                    Text("\(factures.count) facture\(factures.count > 1 ? "s" : "")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.systemGray6)
                        .cornerRadius(4)
                }
            }
            
            if factures.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "doc.text.fill")
                        .font(.title)
                        .foregroundColor(.secondary.opacity(0.6))
                    
                    Text("Aucune facture")
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    Text("Ce client n'a pas encore de facture")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .background(Color.systemBackground)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 1)
            } else {
                VStack(spacing: 12) {
                    // Statistiques
                    HStack {
                        StatisticCard(
                            title: "CA Total",
                            value: client.chiffreAffaires(from: factures, lignes: lignes).euroFormatted,
                            color: .green
                        )
                        
                        StatisticCard(
                            title: "Factures Payées",
                            value: "\(factures.filter { $0.statut == StatutFacture.payee.rawValue }.count)",
                            color: .blue
                        )
                        
                        StatisticCard(
                            title: "En Attente",
                            value: "\(factures.filter { $0.statut == StatutFacture.envoyee.rawValue }.count)",
                            color: .orange
                        )
                    }
                    
                    // Liste des factures récentes
                    VStack(spacing: 8) {
                        ForEach(Array(factures.prefix(5))) { facture in
                            FactureHistoryRow(facture: facture, lignes: lignes)
                        }
                        
                        if factures.count > 5 {
                            Text("... et \(factures.count - 5) autres factures")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.top, 8)
                        }
                    }
                }
                .padding()
                .background(Color.systemBackground)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 1)
            }
        }
    }
    
    // MARK: - Statistic Card
    struct StatisticCard: View {
        let title: String
        let value: String
        let color: Color
        
        var body: some View {
            VStack(spacing: 4) {
                Text(value)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(color.opacity(0.1))
            .cornerRadius(8)
        }
    }
    
    // MARK: - Facture History Row
    struct FactureHistoryRow: View {
        let facture: FactureDTO
        let lignes: [LigneFactureDTO]
        
        var body: some View {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(facture.numero)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text(facture.dateFacture.frenchFormatted)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    Text(facture.calculateTotalTTC(with: lignes).euroFormatted)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    HStack(spacing: 4) {
                        Circle()
                            .fill(StatutFacture(rawValue: facture.statut)?.color ?? .gray)
                            .frame(width: 6, height: 6)
                        
                        Text(facture.statut)
                            .font(.caption2)
                            .foregroundColor(StatutFacture(rawValue: facture.statut)?.color ?? .gray)
                    }
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color.systemGray6.opacity(0.5))
            .cornerRadius(8)
        }
    }
    
    #Preview {
        let mockClient = ClientDTO(
            id: UUID(),
            nom: "Jean Dupont",
            entreprise: "SARL Dupont",
            email: "jean.dupont@email.com",
            telephone: "",
            siret: "",
            numeroTVA: "",
            adresse: "",
            adresseRue: "",
            adresseCodePostal: "",
            adresseVille: "",
            adressePays: "France"
        )
        
        EditClientView(
            client: mockClient,
            factures: [],
            lignes: [],
            onUpdate: { _ in print("Update client") },
            onDelete: { _ in print("Delete client") }
        )
    }
}

struct DangerZoneSection: View {
    let onDelete: () -> Void
    
    var body: some View {
        VStack(spacing: 15) {
            HStack {
                Text("Zone de danger")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.red)
                Spacer()
            }
            
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Supprimer ce client")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.red)
                        
                        Text("Cette action supprimera définitivement le client et toutes ses factures. Cette action ne peut pas être annulée.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button("Supprimer", action: onDelete)
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                }
            }
            .padding()
            .background(Color.red.opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.red.opacity(0.3), lineWidth: 1)
            )
        }
    }
}
