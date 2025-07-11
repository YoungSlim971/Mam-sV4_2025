
// Views/Factures/FacturesView.swift
import SwiftUI
import UniformTypeIdentifiers
import DataLayer
import PDFEngine


struct FacturesView: View {
    @EnvironmentObject private var dependencyContainer: DependencyContainer
    @Binding var searchText: String

    @State private var selectedStatut: StatutFacture? = nil
    @State private var showingAddFacture = false
    @State private var showingFileImporter = false
    @State private var selectedFactureID: UUID?
    @State private var sortOrder = SortOrder.dateDesc

    @State private var filterMode: FilterMode = .all
    @State private var selectedDate = Date()
    @State private var showingCalendar = false

    @State private var pdfDocument: GeneratedPDFDocument?
    @State private var showingSavePanel = false
    @State private var isGeneratingPDF = false
    @State private var isImporting = false
    private let pdfService = PDFService()
    private let excelImporter = ExcelImporter()
    private let pdfImporter = PDFImporter()
    @State private var importError: Error?
    
    @State private var factures: [FactureDTO] = []
    @State private var clients: [ClientDTO] = []
    @State private var lignes: [LigneFactureDTO] = []
    @State private var entreprise: EntrepriseDTO?
    @State private var isLoading = true

    enum FilterMode: String, CaseIterable {
        case all = "Toutes factures"
        case monthly = "Par mois"
    }

    enum SortOrder: String, CaseIterable {
        case dateDesc = "Date (récent)"
        case dateAsc = "Date (ancien)"
        case numeroDesc = "Numéro (Z-A)"
        case numeroAsc = "Numéro (A-Z)"
        case montantDesc = "Montant (élevé)"
        case montantAsc = "Montant (faible)"
    }

    var body: some View {
        VStack(spacing: 0) {
            HeaderView(showingAddFacture: $showingAddFacture, showingFileImporter: $showingFileImporter, isImporting: $isImporting)

            FilterBar(
                selectedStatut: $selectedStatut,
                sortOrder: $sortOrder,
                filterMode: $filterMode,
                selectedDate: $selectedDate,
                showingCalendar: $showingCalendar,
                filteredFacturesCount: filteredAndSortedFactures.count
            )

            SummaryView(factures: filteredAndSortedFactures)

            FacturesList(
                factures: filteredAndSortedFactures,
                selectedFactureID: $selectedFactureID, // Utiliser l'ID pour la sélection
                exportPDF: exportPDF(for:),
                isGeneratingPDF: isGeneratingPDF
            )
        }
        .sheet(isPresented: $showingAddFacture) {
            AddFactureView()
        }
        // La sheet est maintenant liée à l'ID, pas au DTO
        .sheet(item: $selectedFactureID) { factureID in
            if let factureDTO = factures.first(where: { $0.id == factureID }) {
                EditFactureView(
                    factureDTO: factureDTO,
                    lignes: lignes.filter { $0.factureId == factureID },
                    isReadOnly: false
                )
            } else {
                Text("Cette facture n'est plus disponible.")
            }
        }
        .fileImporter(isPresented: $showingFileImporter, allowedContentTypes: [.pdf, .spreadsheet], allowsMultipleSelection: false) { result in
            handleFileImport(result: result)
        }
        .alert("Erreur d'importation", isPresented: .constant(importError != nil), presenting: importError) { error in
            Button("OK") { importError = nil }
        } message: { error in
            Text(error.localizedDescription)
        }
    }
    
    private func handleFileImport(result: Result<[URL], Error>) {
        Task {
            isImporting = true
            defer { isImporting = false }
            do {
                guard let url = try result.get().first else { return }
                if url.pathExtension.lowercased() == "pdf" {
                    // TODO: Migrer l'import PDF vers les use cases
                    // try await pdfImporter.importFacture(from: url, dataService: dataService)
                    print("Import PDF temporairement désactivé pendant la migration")
                } else {
                    let facturesDTO = try await excelImporter.importFactures(from: url)
                    for factureDTO in facturesDTO {
                        let _ = await dependencyContainer.createFactureUseCase.execute(clientId: factureDTO.clientId, tva: factureDTO.tva)
                    }
                    await loadData()
                }
            } catch {
                importError = error
                print("Erreur lors de l'importation : \(error.localizedDescription)")
            }
        }
    }

