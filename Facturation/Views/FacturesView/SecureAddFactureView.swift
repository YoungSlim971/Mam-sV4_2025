import SwiftUI
import DataLayer

struct SecureAddFactureView: View {
    @Environment(\.dismiss) private var dismiss
    let clients: [ClientDTO]
    let onFactureAdded: (FactureDTO) async -> Void
    
    @State private var selectedClient: ClientDTO?
    @State private var tva: Double = 20.0
    @State private var dateFacture = Date()
    @State private var dateEcheance = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
    @State private var conditionsPaiement: ConditionsPaiement = .virement
    @State private var notes = ""
    
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    // Validation errors
    @State private var clientError: String?
    @State private var tvaError: String?
    @State private var dateError: String?
    
    var isFormValid: Bool {
        return validateAll() && selectedClient != nil
    }
    
    private var clientSelectionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Client*")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Menu {
                ForEach(clients, id: \.id) { client in
                    Button("\(client.nom) \(client.entreprise)") {
                        selectedClient = client
                        validateClient()
                    }
                }
            } label: {
                HStack {
                    if let client = selectedClient {
                        Text("\(client.nom) \(client.entreprise)")
                            .foregroundColor(.primary)
                    } else {
                        Text("Sélectionner un client")
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.controlBackgroundColor))
                .cornerRadius(8)
            }
            
            if let error = clientError {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    clientSelectionSection
                    dateSelectionSection
                    tvaSection
                    submitSection
                }
                .padding()
            }
            .navigationTitle("Nouvelle facture")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var dateSelectionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Dates")
                .font(.headline)
            DatePicker("Date de facture", selection: $dateFacture, displayedComponents: .date)
                .onChange(of: dateFacture) { _, _ in validateDates() }
            DatePicker("Date d'échéance", selection: $dateEcheance, displayedComponents: .date)
                .onChange(of: dateEcheance) { _, _ in validateDates() }
            if let error = dateError {
                Text(error).foregroundColor(.red).font(.caption)
            }
        }
    }
    
    private var tvaSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("TVA (%)")
                .font(.headline)
            TextField("Taux TVA", value: $tva, format: .number)
                .onChange(of: tva) { _, _ in validateTVA() }
            if let error = tvaError {
                Text(error).foregroundColor(.red).font(.caption)
            }
        }
    }
    
    private var submitSection: some View {
        VStack {
            if let error = errorMessage {
                Text(error).foregroundColor(.red).font(.caption)
            }
            Button("Créer la facture") {
                Task {
                    await createFacture()
                }
            }
            .disabled(!isFormValid || isLoading)
            .buttonStyle(.borderedProminent)
        }
    }
    
    private func createFacture() async {
        guard let client = selectedClient else { return }
        
        isLoading = true
        
        let factureDTO = FactureDTO(
            id: UUID(),
            numero: "TEMP-\(UUID().uuidString.prefix(8))",
            dateFacture: dateFacture,
            dateEcheance: dateEcheance,
            datePaiement: nil,
            tva: tva,
            conditionsPaiement: conditionsPaiement.rawValue,
            remisePourcentage: 0.0,
            statut: StatutFacture.brouillon.rawValue,
            notes: notes,
            notesCommentaireFacture: nil,
            clientId: client.id,
            ligneIds: []
        )
        
        await onFactureAdded(factureDTO)
        isLoading = false
        dismiss()
    }
    
    private func validateAll() -> Bool {
        validateClient()
        validateTVA()
        validateDates()
        return clientError == nil && tvaError == nil && dateError == nil
    }
    
    private func validateClient() {
        clientError = selectedClient == nil ? "Veuillez sélectionner un client" : nil
    }
    
    private func validateTVA() {
        let validRates: [Double] = [0.0, 2.1, 5.5, 10.0, 20.0]
        if !validRates.contains(tva) {
            tvaError = "Taux TVA invalide (valeurs autorisées: 0.0, 2.1, 5.5, 10.0, 20.0%)"
        } else {
            tvaError = nil
        }
    }
    
    private func validateDates() {
        if dateEcheance < dateFacture {
            dateError = "La date d'échéance doit être postérieure à la date de facture"
        } else {
            dateError = nil
        }
    }
}

#Preview {
    let sampleClients = [
        ClientDTO(
            id: UUID(),
            nom: "Dupont",
            entreprise: "Jean",
            email: "jean.dupont@example.com",
            telephone: "01 23 45 67 89",
            siret: "",
            numeroTVA: "",
            adresse: "123 Rue de la Paix",
            adresseRue: "123 Rue de la Paix",
            adresseCodePostal: "75000",
            adresseVille: "Paris",
            adressePays: "France"
        )
    ]
    
    SecureAddFactureView(
        clients: sampleClients,
        onFactureAdded: { facture in
            print("Facture ajoutée: \(facture.numero)")
        }
    )
}