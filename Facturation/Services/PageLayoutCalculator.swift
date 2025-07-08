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
            height += 18 // Augmenté pour plus d'espace
        }
        
        if ligne.dateCommande != nil {
            height += 18 // Augmenté pour plus d'espace
        }
        
        // Calcul plus précis pour les désignations longues
        let designationLength = ligne.designation.count
        let charactersPerLine = 45 // Estimation conservative
        if designationLength > charactersPerLine {
            let extraLines = Int(ceil(Double(designationLength - charactersPerLine) / Double(charactersPerLine)))
            height += CGFloat(extraLines * 18)
        }
        
        // Ajoute une marge minimale optimisée pour éviter que les lignes se chevauchent
        height += 3 // Réduit de 5px à 3px pour plus d'efficacité
        
        return height
    }
    
    func calculateHeaderHeight() -> CGFloat {
        var height: CGFloat = 140  // Réduit de 40px (suppression barre bleue + espacement réduit)
        
        if let entreprise = entreprise {
            if !entreprise.certificationTexte.isEmpty {
                height += 15  // Réduit de 5px
            }
            if entreprise.nomDirigeant != nil {
                height += 10  // Réduit de 5px
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
        // Hauteur optimisée avec marge de sécurité réduite
        return 70.0 + CGFloat(totalLines * 14) + 15.0 // Optimisé pour plus de lignes
    }
    
    func generatePages() -> [InvoicePageContent] {
        var pages: [InvoicePageContent] = []
        
        let headerHeight = calculateHeaderHeight()
        let clientHeight: CGFloat = 100 // Réduit avec les optimisations d'espace
        let tableHeaderHeight: CGFloat = 35 // Réduit pour plus d'espace lignes
        let totalsHeight: CGFloat = 130 // Réduit pour plus d'espace lignes
        let footerHeight = calculateFooterHeight()
        let firstPagePadding: CGFloat = 25 // Marge de sécurité première page
        let subsequentPagePadding: CGFloat = 15 // Marge réduite pages suivantes
        
        let firstPageFixedHeight = headerHeight + clientHeight + tableHeaderHeight + totalsHeight + footerHeight + firstPagePadding
        let firstPageAvailableHeight = max(50, PDFConstants.pageHeight - PDFConstants.topMargin - PDFConstants.bottomMargin - firstPageFixedHeight)
        
        let subsequentPageFixedHeight = tableHeaderHeight + totalsHeight + footerHeight + subsequentPagePadding
        let subsequentPageAvailableHeight = max(50, PDFConstants.pageHeight - PDFConstants.topMargin - PDFConstants.bottomMargin - subsequentPageFixedHeight)
        
        var currentLineIndex = 0
        var currentPageHeight: CGFloat = 0
        var linesForCurrentPage: [LigneFactureDTO] = []

        let sortedLines = lines.sorted { lhs, rhs in
            guard let dateLhs = lhs.dateCommande, let dateRhs = rhs.dateCommande else {
                return lhs.dateCommande != nil
            }
            return dateLhs < dateRhs
        }
        
        // Système de pagination basé sur un nombre fixe de lignes par page
        let maxLinesPerPage = 9 // 9 lignes par page pour les pages multiples
        
        // Déterminer si on aura plusieurs pages
        let willHaveMultiplePages = sortedLines.count > maxLinesPerPage
        
        // Si une seule page, utiliser l'ancien système basé sur la hauteur pour optimiser l'espace
        if !willHaveMultiplePages {
            while currentLineIndex < sortedLines.count {
                let isFirstPage = pages.isEmpty
                let availableHeight = isFirstPage ? firstPageAvailableHeight : subsequentPageAvailableHeight
                
                let ligne = sortedLines[currentLineIndex]
                let lineHeight = calculateLineHeight(for: ligne)
                
                let safetyMargin = 0.9 // Marge de sécurité pour page unique
                let safeAvailableHeight = availableHeight * safetyMargin
                
                if currentPageHeight + lineHeight <= safeAvailableHeight {
                    linesForCurrentPage.append(ligne)
                    currentPageHeight += lineHeight
                    currentLineIndex += 1
                } else {
                    break // Arrêter si ça ne rentre plus
                }
            }
        } else {
            // Pour plusieurs pages, utiliser le système de 9 lignes par page
            while currentLineIndex < sortedLines.count {
                let isFirstPage = pages.isEmpty
                
                // Ajouter la ligne courante
                linesForCurrentPage.append(sortedLines[currentLineIndex])
                currentLineIndex += 1
                
                // Vérifier si on a atteint 9 lignes ou si c'est la fin
                if linesForCurrentPage.count >= maxLinesPerPage || currentLineIndex >= sortedLines.count {
                    let pageContent = InvoicePageContent(
                        facture: facture,
                        entreprise: entreprise,
                        client: client,
                        lines: linesForCurrentPage,
                        isFirstPage: isFirstPage,
                        isLastPage: currentLineIndex >= sortedLines.count
                    )
                    pages.append(pageContent)
                    
                    // Préparer pour la page suivante
                    linesForCurrentPage = []
                }
            }
        }
        
        // Pour les pages uniques, ajouter la page restante si nécessaire
        if !willHaveMultiplePages && !linesForCurrentPage.isEmpty {
            let pageContent = InvoicePageContent(
                facture: facture,
                entreprise: entreprise,
                client: client,
                lines: linesForCurrentPage,
                isFirstPage: true,
                isLastPage: true
            )
            pages.append(pageContent)
        }
        
        // S'assurer qu'on a au moins une page (cas des factures sans lignes)
        if pages.isEmpty {
            let pageContent = InvoicePageContent(
                facture: facture,
                entreprise: entreprise,
                client: client,
                lines: [],
                isFirstPage: true,
                isLastPage: true
            )
            pages.append(pageContent)
        }
        
        return pages
    }
}
