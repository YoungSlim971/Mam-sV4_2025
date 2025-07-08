//
//  PDFImporter.swift
//  Facturation
//
//  Created by youngslim971 on 04/07/2025.
//

import Foundation
import PDFKit
import Vision
import DataLayer
import Utilities

@preconcurrency
struct PDFImporter {
    enum ImportError: Error, LocalizedError {
        case fileNotFound
        case badFormat
        case mappingFailed
        case ocrFailed(Error)
        case facturXParsingFailed(Error)
        case invalidData(message: String)
        case clientNotFound

        var errorDescription: String? {
            switch self {
            case .fileNotFound:
                return "Le fichier PDF n'a pas été trouvé."
            case .badFormat:
                return "Le format du fichier PDF n'est pas pris en charge ou est corrompu."
            case .mappingFailed:
                return "Le mappage des données du PDF a échoué. Vérifiez le format du document."
            case .ocrFailed(let error):
                return "L'analyse OCR du PDF a échoué : \(error.localizedDescription)"
            case .facturXParsingFailed(let error):
                return "L'extraction des données Factur-X a échoué : \(error.localizedDescription)"
            case .invalidData(let message):
                return message
            case .clientNotFound:
                return "Le client n'a pas été trouvé lors de la génération du numéro de facture."
            }
        }
    }

    @preconcurrency
    func importFacture(from url: URL, dataService: DataService) async throws {
        guard Foundation.FileManager.default.fileExists(atPath: url.path(percentEncoded: false)) else {
            throw ImportError.fileNotFound
        }

        guard let pdf = PDFDocument(url: url) else {
            throw ImportError.badFormat
        }

        let rows: [[String]] = try await extractRows(from: pdf)
        
        // Assuming the first row is always headers
        guard let headerRow = rows.first, !headerRow.isEmpty else {
            throw ImportError.badFormat // Or a more specific error for missing headers
        }
        
        let headerMap = buildHeaderMap(from: headerRow)
        
        // Pass the remaining rows (excluding header) to buildFacture
        try await buildFacture(from: rows.dropFirst(), headerMap: headerMap, dataService: dataService)
    }

    // MARK: - PDF Content Extraction
    private func extractRows(from pdf: PDFDocument) async throws -> [[String]] {
        // 1. Try to extract Factur-X XML
        if let facturXData = extractFacturX(from: pdf) {
            do {
                return try parseFacturXXML(data: facturXData)
            } catch {
                throw ImportError.facturXParsingFailed(error)
            }
        }

        // 2. Try to extract text directly from PDF pages
        var allTextLines: [String] = []
        var hasTextContent = false
        for i in 0..<pdf.pageCount {
            if let page = pdf.page(at: i), let pageString = page.string {
                if !pageString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    allTextLines.append(contentsOf: pageString.components(separatedBy: .newlines))
                    hasTextContent = true
                }
            }
        }

        if hasTextContent {
            // Simple text PDF, parse lines into rows (e.g., by comma or tab, or just single lines)
            // This is a very basic assumption; real-world parsing would need more logic
            return allTextLines.map { [$0] } // Each line becomes a single-column row
        }

