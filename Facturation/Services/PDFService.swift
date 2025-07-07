
import SwiftUI
import PDFKit
import CoreGraphics
import AppKit
import UniformTypeIdentifiers

// MARK: - FileDocument wrapper used by .fileExporter
struct GeneratedPDFDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.pdf] }
    var data: Data
    
    init(data: Data = Data()) {
        self.data = data
    }
    
    init(configuration: ReadConfiguration) throws {
        self.data = configuration.file.regularFileContents ?? Data()
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

// MARK: - Page Content Struct (utilisé par les vues PDF)
struct InvoicePageContent {
    var facture: FactureDTO
    var entreprise: EntrepriseDTO?
    var client: ClientDTO?
    var lines: [LigneFactureDTO]
    var isFirstPage: Bool
    var isLastPage: Bool
}

// MARK: - PDF generation service
final class PDFService {
    
    /// In‑memory cache to avoid regenerating the same PDF multiple times.
    private var cache: [UUID: Data] = [:]
    private let maxCache = 20

    /// Layout configuration for PDF pages
    struct Layout {
        let pageRect: CGRect
        let contentRect: CGRect
        let headerHeight: CGFloat
        let footerHeight: CGFloat

        init(pageSize: CGSize = CGSize(width: 595, height: 842),
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

    // MARK: - Drawing Helpers
    private func drawHeader(_ context: CGContext, facture: FactureDTO, entreprise: EntrepriseDTO?, layout: Layout) {
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

    private func drawFooter(_ context: CGContext, facture: FactureDTO, layout: Layout, pageNumber: Int, totalPages: Int) {
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

    private func drawLine(_ context: CGContext, line: LigneFactureDTO, at origin: CGPoint, layout: Layout) {
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
    
    /// Generates an A4 PDF for the given facture.
    /// - Returns: `Data` representing the PDF or `nil` on failure.
    @MainActor
    func generatePDF(for facture: FactureDTO, lignes: [LigneFactureDTO], client: ClientDTO, entreprise: EntrepriseDTO) async -> Data? {
        if let cached = cache[facture.id] { return cached }
        if cache.count >= maxCache { cache.remove(at: cache.startIndex) }

        let pageSize = CGSize(width: 595, height: 842) // A4

        let pageContent = InvoicePageContent(facture: facture, entreprise: entreprise, client: client, lines: lignes, isFirstPage: true, isLastPage: true)

        let renderer = ImageRenderer(content:
            FacturePDFView(pageContent: pageContent)
                .frame(maxWidth: .infinity)
                .padding()
        )

        renderer.scale = 1.0
        let pdfDocument = PDFDocument()
        guard let image = renderer.nsImage else { return nil }
        let totalHeight = image.size.height
        let pageCount = Int(ceil(totalHeight / pageSize.height))

        for pageIndex in 0..<pageCount {
            let imageRect = CGRect(x: 0, y: CGFloat(pageIndex) * pageSize.height, width: pageSize.width, height: pageSize.height)

            let pdfPage = PDFPage(image: NSImage(size: pageSize, flipped: false) { rect in
                image.draw(at: .zero, from: imageRect, operation: .copy, fraction: 1.0)
                return true
            })

            if let page = pdfPage {
                pdfDocument.insert(page, at: pageIndex)
            }
        }

        if let data = pdfDocument.dataRepresentation() {
            cache[facture.id] = data
            return data
        }
        return nil
    }

    /// Generates a PDF using Core Graphics with automatic page breaks
    @MainActor
    func generateDynamicPDF(for facture: FactureDTO, lignes: [LigneFactureDTO], entreprise: EntrepriseDTO) async -> Data? {
        let layout = Layout()
        let lineHeight: CGFloat = 20

        // Calculate total pages
        let linesPerPage = Int(layout.contentRect.height / lineHeight)
        let totalPages = max(1, Int(ceil(Double(lignes.count) / Double(linesPerPage))))

        let data = NSMutableData()
        var mediaBox = layout.pageRect
        guard let consumer = CGDataConsumer(data: data as CFMutableData),
              let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else {
            return nil
        }

        var yCursor = layout.pageRect.height - layout.headerHeight - 20
        var pageNumber = 1
        context.beginPDFPage(nil)
        drawHeader(context, facture: facture, entreprise: entreprise, layout: layout)

        for line in lignes {
            if yCursor - lineHeight < layout.contentRect.minY {
                drawFooter(context, facture: facture, layout: layout, pageNumber: pageNumber, totalPages: totalPages)
                context.endPDFPage()
                context.beginPDFPage(nil)
                pageNumber += 1
                yCursor = layout.pageRect.height - layout.headerHeight - 20
                drawHeader(context, facture: facture, entreprise: entreprise, layout: layout)
            }
            drawLine(context, line: line, at: CGPoint(x: layout.contentRect.minX, y: yCursor), layout: layout)
            yCursor -= lineHeight
        }

        drawFooter(context, facture: facture, layout: layout, pageNumber: pageNumber, totalPages: totalPages)
        context.endPDFPage()
        context.closePDF()

        cache[facture.id] = data as Data
        return data as Data
    }
}
