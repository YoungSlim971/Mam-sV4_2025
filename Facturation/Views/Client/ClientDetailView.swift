import SwiftUI
import DataLayer
import PDFEngine




struct ClientDetailView: View {
    let client: ClientDTO
    @EnvironmentObject private var dataService: DataService
    @Environment(\.dismiss) private var dismiss

    @State private var startDate: Date = Date()
    @State private var endDate: Date = Date()
    @State private var selectedFactureID: UUID?

    init(client: ClientDTO) {
        self.client = client
    }

    private var filteredFactures: [FactureDTO] {
        let clientFactures = dataService.factures.filter { $0.clientId == client.id }
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

                if filteredFactures.isEmpty {
                    ContentUnavailableView("Aucune facture", systemImage: "doc.text.magnifyingglass", description: Text("Aucune facture ne correspond à la période sélectionnée."))
                } else {
                    List(filteredFactures) { facture in
                        FactureRowForClient(facture: facture, client: client)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedFactureID = facture.id
                            }
                    }
                    .listStyle(.inset(alternatesRowBackgrounds: true))
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
                ClientFactureViewWrapper(factureID: id)
            }
        }
        .onAppear {
            let calendar = Calendar.current
            let components = calendar.dateComponents([.year], from: Date())
            startDate = calendar.date(from: components) ?? Date()
        }
        .frame(minWidth: 700, minHeight: 500)
    }
}

// Extension pour rendre UUID conforme à Identifiable
extension UUID: Identifiable {
    public var id: UUID { self }
}

private struct FactureRowForClient: View {
    let facture: FactureDTO
    let client: ClientDTO
    @EnvironmentObject private var dataService: DataService
    @State private var pdfDocument: GeneratedPDFDocument?
    @State private var showingSavePanel = false
    @State private var isGeneratingPDF = false
    private let pdfService = PDFService()

    private func exportSingleFacturePDF() {
        Task {
            isGeneratingPDF = true
            defer { isGeneratingPDF = false }
            
            guard let entreprise = dataService.entreprise else { return }
            let lignes = dataService.lignes.filter { $0.factureId == facture.id }
            
            if let pdfData = await pdfService.generatePDF(for: facture, lignes: lignes, client: client, entreprise: entreprise) {
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
            Text("\(facture.calculateTotalTTC(with: dataService.lignes)) EUR")
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

// MARK: - Wrapper pour charger le FactureModel avant de présenter la vue de détail.
private struct ClientFactureViewWrapper: View {
    let factureID: UUID
    @EnvironmentObject private var dataService: DataService
    @State private var facture: FactureModel?
    @State private var isLoading = true

    var body: some View {
        content
            .onAppear(perform: loadFactureModel)
    }

    @ViewBuilder
    private var content: some View {
        if isLoading {
            ProgressView("Chargement de la facture...")
        } else if let facture = facture {
            if facture.isValidModel {
                ClientFactureDetailView(facture: facture)
            } else {
                invalidDataView
            }
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
            Text("Cette facture a peut-être été supprimée.")
                .foregroundColor(.secondary)
        }
    }

    private func loadFactureModel() {
        Task {
            isLoading = true
            self.facture = await dataService.fetchFactureModel(id: factureID)
            isLoading = false
        }
    }
    
}
#if DEBUG
struct ClientFactureViewWrapper_Previews: PreviewProvider {
    static var previews: some View {
        let dummyService = DataService.previewMock() // Assure-toi d’avoir une méthode mock
        return ClientFactureViewWrapper(factureID: UUID())
            .environmentObject(dummyService)
    }
}
#endif
