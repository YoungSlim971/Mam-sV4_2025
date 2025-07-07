
// Views/Factures/FacturesView.swift
import SwiftUI
import UniformTypeIdentifiers


struct FacturesView: View {
    @EnvironmentObject private var dataService: DataService
    @Binding var searchText: String

    @State private var selectedStatut: StatutFacture? = nil
    @State private var showingAddFacture = false
    @State private var showingFileImporter = false
    @State private var selectedFactureID: UUID? // Remplacer le DTO par un ID stable
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
            // On cherche le DTO correspondant à l'ID pour passer à EditFactureView
            // EditFactureView doit être capable de gérer un DTO potentiellement invalide
            if let factureDTO = dataService.factures.first(where: { $0.id == factureID }) {
                EditFactureView(
                    factureDTO: factureDTO,
                    lignes: dataService.lignes.filter { $0.factureId == factureID },
                    isReadOnly: false
                )
            } else {
                // Fallback si la facture a été supprimée entre-temps
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
                    try await pdfImporter.importFacture(from: url, dataService: dataService)
                } else {
                    try await excelImporter.importFacture(from: url, dataService: dataService)
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
            guard let entreprise = dataService.entreprise,
                  let client = dataService.clients.first(where: { $0.id == facture.clientId }) else { return }
            
            let lignes = dataService.lignes.filter { $0.factureId == facture.id }
            if let pdfData = await pdfService.generatePDF(for: facture, lignes: lignes, client: client, entreprise: entreprise) {
                pdfDocument = GeneratedPDFDocument(data: pdfData)
                showingSavePanel = true
            }
        }
    }

    private var filteredAndSortedFactures: [FactureDTO] {
        var result = dataService.factures

        if let statut = selectedStatut {
            result = result.filter { $0.statut == statut.rawValue }
        }

        if !searchText.isEmpty {
            result = result.filter { facture in
                facture.numero.localizedCaseInsensitiveContains(searchText) ||
                (dataService.clients.first { $0.id == facture.clientId }?.nomCompletClient.localizedCaseInsensitiveContains(searchText) ?? false)
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
        case .montantDesc: result.sort { $0.calculateTotalTTC(with: dataService.lignes) > $1.calculateTotalTTC(with: dataService.lignes) }
        case .montantAsc: result.sort { $0.calculateTotalTTC(with: dataService.lignes) < $1.calculateTotalTTC(with: dataService.lignes) }
        }

        return result
    }
}

private struct FactureRow: View {
    let facture: FactureDTO
    @EnvironmentObject private var dataService: DataService

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(facture.numero)
                    .font(.headline)
                Text(facture.dateFacture, style: .date)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Text(facture.statut)
        }
    }
}

// MARK: - FacturesList (Utilise maintenant un Binding sur l'ID)
private struct FacturesList: View {
    let factures: [FactureDTO]
    @Binding var selectedFactureID: UUID?
    let exportPDF: (FactureDTO) -> Void
    let isGeneratingPDF: Bool

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
                LazyVStack(spacing: 8) {
                    ForEach(factures) { facture in
                        FactureRow(facture: facture)
                            .onTapGesture {
                                selectedFactureID = facture.id // On assigne l'ID
                            }
                            .contextMenu {
                                FactureContextMenu(facture: facture, exportPDF: exportPDF, isGeneratingPDF: isGeneratingPDF)
                            }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - FactureContextMenu (Sécurisation des actions)
struct FactureContextMenu: View {
    let facture: FactureDTO
    let exportPDF: (FactureDTO) -> Void
    let isGeneratingPDF: Bool
    @EnvironmentObject private var dataService: DataService

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
                    await dataService.updateFactureDTO(updatedFacture)
                }
            }
        }

        if facture.statut == StatutFacture.brouillon.rawValue {
            Button("Marquer comme envoyée") {
                Task {
                    var updatedFacture = facture
                    updatedFacture.statut = StatutFacture.envoyee.rawValue
                    await dataService.updateFactureDTO(updatedFacture)
                }
            }
        }

        Divider()

        Button("Supprimer", role: .destructive) {
            Task { await dataService.deleteFactureDTO(id: facture.id) }
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
    @EnvironmentObject private var dataService: DataService
    
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
        factures.reduce(0) { $0 + $1.calculateSousTotal(with: dataService.lignes) }
    }
    
    private var totalTTC: Double {
        factures.reduce(0) { $0 + $1.calculateTotalTTC(with: dataService.lignes) }
    }
}

