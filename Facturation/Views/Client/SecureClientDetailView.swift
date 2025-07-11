// Views/Client/SecureClientDetailView.swift
import SwiftUI
import DataLayer
import PDFEngine

struct SecureClientDetailView: View {
    let client: ClientDTO
    @EnvironmentObject private var dependencies: DependencyContainer
    @Environment(\.dismiss) private var dismiss

    @State private var startDate: Date = Date()
    @State private var endDate: Date = Date()
    @State private var selectedFactureID: UUID?
    @State private var factures: [FactureDTO] = []
    @State private var lignes: [LigneFactureDTO] = []
    @State private var entreprise: EntrepriseDTO?
    @State private var isLoading = false
    @State private var errorMessage: String?

    init(client: ClientDTO) {
        self.client = client
    }

    private var filteredFactures: [FactureDTO] {
        let clientFactures = factures.filter { $0.clientId == client.id }
        let sortedFactures = clientFactures.sorted { $0.dateFacture > $1.dateFacture }
        
        return sortedFactures.filter { facture in
            let startOfDay = Calendar.current.startOfDay(for: startDate)
            let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: endDate) ?? endDate
            return facture.dateFacture >= startOfDay && facture.dateFacture < endOfDay
        }
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 15) {
                Text("Factures de \(client.nomCompletClient)")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(nsColor: .controlBackgroundColor)).shadow(radius: 2))
                    .padding([.horizontal, .top])

                HStack(spacing: 20) {
                    DatePicker("Du", selection: $startDate, displayedComponents: .date)
                    DatePicker("Au", selection: $endDate, displayedComponents: .date)
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 10).fill(Color(nsColor: .controlBackgroundColor)).shadow(radius: 1))
                .padding(.horizontal)

                if isLoading {
                    ProgressView("Chargement des factures...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if filteredFactures.isEmpty {
                    ContentUnavailableView("Aucune facture", systemImage: "doc.text.magnifyingglass", description: Text("Aucune facture ne correspond à la période sélectionnée."))
                } else {
                    List(filteredFactures) { facture in
                        SecureFactureRowForClient(facture: facture, client: client, lignes: lignes, entreprise: entreprise)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedFactureID = facture.id
                            }
                    }
                    .listStyle(.inset(alternatesRowBackgrounds: true))
                }
                
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") { dismiss() }
                }
            }
            .environment(\.locale, .init(identifier: "fr_FR"))
            .padding()
            .sheet(item: $selectedFactureID) { id in
                SecureClientFactureViewWrapper(factureID: id)
                    .environmentObject(dependencies)
            }
        }
        .onAppear {
            let calendar = Calendar.current
            let components = calendar.dateComponents([.year], from: Date())
            startDate = calendar.date(from: components) ?? Date()
            loadData()
        }
        .frame(minWidth: 700, minHeight: 500)
    }
    
    private func loadData() {
        Task {
            isLoading = true
            errorMessage = nil
            
            do {
                // Load factures
                let fetchFacturesResult = await dependencies.fetchFacturesUseCase.execute()
                switch fetchFacturesResult {
                case .success(let fetchedFactures):
                    factures = fetchedFactures
                case .failure(let error):
                    errorMessage = "Erreur lors du chargement des factures: \(error.localizedDescription)"
                }
                
                // Load lignes
                let fetchLignesResult = await dependencies.fetchLignesUseCase.execute()
                switch fetchLignesResult {
                case .success(let fetchedLignes):
                    lignes = fetchedLignes
                case .failure(let error):
                    errorMessage = "Erreur lors du chargement des lignes: \(error.localizedDescription)"
                }
                
                // Load entreprise
                let fetchEntrepriseResult = await dependencies.getEntrepriseUseCase.execute()
                switch fetchEntrepriseResult {
                case .success(let fetchedEntreprise):
                    entreprise = fetchedEntreprise
                case .failure(let error):
                    errorMessage = "Erreur lors du chargement de l'entreprise: \(error.localizedDescription)"
                }
                
            } catch {
                errorMessage = "Erreur inattendue: \(error.localizedDescription)"
            }
            
            isLoading = false
        }
    }
}

// MARK: - Secure Facture Row for Client
private struct SecureFactureRowForClient: View {
    let facture: FactureDTO
    let client: ClientDTO
    let lignes: [LigneFactureDTO]
    let entreprise: EntrepriseDTO?
    