        // 3. If no text, try OCR for scanned PDFs
        return try await performOCR(on: pdf)
    }

    private func extractFacturX(from pdf: PDFDocument) -> Data? {
        // Extraction Factur-X désactivée : nécessite macOS 14+ et Xcode 15+.
        // Activez le bloc ci-dessous dès que tout l’environnement est à jour.
        /*
        #if compiler(>=5.9)
        if #available(macOS 14, *) {
            guard let documentCatalog = pdf.documentCatalog else { return nil }
            if let embeddedFiles = documentCatalog.embeddedFiles {
                for embeddedFile in embeddedFiles {
                    if embeddedFile.name.lowercased().contains("factur-x") && embeddedFile.name.lowercased().hasSuffix(".xml") {
                        return embeddedFile.data
                    }
                }
            }
        }
        #endif
        */
        return nil
    }

    private func parseFacturXXML(data: Data) throws -> [[String]] {
        // This is a placeholder. Real Factur-X parsing requires a robust XML parser
        // and knowledge of the Factur-X UBL/CII schema.
        // For demonstration, we'll just return a dummy structure.
        print("Attempting to parse Factur-X XML (placeholder implementation)")
        // Example: Parse some known fields from a simplified XML structure
        // In a real scenario, you'd use XMLParser or Codable with XMLDecoder
        
        // Dummy implementation:
        let xmlString = String(data: data, encoding: .utf8) ?? ""
        var extractedData: [[String]] = []
        
        // Example: Extracting Invoice ID and Date from a very simple XML structure
        if let invoiceIDRange = xmlString.range(of: "<cbc:ID>", options: .literal),
           let invoiceIDEndRange = xmlString.range(of: "</cbc:ID>", options: .literal, range: invoiceIDRange.upperBound..<xmlString.endIndex) {
            let id = String(xmlString[invoiceIDRange.upperBound..<invoiceIDEndRange.lowerBound])
            extractedData.append(["Invoice ID", id])
        }
        
        if let invoiceDateRange = xmlString.range(of: "<cbc:IssueDate>", options: .literal),
           let invoiceDateEndRange = xmlString.range(of: "</cbc:IssueDate>", options: .literal, range: invoiceDateRange.upperBound..<xmlString.endIndex) {
            let date = String(xmlString[invoiceDateRange.upperBound..<invoiceDateEndRange.lowerBound])
            extractedData.append(["Issue Date", date])
        }
        
        // Add more parsing logic for client, lines, etc.
        
        if extractedData.isEmpty {
            throw ImportError.facturXParsingFailed(NSError(domain: "PDFImporter", code: 0, userInfo: [NSLocalizedDescriptionKey: "No recognizable data found in Factur-X XML."]))
        }
        
        return extractedData
    }

    private func performOCR(on pdf: PDFDocument) async throws -> [[String]] {
        var extractedRows: [[String]] = []

        for i in 0..<pdf.pageCount {
            guard let page = pdf.page(at: i) else { continue }

            // Render PDF page to image for OCR
            let pageRect = page.bounds(for: .mediaBox)
            let renderer = UIGraphicsImageRenderer(bounds: pageRect) // Use UIGraphicsImageRenderer for macOS
            let image = renderer.image { ctx in
                ctx.saveGState()
                ctx.translateBy(x: 0, y: pageRect.height)
                ctx.scaleBy(x: 1.0, y: -1.0)
                page.draw(with: .mediaBox, to: ctx)
                ctx.restoreGState()
            }

            guard let cgImage = image.cgImage else { continue }

            let request = VNRecognizeTextRequest()
            request.recognitionLevel = .accurate // More accurate but slower
            request.usesLanguageCorrection = true
            request.recognitionLanguages = ["fr-FR", "en-US"] // Prioritize French, then English

            let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try requestHandler.perform([request])
                guard let observations = request.results else { continue }

                let recognizedText = observations.compactMap { observation in
                    // Get the top candidate for the recognized text
                    observation.topCandidates(1).first?.string
                }.joined(separator: "\n") // Join lines with newline for easier processing

                // Simple split by lines for now. More advanced parsing would involve
                // analyzing bounding boxes to group text into logical rows/columns.
                let lines = recognizedText.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                extractedRows.append(contentsOf: lines.map { [$0] }) // Each line as a single-column row

            } catch {
                throw ImportError.ocrFailed(error)
            }
        }
        
        if extractedRows.isEmpty {
            throw ImportError.badFormat // If OCR found nothing, consider it a bad format for import
        }
        return extractedRows
    }

    // MARK: - Data Mapping
    private func buildHeaderMap(from headers: [String]) -> [String: Int] {
        var headerMap: [String: Int] = [:]
        for (index, header) in headers.enumerated() {
            // Normalize header names for robust matching
            let normalizedHeader = header.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            headerMap[normalizedHeader] = index
        }
        return headerMap
    }

    @preconcurrency
    private func buildFacture(from rows: ArraySlice<[String]>, headerMap: [String: Int], dataService: DataService) async throws {
        // Fonction utilitaire pour accéder de façon sécurisée à une valeur de ligne
        func valueAt(_ map: [String: Int], _ key: String, _ row: [String]) -> String {
            let idx = map[key] ?? -1
            return (idx >= 0 && idx < row.count) ? row[idx] : ""
        }

        guard let firstDataRow = rows.first else {
            throw ImportError.mappingFailed
        }

        // --- Client Mapping ---
        let clientName = valueAt(headerMap, "nom", firstDataRow)
        let clientEmail = valueAt(headerMap, "email", firstDataRow)

        let existingClientDTOs = await dataService.fetchClients()
        let foundClientDTO = existingClientDTOs.first { c in
            (c.email == clientEmail && !clientEmail.isEmpty) ||
            (c.nom == clientName && !clientName.isEmpty)
        }

        var clientId: UUID
        if let existing = foundClientDTO {
            clientId = existing.id
        } else {
            let newClientDTO = ClientDTO(
                id: UUID(),
                nom: clientName,
                entreprise: "",
                email: clientEmail,
                telephone: valueAt(headerMap, "téléphone", firstDataRow),
                siret: valueAt(headerMap, "siret", firstDataRow),
                numeroTVA: valueAt(headerMap, "n° tva", firstDataRow),
                adresse: valueAt(headerMap, "adresse", firstDataRow),
                adresseRue: "",
                adresseCodePostal: "",
                adresseVille: "",
                adressePays: ""
            )

            // Validate SIRET and TVA before adding
            if !newClientDTO.siret.isEmpty && !Validator.isValidSIRET(newClientDTO.siret) {
                throw ImportError.invalidData(message: "SIRET invalide pour le client \(newClientDTO.nom).")
            }
            if !newClientDTO.numeroTVA.isEmpty && !Validator.isValidTVA(newClientDTO.numeroTVA) {
                throw ImportError.invalidData(message: "Numéro TVA invalide pour le client \(newClientDTO.nom).")
            }

            await dataService.addClientDTO(newClientDTO)
            clientId = newClientDTO.id
        }

        // --- LigneFacture Mapping ---
        var ligneIds: [UUID] = []
        for (rowIndex, row) in rows.enumerated() {
            if rowIndex == 0 && headerMap.values.contains(0) { continue }

            let designation = valueAt(headerMap, "désignation", row)
            let quantite = Double(valueAt(headerMap, "quantité", row)) ?? 0.0
            let prixUnitaire = Double(valueAt(headerMap, "prix unitaire", row)) ?? 0.0
            let referenceCommande = valueAt(headerMap, "réf. commande", row)

            var dateCommande: Date? = nil
            let dateCommandeString = valueAt(headerMap, "date commande", row)
            if !dateCommandeString.isEmpty, let date = DateFormatter.yyyyMMdd.date(from: dateCommandeString) {
                dateCommande = date
            }

            let ligneDTO = LigneFactureDTO(
                id: UUID(),
                designation: designation,
                quantite: quantite,
                prixUnitaire: prixUnitaire,
                referenceCommande: referenceCommande,
                dateCommande: dateCommande,
                produitId: nil,
                factureId: nil
            )
            await dataService.addLigneDTO(ligneDTO)
            ligneIds.append(ligneDTO.id)
        }

        // Get the client model for numbering
        guard let client = await dataService.fetchClientModel(id: clientId) else {
            throw ImportError.clientNotFound
        }
        let numero = await dataService.genererNumeroFacture(client: client)
        let factureDTO = FactureDTO(
            id: UUID(),
            numero: numero,
            dateFacture: Date(),
            dateEcheance: nil,
            datePaiement: nil,
            tva: 20.0,
            conditionsPaiement: ConditionsPaiement.virement.rawValue,
            remisePourcentage: 0.0,
            statut: StatutFacture.brouillon.rawValue,
            notes: "",
            notesCommentaireFacture: nil,
            clientId: clientId,
            ligneIds: ligneIds
        )

        await dataService.addFactureDTO(factureDTO)
    }
}

// MARK: - Helper Extensions
extension DateFormatter {
    static let yyyyMMdd: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "en_US_POSIX") // Use POSIX locale for consistent parsing
        return formatter
    }()
}

// Placeholder for UIGraphicsImageRenderer on macOS (Vision framework requires CGImage)
#if os(macOS)
import AppKit

class UIGraphicsImageRenderer {
    let bounds: CGRect

    init(bounds: CGRect) {
        self.bounds = bounds
    }

    func image(actions: (CGContext) -> Void) -> NSImage {
        let image = NSImage(size: bounds.size)
        image.lockFocus()
        let context = NSGraphicsContext.current?.cgContext
        if let context = context {
            actions(context)
        }
        image.unlockFocus()
        return image
    }
}

extension NSImage {
    var cgImage: CGImage? {
        var imageRect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        return cgImage(forProposedRect: &imageRect, context: nil, hints: nil)
    }
}
#endif