    private func exportPDF(for facture: FactureDTO) {
        Task {
            isGeneratingPDF = true
            defer { isGeneratingPDF = false }
            
            print("🔍 Exportation PDF pour facture: \(facture.numero) (ID: \(facture.id))")
            
            // Charger les données fraîches
            await loadData()
            
            guard let entreprise = entreprise,
                  let client = clients.first(where: { $0.id == facture.clientId }) else { 
                print("❌ Données manquantes pour l'export PDF")
                return 
            }
            
            let factureLines = lignes.filter { $0.factureId == facture.id }
            print("📄 Export facture \(facture.numero) avec \(factureLines.count) lignes pour client \(client.nom)")
            
            if let pdfData = await pdfService.generatePDF(for: facture, lignes: factureLines, client: client, entreprise: entreprise) {
                pdfDocument = GeneratedPDFDocument(data: pdfData)
                showingSavePanel = true
                print("✅ PDF généré avec succès pour facture \(facture.numero)")
            } else {
                print("❌ Échec de génération PDF pour facture \(facture.numero)")
            }
        }
    }

    private var filteredAndSortedFactures: [FactureDTO] {
        var result = factures

        if let statut = selectedStatut {
            result = result.filter { $0.statut == statut.rawValue }
        }

        if !searchText.isEmpty {
            result = result.filter { facture in
                facture.numero.localizedCaseInsensitiveContains(searchText) ||
                (clients.first { $0.id == facture.clientId }?.nomCompletClient.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }

        if filterMode == .monthly {
            result = result.filter { Calendar.current.isDate($0.dateFacture, equalTo: selectedDate, toGranularity: .month) }
        }

        switch sortOrder {
        case .dateDesc: result.sort { $0.dateFacture > $1.dateFacture }
        case .dateAsc: result.sort { $0.dateFacture < $1.dateFacture }
        case .numeroDesc: result.sort { $0.numero > $1.numero }
        case .numeroAsc: result.sort { $0.numero < $1.numero }
        case .montantDesc: result.sort { $0.calculateTotalTTC(with: lignes) > $1.calculateTotalTTC(with: lignes) }
        case .montantAsc: result.sort { $0.calculateTotalTTC(with: lignes) < $1.calculateTotalTTC(with: lignes) }
        }

        return result
    }
    
    private func loadData() async {
        isLoading = true
        
        async let facturesResult = dependencyContainer.fetchFacturesUseCase.execute()
        async let clientsResult = dependencyContainer.fetchClientsUseCase.execute()
        async let lignesResult = dependencyContainer.fetchLignesUseCase.execute()
        async let entrepriseResult = dependencyContainer.fetchEntrepriseUseCase.execute()
        
        let (facturesRes, clientsRes, lignesRes, entrepriseRes) = await (facturesResult, clientsResult, lignesResult, entrepriseResult)
        
        if case .success(let facturesData) = facturesRes {
            factures = facturesData
        }
        
        if case .success(let clientsData) = clientsRes {
            clients = clientsData
        }
        
        if case .success(let lignesData) = lignesRes {
            lignes = lignesData
        }
        
        if case .success(let entrepriseData) = entrepriseRes {
            entreprise = entrepriseData
        }
        
        isLoading = false
    }
}

private struct FacturesList: View {
    let factures: [FactureDTO]
    @Binding var selectedFactureID: UUID?
    let exportPDF: (FactureDTO) -> Void
    let isGeneratingPDF: Bool
    @EnvironmentObject private var dependencyContainer: DependencyContainer
    
    @State private var clients: [ClientDTO] = []
    @State private var lignes: [LigneFactureDTO] = []

    var body: some View {
        ScrollView {
            if factures.isEmpty {
                VStack {
                    Image(systemName: "doc.text")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("Aucune facture")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .padding()
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(factures) { facture in
                        FactureRow(
                            facture: facture,
                            client: clients.first(where: { $0.id == facture.clientId }),
                            total: facture.calculateTotalTTC(with: lignes),
                            onTap: { selectedFactureID = facture.id },
                            onExport: { exportPDF(facture) },
                            isGeneratingPDF: isGeneratingPDF
                        )
                        .padding(.horizontal, 6)
                    }
                }
                .padding(.vertical)
            }
        }
    }
}

private struct FactureRow: View {
    let facture: FactureDTO
    let client: ClientDTO?
    let total: Double
    let onTap: () -> Void
    let onExport: () -> Void
    let isGeneratingPDF: Bool

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                // Bloc numéro/date
                VStack(alignment: .leading, spacing: 3) {
                    Text(facture.numero)
                        .font(.headline)
                    Text(facture.dateFacture.frenchFormatted)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(minWidth: 100, idealWidth: 120, maxWidth: 150, alignment: .leading)

                // Bloc client
                VStack(alignment: .leading, spacing: 2) {
                    Text(client?.nomCompletClient ?? "Client inconnu")
                        .font(.subheadline)
                        .lineLimit(1)
                    if let ent = client?.entreprise, !ent.isEmpty {
                        Text(ent)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                .frame(minWidth: 120, maxWidth: .infinity, alignment: .leading)

                Spacer()

                // Bloc montant + statut
                VStack(alignment: .trailing, spacing: 2) {
                    Text(total.euroFormatted)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                    Text(facture.statutDisplay)
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 3)
                        .background(facture.statutColor)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .lineLimit(1)
                }

                // Bouton export rapide (optionnel)
                Menu {
                    Button("Exporter PDF", action: onExport)
                        .disabled(isGeneratingPDF)
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(.primary)
                        .font(.title3)
                        .padding(.leading, 5)
                }
                .menuStyle(.borderlessButton)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(NSColor.controlBackgroundColor))
                    .shadow(color: Color.black.opacity(0.03), radius: 2, x: 0, y: 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .contextMenu {
            Button("Exporter PDF", action: onExport)
                .disabled(isGeneratingPDF)
        }
    }
}

// MARK: - FactureContextMenu (Sécurisation des actions)
struct FactureContextMenu: View {
    let facture: FactureDTO
    let exportPDF: (FactureDTO) -> Void
    let isGeneratingPDF: Bool
    @EnvironmentObject private var dependencyContainer: DependencyContainer

    var body: some View {
        // L'action de modification doit maintenant utiliser l'ID
        // NavigationLink("Modifier", value: facture.id) est une meilleure approche dans un NavigationSplitView

        Button("Exporter PDF") {
            exportPDF(facture)
        }
        .disabled(isGeneratingPDF)

        Divider()

        if facture.statut != StatutFacture.payee.rawValue {
            Button("Marquer comme payée") {
                Task {
                    var updatedFacture = facture
                    updatedFacture.statut = StatutFacture.payee.rawValue
                    updatedFacture.datePaiement = Date()
                    let _ = await dependencyContainer.updateFactureUseCase.execute(facture: updatedFacture)
                }
            }
        }

        if facture.statut == StatutFacture.brouillon.rawValue {
            Button("Marquer comme envoyée") {
                Task {
                    var updatedFacture = facture
                    updatedFacture.statut = StatutFacture.envoyee.rawValue
                    let _ = await dependencyContainer.updateFactureUseCase.execute(facture: updatedFacture)
                }
            }
        }

        Divider()

        Button("Supprimer", role: .destructive) {
            Task { 
                let _ = await dependencyContainer.deleteFactureUseCase.execute(factureId: facture.id)
            }
        }
    }
}

// MARK: - Missing Components
private struct HeaderView: View {
    @Binding var showingAddFacture: Bool
    @Binding var showingFileImporter: Bool
    @Binding var isImporting: Bool
    
    var body: some View {
        HStack {
            Text("Factures")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Spacer()
            
            HStack {
                Button("Importer", systemImage: "square.and.arrow.down") {
                    showingFileImporter = true
                }
                .disabled(isImporting)
                
                Button("Nouvelle facture", systemImage: "plus") {
                    showingAddFacture = true
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }
}

private struct FilterBar: View {
    @Binding var selectedStatut: StatutFacture?
    @Binding var sortOrder: FacturesView.SortOrder
    @Binding var filterMode: FacturesView.FilterMode
    @Binding var selectedDate: Date
    @Binding var showingCalendar: Bool
    let filteredFacturesCount: Int
    
    var body: some View {
        HStack {
            Menu("Statut: \(selectedStatut?.rawValue ?? "Tous")") {
                Button("Tous") { selectedStatut = nil }
                ForEach(StatutFacture.allCases, id: \.self) { statut in
                    Button(statut.rawValue) { selectedStatut = statut }
                }
            }
            
            Menu("Tri: \(sortOrder.rawValue)") {
                ForEach(FacturesView.SortOrder.allCases, id: \.self) { order in
                    Button(order.rawValue) { sortOrder = order }
                }
            }
            
            Menu("Filtre: \(filterMode.rawValue)") {
                ForEach(FacturesView.FilterMode.allCases, id: \.self) { mode in
                    Button(mode.rawValue) { filterMode = mode }
                }
            }
            
            if filterMode == .monthly {
                Button("Mois: \(selectedDate.formatted(.dateTime.month().year()))") {
                    showingCalendar.toggle()
                }
            }
            
            Spacer()
            
            Text("\(filteredFacturesCount) facture(s)")
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
    }
}

private struct SummaryView: View {
    let factures: [FactureDTO]
    @EnvironmentObject private var dependencyContainer: DependencyContainer
    
    @State private var lignes: [LigneFactureDTO] = []
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Total HT")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(totalHT, format: .currency(code: "EUR"))
                    .font(.headline)
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text("Total TTC")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(totalTTC, format: .currency(code: "EUR"))
                    .font(.headline)
                    .fontWeight(.bold)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
    }
    
    private var totalHT: Double {
        factures.reduce(0) { $0 + $1.calculateSousTotal(with: lignes) }
    }
    
    private var totalTTC: Double {
        factures.reduce(0) { $0 + $1.calculateTotalTTC(with: lignes) }
    }
}

