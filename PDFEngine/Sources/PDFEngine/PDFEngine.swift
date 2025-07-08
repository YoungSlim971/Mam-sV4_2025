import Foundation
import SwiftUI
import PDFKit
import Logging

// Main types are defined in this module and available via import
import DataLayer

/// Main coordinator for all PDF engine functionality
public final class PDFEngine {
    private let logger = Logger(label: "com.facturation.pdfengine.coordinator")
    
    public let pdfService: PDFService
    public let layoutCalculator: PageLayoutCalculator
    
    public init() {
        self.pdfService = PDFService()
        self.layoutCalculator = PageLayoutCalculator()
        
        logger.info("PDFEngine initialized")
    }
    
    /// Generate a PDF document for export
    public func generatePDFDocument(
        for facture: FactureDTO,
        lignes: [LigneFactureDTO],
        client: ClientDTO,
        entreprise: EntrepriseDTO
    ) async -> GeneratedPDFDocument? {
        logger.info("Generating PDF document", metadata: ["facture": "\(facture.numero)"])
        
        guard let pdfData = await pdfService.generatePDF(
            for: facture,
            lignes: lignes,
            client: client,
            entreprise: entreprise
        ) else {
            logger.error("Failed to generate PDF data", metadata: ["facture": "\(facture.numero)"])
            return nil
        }
        
        return GeneratedPDFDocument(data: pdfData)
    }
    
    /// Clear PDF cache
    public func clearCache() {
        pdfService.clearCache()
    }
    
    /// Get cache information
    public func getCacheInfo() -> (count: Int, maxSize: Int) {
        return pdfService.getCacheInfo()
    }
}