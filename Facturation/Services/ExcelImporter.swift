import Foundation
import CoreXLSX

class ExcelImporter {

    enum ImportError: Error, LocalizedError {
        case fileNotFound
        case invalidFileFormat
        case sheetNotFound(name: String)
        case missingHeader(column: String)
        case invalidData(message: String)
        case clientCreationError
        case factureCreationError
        case unknownError(Error)

        var errorDescription: String? {
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

    @preconcurrency
    func importFacture(from url: URL, dataService: DataService) async throws {
        guard Foundation.FileManager.default.fileExists(atPath: url.path) else {
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

            // --- Extraction des données du client (première ligne de données)
            guard let firstDataRow = dataRows.first else {
                throw ImportError.invalidData(message: "Aucune donnée trouvée dans le fichier.")
            }

            let clientDTO = try await extractClient(from: firstDataRow.cells, headers: headerMap, dataService: dataService, sharedStrings: sharedStrings)

            // --- Extraction des données de la facture (première ligne de données)
            var factureDTO = try extractFacture(from: firstDataRow.cells, headers: headerMap, clientId: clientDTO.id, sharedStrings: sharedStrings)

            // --- Extraction des lignes de facture
            for row in dataRows {
                let ligneDTO = try extractLigneFacture(from: row.cells, headers: headerMap, sharedStrings: sharedStrings)
                await dataService.addLigneDTO(ligneDTO)
                factureDTO.ligneIds.append(ligneDTO.id)
            }

            // Sauvegarde de la facture
            await dataService.addFactureDTO(factureDTO)
            // plus de return (effet de bord uniquement)

        } catch let error as ImportError {
            throw error
        } catch {
            throw ImportError.unknownError(error)
        }
    }

    private func getCellValue(_ cells: [Cell], _ headerMap: [String: Int], _ headerName: String, _ sharedStrings: SharedStrings) throws -> String? {
        guard let index = headerMap[headerName] else {
            // Allow missing headers for optional fields, return nil
            return nil
        }
        guard index < cells.count else {
            return nil // Cell might be empty
        }
        return cells[index].stringValue(sharedStrings)
    }

    @preconcurrency
    private func extractClient(from cells: [Cell], headers: [String: Int], dataService: DataService, sharedStrings: SharedStrings) async throws -> ClientDTO {
        guard let nom = try getCellValue(cells, headers, "Nom", sharedStrings) else {
            throw ImportError.missingHeader(column: "Nom (Client)")
        }
        let email = try getCellValue(cells, headers, "Email", sharedStrings)
        let telephone = try getCellValue(cells, headers, "Téléphone", sharedStrings)
        let siret = try getCellValue(cells, headers, "SIRET", sharedStrings)
        let numeroTVA = try getCellValue(cells, headers, "N° TVA", sharedStrings)
        let adresseComplete = try getCellValue(cells, headers, "Adresse", sharedStrings) // Assuming single address field for now

        // Check if client exists
        let clients = await dataService.fetchClients()
        if let existingClient = clients.first(where: { $0.email == email && $0.nom == nom }) {
            return existingClient
        } else {
            var newClientDTO = ClientDTO(
                id: UUID(),
                nom: nom,
                entreprise: "",
                email: email ?? "",
                telephone: telephone ?? "",
                siret: siret ?? "",
                numeroTVA: numeroTVA ?? "",
                adresse: "",
                adresseRue: "",
                adresseCodePostal: "",
                adresseVille: "",
                adressePays: ""
            )

            if let fullAddress = adresseComplete {
                let components = fullAddress.split(separator: "\n").map(String.init)
                if components.count >= 1 { newClientDTO.adresseRue = components[0] }
                if components.count >= 2 {
                    newClientDTO.adresseCodePostal = components[1].prefix(5).trimmingCharacters(in: .whitespacesAndNewlines)
                    newClientDTO.adresseVille = components[1].dropFirst(5).trimmingCharacters(in: .whitespacesAndNewlines)
                }
                if components.count >= 3 { newClientDTO.adressePays = components[2] }
            }

            // Validate SIRET and TVA before adding
            if !newClientDTO.siret.isEmpty && !Validator.isValidSIRET(newClientDTO.siret) {
                throw ImportError.invalidData(message: "SIRET invalide pour le client \(newClientDTO.nom).")
            }
            if !newClientDTO.numeroTVA.isEmpty && !Validator.isValidTVA(newClientDTO.numeroTVA) {
                throw ImportError.invalidData(message: "Numéro TVA invalide pour le client \(newClientDTO.nom).")
            }

            await dataService.addClientDTO(newClientDTO)
            return newClientDTO
        }
    }

    private func extractFacture(from cells: [Cell], headers: [String: Int], clientId: UUID, sharedStrings: SharedStrings) throws -> FactureDTO {
        guard let numeroFacture = try getCellValue(cells, headers, "Facture N°", sharedStrings) ?? getCellValue(cells, headers, "N° FACTURE", sharedStrings) else {
            throw ImportError.missingHeader(column: "Facture N° ou N° FACTURE")
        }
        guard let dateString = try getCellValue(cells, headers, "DATE", sharedStrings),
              let date = DateFormatter.parseExcelDate(dateString) else {
            throw ImportError.invalidData(message: "Date de facture manquante ou invalide.")
        }

        let commentaire = try getCellValue(cells, headers, "Commentaires", sharedStrings)
        let conditionsPaiementString = try getCellValue(cells, headers, "VIREMENT", sharedStrings) ?? ConditionsPaiement.virement.rawValue
        guard let conditionsPaiement = ConditionsPaiement(rawValue: conditionsPaiementString) else {
            throw ImportError.invalidData(message: "Conditions de paiement invalides.")
        }

        let dateVirementString = try getCellValue(cells, headers, "Date de virement", sharedStrings)
        let dateVirement = dateVirementString.flatMap { DateFormatter.parseExcelDate($0) }

        let statutString = try getCellValue(cells, headers, "Statut", sharedStrings)
        let statut = statutString.flatMap { StatutFacture(rawValue: $0) } ?? .brouillon

        var dto = FactureDTO(
            id: UUID(),
            numero: numeroFacture,
            dateFacture: date,
            dateEcheance: nil,
            datePaiement: dateVirement,
            tva: 20.0,
            conditionsPaiement: conditionsPaiement.rawValue,
            remisePourcentage: 0.0,
            statut: statut.rawValue,
            notes: "",
            notesCommentaireFacture: commentaire,
            clientId: clientId,
            ligneIds: []
        )

        if dto.datePaiement != nil {
            dto.statut = StatutFacture.payee.rawValue
        }

        return dto
    }

    private func extractLigneFacture(from cells: [Cell], headers: [String: Int], sharedStrings: SharedStrings) throws -> LigneFactureDTO {
        guard let designation = try getCellValue(cells, headers, "DESCRIPTION", sharedStrings) else {
            throw ImportError.missingHeader(column: "DESCRIPTION (LigneFacture)")
        }
        guard let quantiteString = try getCellValue(cells, headers, "Qté", sharedStrings),
              let quantite = Double(quantiteString) else {
            throw ImportError.invalidData(message: "Quantité manquante ou invalide pour la ligne de facture.")
        }
        guard let prixUnitaireString = try getCellValue(cells, headers, "PRIX UNIT", sharedStrings) ?? getCellValue(cells, headers, "PU", sharedStrings),
              let prixUnitaire = Double(prixUnitaireString) else {
            throw ImportError.invalidData(message: "Prix unitaire manquant ou invalide pour la ligne de facture.")
        }

        let referenceCommande = try getCellValue(cells, headers, "BON CDE N°", sharedStrings)
        let dateCommandeString = try getCellValue(cells, headers, "Date commande", sharedStrings)
        let dateCommande = dateCommandeString.flatMap { DateFormatter.parseExcelDate($0) }

        return LigneFactureDTO(
            id: UUID(),
            designation: designation,
            quantite: quantite,
            prixUnitaire: prixUnitaire,
            referenceCommande: referenceCommande,
            dateCommande: dateCommande,
            produitId: nil,
            factureId: nil
        )
    }
}

extension DateFormatter {
    static let excelDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        formatter.locale = Locale(identifier: "fr_FR") // Use French locale for dd/MM/yyyy
        formatter.timeZone = TimeZone(secondsFromGMT: 0) // Important for consistent parsing
        return formatter
    }()

    static let excelDateFormatterFallback: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()

    static func parseExcelDate(_ dateString: String) -> Date? {
        if let date = excelDateFormatter.date(from: dateString) {
            return date
        }
        return excelDateFormatterFallback.date(from: dateString)
    }
}
