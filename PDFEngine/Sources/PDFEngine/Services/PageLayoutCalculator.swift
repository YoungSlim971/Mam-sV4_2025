import Foundation
import CoreGraphics
import AppKit
import Logging
import DataLayer

/// Calculates optimal page layouts for invoices
public final class PageLayoutCalculator {
    private let logger = Logger(label: "com.facturation.pdfengine.layout")
    
    public struct PageBreakInfo {
        public let pageNumber: Int
        public let linesOnPage: [LigneFactureDTO]
        public let isFirstPage: Bool
        public let isLastPage: Bool
        
        public init(pageNumber: Int, linesOnPage: [LigneFactureDTO], isFirstPage: Bool, isLastPage: Bool) {
            self.pageNumber = pageNumber
            self.linesOnPage = linesOnPage
            self.isFirstPage = isFirstPage
            self.isLastPage = isLastPage
        }
    }
    
    public init() {}
    
    /// Calculate how to split invoice lines across multiple pages
    public func calculatePageBreaks(
        for facture: FactureDTO,
        lignes: [LigneFactureDTO],
        layout: PDFLayout
    ) -> [PageBreakInfo] {
        logger.debug("Calculating page breaks", metadata: ["factureId": "\(facture.id)", "lignesCount": "\(lignes.count)"])
        
        let availableHeight = layout.contentRect.height
        let headerHeight: CGFloat = 100 // Space for company info and client details
        let footerHeight: CGFloat = 80  // Space for totals
        let lineHeight: CGFloat = 20    // Height per invoice line
        
        // Calculate how many lines fit on first page (with header) and subsequent pages
        let firstPageAvailableHeight = availableHeight - headerHeight - footerHeight
        let subsequentPageAvailableHeight = availableHeight - footerHeight
        
        let linesPerFirstPage = max(1, Int(firstPageAvailableHeight / lineHeight))
        let linesPerSubsequentPage = max(1, Int(subsequentPageAvailableHeight / lineHeight))
        
        logger.debug("Page capacity calculated", metadata: [
            "linesPerFirstPage": "\(linesPerFirstPage)",
            "linesPerSubsequentPage": "\(linesPerSubsequentPage)"
        ])
        
        var pages: [PageBreakInfo] = []
        var remainingLines = lignes
        var pageNumber = 1
        
        // First page
        if !remainingLines.isEmpty {
            let firstPageLines = Array(remainingLines.prefix(linesPerFirstPage))
            remainingLines = Array(remainingLines.dropFirst(linesPerFirstPage))
            
            pages.append(PageBreakInfo(
                pageNumber: pageNumber,
                linesOnPage: firstPageLines,
                isFirstPage: true,
                isLastPage: remainingLines.isEmpty
            ))
            pageNumber += 1
        }
        
        // Subsequent pages
        while !remainingLines.isEmpty {
            let pageLines = Array(remainingLines.prefix(linesPerSubsequentPage))
            remainingLines = Array(remainingLines.dropFirst(linesPerSubsequentPage))
            
            pages.append(PageBreakInfo(
                pageNumber: pageNumber,
                linesOnPage: pageLines,
                isFirstPage: false,
                isLastPage: remainingLines.isEmpty
            ))
            pageNumber += 1
        }
        
        // If no lines, create at least one page
        if pages.isEmpty {
            pages.append(PageBreakInfo(
                pageNumber: 1,
                linesOnPage: [],
                isFirstPage: true,
                isLastPage: true
            ))
        }
        
        logger.info("Page breaks calculated", metadata: ["totalPages": "\(pages.count)"])
        return pages
    }
    
    /// Calculate the optimal font size for a given text to fit in a rectangle
    public func calculateOptimalFontSize(
        for text: String,
        in rect: CGRect,
        maximumFontSize: CGFloat = 24,
        minimumFontSize: CGFloat = 8
    ) -> CGFloat {
        var fontSize = maximumFontSize
        
        while fontSize >= minimumFontSize {
            let font = NSFont.systemFont(ofSize: fontSize)
            let attributes: [NSAttributedString.Key: Any] = [.font: font]
            let textSize = text.size(withAttributes: attributes)
            
            if textSize.width <= rect.width && textSize.height <= rect.height {
                return fontSize
            }
            
            fontSize -= 1
        }
        
        return minimumFontSize
    }
    
    /// Calculate the required height for a text block with word wrapping
    public func calculateTextHeight(
        for text: String,
        width: CGFloat,
        fontSize: CGFloat
    ) -> CGFloat {
        let font = NSFont.systemFont(ofSize: fontSize)
        let attributes: [NSAttributedString.Key: Any] = [.font: font]
        
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = text.boundingRect(
            with: constraintRect,
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: attributes,
            context: nil
        )
        
        return ceil(boundingBox.height)
    }
}