    @State private var pdfDocument: GeneratedPDFDocument?
    @State private var showingSavePanel = false
    @State private var isGeneratingPDF = false
    private let pdfService = PDFService()

    private func exportSingleFacturePDF() {
        Task {
            isGeneratingPDF = true
            defer { isGeneratingPDF = false }
            
            guard let entreprise = entreprise else { return }
            let factureLignes = lignes.filter { $0.factureId == facture.id }
            
            if let pdfData = await pdfService.generatePDF(for: facture, lignes: factureLignes, client: client, entreprise: entreprise) {
                pdfDocument = GeneratedPDFDocument(data: pdfData)
                showingSavePanel = true
            }
        }
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(facture.numero)
                    .font(.headline)
                    .fontWeight(.semibold)
                Text(facture.dateFacture, style: .date)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Text(facture.calculateTotalTTC(with: lignes).formattedEuros)
                .font(.system(.body, design: .monospaced))
                .fontWeight(.medium)
            
            Text(facture.statut)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background((StatutFacture(rawValue: facture.statut)?.color ?? .gray).opacity(0.2))
                .foregroundColor(StatutFacture(rawValue: facture.statut)?.color ?? .gray)
                .cornerRadius(6)

            Button(action: exportSingleFacturePDF) {
                Image(systemName: "square.and.arrow.down")
            }
            .buttonStyle(.borderless)
            .disabled(isGeneratingPDF)
        }
        .padding(.vertical, 8)
        .fileExporter(isPresented: $showingSavePanel, document: pdfDocument, contentType: .pdf, defaultFilename: "Facture-\(facture.numero).pdf") { result in
            if case .failure(let error) = result {
                print("Erreur d'exportation PDF: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Secure Wrapper for loading FactureDTO
private struct SecureClientFactureViewWrapper: View {
    let factureID: UUID
    @EnvironmentObject private var dependencies: DependencyContainer
    @State private var facture: FactureDTO?
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        content
            .onAppear(perform: loadFactureModel)
    }

    @ViewBuilder
    private var content: some View {
        if isLoading {
            ProgressView("Chargement de la facture...")
        } else if let facture = facture {
            SecureClientFactureDetailView(facture: facture)
                .environmentObject(dependencies)
        } else {
            invalidDataView
        }
    }

    private var invalidDataView: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            Text("Facture non disponible")
                .font(.title.bold())
            Text(errorMessage ?? "Cette facture a peut-être été supprimée.")
                .foregroundColor(.secondary)
        }
    }

    private func loadFactureModel() {
        Task {
            isLoading = true
            errorMessage = nil
            
            let result = await dependencies.getFactureUseCase.execute(id: factureID)
            switch result {
            case .success(let fetchedFacture):
                facture = fetchedFacture
            case .failure(let error):
                errorMessage = "Erreur lors du chargement: \(error.localizedDescription)"
            }
            
            isLoading = false
        }
    }
}

// MARK: - Secure Client Facture Detail View
private struct SecureClientFactureDetailView: View {
    let facture: FactureDTO
    @EnvironmentObject private var dependencies: DependencyContainer
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("Détails de la facture")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding()
                
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Numéro:")
                            .fontWeight(.semibold)
                        Spacer()
                        Text(facture.numero)
                    }
                    
                    HStack {
                        Text("Date d'émission:")
                            .fontWeight(.semibold)
                        Spacer()
                        Text(facture.dateFacture, style: .date)
                    }
                    
                    HStack {
                        Text("Date d'échéance:")
                            .fontWeight(.semibold)
                        Spacer()
                        if let dateEcheance = facture.dateEcheance {
                            Text(dateEcheance, style: .date)
                        } else {
                            Text("Non définie")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    HStack {
                        Text("Statut:")
                            .fontWeight(.semibold)
                        Spacer()
                        Text(facture.statut)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background((StatutFacture(rawValue: facture.statut)?.color ?? .gray).opacity(0.2))
                            .foregroundColor(StatutFacture(rawValue: facture.statut)?.color ?? .gray)
                            .cornerRadius(6)
                    }
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(10)
                .padding()
                
                Spacer()
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") { dismiss() }
                }
            }
        }
    }
}

// Extension pour UUID Identifiable
extension UUID: @retroactive Identifiable {
    public var id: UUID { self }
}