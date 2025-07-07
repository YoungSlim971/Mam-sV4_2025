

import XCTest
import PDFKit
import Vision
@testable import Facturation // Assuming your main app target is Facturation

class ImportPDFTests: XCTestCase {

    var dataService: DataService!

    @MainActor
    override func setUp() {
        super.setUp()
        // Initialize DataService with an in-memory container for testing
        let schema = Schema([Facture.self, LigneFacture.self, Client.self, Entreprise.self, Produit.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: [config])
        dataService = DataService(modelContainer: container) // Assuming you add an init to DataService for testing
    }

    override func tearDown() {
        dataService = nil
        super.tearDown()
    }

    // Helper to create a dummy PDF file with text content
    func createTextPDF(text: String) throws -> URL {
        let pdfView = PDFView()
        let pdfDocument = PDFDocument()
        let page = PDFPage(image: NSImage(size: NSSize(width: 612, height: 792)))! // A4 size
        pdfDocument.insert(page, at: 0)

        let tempDirectory = FileManager.default.temporaryDirectory
        let fileName = UUID().uuidString + ".pdf"
        let fileURL = tempDirectory.appendingPathComponent(fileName)

        // Add text to the PDF page (simplified for testing)
        let mutableAttributedString = NSMutableAttributedString(string: text)
        let textRect = NSRect(x: 50, y: 700, width: 500, height: 50)
        let textAnnotation = PDFAnnotation(bounds: textRect, forType: .freeText, withProperties: nil)
        textAnnotation.contents = text
        page.addAnnotation(textAnnotation)

        pdfDocument.write(to: fileURL)
        return fileURL
    }

    // Helper to create a dummy PDF file with embedded XML (Factur-X simulation)
    func createFacturXPDF(xmlContent: String) throws -> URL {
        let pdfDocument = PDFDocument()
        let page = PDFPage(image: NSImage(size: NSSize(width: 612, height: 792)))!
        pdfDocument.insert(page, at: 0)

        let tempDirectory = FileManager.default.temporaryDirectory
        let fileName = UUID().uuidString + ".pdf"
        let fileURL = tempDirectory.appendingPathComponent(fileName)

        // Embed XML as a file attachment
        if let xmlData = xmlContent.data(using: .utf8) {
            let embeddedFile = PDFEmbeddedFile()
            embeddedFile.data = xmlData
            embeddedFile.name = "factur-x.xml"
            pdfDocument.documentCatalog?.addEmbeddedFile(embeddedFile)
        }

        pdfDocument.write(to: fileURL)
        return fileURL
    }

    // Test case for text-based PDF extraction
    func testImportFacture_TextPDF() async throws {
        let textContent = "Nom: Test Client\nEmail: test@example.com\nDate: 2023-01-15\nDesignation: Produit A\nQuantite: 2\nPrix unitaire: 10.0"
        let pdfURL = try createTextPDF(text: textContent)
        addTeardownBlock { try? FileManager.default.removeItem(at: pdfURL) }

        let importer = PDFImporter()
        let facture = try await importer.importFacture(from: pdfURL, dataService: dataService)

        XCTAssertEqual(facture.client?.nom, "Test Client")
        XCTAssertEqual(facture.lignes.first?.designation, "Produit A")
    }

    // Test case for Factur-X PDF extraction (mocked XML parsing)
    func testImportFacture_FacturXPDF() async throws {
        let xmlContent = "<Invoice><cbc:ID>INV-2023-001</cbc:ID><cbc:IssueDate>2023-01-15</cbc:IssueDate></Invoice>"
        let pdfURL = try createFacturXPDF(xmlContent: xmlContent)
        addTeardownBlock { try? FileManager.default.removeItem(at: pdfURL) }

        let importer = PDFImporter()
        let facture = try await importer.importFacture(from: pdfURL, dataService: dataService)

        XCTAssertEqual(facture.numero, "INV-2023-001") // Assuming your buildFacture can extract this
        // Further assertions based on your actual XML parsing logic
    }

    // Test case for scanned PDF (OCR) extraction - requires mocking Vision framework
    func testImportFacture_ScannedPDF_OCR() async throws {
        // This test is more complex as it requires mocking Vision framework's OCR
        // For a real test, you'd need to provide a mock for VNRecognizeTextRequest
        // or use a pre-generated image that Vision can process.
        // Here, we'll simulate a successful OCR result.

        // Create a dummy image that OCR would process
        let image = NSImage(size: NSSize(width: 100, height: 100))
        let tempDirectory = FileManager.default.temporaryDirectory
        let imageURL = tempDirectory.appendingPathComponent(UUID().uuidString + ".png")
        if let tiffData = image.tiffRepresentation, let bitmapImage = NSBitmapImageRep(data: tiffData) {
            let pngData = bitmapImage.representation(using: .png, properties: [:])
            try pngData?.write(to: imageURL)
        }
        addTeardownBlock { try? FileManager.default.removeItem(at: imageURL) }

        // Create a dummy PDF with an image (simulating a scanned document)
        let pdfDocument = PDFDocument()
        let page = PDFPage(image: image)!
        pdfDocument.insert(page, at: 0)
        let pdfURL = tempDirectory.appendingPathComponent(UUID().uuidString + ".pdf")
        pdfDocument.write(to: pdfURL)
        addTeardownBlock { try? FileManager.default.removeItem(at: pdfURL) }

        // Mock the OCR process to return predefined text
        // This part is conceptual as directly mocking Vision is hard in XCTest
        // You might need to refactor PDFImporter to allow injecting a mock OCR service.
        // For now, we'll assume OCR works and returns a specific string.
        let importer = PDFImporter()
        // In a real scenario, you'd inject a mock OCR service here
        // For this test, we'll rely on the actual Vision framework if it can process the dummy image
        // or skip this test if it's too complex to mock.

        // Since direct mocking of VNRecognizeTextRequest is not straightforward,
        // this test will primarily verify that the OCR path is taken and doesn't crash.
        // A more robust test would involve a dedicated OCR mocking framework or
        // integration tests with actual scanned PDFs.
        
        // For now, we'll just ensure the import process doesn't throw an unexpected error
        // when it attempts OCR.
        do {
            _ = try await importer.importFacture(from: pdfURL, dataService: dataService)
            // If it reaches here, OCR path was likely attempted without crashing
            XCTFail("OCR test needs proper mocking or a real scanned PDF to assert content.")
        } catch PDFImporter.ImportError.ocrFailed(let error) {
            XCTFail("OCR failed as expected (or due to missing mock): \(error.localizedDescription)")
        } catch {
            // Other errors are unexpected for this test
            XCTFail("Unexpected error during OCR test: \(error.localizedDescription)")
        }
    }

    // Test case for buildFacture mapping logic
    func testBuildFactureMapping() async throws {
        let importer = PDFImporter()
        let headers = ["Nom", "Email", "Date", "Designation", "Quantite", "Prix unitaire"]
        let headerMap = importer.buildHeaderMap(from: headers) // Assuming buildHeaderMap is internal or testable

        let rows: [[String]] = [
            ["Client A", "clientA@example.com", "2024-01-01", "Service X", "1", "100.0"],
            ["Client A", "clientA@example.com", "2024-01-01", "Produit Y", "3", "25.0"]
        ]

        let facture = try await importer.buildFacture(from: ArraySlice(rows), headerMap: headerMap, dataService: dataService)

        XCTAssertEqual(facture.client?.nom, "Client A")
        XCTAssertEqual(facture.lignes.count, 2)
        XCTAssertEqual(facture.lignes[0].designation, "Service X")
        XCTAssertEqual(facture.lignes[1].quantite, 3.0)
    }
}

// To make DataService testable with an in-memory container
extension DataService {
    convenience init(modelContainer: ModelContainer) {
        self.init() // Call the existing designated initializer
        self.modelContainer = modelContainer
        self.modelContext = modelContainer.mainContext
        // Re-fetch data with the new context
        Task { await self.fetchData() }
    }
}

// Make buildHeaderMap and buildFacture internal for testing
extension PDFImporter {
    func buildHeaderMap(from headers: [String]) -> [String: Int] {
        var headerMap: [String: Int] = [:]
        for (index, header) in headers.enumerated() {
            let normalizedHeader = header.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            headerMap[normalizedHeader] = index
        }
        return headerMap
    }

