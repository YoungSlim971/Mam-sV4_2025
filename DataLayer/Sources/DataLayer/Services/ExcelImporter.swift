import Foundation
import CoreXLSX
import Logging

public class ExcelImporter {
    private let logger = Logger(label: "com.facturation.datalayer.excel-importer")

    public enum ImportError: Error, LocalizedError {
        case fileNotFound
        case invalidFileFormat
        case sheetNotFound(name: String)
        case missingHeader(column: String)
        case invalidData(message: String)
        case clientCreationError
        case factureCreationError
        case unknownError(Error)

        public var errorDescription: String? {
            switch self {
            case .fileNotFound:
                return "Le fichier Excel n'a pas été trouvé."
            case .invalidFileFormat:
                return "Le format du fichier Excel est invalide."
            case .sheetNotFound(let name):
                return "La feuille de calcul '\(name)' n'a pas été trouvée."
            case .missingHeader(let column):
                return "En-tête manquant : '\(column)'."
            case .invalidData(let message):
                return "Données invalides : \(message)"
            case .clientCreationError:
                return "Erreur lors de la création du client."
            case .factureCreationError:
                return "Erreur lors de la création de la facture."
            case .unknownError(let error):
                return "Une erreur inconnue est survenue : \(error.localizedDescription)"
            }
        }
    }
    
    public init() {}

    public func importFactures(from url: URL) async throws -> [FactureDTO] {
        logger.info("Starting Excel import", metadata: ["file": "\(url.lastPathComponent)"])
        
        guard Foundation.FileManager.default.fileExists(atPath: url.path) else {
            logger.error("File not found", metadata: ["path": "\(url.path)"])
            throw ImportError.fileNotFound
        }

        do {
            guard let file = XLSXFile(filepath: url.path(percentEncoded: false)) else {
                throw ImportError.invalidFileFormat
            }
            guard let sharedStrings = try file.parseSharedStrings() else {
                throw ImportError.invalidFileFormat
            }
            let workbooks = try file.parseWorkbooks()
            guard let workbook = workbooks.first else {
                throw ImportError.invalidFileFormat
            }

            guard let sheet = workbook.sheets.items.first else {
                throw ImportError.sheetNotFound(name: "Première feuille")
            }

            let sheetID = sheet.id
            let worksheet = try file.parseWorksheet(at: sheetID)
            guard let data = worksheet.data else {
                throw ImportError.invalidFileFormat
            }

            // Extract rows
            let rows = data.rows

            guard let headerRow = rows.first else {
                throw ImportError.invalidFileFormat
            }

            let headers = headerRow.cells.map { $0.stringValue(sharedStrings) }
            let dataRows = rows.dropFirst()

            // Mapping des en-têtes pour un accès facile
            var headerMap: [String: Int] = [:]
            for (index, header) in headers.enumerated() {
                guard let header = header, !header.isEmpty else { continue }
                headerMap[header] = index
            }

            var importedFactures: [FactureDTO] = []

            for row in dataRows {
                let cells = row.cells
                
                // Skip empty rows
                if cells.allSatisfy({ $0.stringValue(sharedStrings)?.isEmpty ?? true }) {
                    continue
                }
                
                do {
                    let facture = try parseFactureFromRow(cells: cells, headerMap: headerMap, sharedStrings: sharedStrings)
                    importedFactures.append(facture)
                } catch {
                    logger.warning("Failed to parse row", metadata: ["error": "\(error)"])
                    // Continue with next row instead of failing the entire import
                }
            }

            logger.info("Excel import completed", metadata: ["importedCount": "\(importedFactures.count)"])
            return importedFactures

        } catch {
            logger.error("Excel import failed", metadata: ["error": "\(error)"])
            throw ImportError.unknownError(error)
        }
    }
    
    public func importClients(from url: URL) async throws -> [ClientDTO] {
        logger.info("Starting client Excel import", metadata: ["file": "\(url.lastPathComponent)"])
        
        // Similar implementation for client import
        // TODO: Implement client-specific parsing logic
        
        return []
    }
    
    public func importProduits(from url: URL) async throws -> [ProduitDTO] {
        logger.info("Starting produit Excel import", metadata: ["file": "\(url.lastPathComponent)"])
        
        // Similar implementation for produit import
        // TODO: Implement produit-specific parsing logic
        
        return []
    }

    private func parseFactureFromRow(cells: [Cell], headerMap: [String: Int], sharedStrings: SharedStrings) throws -> FactureDTO {
        // Helper function to safely get cell value
        func getCellValue(for header: String) -> String? {
            guard let index = headerMap[header], index < cells.count else { return nil }
            return cells[index].stringValue(sharedStrings)
        }
        
        // Extract required fields
        guard let numeroStr = getCellValue(for: "Numero") ?? getCellValue(for: "Numéro"),
              !numeroStr.isEmpty else {
            throw ImportError.invalidData(message: "Numéro de facture manquant")
        }
        
        // Parse other fields with defaults
        let dateFactureStr = getCellValue(for: "Date") ?? getCellValue(for: "Date Facture") ?? ""
        let clientNom = getCellValue(for: "Client") ?? ""
        let montantStr = getCellValue(for: "Montant") ?? getCellValue(for: "Total") ?? "0"
        let statutStr = getCellValue(for: "Statut") ?? getCellValue(for: "Status") ?? "brouillon"
        
        // Convert string values to appropriate types
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy"
        let dateFacture = dateFormatter.date(from: dateFactureStr) ?? Date()
        
        let montant = Double(montantStr.replacingOccurrences(of: ",", with: ".")) ?? 0.0
        
        // Create FactureDTO
        return FactureDTO(
            id: UUID(),
            numero: numeroStr,
            dateFacture: dateFacture,
            dateEcheance: Calendar.current.date(byAdding: .day, value: 30, to: dateFacture),
            datePaiement: nil,
            tva: 20.0, // Default VAT rate
            conditionsPaiement: "Virement",
            remisePourcentage: 0.0,
            statut: statutStr,
            notes: "",
            notesCommentaireFacture: nil,
            clientId: UUID(), // Would need to be matched with existing client or create new one
            ligneIds: []
        )
    }
}