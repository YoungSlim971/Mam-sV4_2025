// Views/Factures/AddFactureView.swift
import SwiftUI
import Foundation // Ajouté pour Date

// Note fixe appliquée à toutes les factures
private let defaultFactureNote = """
TVA NON APPLICABLE — ARTICLE 293 B du CGI.
Les règlements se font par VIREMENT sur le compte EXOTROPIC.
"""

struct AddFactureView: View {
    @EnvironmentObject private var dataService: DataService
    @Environment(\.dismiss) private var dismiss

    @State private var selectedClient: ClientDTO?
    @State private var showingClientCreation = false
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack {
                    Button("Annuler") {
                        if selectedClient != nil {
                            selectedClient = nil
                        } else {
                            dismiss()
                        }
                    }
                    .keyboardShortcut(.cancelAction) // Cmd+.
                    .padding(.vertical, 6)
                    .padding(.horizontal, 18)
                    .background(Color.systemGray5)
                    .cornerRadius(8)
                    .foregroundColor(.primary)

                    Spacer()
                }
                .padding(.top, 8)
                .padding(.horizontal)

                if dataService.clients.isEmpty {
                    EmptyClientsState(showingClientCreation: $showingClientCreation)
                } else if selectedClient == nil {
                    ClientSelectionView(
                        clients: filteredClients,
                        selectedClient: $selectedClient,
                        searchText: $searchText,
                        showingClientCreation: $showingClientCreation
                    )
                } else {
                    FactureFormView(
                        client: selectedClient!,
                        onCancel: {
                            selectedClient = nil
                        },
                        onCreate: { facture in
                            createFacture(facture, for: selectedClient!)
                        }
                    )
                }
            }
            .navigationTitle(selectedClient == nil ? "Nouvelle Facture" : "Détails de la facture")
        }
        .sheet(isPresented: $showingClientCreation) {
            AddClientView(onCreate: { _ in
                showingClientCreation = false
            })
        }
    }

    private var filteredClients: [ClientDTO] {
        if searchText.isEmpty {
            return dataService.clients
        }
        return dataService.clients.filter { client in
            client.nomCompletClient.localizedCaseInsensitiveContains(searchText) ||
            client.email.localizedCaseInsensitiveContains(searchText)
        }
    }

    private func createFacture(_ editableFacture: EditableFacture, for client: ClientDTO) {
        Task {
            let numero: String
            if editableFacture.numerotationAutomatique {
                // Get client model for numbering
                guard let clientModel = await dataService.fetchClientModel(id: client.id) else {
                    print("Erreur: Client non trouvé pour la génération du numéro")
                    return
                }
                numero = await dataService.genererNumeroFacture(client: clientModel)
            } else {
                // We use the custom number, ensuring it's not empty (already validated by isFactureValid)
                numero = editableFacture.numeroPersonnalise ?? ""
            }
            
            // Create ligne DTOs first
            var ligneDTOs: [LigneFactureDTO] = []
            for editableLigne in editableFacture.lignes {
                let ligneDTO = LigneFactureDTO(
                    id: UUID(),
                    designation: editableLigne.designation,
                    quantite: editableLigne.quantite,
                    prixUnitaire: editableLigne.prixUnitaire,
                    referenceCommande: editableLigne.referenceCommande,
                    dateCommande: editableLigne.dateCommande,
                    produitId: editableLigne.produitId,
                    factureId: nil // Will be set after facture creation
                )
                ligneDTOs.append(ligneDTO)
            }
            
            // Create facture DTO
            let factureDTO = FactureDTO(
                id: UUID(),
                numero: numero,
                dateFacture: editableFacture.dateFacture,
                dateEcheance: editableFacture.dateEcheance,
                datePaiement: editableFacture.datePaiement,
                tva: editableFacture.tva,
                conditionsPaiement: editableFacture.conditionsPaiement.rawValue,
                remisePourcentage: editableFacture.remisePourcentage,
                statut: editableFacture.statut.rawValue,
                notes: defaultFactureNote,
                notesCommentaireFacture: editableFacture.notesCommentaireFacture,
                clientId: client.id,
                ligneIds: ligneDTOs.map { $0.id }
            )

            // Add lignes and facture
            for var ligneDTO in ligneDTOs {
                ligneDTO.factureId = factureDTO.id
                await dataService.addLigneDTO(ligneDTO)
            }
            
            await dataService.addFactureDTO(factureDTO)
            dismiss()
        }
    }
}

