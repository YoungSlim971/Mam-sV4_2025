import SwiftUI

// MARK: - Constants
enum PDFConstants {
    static let pageWidth: CGFloat = 595          // A4 @72 dpi
    static let pageHeight: CGFloat = 842         // A4 @72 dpi
    static let horizontalMargin: CGFloat = 45
    static let topMargin: CGFloat = 40
    static let bottomMargin: CGFloat = 40
    
    // Hauteurs dynamiques pour la pagination
    static let lineItemBaseHeight: CGFloat = 35
    static let lineItemWithRefHeight: CGFloat = 50
    static let lineItemWithDateHeight: CGFloat = 50
    static let lineItemFullHeight: CGFloat = 65
}

// MARK: - Page Layout Calculator
struct PageLayoutCalculator {
    let facture: FactureDTO
    let entreprise: EntrepriseDTO?
    let client: ClientDTO?
    let lines: [LigneFactureDTO]
    
    func calculateLineHeight(for ligne: LigneFactureDTO) -> CGFloat {
        var height = PDFConstants.lineItemBaseHeight
        
        if let ref = ligne.referenceCommande, !ref.isEmpty {
            height += 15
        }
        
        if ligne.dateCommande != nil {
            height += 15
        }
        
        let designationLength = ligne.designation.count
        if designationLength > 50 {
            height += CGFloat((designationLength / 50) * 15)
        }
        
        return height
    }
    
    func calculateHeaderHeight() -> CGFloat {
        var height: CGFloat = 180
        
        if let entreprise = entreprise {
            if !entreprise.certificationTexte.isEmpty {
                height += 20
            }
            if entreprise.nomDirigeant != nil {
                height += 15
            }
        }
        
        return height
    }
    
    func calculateFooterHeight() -> CGFloat {
        let noteLines = facture.notes
            .split(separator: "\n")
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .count
        
        let commentLines = (facture.notesCommentaireFacture ?? "")
            .split(separator: "\n")
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .count
        
        let totalLines = noteLines + commentLines
        return 60.0 + CGFloat(totalLines * 12)
    }
    
    func generatePages() -> [InvoicePageContent] {
        var pages: [InvoicePageContent] = []
        
        let headerHeight = calculateHeaderHeight()
        let clientHeight: CGFloat = 120
        let tableHeaderHeight: CGFloat = 30
        let totalsHeight: CGFloat = 120
        let footerHeight = calculateFooterHeight()
        
        let firstPageFixedHeight = headerHeight + clientHeight + tableHeaderHeight + totalsHeight + footerHeight
        let firstPageAvailableHeight = PDFConstants.pageHeight - PDFConstants.topMargin - PDFConstants.bottomMargin - firstPageFixedHeight
        
        let subsequentPageFixedHeight = tableHeaderHeight + totalsHeight + footerHeight
        let subsequentPageAvailableHeight = PDFConstants.pageHeight - PDFConstants.topMargin - PDFConstants.bottomMargin - subsequentPageFixedHeight
        
        var currentLineIndex = 0
        var currentPageHeight: CGFloat = 0
        var linesForCurrentPage: [LigneFactureDTO] = []

        let sortedLines = lines.sorted { lhs, rhs in
            guard let dateLhs = lhs.dateCommande, let dateRhs = rhs.dateCommande else {
                return lhs.dateCommande != nil
            }
            return dateLhs < dateRhs
        }
        
        while currentLineIndex < sortedLines.count {
            let isFirstPage = pages.isEmpty
            let availableHeight = isFirstPage ? firstPageAvailableHeight : subsequentPageAvailableHeight
            
            let ligne = sortedLines[currentLineIndex]
            let lineHeight = calculateLineHeight(for: ligne)
            
            if currentPageHeight + lineHeight <= availableHeight {
                linesForCurrentPage.append(ligne)
                currentPageHeight += lineHeight
                currentLineIndex += 1
            } else {
                if !linesForCurrentPage.isEmpty {
                    let pageContent = InvoicePageContent(
                        facture: facture,
                        entreprise: entreprise,
                        client: client,
                        lines: linesForCurrentPage,
                        isFirstPage: isFirstPage,
                        isLastPage: false
                    )
                    pages.append(pageContent)
                }
                
                linesForCurrentPage = [ligne]
                currentPageHeight = lineHeight
                currentLineIndex += 1
            }
        }
        
        if !linesForCurrentPage.isEmpty || pages.isEmpty {
            let isLastPage = true
            let isFirstPage = pages.isEmpty
            
            let pageContent = InvoicePageContent(
                facture: facture,
                entreprise: entreprise,
                client: client,
                lines: linesForCurrentPage,
                isFirstPage: isFirstPage,
                isLastPage: isLastPage
            )
            pages.append(pageContent)
        }
        
        if let lastPage = pages.last {
            pages[pages.count - 1] = InvoicePageContent(
                facture: lastPage.facture,
                entreprise: lastPage.entreprise,
                client: lastPage.client,
                lines: lastPage.lines,
                isFirstPage: lastPage.isFirstPage,
                isLastPage: true
            )
        }
        
        return pages
    }
}