    func buildFacture(from rows: ArraySlice<[String]>, headerMap: [String: Int], dataService: DataService) async throws -> FactureDTO {
        // This is a simplified example. Real-world mapping needs robust error handling
        // and potentially more sophisticated logic to identify data blocks.

        guard let firstDataRow = rows.first else {
            throw ImportError.mappingFailed
        }

        // --- Client Mapping ---
        var clientDTO: ClientDTO?
        let clientName = firstDataRow[headerMap["nom"] ?? -1]
        let clientEmail = firstDataRow[headerMap["email"] ?? -1]

        // Attempt to find existing client
        let existingClients = await dataService.fetchClients()
        clientDTO = existingClients.first { c in
            (c.email == clientEmail && !clientEmail.isEmpty) || (c.nom == clientName && !clientName.isEmpty)
        }

        if clientDTO == nil {
            // Create new client if not found
            var newClient = ClientDTO(
                id: UUID(),
                nom: clientName,
                entreprise: "",
                email: clientEmail,
                telephone: firstDataRow[headerMap["téléphone"] ?? -1],
                siret: firstDataRow[headerMap["siret"] ?? -1],
                numeroTVA: firstDataRow[headerMap["n° tva"] ?? -1],
                adresse: firstDataRow[headerMap["adresse"] ?? -1],
                adresseRue: "",
                adresseCodePostal: "",
                adresseVille: "",
                adressePays: ""
            )
            await dataService.addClientDTO(newClient)
            clientDTO = newClient
        }

        guard let finalClient = clientDTO else {
            throw ImportError.mappingFailed
        }

        // --- Facture Mapping ---
        var newFacture = FactureDTO(
            id: UUID(),
            numero: await dataService.genererNumeroFacture(),
            dateFacture: Date(),
            dateEcheance: nil,
            datePaiement: nil,
            tva: 20.0,
            conditionsPaiement: "",
            remisePourcentage: 0.0,
            statut: StatutFacture.brouillon.rawValue,
            notes: "",
            notesCommentaireFacture: nil,
            clientId: finalClient.id,
            ligneIds: []
        )

        // Date parsing (example, needs robust date formatter)
        if let dateString = firstDataRow[headerMap["date"] ?? -1], let date = DateFormatter.yyyyMMdd.date(from: dateString) {
            newFacture.dateFacture = date
        }
        if let dueDateString = firstDataRow[headerMap["date échéance"] ?? -1], let dueDate = DateFormatter.yyyyMMdd.date(from: dueDateString) {
            newFacture.dateEcheance = dueDate
        }
        if let paymentDateString = firstDataRow[headerMap["date virement"] ?? -1], let paymentDate = DateFormatter.yyyyMMdd.date(from: paymentDateString) {
            newFacture.datePaiement = paymentDate
            newFacture.statut = StatutFacture.payee.rawValue
        }

        newFacture.notesCommentaireFacture = firstDataRow[headerMap["commentaire"] ?? -1]
        newFacture.conditionsPaiement = firstDataRow[headerMap["conditions paiement"] ?? -1]
        
        // --- LigneFacture Mapping ---
        // Assuming lines start from the second row and have consistent columns
        var lignes: [LigneFactureDTO] = []
        for (rowIndex, row) in rows.enumerated() {
            // Skip header row if it's still present in 'rows'
            if rowIndex == 0 && headerMap.values.contains(0) { continue } 
            
            let designation = row[headerMap["désignation"] ?? -1]
            let quantite = Double(row[headerMap["quantité"] ?? -1] ?? "0") ?? 0.0
            let prixUnitaire = Double(row[headerMap["prix unitaire"] ?? -1] ?? "0") ?? 0.0
            let referenceCommande = row[headerMap["réf. commande"] ?? -1]
            
            var dateCommande: Date? = nil
            if let dateCommandeString = row[headerMap["date commande"] ?? -1], let date = DateFormatter.yyyyMMdd.date(from: dateCommandeString) {
                dateCommande = date
            }
            
            let ligne = LigneFactureDTO(
                id: UUID(),
                designation: designation,
                quantite: quantite,
                prixUnitaire: prixUnitaire,
                referenceCommande: referenceCommande,
                dateCommande: dateCommande,
                produitId: nil,
                factureId: nil
            )
            await dataService.addLigneDTO(ligne)
            lignes.append(ligne)
        }
        newFacture.ligneIds = lignes.map { $0.id }

        await dataService.addFactureDTO(newFacture)
        return newFacture
    }
}