// MARK: - Empty Clients State
struct EmptyClientsState: View {
    @Binding var showingClientCreation: Bool

    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "person.2.slash")
                .font(.system(size: 60))
                .foregroundColor(.secondary.opacity(0.6))

            VStack(spacing: 12) {
                Text("Aucun client")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Vous devez d'abord créer un client avant de pouvoir créer une facture.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Button(action: { showingClientCreation = true }) {
                Label("Créer un client", systemImage: "person.badge.plus")
                    .font(.headline)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - Client Selection View
struct ClientSelectionView: View {
    let clients: [ClientDTO]
    @Binding var selectedClient: ClientDTO?
    @Binding var searchText: String
    @Binding var showingClientCreation: Bool

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 15) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Sélectionner un client")
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text("Choisissez le client pour cette facture")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Button(action: { showingClientCreation = true }) {
                        Label("Nouveau", systemImage: "person.badge.plus")
                            .font(.subheadline)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }

                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)

                    TextField("Rechercher un client...", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
            }
            .padding()

            Divider()

            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(clients) { client in
                        ClientSelectionRow(
                            client: client,
                            isSelected: selectedClient?.id == client.id
                        ) {
                            selectedClient = client
                        }
                    }
                }
                .padding()
            }

            if selectedClient != nil {
                Divider()
                SelectedClientPreview(client: selectedClient!)
                    .padding()
            }
        }
    }
}

// MARK: - Client Selection Row
struct ClientSelectionRow: View {
    let client: ClientDTO
    let isSelected: Bool
    let onSelect: () -> Void

