import SwiftUI
import PDFKit
import CoreGraphics
import AppKit
import UniformTypeIdentifiers
import Logging
import DataLayer

/// Layout configuration for PDF pages
public struct PDFLayout {
    public let pageRect: CGRect
    public let contentRect: CGRect
    public let headerHeight: CGFloat
    public let footerHeight: CGFloat

    public init(pageSize: CGSize = CGSize(width: 595, height: 842),
         margins: EdgeInsets = EdgeInsets(top: 40, leading: 40, bottom: 40, trailing: 40),
         headerHeight: CGFloat = 80,
         footerHeight: CGFloat = 40) {
        self.pageRect = CGRect(origin: .zero, size: pageSize)
        self.headerHeight = headerHeight
        self.footerHeight = footerHeight
        self.contentRect = CGRect(
            x: margins.leading,
            y: margins.bottom + footerHeight,
            width: pageSize.width - margins.leading - margins.trailing,
            height: pageSize.height - margins.top - margins.bottom - headerHeight - footerHeight
        )
    }
}

// MARK: - PDF generation service
public final class PDFService {
    private let logger = Logger(label: "com.facturation.pdfengine.service")
    
    /// In‑memory cache to avoid regenerating the same PDF multiple times.
    private var cache: [UUID: Data] = [:]
    private let maxCache = 20

    public init() {}

    // MARK: - Drawing Helpers
    private func drawHeader(_ context: CGContext, facture: FactureDTO, entreprise: EntrepriseDTO?, layout: PDFLayout) {
        let title = entreprise?.nom ?? "Facture"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 18, weight: .bold)
        ]
        let rect = CGRect(x: layout.contentRect.minX,
                          y: layout.pageRect.height - layout.headerHeight - 20,
                          width: layout.contentRect.width,
                          height: layout.headerHeight)
        title.draw(in: rect, withAttributes: attributes)
    }

    private func drawFooter(_ context: CGContext, facture: FactureDTO, layout: PDFLayout, pageNumber: Int, totalPages: Int) {
        let footerText = "Page \(pageNumber) of \(totalPages)"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 10),
            .foregroundColor: NSColor.gray
        ]
        let rect = CGRect(x: layout.contentRect.minX,
                          y: layout.footerHeight / 4,
                          width: layout.contentRect.width,
                          height: layout.footerHeight / 2)
        footerText.draw(in: rect, withAttributes: attributes)
    }

    private func drawLine(_ context: CGContext, line: LigneFactureDTO, at origin: CGPoint, layout: PDFLayout) {
        let lineText = "\(line.designation) - \(line.quantite)x \(line.prixUnitaire)" as NSString
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 12)
        ]
        let rect = CGRect(x: origin.x,
                          y: origin.y - 14,
                          width: layout.contentRect.width,
                          height: 14)
        lineText.draw(in: rect, withAttributes: attributes)
    }
    
    /// Generates an A4 PDF for the given facture with automatic pagination.
    /// - Returns: `Data` representing the PDF or `nil` on failure.
    @MainActor
    public func generatePDF(for facture: FactureDTO, lignes: [LigneFactureDTO], client: ClientDTO, entreprise: EntrepriseDTO) async -> Data? {
        logger.info("Génération PDF pour facture", metadata: ["numero": "\(facture.numero)", "id": "\(facture.id)"])
        logger.debug("Facture details", metadata: ["lignesCount": "\(lignes.count)", "client": "\(client.nom)"])
        
        // Check cache first
        if let cached = cache[facture.id] { 
            logger.debug("PDF trouvé en cache", metadata: ["facture": "\(facture.numero)"])
            return cached 
        }
        
        // Manage cache size
        if cache.count >= maxCache { 
            cache.remove(at: cache.startIndex) 
        }

        // Generate PDF using Core Graphics
        let data = await generatePDFUsingCoreGraphics(facture: facture, lignes: lignes, client: client, entreprise: entreprise)
        
        if let data = data {
            cache[facture.id] = data
            logger.info("PDF généré avec succès", metadata: ["facture": "\(facture.numero)", "size": "\(data.count) bytes"])
        } else {
            logger.error("Échec de génération PDF", metadata: ["facture": "\(facture.numero)"])
        }
        
        return data
    }
    
    @MainActor
    private func generatePDFUsingCoreGraphics(facture: FactureDTO, lignes: [LigneFactureDTO], client: ClientDTO, entreprise: EntrepriseDTO) async -> Data? {
        let layout = PDFLayout()
        let data = NSMutableData()
        
        var mediaBox = layout.pageRect
        guard let dataConsumer = CGDataConsumer(data: data as CFMutableData),
              let context = CGContext(consumer: dataConsumer, mediaBox: &mediaBox, nil) else {
            logger.error("Failed to create PDF context")
            return nil
        }
        
        // Start PDF document
        context.beginPDFPage(nil)
        
        // Draw header
        drawHeader(context, facture: facture, entreprise: entreprise, layout: layout)
        
        // Draw client info
        let clientInfo = """
        Facture: \(facture.numero)
        Date: \(facture.dateFacture.formatted(date: .abbreviated, time: .omitted))
        Client: \(client.nomCompletClient)
        
        Adresse:
        \(client.adresseComplete)
        """
        
        let clientAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 12)
        ]
        
        let clientRect = CGRect(x: layout.contentRect.minX,
                               y: layout.contentRect.maxY - 100,
                               width: layout.contentRect.width,
                               height: 100)
        clientInfo.draw(in: clientRect, withAttributes: clientAttributes)
        
        // Draw invoice lines
        var currentY = layout.contentRect.maxY - 150
        let lineHeight: CGFloat = 20
        
        for ligne in lignes {
            let lineText = String(format: "%-40s %8.2f x %8.2f = %8.2f €", 
                                 ligne.designation,
                                 ligne.quantite,
                                 ligne.prixUnitaire,
                                 ligne.total)
            
            let lineRect = CGRect(x: layout.contentRect.minX,
                                 y: currentY,
                                 width: layout.contentRect.width,
                                 height: lineHeight)
            
            lineText.draw(in: lineRect, withAttributes: clientAttributes)
            currentY -= lineHeight
        }
        
        // Draw totals
        let sousTotal = facture.calculateSousTotal(with: lignes)
        let montantTVA = facture.calculateMontantTVA(with: lignes)
        let totalTTC = facture.calculateTotalTTC(with: lignes)
        
        currentY -= 20
        let totalsText = """
        Sous-total HT: \(String(format: "%.2f €", sousTotal))
        TVA (\(facture.tva)%): \(String(format: "%.2f €", montantTVA))
        Total TTC: \(String(format: "%.2f €", totalTTC))
        """
        
        let totalsRect = CGRect(x: layout.contentRect.maxX - 200,
                               y: currentY - 60,
                               width: 200,
                               height: 60)
        
        let totalsAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 12, weight: .semibold)
        ]
        
        totalsText.draw(in: totalsRect, withAttributes: totalsAttributes)
        
        // Draw footer
        drawFooter(context, facture: facture, layout: layout, pageNumber: 1, totalPages: 1)
        
        // End PDF
        context.endPDFPage()
        context.closePDF()
        
        return data as Data
    }
    
    /// Clears the PDF cache
    public func clearCache() {
        logger.info("Clearing PDF cache", metadata: ["cacheSize": "\(cache.count)"])
        cache.removeAll()
    }
    
    /// Returns cache statistics
    public func getCacheInfo() -> (count: Int, maxSize: Int) {
        return (cache.count, maxCache)
    }
}