import SwiftUI
import PDFKit
// MARK: - FacturePDFView avec mise en page améliorée
struct FacturePDFView: View {
    let pageContent: InvoicePageContent
    @State private var pageNumber: Int = 1
    @State private var totalPages: Int = 1
    
    init(pageContent: InvoicePageContent, pageNumber: Int = 1, totalPages: Int = 1) {
        self.pageContent = pageContent
        self._pageNumber = State(initialValue: pageNumber)
        self._totalPages = State(initialValue: totalPages)
    }
    
    // MARK: - Date Formatter
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if pageContent.isFirstPage {
                headerSection
                    .padding(.bottom, 30)
                
                clientSection
                    .padding(.bottom, 30)
            }
            
            if !pageContent.lines.isEmpty {
                tableSection
            }
            
            Spacer(minLength: 0)
            
            if pageContent.isLastPage {
                totalsSection
                    .padding(.top, 20)
            }
            
            // Numéro de page
            pageNumberView
                .padding(.top, 15)
        }
        .padding(.horizontal, PDFConstants.horizontalMargin)
        .padding(.top, PDFConstants.topMargin)
        .padding(.bottom, PDFConstants.bottomMargin)
        .frame(width: PDFConstants.pageWidth, height: PDFConstants.pageHeight, alignment: .topLeading)
        .background(Color.white)
    }
    
    // MARK: - Header Section - Mise en page améliorée
    private var headerSection: some View {
        VStack(spacing: 0) {
            headerDecorativeLine
            
            HStack(alignment: .top, spacing: 25) {
                companySection
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                invoiceInfoSection
                    .frame(width: 250)
            }
        }
    }
    
    // MARK: - Header Sub-components
    private var headerDecorativeLine: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [.blue, .blue.opacity(0.7)]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: 4)
            .padding(.bottom, 20)
    }
    
    private var companySection: some View {
        VStack(alignment: .leading, spacing: 0) {
            companyLogoAndName
            
            Spacer().frame(height: 15)
            
            companyDetails
        }
    }
    
    private var companyLogoAndName: some View {
        HStack(alignment: .top, spacing: 15) {
            if let logoData = pageContent.entreprise?.logo,
               let nsImage = NSImage(data: logoData) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(pageContent.entreprise?.nom ?? "ENTREPRISE")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                if let certif = pageContent.entreprise?.certificationTexte, !certif.isEmpty {
                    Text(certif)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(Capsule())
                }
            }
        }
    }
    
    private var companyDetails: some View {
        Group {
            if let entreprise = pageContent.entreprise {
                VStack(alignment: .leading, spacing: 4) {
                    InfoRow(label: "", value: entreprise.adresseRue, isBold: false)
                    InfoRow(label: "", value: "\(entreprise.adresseCodePostal) \(entreprise.adresseVille)", isBold: false)
                    InfoRow(label: "", value: entreprise.adressePays, isBold: false)
                    
                    Spacer().frame(height: 8)
                    
                    InfoRow(label: "SIRET", value: entreprise.siret, isBold: true)
                    InfoRow(label: "Tél", value: entreprise.telephone, isBold: false)
                    InfoRow(label: "Email", value: entreprise.email, isBold: false)
                }
            }
        }
    }
    
    private var invoiceInfoSection: some View {
        VStack(alignment: .trailing, spacing: 0) {
            invoiceTitle
                .padding(.bottom, 25)
            
            invoiceDetails
        }
    }
    
    private var invoiceTitle: some View {
        VStack(alignment: .trailing, spacing: 8) {
            Text("FACTURE")
                .font(.largeTitle)
                .fontWeight(.black)
                .foregroundColor(.blue)
            
            Rectangle()
                .fill(Color.blue)
                .frame(width: 150, height: 3)
            
            Text("N° \(pageContent.facture.numero)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
        }
    }
    
    private var invoiceDetails: some View {
        VStack(alignment: .trailing, spacing: 6) {
            InfoRow(label: "Date d'émission", value: pageContent.facture.dateFacture, formatter: dateFormatter, alignment: .trailing)
            
            if let dateEcheance = pageContent.facture.dateEcheance {
                InfoRow(
                    label: "Date d'échéance",
                    value: dateEcheance,
                    formatter: dateFormatter,
                    alignment: .trailing,
                    valueColor: dateEcheance < Date() ? .red : .primary
                )
            }
            
            InfoRow(label: "Mode de paiement", value: pageContent.facture.conditionsPaiement, alignment: .trailing)
            
            if pageContent.facture.remisePourcentage > 0 {
                InfoRow(
                    label: "Remise",
                    value: "\(String(format: "%.0f", pageContent.facture.remisePourcentage))%",
                    alignment: .trailing,
                    valueColor: .green
                )
            }
        }
        .padding(15)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.gray.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
        )
    }
    // MARK: - Client Section - Mise en page améliorée
    var clientSection: some View {
        HStack {
            Spacer()
            
            VStack(alignment: .leading, spacing: 0) {
                // En-tête
                HStack {
                    Rectangle()
                        .fill(Color.blue)
                        .frame(width: 5, height: 30)
                    
                    Text("FACTURÉ À")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                        .padding(.leading, 10)
                    
                    Spacer()
                }
                .padding(.bottom, 12)
                
                // Informations client
                if let client = pageContent.client {
                    VStack(alignment: .leading, spacing: 4) {
                        // Nom et entreprise
                        Text(client.nom)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        if !client.entreprise.isEmpty {
                            Text(client.entreprise)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer().frame(height: 8)
                        
                        // Adresse
                        VStack(alignment: .leading, spacing: 2) {
                            if !client.adresseRue.isEmpty {
                                Text(client.adresseRue)
                            }
                            if !client.adresseVilleComplete.isEmpty {
                                Text(client.adresseVilleComplete)
                            }
                        }
                        .font(.caption)
                        .foregroundColor(.primary)
                        
                        Spacer().frame(height: 8)
                        
                        // Contact
                        VStack(alignment: .leading, spacing: 2) {
                            if !client.email.isEmpty {
                                Text(client.email)
                                    .foregroundColor(.blue)
                            }
                            if !client.telephone.isEmpty {
                                Text("Tél : \(client.telephone)")
                            }
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                } else {
                    Text("Client non spécifié")
                        .font(.caption)
                        .italic()
                        .foregroundColor(.red)
                }
            }
            .padding(20)
            .frame(width: 320, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.blue.opacity(0.03))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.blue.opacity(0.3), lineWidth: 2)
                    )
            )
        }
    }
    
    // MARK: - Table Section - Mise en page améliorée
    private var tableSection: some View {
        VStack(spacing: 0) {
            // En-tête du tableau avec style
            HStack(spacing: 0) {
                TableHeaderCell(text: "DÉSIGNATION", width: nil, alignment: .leading)
                TableHeaderCell(text: "QTÉ", width: 60, alignment: .center)
                TableHeaderCell(text: "PRIX U.", width: 80, alignment: .trailing)
                TableHeaderCell(text: "TOTAL", width: 90, alignment: .trailing)
            }
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [.blue, .blue.opacity(0.8)]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            
            // Lignes du tableau
            VStack(spacing: 0) {
                ForEach(Array(pageContent.lines.enumerated()), id: \.element.id) { index, ligne in
                    InvoiceLineRowImproved(ligne: ligne, isEven: index % 2 == 0)
                        .overlay(
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 0.5)
                                .offset(y: 17), // Centré sur la ligne
                            alignment: .bottom
                        )
                }
            }
            
            // Note de facture si elle existe
            if let note = pageContent.facture.notesCommentaireFacture,
               !note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
               pageContent.isLastPage {
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "note.text")
                            .foregroundColor(.orange)
                        Text("Note :")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                        Spacer()
                    }
                    
                    Text(note)
                        .font(.caption)
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(12)
                .background(Color.orange.opacity(0.08))
                .overlay(
                    Rectangle()
                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                )
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
    
    // MARK: - Totals Section - Mise en page améliorée
    private var totalsSection: some View {
        let tvaFormat = String(format: "%.1f", pageContent.facture.tva)
        return VStack(spacing: 0) {
            // Ligne de séparation
            Rectangle()
                .fill(Color.blue.opacity(0.3))
                .frame(height: 2)
                .padding(.bottom, 20)
            
            HStack(alignment: .top, spacing: 30) {
                // Notes et conditions (gauche)
                if !pageContent.facture.notes.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.blue)
                            Text("CONDITIONS")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                        }
                        
                        VStack(alignment: .leading, spacing: 3) {
                            ForEach(pageContent.facture.notes.split(separator: "\n").map(String.init), id: \.self) { line in
                                HStack(alignment: .top, spacing: 4) {
                                    Text("•")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                    Text(line)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                // Totaux (droite)
                VStack(alignment: .trailing, spacing: 8) {
                    TotalRow(label: "Sous-total HT", amount: pageContent.facture.calculateSousTotal(with: pageContent.lines), isMain: false)
                    
                    if pageContent.facture.remisePourcentage > 0 {
                        TotalRow(
                            label: "Remise (\(String(format: "%.0f", pageContent.facture.remisePourcentage))%)",
                            amount: -calculateRemiseAmount(),
                            isMain: false,
                            color: .green
                        )
                    }
                    
                    TotalRow(
                        label: "TVA (\(tvaFormat)%) ",
                        amount: pageContent.facture.calculateMontantTVA(with: pageContent.lines),
                        isMain: false
                    )
                    
                    // Ligne de séparation pour le total
                    Rectangle()
                        .fill(Color.blue)
                        .frame(height: 2)
                        .frame(width: 200)
                        .padding(.vertical, 6)
                    
                    TotalRow(
                        label: "TOTAL TTC",
                        amount: pageContent.facture.calculateTotalTTC(with: pageContent.lines),
                        isMain: true,
                        color: .blue
                    )
                    
                    // Statut de paiement
                    paymentStatusView
                        .padding(.top, 10)
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.03))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                        )
                )
                .frame(width: 280)
            }
        }
    }
    
    // MARK: - Payment Status View
    private var paymentStatusView: some View {
        Group {
            if let datePaiement = pageContent.facture.datePaiement {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title3)
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("PAYÉE")
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                        Text("le \(datePaiement, formatter: dateFormatter)")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
                .padding(8)
                .background(Color.green.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            } else {
                Group {
                    if let dateEcheance = pageContent.facture.dateEcheance {
                        let daysRemaining = Calendar.current.dateComponents([.day], from: Date(), to: dateEcheance).day ?? 0
                        let isOverdue = dateEcheance < Date()
                        
                        HStack(spacing: 8) {
                            Image(systemName: isOverdue ? "exclamationmark.triangle.fill" : "calendar")
                                .foregroundColor(isOverdue ? .red : .orange)
                                .font(.title3)
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(isOverdue ? "EN RETARD" : "À RÉGLER")
                                    .fontWeight(.bold)
                                    .foregroundColor(isOverdue ? .red : .orange)
                                Text("le \(dateEcheance, formatter: dateFormatter)")
                                    .font(.caption)
                                    .foregroundColor(isOverdue ? .red : .orange)
                                if !isOverdue && daysRemaining >= 0 {
                                    Text("(\(daysRemaining) jours)")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(8)
                        .background((isOverdue ? Color.red : Color.orange).opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    } else {
                        EmptyView()
                    }
                }
            }
        }
    }
    
    // MARK: - Page Number View
    private var pageNumberView: some View {
        HStack {
            Text("Facture \(pageContent.facture.numero)")
                .font(.caption2)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text("Page \(pageNumber) / \(totalPages)")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.top, 5)
    }
    
    // MARK: - Helper Methods
    private func calculateRemiseAmount() -> Double {
        return pageContent.facture.calculateSousTotal(with: pageContent.lines) * (pageContent.facture.remisePourcentage / 100)
    }
    
    // MARK: - Static Generation Method
    static func generatePages(facture: FactureDTO, lignes: [LigneFactureDTO], client: ClientDTO, entreprise: EntrepriseDTO?) -> [FacturePDFView] {
        let calculator = PageLayoutCalculator(facture: facture, entreprise: entreprise, client: client, lines: lignes)
        let pageContents = calculator.generatePages()
        
        return pageContents.enumerated().map { index, content in
            FacturePDFView(pageContent: content, pageNumber: index + 1, totalPages: pageContents.count)
        }
    }
}

// MARK: - Preview Provider
struct FacturePDFView_Previews: PreviewProvider {
    static var previews: some View {
        // Données de test DTO
        let client = ClientDTO(
            id: UUID(),
            nom: "Dupont",
            entreprise: "SARL Dupont & Fils",
            email: "jean.dupont@example.com",
            telephone: "01 23 45 67 89",
            siret: "123 456 789 00012",
            numeroTVA: "FR12345678900",
            adresse: "",
            adresseRue: "123 rue de la République",
            adresseCodePostal: "75001",
            adresseVille: "Paris",
            adressePays: "France"
        )

        let entreprise = EntrepriseDTO(
            id: UUID(),
            nom: "EXOTROPIC",
            nomContact: nil,
            nomDirigeant: "Marie Martin",
            telephone: "05 90 12 34 56",
            email: "contact@exotropic.fr",
            siret: "987 654 321 00098",
            numeroTVA: "FR98765432100",
            iban: "",
            bic: nil,
            adresseRue: "21 Rue Victor Hugues",
            adresseCodePostal: "97100",
            adresseVille: "BASSE-TERRE",
            adressePays: "Guadeloupe",
            certificationTexte: "ISO 9001:2015",
            logo: nil,
            prefixeFacture: "F",
            prochainNumero: 1,
            tvaTauxDefaut: 20,
            delaiPaiementDefaut: 30
        )

        let facture = FactureDTO(
            id: UUID(),
            numero: "F2025-0102",
            dateFacture: Date(),
            dateEcheance: Calendar.current.date(byAdding: .day, value: 30, to: Date()),
            datePaiement: nil,
            tva: 20,
            conditionsPaiement: "Virement",
            remisePourcentage: 10,
            statut: "Brouillon",
            notes: "Paiement par virement bancaire sous 30 jours\nEscompte 2% pour paiement sous 8 jours\nMerci de mentionner le numéro de facture",
            notesCommentaireFacture: "Développement réalisé selon cahier des charges v2.1\nTests d'acceptation validés le 02/07/2025\nFormation utilisateurs incluse",
            clientId: client.id,
            ligneIds: []
        )

        var lignesDTO: [LigneFactureDTO] = []
        let lignes = [
            ("Développement application mobile iOS", 1.0, 2500.00, "DEV-2025-001", -10),
            ("Intégration API de paiement", 1.0, 1200.00, "API-2025-001", -5),
            ("Formation équipe - 2 jours", 2.0, 800.00, "FORM-2025-001", -2),
            ("Support technique premium - 3 mois", 3.0, 250.00, nil, 0),
            ("Serveur cloud dédié - configuration", 1.0, 450.00, "CLOUD-2025-001", -15)
        ]

        for (_, (designation, quantite, prix, ref, dateDays)) in lignes.enumerated() {
            let ligne = LigneFactureDTO(
                id: UUID(),
                designation: designation,
                quantite: quantite,
                prixUnitaire: prix,
                referenceCommande: ref,
                dateCommande: dateDays != 0 ? Calendar.current.date(byAdding: .day, value: dateDays, to: Date()) : nil,
                produitId: nil,
                factureId: facture.id
            )
            lignesDTO.append(ligne)
        }

        // Générer les pages
        let pages = FacturePDFView.generatePages(facture: facture, lignes: lignesDTO, client: client, entreprise: entreprise)
        
        return Group {
            if let firstPage = pages.first {
                firstPage
                    .previewLayout(.fixed(width: PDFConstants.pageWidth, height: PDFConstants.pageHeight))
                    .previewDisplayName("Facture - Mise en page améliorée")
            }

            if pages.count > 1 {
                pages[1]
                    .previewLayout(.fixed(width: PDFConstants.pageWidth, height: PDFConstants.pageHeight))
                    .previewDisplayName("Page 2 - Mise en page améliorée")
            }
        }
    }
}