    @EnvironmentObject private var dataService: DataService

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 15) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.blue : Color.systemGray5)
                        .frame(width: 20, height: 20)

                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                }

                Image(systemName: client.entreprise.isEmpty ? "person.circle.fill" : "building.2")
                    .font(.title2)
                    .foregroundColor(.blue)

                VStack(alignment: .leading, spacing: 4) {
                    Text(client.nomCompletClient)
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)

                    if !client.email.isEmpty {
                        Text(client.email)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    if !client.adresseVilleComplete.isEmpty {
                        HStack {
                            Image(systemName: "location.circle")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Text(client.adresseVilleComplete)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(client.facturesCount(from: dataService.factures))")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)

                    let count = client.facturesCount(from: dataService.factures)
                    Text("facture\(count > 1 ? "s" : "")")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color.systemBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Selected Client Preview
struct SelectedClientPreview: View {
    let client: ClientDTO
    @EnvironmentObject private var dataService: DataService

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Client sélectionné")
                .font(.headline)
                .fontWeight(.semibold)

            HStack(spacing: 15) {
                Image(systemName: client.entreprise.isEmpty ? "person.circle.fill" : "building.2")
                    .font(.title)
                    .foregroundColor(.blue)

                VStack(alignment: .leading, spacing: 4) {
                    Text(client.nomCompletClient)
                        .font(.headline)
                        .fontWeight(.medium)

                    if !client.email.isEmpty {
                        Text(client.email)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    if !client.adresseCompacteLigne.isEmpty {
                        Text(client.adresseCompacteLigne)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    let ca = client.chiffreAffaires(from: dataService.factures, lignes: dataService.lignes)
                    if ca > 0 {
                        Text(ca.euroFormatted)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)

                        Text("CA total")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color.systemGray5.opacity(0.5))
        .cornerRadius(12)
    }
}

// MARK: - Facture Form View
struct FactureFormView: View {
    let client: ClientDTO
    let onCancel: () -> Void
    let onCreate: (EditableFacture) -> Void

    @State private var editableFacture = EditableFacture()
    @State private var showingPreview = false

    init(client: ClientDTO, onCancel: @escaping () -> Void, onCreate: @escaping (EditableFacture) -> Void) {
        self.client = client
        self.onCancel = onCancel
        self.onCreate = onCreate

        var defaultFacture = EditableFacture()
        defaultFacture.lignes = [EditableLigneFacture()]
        defaultFacture.notes = defaultFactureNote // Assigner la note par défaut
        self._editableFacture = State(initialValue: defaultFacture)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                ClientSelectedView(client: client, onChangeClient: onCancel)
                FactureBasicInfoView(editableFacture: $editableFacture)
                FactureLinesView(editableFacture: $editableFacture)
                FactureTotalsView(editableFacture: $editableFacture)
                FactureNotesView()
                FactureCommentView(editableFacture: $editableFacture) // Nouveau champ
                ActionButtonsView(
                    editableFacture: editableFacture,
                    onPreview: { showingPreview = true },
                    onCreate: { onCreate(editableFacture) },
                    isValid: isFactureValid
                )

                Spacer(minLength: 100)
            }
            .padding()
        }
        .sheet(isPresented: $showingPreview) {
            FacturePreviewView(editableFacture: editableFacture, client: client)
        }
    }

    private var isFactureValid: Bool {
        let hasLignesValides = !editableFacture.lignes.isEmpty &&
                               editableFacture.lignes.allSatisfy { !$0.designation.trimmingCharacters(in: .whitespaces).isEmpty }
        
        let hasNumeroValide = editableFacture.numerotationAutomatique ||
                              !(editableFacture.numeroPersonnalise ?? "").trimmingCharacters(in: .whitespaces).isEmpty
        
        return hasLignesValides && hasNumeroValide
    }
}

// MARK: - Client Selected View
struct ClientSelectedView: View {
    let client: ClientDTO
    let onChangeClient: () -> Void
    @EnvironmentObject private var dataService: DataService

    var body: some View {
        VStack(spacing: 15) {
            HStack {
                Text("Client sélectionné")
                    .font(.title2)
                    .fontWeight(.semibold)

                Spacer()

                Button("Changer") {
                    onChangeClient()
                }
                .foregroundColor(.blue)
            }

            HStack(spacing: 15) {
                Image(systemName: client.entreprise.isEmpty ? "person.circle.fill" : "building.2")
                    .font(.title)
                    .foregroundColor(.blue)

                VStack(alignment: .leading, spacing: 4) {
                    Text(client.nomCompletClient)
                        .font(.headline)
                        .fontWeight(.semibold)

                    if !client.email.isEmpty {
                        Text(client.email)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    if !client.adresseCompacteLigne.isEmpty {
                        Text(client.adresseCompacteLigne)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(client.facturesCount(from: dataService.factures))")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)

                    let count = client.facturesCount(from: dataService.factures)
                    Text("facture\(count > 1 ? "s" : "")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color.systemBackground)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 1)
    }
}

// MARK: - Facture Basic Info View
struct FactureBasicInfoView: View {
    @Binding var editableFacture: EditableFacture
    @State private var showDatePaiement: Bool = false

    var body: some View {
        VStack(spacing: 15) {
            HStack {
                Text("Informations de base")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
            }

            VStack(spacing: 12) {
                // --- NUMÉROTATION ---
                Toggle("Numérotation automatique", isOn: $editableFacture.numerotationAutomatique)
                
                if !editableFacture.numerotationAutomatique {
                    HStack {
                        Text("N° personnalisé")
                            .fontWeight(.medium)
                            .frame(width: 130, alignment: .leading)
                        TextField("Numéro de facture", text: Binding(
                            get: { editableFacture.numeroPersonnalise ?? "" },
                            set: { editableFacture.numeroPersonnalise = $0 }
                        ))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    .padding(.leading)
                }
                
                Divider().padding(.vertical, 5)
                
                // --- DATES ---
                HStack {
                    Text("Date de facture")
                        .fontWeight(.medium)
                        .frame(width: 130, alignment: .leading)
                    DatePicker("", selection: $editableFacture.dateFacture, displayedComponents: .date)
                        .labelsHidden()
                    Spacer()
                }

                HStack {
                    Text("Date d'échéance")
                        .fontWeight(.medium)
                        .frame(width: 130, alignment: .leading)
                    DatePicker("", selection: $editableFacture.dateEcheance, displayedComponents: .date)
                        .labelsHidden()
                    Spacer()
                }

                HStack {
                    Text("Statut initial")
                        .fontWeight(.medium)
                        .frame(width: 130, alignment: .leading)
                    Picker("Statut", selection: $editableFacture.statut) {
                        ForEach(StatutFacture.allCases, id: \.self) { statut in
                            HStack {
                                Circle()
                                    .fill(statut.color)
                                    .frame(width: 8, height: 8)
                                Text(statut.rawValue)
                            }
                            .tag(statut)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    Spacer()
                }

                // Toggle pour activer/désactiver la date de paiement
                HStack {
                    Toggle("Ajouter une date de paiement", isOn: $showDatePaiement)
                        .onChange(of: showDatePaiement) { _, newValue in
                            if !newValue { editableFacture.datePaiement = nil }
                            else if editableFacture.datePaiement == nil {
                                editableFacture.datePaiement = Date()
                            }
                        }
                    Spacer()
                }

                // DatePicker affiché seulement si le toggle est actif
                if showDatePaiement {
                    HStack {
                        Text("Date de paiement")
                            .fontWeight(.medium)
                            .frame(width: 130, alignment: .leading)
                        DatePicker(
                            "",
                            selection: Binding<Date>(
                                get: { editableFacture.datePaiement ?? Date() },
                                set: { editableFacture.datePaiement = $0 }
                            ),
                            displayedComponents: .date
                        )
                        .labelsHidden()
                        Spacer()
                    }
                }

                HStack {
                    Text("Conditions de paiement")
                        .fontWeight(.medium)
                        .frame(width: 130, alignment: .leading)
                    Picker("Conditions de paiement", selection: $editableFacture.conditionsPaiement) {
                        ForEach(ConditionsPaiement.allCases, id: \.self) {
                            Text($0.rawValue).tag($0)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    Spacer()
                }

                HStack {
                    Text("Remise (%)")
                        .fontWeight(.medium)
                        .frame(width: 130, alignment: .leading)
                    TextField("0.0", value: $editableFacture.remisePourcentage, format: .number)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 80)
                    Spacer()
                }
            }
            .padding()
            .background(Color.systemBackground)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 1)
        }
        .onAppear {
            // Initialisation de showDatePaiement selon la présence d'une date existante
            showDatePaiement = editableFacture.datePaiement != nil
        }
    }
}

// MARK: - Facture Lines View
struct FactureLinesView: View {
    @Binding var editableFacture: EditableFacture

    var body: some View {
        VStack(spacing: 15) {
            HStack {
                Text("Lignes de facture")
                    .font(.title2)
                    .fontWeight(.semibold)

                Spacer()

                Button(action: ajouterLigne) {
                    Label("Ajouter", systemImage: "plus.circle.fill")
                        .font(.subheadline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
            }

            VStack(spacing: 8) {
                ForEach(editableFacture.lignes.indices, id: \.self) { index in
                    NewFactureLigneRow(
                        ligne: $editableFacture.lignes[index],
                        canDelete: editableFacture.lignes.count > 1,
                        onDelete: { supprimerLigne(at: index) }
                    )
                }
            }
            .padding()
            .background(Color.systemBackground)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 1)
        }
    }

    private func ajouterLigne() {
        editableFacture.lignes.append(EditableLigneFacture())
    }

    private func supprimerLigne(at index: Int) {
        if editableFacture.lignes.count > 1 {
            editableFacture.lignes.remove(at: index)
        }
    }
}

// MARK: - New Facture Ligne Row
struct NewFactureLigneRow: View {
    @EnvironmentObject private var dataService: DataService
    @Binding var ligne: EditableLigneFacture
    let canDelete: Bool
    let onDelete: () -> Void

    @State private var selectedProduitId: UUID? = nil

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Picker("Produit", selection: $selectedProduitId) {
                    Text("Saisie manuelle").tag(nil as UUID?)
                    ForEach(dataService.produits) { produit in
                        Text(produit.designation).tag(produit.id as UUID?)
                    }
                }
                .pickerStyle(MenuPickerStyle())

                if canDelete {
                    Button(action: onDelete) {
                        Image(systemName: "trash.circle.fill")
                            .foregroundColor(.red)
                            .font(.title3)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }

            TextField("Description du produit ou service", text: $ligne.designation)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Référence commande")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("Réf. Commande", text: Binding(get: { ligne.referenceCommande ?? "" }, set: { ligne.referenceCommande = $0.isEmpty ? nil : $0 }))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .frame(maxWidth: .infinity)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Date commande")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    DatePicker("", selection: Binding(get: { ligne.dateCommande ?? Date() }, set: { ligne.dateCommande = $0 }), displayedComponents: .date)
                        .labelsHidden()
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .frame(maxWidth: .infinity)
            }

            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Quantité")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("1", value: $ligne.quantite, format: .number)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .frame(maxWidth: .infinity)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Prix Unitaire HT")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("0,00 €", value: $ligne.prixUnitaire, format: .currency(code: "EUR").locale(Locale(identifier: "fr_FR")))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .frame(maxWidth: .infinity)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Total HT")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(ligne.total.euroFormatted)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(8)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor).opacity(0.3))
        .cornerRadius(8)
        .onAppear {
            selectedProduitId = ligne.produitId
        }
        .onChange(of: selectedProduitId) { _, newValue in
            guard let id = newValue,
                  let produit = dataService.produits.first(where: { $0.id == id }) else { return }
            ligne.designation = produit.designation
            ligne.prixUnitaire = produit.prixUnitaire
            ligne.produitId = produit.id
        }
    }
}

// MARK: - Facture Totals View
struct FactureTotalsView: View {
    @Binding var editableFacture: EditableFacture

    var body: some View {
        VStack(spacing: 15) {
            HStack {
                Text("TVA et totaux")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
            }

            VStack(spacing: 12) {
                HStack {
                    Text("Taux de TVA (%)")
                        .fontWeight(.medium)
                    Spacer()
                    TextField("20", value: $editableFacture.tva, format: .number)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 80)
                }
                // Helper text for TVA input
                HStack {
                    Text("Entrez le taux de TVA en pourcentage (ex : 20 pour 20%).")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                // Optionally, still show valid rates for info
                HStack {
                    Text("Taux valides : 0%, 2.1%, 5.5%, 10%, 20%")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Spacer()
                }

                Divider()

                HStack {
                    Text("Sous-total HT")
                    Spacer()
                    Text(editableFacture.sousTotal.euroFormatted)
                        .fontWeight(.medium)
                }

                HStack {
                    Text("TVA (\(String(format: "%.1f", editableFacture.tva))%)")
                    Spacer()
                    // Use .tva / 100 for calculation
                    Text((editableFacture.sousTotal * (editableFacture.tva / 100)).euroFormatted)
                        .fontWeight(.medium)
                }

                Divider()

                HStack {
                    Text("Total TTC")
                        .font(.title3)
                        .fontWeight(.bold)
                    Spacer()
                    // Use .tva / 100 for calculation
                    Text((editableFacture.sousTotal * (1 + (editableFacture.tva / 100))).euroFormatted)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
            }
            .padding()
            .background(Color.systemBackground)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 1)
        }
    }
}

// MARK: - Facture Notes View (lecture seule)
struct FactureNotesView: View {
    var body: some View {
        VStack(spacing: 15) {
            HStack {
                Text("Notes")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
            }

            Text(defaultFactureNote)
                .font(.footnote)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding()
                .background(Color.systemBackground)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 1)
        }
    }
}

// MARK: - Facture Comment View
struct FactureCommentView: View {
    @Binding var editableFacture: EditableFacture

    var body: some View {
        VStack(spacing: 15) {
            HStack {
                Text("Commentaire spécifique à la facture")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
            }

            TextEditor(text: Binding(get: { editableFacture.notesCommentaireFacture ?? "" }, set: { editableFacture.notesCommentaireFacture = $0.isEmpty ? nil : $0 }))
                .frame(minHeight: 80, maxHeight: 150)
                .padding(8)
                .background(Color.systemBackground)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
        }
    }
}

// MARK: - Action Buttons View
struct ActionButtonsView: View {
    let editableFacture: EditableFacture
    let onPreview: () -> Void
    let onCreate: () -> Void
    let isValid: Bool

    var body: some View {
        VStack(spacing: 15) {
            HStack(spacing: 15) {
                Button(action: onPreview) {
                    Label("Aperçu", systemImage: "eye.fill")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(NSColor.controlBackgroundColor))
                        .foregroundColor(.primary)
                        .cornerRadius(10)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(!isValid)

                Button(action: onCreate) {
                    Label("Créer la facture", systemImage: "checkmark.circle.fill")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(isValid ? Color.blue : Color.systemGray4)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(!isValid)
            }

            if !isValid {
                Text("Veuillez remplir au moins une ligne avec une description et vérifier le numéro de facture personnalisé s'il est utilisé.")
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }
        }
    }
}

// MARK: - Facture Preview View
struct FacturePreviewView: View {
    let editableFacture: EditableFacture
    let client: ClientDTO
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    FacturePreviewContent(editableFacture: editableFacture, client: client)
                }
                .padding()
            }
            .navigationTitle("Aperçu de la facture")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button("Fermer") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Facture Preview Content
struct FacturePreviewContent: View {
    let editableFacture: EditableFacture
    let client: ClientDTO

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("FACTURE")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Numéro: [À générer]")
                    .font(.headline)

                Text("Date: \(editableFacture.dateFacture.frenchFormatted)")
                Text("Échéance: \(editableFacture.dateEcheance.frenchFormatted)")
                if let datePaiement = editableFacture.datePaiement {
                    Text("Date de paiement: \(datePaiement.frenchFormatted)")
                }
                Text("Conditions de paiement: \(editableFacture.conditionsPaiement.rawValue)")
                if editableFacture.remisePourcentage > 0 {
                    Text("Remise: \(editableFacture.remisePourcentage.formatted(.number.precision(.fractionLength(0...2))))%")
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 4) {
                Text("Facturé à:")
                    .font(.headline)

                Text(client.nomCompletClient)
                    .fontWeight(.semibold)

                if !client.adresseComplete.isEmpty {
                    Text(client.adresseComplete)
                        .foregroundColor(.secondary)
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("Détail de la facture")
                    .font(.headline)

                ForEach(editableFacture.lignes.indices, id: \.self) { index in
                    let ligne = editableFacture.lignes[index]
                    VStack(alignment: .leading) {
                        HStack {
                            Text(ligne.designation)
                                .fontWeight(.medium)
                            Spacer()
                            Text(ligne.total.euroFormatted)
                                .fontWeight(.semibold)
                        }
                        Text("Qté: \(String(format: "%.0f", ligne.quantite)) × \(ligne.prixUnitaire.euroFormatted)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        if let refCommande = ligne.referenceCommande, !refCommande.isEmpty {
                            Text("Réf. Commande: \(refCommande)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        if let dateCommande = ligne.dateCommande {
                            Text("Date Commande: \(dateCommande.frenchFormatted)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            Divider()

            VStack(alignment: .trailing, spacing: 4) {
                HStack {
                    Text("Sous-total HT:")
                    Spacer()
                    Text(editableFacture.sousTotal.euroFormatted)
                }

                HStack {
                    Text("TVA (\(String(format: "%.1f", editableFacture.tva))%):")
                    Spacer()
                    Text((editableFacture.sousTotal * (editableFacture.tva / 100)).euroFormatted)
                }

                if editableFacture.remisePourcentage > 0 {
                    HStack {
                        Text("Remise (\(editableFacture.remisePourcentage.formatted(.number.precision(.fractionLength(0...2))))%):")
                        Spacer()
                        Text("-\(((editableFacture.sousTotal + (editableFacture.sousTotal * (editableFacture.tva / 100))) * (editableFacture.remisePourcentage / 100)).euroFormatted)")
                    }
                }

                HStack {
                    Text("Total TTC:")
                        .fontWeight(.bold)
                    Spacer()
                    Text((editableFacture.sousTotal * (1 + (editableFacture.tva / 100))).euroFormatted)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
            }

            if !editableFacture.notes.isEmpty {
                Divider()

                VStack(alignment: .leading, spacing: 4) {
                    Text("Notes:")
                        .font(.headline)
                    Text(editableFacture.notes)
                        .foregroundColor(.secondary)
                }
            }

            if let commentaire = editableFacture.notesCommentaireFacture, !commentaire.isEmpty {
                Divider()

                VStack(alignment: .leading, spacing: 4) {
                    Text("Commentaire:")
                        .font(.headline)
                    Text(commentaire)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color.systemBackground)
        .cornerRadius(12)
        .shadow(radius: 5)
    }
}



#Preview {
    AddFactureView()
        .environmentObject(DataService.shared)
}
