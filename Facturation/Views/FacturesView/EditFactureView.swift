import SwiftUI

struct EditFactureView: View {
    @EnvironmentObject private var dataService: DataService
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let factureDTO: FactureDTO
    @State private var editedFacture: EditableFacture
    @State private var isReadOnly: Bool

    // État pour gérer la validité du modèle sous-jacent
    @State private var factureModel: FactureModel?
    @State private var isLoading = true

    // UI State
    @State private var showingFutureDateAlert = false
    @State private var pdfFile: GeneratedPDFDocument?
    @State private var showingSavePanel = false
    @State private var isGeneratingPDF = false

    init(factureDTO: FactureDTO, lignes: [LigneFactureDTO] = [], isReadOnly: Bool = false) {
        self.factureDTO = factureDTO
        self._editedFacture = State(initialValue: EditableFacture(fromDTO: factureDTO, lignes: lignes))
        self._isReadOnly = State(initialValue: isReadOnly)
    }

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Chargement...")
                } else if let facture = self.factureModel {
                    if facture.isValidModel {
                        factureForm(facture: facture)
                    } else {
                        factureDeletedView
                    }
                } else {
                    factureDeletedView
                }
            }
        }
        .onAppear(perform: loadFactureModel)
        .onChange(of: dataService.factures) { _, _ in
            // Re-valider si les données globales changent
            loadFactureModel()
        }
    }

    @ViewBuilder
    private func factureForm(facture: FactureModel) -> some View {
        Form {
            headerSection
            clientSection
            lignesSection
            totauxSection
            notesSection
        }
        .formStyle(.grouped)
        .navigationTitle("Facture \(facture.numero)")
        .toolbar {
            if !isReadOnly {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Enregistrer", action: { saveChanges(facture: facture) })
                        .keyboardShortcut("s", modifiers: [.command])
                }
                ToolbarItem {
                    Button("Exporter PDF", systemImage: "square.and.arrow.up") {
                        exportPDF(facture: facture)
                    }
                    .disabled(isGeneratingPDF)
                }
                ToolbarItem {
                    Button("Supprimer", systemImage: "trash", role: .destructive) {
                        Task { await dataService.deleteFactureDTO(id: facture.id); dismiss() }
                    }
                }
            }
        }
        .fileExporter(isPresented: $showingSavePanel, document: pdfFile, contentType: .pdf, defaultFilename: "Facture-\(facture.numero).pdf") { _ in }
    }
    
    @ViewBuilder
    private var factureDeletedView: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            Text("Facture non disponible")
                .font(.title.bold())
            Text("Cette facture a été supprimée ou n'est plus accessible.")
                .foregroundColor(.secondary)
            Button("Fermer") { dismiss() }.buttonStyle(.borderedProminent)
        }
        .navigationTitle("Erreur")
    }

    // MARK: - Sections
    
    @ViewBuilder private var headerSection: some View {
        Section("Informations") {
            DatePicker("Date facture", selection: $editedFacture.dateFacture, displayedComponents: .date)
            DatePicker("Date échéance", selection: $editedFacture.dateEcheance, displayedComponents: .date)
            Picker("Statut", selection: $editedFacture.statut) {
                ForEach(StatutFacture.allCases, id: \.self) { Text($0.rawValue.capitalized).tag($0) }
            }
            if editedFacture.statut == .payee {
                DatePicker("Date de paiement", selection: Binding(get: { editedFacture.datePaiement ?? Date() }, set: { editedFacture.datePaiement = $0 }), displayedComponents: .date)
            }
        }
    }
    
    @ViewBuilder private var clientSection: some View {
        Section("Client") {
            if let client = dataService.clients.first(where: { $0.id == factureDTO.clientId }) {
                Text(client.nomCompletClient).font(.headline)
            } else {
                Text("Client non trouvé").foregroundColor(.red)
            }
        }
    }
    
    @ViewBuilder private var lignesSection: some View {
        Section("Lignes de facture") {
            ForEach($editedFacture.lignes) { $ligne in
                VStack {
                    TextField("Désignation", text: $ligne.designation)
                    HStack {
                        TextField("Qté", value: $ligne.quantite, format: .number)
                        TextField("Prix U.", value: $ligne.prixUnitaire, format: .currency(code: "EUR"))
                        Text(ligne.total.euroFormatted).frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
                .swipeActions {
                    Button(role: .destructive) {
                        editedFacture.lignes.removeAll { $0.id == ligne.id }
                    } label: { Label("Supprimer", systemImage: "trash") }
                }
            }
            Button("Ajouter une ligne") { editedFacture.lignes.append(EditableLigneFacture()) }
        }
    }
    
    @ViewBuilder private var totauxSection: some View {
        Section("Totaux") {
            HStack { Text("Sous-total"); Spacer(); Text(editedFacture.sousTotal.euroFormatted) }
            HStack { Text("TVA (\(editedFacture.tva.formatted(.percent)))"); Spacer(); Text(editedFacture.montantTVA.euroFormatted) }
            HStack { Text("Total TTC").bold(); Spacer(); Text(editedFacture.totalTTC.euroFormatted).bold() }
        }
    }
    
    @ViewBuilder private var notesSection: some View {
        Section("Notes & Commentaires") {
            TextEditor(text: $editedFacture.notes)
            TextEditor(text: Binding(get: { editedFacture.notesCommentaireFacture ?? "" }, set: { editedFacture.notesCommentaireFacture = $0 }))
        }
    }

    // MARK: - Data Logic
    
    private func loadFactureModel() {
        Task {
            isLoading = true
            self.factureModel = await dataService.fetchFactureModel(id: factureDTO.id)
            isLoading = false
        }
    }
    
    private func saveChanges(facture: FactureModel) {
        // Re-valider une dernière fois avant la sauvegarde.
        guard facture.isValidModel else {
            print("❌ ERREUR: Tentative de sauvegarde sur une facture invalidée.")
            factureModel = nil // Déclenche l'affichage de la vue d'erreur
            return
        }

        // Appliquer les modifications de l'état éditable au modèle persisté
        facture.updateFromDTO(editedFacture.toDTO(id: factureDTO.id, clientId: facture.client?.id ?? UUID(), ligneIds: editedFacture.lignes.map { $0.id }))
        
        // Gérer les lignes (simplifié pour l'exemple)
        // Une logique complète devrait gérer l'ajout, la suppression et la mise à jour des lignes.

        // La sauvegarde est gérée par le contexte de SwiftData, pas besoin d'appeler un service.
        print("✅ Facture \(facture.numero) mise à jour.")
        dismiss()
    }
    
    @MainActor
    private func exportPDF(facture: FactureModel) {
        isGeneratingPDF = true
        Task {
            defer { isGeneratingPDF = false }
            guard let clientDTO = dataService.clients.first(where: { $0.id == facture.client?.id }),
                  let entrepriseDTO = dataService.entreprise else { return }
            
            let lignesDTO = facture.lignes.map { $0.toDTO() }
            let factureDTO = facture.toDTO()
            
            let pdfService = PDFService()
            if let data = await pdfService.generatePDF(for: factureDTO, lignes: lignesDTO, client: clientDTO, entreprise: entrepriseDTO) {
                self.pdfFile = GeneratedPDFDocument(data: data)
                self.showingSavePanel = true
            }
        }
    }
}

// Extension pour convertir EditableFacture en DTO pour la mise à jour
extension EditableFacture {
    func toDTO(id: UUID, clientId: UUID, ligneIds: [UUID]) -> FactureDTO {
        FactureDTO(
            id: id,
            numero: self.numeroPersonnalise ?? "",
            dateFacture: self.dateFacture,
            dateEcheance: self.dateEcheance,
            datePaiement: self.datePaiement,
            tva: self.tva,
            conditionsPaiement: self.conditionsPaiement.rawValue,
            remisePourcentage: self.remisePourcentage,
            statut: self.statut.rawValue,
            notes: self.notes,
            notesCommentaireFacture: self.notesCommentaireFacture,
            clientId: clientId,
            ligneIds: ligneIds
        )
    }
}


