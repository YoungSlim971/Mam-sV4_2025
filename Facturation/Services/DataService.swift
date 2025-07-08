// Services/DataService.swift
@preconcurrency import Foundation
@preconcurrency import SwiftData
import SwiftUI
import Utilities
import DataLayer


@MainActor
class DataService: ObservableObject {
    static let shared = DataService()

    @Published var modelContainer: ModelContainer
    @Published var modelContext: ModelContext

    @Published var clients: [ClientDTO] = []
    @Published var factures: [FactureDTO] = []
    @Published var produits: [ProduitDTO] = []
    @Published var lignes: [LigneFactureDTO] = []
    @Published var entreprise: EntrepriseDTO?

    init() {
        do {
            let schema = Schema([ClientModel.self, EntrepriseModel.self, FactureModel.self, ProduitModel.self, LigneFacture.self])
            
            // Configuration explicite pour la persistance sur disque
            let configuration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false // Forcer la persistance sur disque
            )
            
            let container = try ModelContainer(for: schema, configurations: configuration)
            self.modelContainer = container
            self.modelContext = container.mainContext
            
            print("✅ Persistance SwiftData initialisée avec succès sur disque")
            
        } catch {
            print("❌ Erreur lors de l'initialisation de la persistance principale: \(error)")
            
            // Tentative avec configuration par défaut
            do {
                let schema = Schema([ClientModel.self, EntrepriseModel.self, FactureModel.self, ProduitModel.self, LigneFacture.self])
                let container = try ModelContainer(for: schema)
                self.modelContainer = container
                self.modelContext = container.mainContext
                print("⚠️ Utilisation de la configuration par défaut SwiftData")
                
            } catch {
                // Dernier recours: stockage en mémoire seulement
                do {
                    let schema = Schema([ClientModel.self, EntrepriseModel.self, FactureModel.self, ProduitModel.self, LigneFacture.self])
                    let container = try ModelContainer(for: schema, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
                    self.modelContainer = container
                    self.modelContext = container.mainContext
                    print("🔴 ATTENTION: Utilisation du stockage en mémoire uniquement. Les données ne seront PAS persistées!")
                } catch {
                    fatalError("Impossible d'initialiser SwiftData: \(error)")
                }
            }
        }
    }

    func resetContainer() {
        do {
            let schema = Schema([ClientModel.self, EntrepriseModel.self, FactureModel.self, ProduitModel.self, LigneFacture.self])
            let newContainer = try ModelContainer(for: schema)
            DispatchQueue.main.async {
                self.modelContainer = newContainer
                self.modelContext = newContainer.mainContext
            }
        } catch {
            print("Failed to reset ModelContainer: \(error)")
        }
    }

    var container: ModelContainer {
        return modelContainer
    }
    
    /// Vérifie si la persistance sur disque est active ou si on utilise le stockage en mémoire
    var isPersistenceActive: Bool {
        // Vérifier si le container utilise un stockage persistant
        return !modelContainer.configurations.contains { config in
            config.isStoredInMemoryOnly
        }
    }
    
    /// Retourne le statut de persistance pour information
    func getPersistenceStatus() -> String {
        if isPersistenceActive {
            return "✅ Persistance sur disque active - Données sauvegardées"
        } else {
            return "🔴 Stockage en mémoire seulement - Données perdues à la fermeture"
        }
    }


    // MARK: - Data Fetching
    func fetchData() async {
        async let clientsTask = fetchClientDTOs()
        async let facturesTask = fetchFactureDTOs()
        async let produitsTask = fetchProduitDTOs()
        async let lignesTask = fetchLigneDTOs()
        async let entrepriseTask = fetchEntrepriseDTO()

        self.clients = await clientsTask
        self.factures = await facturesTask
        self.produits = await produitsTask
        self.lignes = await lignesTask
        self.entreprise = await entrepriseTask
    }
    
    private func fetchClientModels() async -> [ClientModel] {
        do {
            let descriptor = FetchDescriptor<ClientModel>(sortBy: [SortDescriptor(\ClientModel.nom)])
            return try modelContext.fetch(descriptor)
        } catch {
            print("Erreur lors de la récupération des clients: \(error)")
            return []
        }
    }
    
    private func fetchFactureModels() async -> [FactureModel] {
        do {
            let descriptor = FetchDescriptor<FactureModel>(sortBy: [SortDescriptor(\FactureModel.dateFacture, order: .reverse)])
            return try modelContext.fetch(descriptor)
        } catch {
            print("Erreur lors de la récupération des factures: \(error)")
            return []
        }
    }
    
    private func fetchProduitModels() async -> [ProduitModel] {
        do {
            let descriptor = FetchDescriptor<ProduitModel>(sortBy: [SortDescriptor(\ProduitModel.designation)])
            return try modelContext.fetch(descriptor)
        } catch {
            print("Erreur lors de la récupération des produits: \(error)")
            return []
        }
    }
    
    private func fetchLigneModels() async -> [LigneFacture] {
        do {
            let descriptor = FetchDescriptor<LigneFacture>()
            return try modelContext.fetch(descriptor)
        } catch {
            print("Erreur lors de la récupération des lignes: \(error)")
            return []
        }
    }
    
    private func fetchEntreprise() async -> EntrepriseModel? {
        do {
            let descriptor = FetchDescriptor<EntrepriseModel>()
            return try modelContext.fetch(descriptor).first
        } catch {
            print("Erreur lors de la récupération de l'entreprise: \(error)")
            return nil
        }
    }

    // MARK: - Initialisation
    private func initializeDefaultEntreprise() async {
        let entreprises = await fetchEntreprises()
        if entreprises.isEmpty {
            let entreprise = EntrepriseModel()
            modelContext.insert(entreprise)
            await saveContext()
        }
    }

    // MARK: - Sauvegarde
    func saveContext() async {
        do {
            try modelContext.save()
            print("💾 Données sauvegardées avec succès (\(isPersistenceActive ? "disque" : "mémoire"))")
        } catch {
            print("❌ Erreur lors de la sauvegarde: \(error)")
        }
    }

    // MARK: - CRUD Entreprise DTO
    func fetchEntreprises() async -> [EntrepriseModel] {
        do {
            let descriptor = FetchDescriptor<EntrepriseModel>()
            return try modelContext.fetch(descriptor)
        } catch {
            print("Erreur lors de la récupération des entreprises: \(error)")
            return []
        }
    }

    func updateEntrepriseDTO(_ dto: EntrepriseDTO) async {
        // Validate SIRET, TVA, and IBAN before updating
        guard Validator.isValidSIRET(dto.siret) else {
            print("Erreur: SIRET invalide pour l'entreprise \(dto.nom)")
            return
        }
        guard Validator.isValidTVA(dto.numeroTVA) else {
            print("Erreur: Numéro TVA invalide pour l'entreprise \(dto.nom)")
            return
        }
        guard Validator.isValidIBAN(dto.iban) else {
            print("Erreur: IBAN invalide pour l'entreprise \(dto.nom)")
            return
        }

        do {
            let descriptor = FetchDescriptor<EntrepriseModel>(predicate: #Predicate { $0.id == dto.id })
            if let entreprise = try modelContext.fetch(descriptor).first {
                entreprise.updateFromDTO(dto)
                await saveContext()
                await fetchData()
            }
        } catch {
            print("Erreur lors de la mise à jour de l'entreprise: \(error)")
        }
    }

    // MARK: - CRUD Clients (Version simplifiée)
    @preconcurrency
    func fetchClients() async -> [ClientDTO] {
        do {
            let descriptor = FetchDescriptor<ClientModel>(sortBy: [SortDescriptor(\ClientModel.nom)])
            let clients = try modelContext.fetch(descriptor)
            return clients.map { $0.toDTO() }
        } catch {
            print("Erreur lors de la récupération des clients: \(error)")
            return []
        }
    }



    // DEPRECATED: Use deleteClientDTO instead
    /*func deleteClient(_ client: Client) async {
        // Supprimer d'abord toutes les factures liées
        let facturesClient = getFacturesForClient(client)
        for factureDTO in facturesClient {
            // On fetch la vraie Facture (PersistentModel) via l’id du DTO
            if let realFacture = try? modelContext.fetch(
                FetchDescriptor<FactureModel>(predicate: #Predicate { $0.id == factureDTO.id })
            ).first {
                modelContext.delete(realFacture)
            }
        }

        // Ensuite supprimer le client
        modelContext.delete(client)
        await saveContext()
        await fetchData()
    }*/

    func searchClients(searchText: String) -> [ClientDTO] {
        // La recherche se fera désormais sur les données publiées
        guard !searchText.isEmpty else { return clients }

        return clients.filter { client in
            client.nom.localizedCaseInsensitiveContains(searchText) ||
            client.entreprise.localizedCaseInsensitiveContains(searchText) ||
            client.email.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    // MARK: - CRUD Clients DTO (Nouvelles méthodes)
    func addClientDTO(_ dto: ClientDTO) async {
        // Validate SIRET and TVA before adding
        guard Validator.isValidSIRET(dto.siret) else {
            print("Erreur: SIRET invalide pour le client \(dto.nom)")
            return
        }
        guard Validator.isValidTVA(dto.numeroTVA) else {
            print("Erreur: Numéro TVA invalide pour le client \(dto.nom)")
            return
        }

        let client = ClientModel.fromDTO(dto)
        modelContext.insert(client)
        await saveContext()
        await fetchData()
    }

    func updateClientDTO(_ dto: ClientDTO) async {
        // Validate SIRET and TVA before updating
        guard Validator.isValidSIRET(dto.siret) else {
            print("Erreur: SIRET invalide pour le client \(dto.nom)")
            return
        }
        guard Validator.isValidTVA(dto.numeroTVA) else {
            print("Erreur: Numéro TVA invalide pour le client \(dto.nom)")
            return
        }

        do {
            let descriptor = FetchDescriptor<ClientModel>(predicate: #Predicate { $0.id == dto.id })
            if let client = try modelContext.fetch(descriptor).first {
                client.updateFromDTO(dto)
                await saveContext()
                await fetchData()
            }
        } catch {
            print("Erreur lors de la mise à jour du client: \(error)")
        }
    }

    func deleteClientDTO(id: UUID) async {
        do {
            // Vérifier d'abord que le client existe et est valide
            let clientDescriptor = FetchDescriptor<ClientModel>(predicate: #Predicate { $0.id == id })
            guard let client = try modelContext.fetch(clientDescriptor).first,
                  client.isValidModel else {
                print("⚠️ Client non trouvé ou invalidé: \(id)")
                return
            }
            
            // Supprimer d'abord toutes les factures liées de manière sécurisée
            let factureDescriptor = FetchDescriptor<FactureModel>(predicate: #Predicate { $0.client?.id == id })
            let facturesClient = try modelContext.fetch(factureDescriptor)
            
            for facture in facturesClient where facture.isValidModel {
                // Supprimer les lignes de facture en premier
                let lignes = facture.lignes.filter { $0.isValidModel }
                for ligne in lignes {
                    modelContext.delete(ligne)
                }
                
                modelContext.delete(facture)
            }

            // Enfin supprimer le client
            modelContext.delete(client)
            
            await saveContext()
            await fetchData()
        } catch {
            print("Erreur lors de la suppression du client: \(error)")
        }
    }

    // MARK: - CRUD Factures (Version simplifiée)
    func fetchFactures() async -> [FactureModel] {
        do {
            let descriptor = FetchDescriptor<FactureModel>(sortBy: [SortDescriptor(\FactureModel.dateFacture, order: .reverse)])
            return try modelContext.fetch(descriptor)
        } catch {
            print("Erreur lors de la récupération des factures: \(error)")
            return []
        }
    }

    func getFacturesWithDynamicStatus() -> [FactureDTO] {
        let now = Date()
        return factures.map { facture in
            var copy = facture
            if copy.statut == StatutFacture.envoyee.rawValue,
               let dateEcheance = copy.dateEcheance,
               dateEcheance < now {
                copy.statut = StatutFacture.enRetard.rawValue
            }
            return copy
        }
    }

    /*
    func addFacture(_ facture: Facture) async {
        modelContext.insert(facture)
        await saveContext()
        await fetchData()
    }

    func updateFacture(_ facture: Facture) async {
        await saveContext()
        await fetchData()
    }
    
    func checkAndUpdateLateFactures() async {
        let allFactures = await fetchFactures()
        var hasChanges = false
        for facture in allFactures where facture.statut == .envoyee {
            if let dateEcheance = facture.dateEcheance, dateEcheance < Date() {
                facture.statut = .enRetard
                hasChanges = true
            }
        }
        if hasChanges {
            await saveContext()
            await fetchData()
        }
    }

    func deleteFacture(_ facture: Facture) async {
        modelContext.delete(facture)
        await saveContext()
        await fetchData()
    }
    */

    func searchFactures(searchText: String = "", statut: StatutFacture? = nil) -> [FactureDTO] {
        var filteredFactures = getFacturesWithDynamicStatus()

        // Filtrage par texte de recherche
        if !searchText.isEmpty {
            filteredFactures = filteredFactures.filter { facture in
                facture.numero.localizedCaseInsensitiveContains(searchText) ||
                (clients.first(where: { $0.id == facture.clientId })?.nom.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (clients.first(where: { $0.id == facture.clientId })?.entreprise.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }

        // Filtrage par statut
        if let statut = statut {
            filteredFactures = filteredFactures.filter { $0.statut == statut.rawValue }
        }

        return filteredFactures
    }


    // MARK: - Statistiques (Version simplifiée)
    func getStatistiques() -> (totalCA: Double, facturesEnAttente: Int, facturesEnRetard: Int, totalFactures: Int) {
        let currentFactures = getFacturesWithDynamicStatus()

        let totalCA = currentFactures
            .filter { $0.statut == StatutFacture.payee.rawValue }
            .reduce(0.0) { $0 + $1.calculateTotalTTC(with: lignes) }

        let facturesEnAttente = currentFactures
            .filter { $0.statut == StatutFacture.envoyee.rawValue }
            .count

        let facturesEnRetard = currentFactures
            .filter { $0.statut == StatutFacture.enRetard.rawValue }
            .count

        let totalFactures = currentFactures.count

        return (totalCA, facturesEnAttente, facturesEnRetard, totalFactures)
    }

    func getMonthlyRevenueData() -> [(month: String, total: Double)] {
        let calendar = Calendar.current
        let now = Date()
        var monthlyData: [String: Double] = [:]

        // Initialize for last 12 months
        for i in 0..<12 {
            if let date = calendar.date(byAdding: .month, value: -i, to: now) {
                let monthKey = date.formatted(.dateTime.month(.abbreviated).year())
                monthlyData[monthKey] = 0.0
            }
        }

        let paidFactures = getFacturesWithDynamicStatus().filter { $0.statut == StatutFacture.payee.rawValue }

        for facture in paidFactures {
            let monthKey = facture.dateFacture.formatted(.dateTime.month(.abbreviated).year())
            monthlyData[monthKey, default: 0.0] += facture.calculateTotalTTC(with: lignes)
        }

        // Sort data by month
        let sortedData = monthlyData.sorted { (entry1, entry2) -> Bool in
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMM yyyy" // Adjust format to match monthKey
            if let date1 = dateFormatter.date(from: entry1.key),
               let date2 = dateFormatter.date(from: entry2.key) {
                return date1 < date2
            }
            return false
        }

        return sortedData.map { (month: $0.key, total: $0.value) }
    }

    func getInvoiceStatusCounts() -> [(status: StatutFacture, count: Int)] {
        let currentFactures = getFacturesWithDynamicStatus()
        var statusCounts: [StatutFacture: Int] = [:]

        for statusCase in StatutFacture.allCases {
            statusCounts[statusCase] = 0
        }

        for facture in currentFactures {
            if let status = StatutFacture(rawValue: facture.statut) {
                statusCounts[status, default: 0] += 1
            }
        }

        return statusCounts.map { (status: $0.key, count: $0.value) }.sorted { $0.status.rawValue < $1.status.rawValue }
    }

    // MARK: - CRUD Produits
    func fetchProduits() async -> [ProduitDTO] {
        let models = await fetchProduitModels()
        return models.map { $0.toDTO() }
    }

    func addProduitDTO(_ dto: ProduitDTO) async {
        do {
            // Validation des données
            guard !dto.designation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                print("Erreur: Désignation vide")
                return
            }
            guard dto.prixUnitaire > 0 else {
                print("Erreur: Prix unitaire invalide")
                return
            }
            
            let produit = ProduitModel.fromDTO(dto)
            modelContext.insert(produit)
            try modelContext.save()
            await fetchData()
        } catch {
            print("Erreur lors de l'ajout du produit: \(error)")
        }
    }

    func updateProduitDTO(_ dto: ProduitDTO) async {
        do {
            let descriptor = FetchDescriptor<ProduitModel>(predicate: #Predicate { $0.id == dto.id })
            if let produit = try modelContext.fetch(descriptor).first {
                produit.updateFromDTO(dto)
                await saveContext()
                await fetchData()
            }
        } catch {
            print("Erreur lors de la mise à jour du produit: \(error)")
        }
    }

    func deleteProduitDTO(id: UUID) async {
        do {
            let descriptor = FetchDescriptor<ProduitModel>(predicate: #Predicate { $0.id == id })
            guard let produit = try modelContext.fetch(descriptor).first,
                  produit.isValidModel else {
                print("⚠️ Produit non trouvé ou invalidé: \(id)")
                return
            }
            
            // Vérifier s'il y a des lignes de facture qui référencent ce produit
            let ligneDescriptor = FetchDescriptor<LigneFacture>(predicate: #Predicate { ligne in
                ligne.produit?.id == id
            })
            let lignesReferencees = try modelContext.fetch(ligneDescriptor)
            
            // Détacher le produit des lignes de facture plutôt que de supprimer les lignes
            for ligne in lignesReferencees where ligne.isValidModel {
                ligne.produit = nil
            }
            
            modelContext.delete(produit)
            await saveContext()
            await fetchData()
        } catch {
            print("Erreur lors de la suppression du produit: \(error)")
        }
    }

    func searchProduits(searchText: String) -> [ProduitDTO] {
        return produits.filter { produit in
            produit.designation.localizedCaseInsensitiveContains(searchText) ||
            (produit.details ?? "").localizedCaseInsensitiveContains(searchText)
        }
    }
    func getEntreprise() async -> EntrepriseDTO? {
        return entreprise
    }
    
    func genererNumeroFacture(client: ClientModel) async -> String {
        guard let entrepriseModel = await fetchEntreprise() else {
            let currentDate = Date()
            let currentMonth = Calendar.current.component(.month, from: currentDate)
            let currentYear = Calendar.current.component(.year, from: currentDate) % 100
            let monthStr = String(format: "%02d", currentMonth)
            let yearStr = String(format: "%02d", currentYear)
            let clientInitials = client.initialesFacturation
            return "\(monthStr)/\(yearStr)-0001-\(clientInitials)"
        }

        return entrepriseModel.genererNumeroFacture(client: client)
    }

    // MARK: - Utilitaires
    func getDatabaseInfo() async -> (clientsCount: Int, facturesCount: Int, entreprisesCount: Int) {
        let entreprises = await fetchEntreprises()
        return (clients.count, factures.count, entreprises.count)
    }

    // MARK: - Export/Import
    func exportFacturesAsJSON() -> Data? {
        let facturesData = factures.map { facture in
            [
                "id": facture.id.uuidString,
                "numero": facture.numero,
                "dateFacture": facture.dateFacture.timeIntervalSince1970,
                "dateEcheance": facture.dateEcheance?.timeIntervalSince1970 as Any,
                "clientId": facture.clientId.uuidString,
                "tva": facture.tva,
                "statut": facture.statut,
                "notes": facture.notes,
                "notesCommentaireFacture": facture.notesCommentaireFacture as Any,
                "totalTTC": facture.calculateTotalTTC(with: lignes)
            ]
        }

        do {
            return try JSONSerialization.data(withJSONObject: facturesData, options: .prettyPrinted)
        } catch {
            print("Erreur lors de l'export JSON: \(error)")
            return nil
        }
    }

    func exportClientsAsJSON() -> Data? {
        let clientsData = clients.map { $0.toDictionary() }

        do {
            return try JSONSerialization.data(withJSONObject: clientsData, options: .prettyPrinted)
        } catch {
            print("Erreur lors de l'export JSON: \(error)")
            return nil
        }
    }
}

// MARK: - Extensions pour la compatibilité
extension DataService {

    /// Nettoie la base de données (pour les tests ou le développement)
      func clearAllData() async {
          // Delete all persistent models
          let allFactures = await fetchFactureModels()
          for facture in allFactures {
              modelContext.delete(facture)
          }

          let allClients = await fetchClientModels()
          for client in allClients {
              modelContext.delete(client)
          }

          let allProduits = await fetchProduitModels()
          for produit in allProduits {
              modelContext.delete(produit)
          }

          await saveContext()
          await fetchData()
      }

    /// Compte le nombre d'éléments dans chaque table
    func getDataCounts() async -> String {
        let info = await getDatabaseInfo()
        return "Clients: \(info.clientsCount), Factures: \(info.facturesCount), Entreprises: \(info.entreprisesCount)"
    }

    /// Vérifie l'intégrité des données
    func checkDataIntegrity() -> [String] {
        var issues: [String] = []

        // Vérifier les factures sans client valide
        let facturesSansClient = factures.filter { facture in
            !clients.contains { $0.id == facture.clientId }
        }
        if !facturesSansClient.isEmpty {
            issues.append("Trouvé \(facturesSansClient.count) factures sans client valide")
        }

        // Vérifier les lignes de factures vides
        for facture in factures {
            if facture.ligneIds.isEmpty {
                issues.append("Facture \(facture.numero) n'a pas de lignes")
            }
        }

        // Vérifier les clients sans nom
        let clientsSansNom = clients.filter { $0.nom.isEmpty }
        if !clientsSansNom.isEmpty {
            issues.append("Trouvé \(clientsSansNom.count) clients sans nom")
        }

        return issues
    }
}

// MARK: - Données d'entraînement
extension DataService {

    /// Génère un jeu de données réalistes pour les tests ou démonstrations.
    /// - Creates realistic company data, supermarket clients, fruits/vegetables products and invoices
    func generateTrainingData() async {
        // Nettoie d'abord toutes les données existantes
        await clearAllData()
        
        var createdProduits: [ProduitModel] = []
        var createdClients: [ClientModel] = []

        // 1. Génération d'une entreprise fictive réaliste
        await generateRealisticCompany()

        // 2. Produits fruits et légumes
        do {
            let fruitsLegumes = [
                ("Tomates grappe", "Tomates fraîches de saison", 2.50),
                ("Courgettes", "Courgettes vertes bio", 1.80),
                ("Pommes Golden", "Pommes Golden délicieuses", 1.95),
                ("Bananes", "Bananes des Antilles", 2.20),
                ("Poivrons rouges", "Poivrons rouges croquants", 3.50),
                ("Carottes", "Carottes nouvelles", 1.40),
                ("Oranges", "Oranges de Valencia", 2.10),
                ("Salade verte", "Salade batavia fraîche", 1.25),
                ("Pommes de terre", "Pommes de terre Charlotte", 1.60),
                ("Citrons", "Citrons de Sicile", 2.80),
                ("Aubergines", "Aubergines violettes", 2.90),
                ("Brocolis", "Brocolis frais", 2.40),
                ("Poires", "Poires Conference", 2.65),
                ("Radis", "Radis roses en botte", 1.15),
                ("Épinards", "Épinards frais en barquette", 1.85),
                ("Concombres", "Concombres longs", 1.70),
                ("Fraises", "Fraises de Plougastel", 4.50),
                ("Kiwis", "Kiwis de l'Adour", 3.20),
                ("Mangues", "Mangues du Sénégal", 3.80),
                ("Avocats", "Avocats Hass", 4.20)
            ]
            
            for (designation, details, prix) in fruitsLegumes {
                let prixVariation = Double.random(in: 0.8...1.2)
                let produit = ProduitModel(
                    designation: designation,
                    details: details,
                    prixUnitaire: prix * prixVariation
                )
                modelContext.insert(produit)
                if produit.isValidModel {
                    createdProduits.append(produit)
                } else {
                    print("⚠️ Produit non valide ignoré: \(produit.designation)")
                }
            }
            try modelContext.save()
            print("✅ \(createdProduits.count) produits fruits/légumes créés")
        } catch {
            print("⚠️ Erreur création produits : \(error)")
        }

        // 3. Clients grandes enseignes
        do {
            let grandesEnseignes = [
                ("Cora Nancy", "contact.nancy@cora.fr", "54000", "Nancy"),
                ("Super U Laxou", "direction@superu-laxou.fr", "54520", "Laxou"),
                ("Carrefour Basse-Terre", "magasin.basseterre@carrefour.fr", "97100", "Basse-Terre"),
                ("Intermarché Lille", "contact@intermarche-lille.fr", "59000", "Lille"),
                ("Leclerc Metz", "direction@leclerc-metz.fr", "57000", "Metz"),
                ("Auchan Strasbourg", "contact.strasbourg@auchan.fr", "67000", "Strasbourg"),
                ("Casino Lyon", "direction@casino-lyon.fr", "69000", "Lyon"),
                ("Monoprix Marseille", "contact@monoprix-marseille.fr", "13000", "Marseille"),
                ("Franprix Toulouse", "direction@franprix-toulouse.fr", "31000", "Toulouse"),
                ("Leader Price Nantes", "contact@leaderprice-nantes.fr", "44000", "Nantes"),
                ("Géant Casino Bordeaux", "direction@geant-bordeaux.fr", "33000", "Bordeaux"),
                ("Hyper U Rennes", "contact@hyperu-rennes.fr", "35000", "Rennes"),
                ("Carrefour Market Dijon", "direction@carrefour-dijon.fr", "21000", "Dijon"),
                ("Super U Angers", "contact@superu-angers.fr", "49000", "Angers"),
                ("Leclerc Poitiers", "direction@leclerc-poitiers.fr", "86000", "Poitiers")
            ]
            
            for (entreprise, email, codePostal, ville) in grandesEnseignes {
                let client = ClientModel()
                client.nom = "Responsable Achats"
                client.entreprise = entreprise
                client.email = email
                client.telephone = generateRandomPhone()
                client.adresseRue = generateRandomAddress()
                client.adresseCodePostal = codePostal
                client.adresseVille = ville
                client.adressePays = "France"
                
                modelContext.insert(client)
                if client.isValidModel {
                    createdClients.append(client)
                } else {
                    print("⚠️ Client non valide ignoré: \(client.entreprise)")
                }
            }
            try modelContext.save()
            print("✅ \(createdClients.count) clients grandes enseignes créés")
        } catch {
            print("⚠️ Erreur création clients : \(error)")
        }

        // 4. Factures avec 2-5 factures par client
        do {
            let calendar = Calendar.current
            let today = Date()
            let sixMonthsAgo = calendar.date(byAdding: .month, value: -6, to: today) ?? today
            
            var totalFactures = 0
            var totalLignes = 0
            
            for client in createdClients {
                let nombreFactures = Int.random(in: 2...5)
                
                for _ in 0..<nombreFactures {
                    let numero = await genererNumeroFacture(client: client)
                    let facture = FactureModel(client: client, numero: numero)
                    
                    // Date aléatoire dans les 6 derniers mois
                    let randomTimeInterval = TimeInterval.random(in: sixMonthsAgo.timeIntervalSince1970...today.timeIntervalSince1970)
                    facture.dateFacture = Date(timeIntervalSince1970: randomTimeInterval)
                    
                    // Date d'échéance (30 jours après la facture)
                    facture.dateEcheance = calendar.date(byAdding: .day, value: 30, to: facture.dateFacture)
                    
                    // Statut aléatoire pondéré (plus de factures payées)
                    let statuts = [
                        StatutFacture.payee,
                        StatutFacture.payee,
                        StatutFacture.payee,
                        StatutFacture.envoyee,
                        StatutFacture.envoyee,
                        StatutFacture.brouillon,
                        StatutFacture.enRetard
                    ]
                    facture.statut = statuts.randomElement() ?? StatutFacture.envoyee
                    
                    // TVA française réaliste (0%, 5.5%, 10%, 20% selon la réglementation)
                    let tvaOptions = [
                        20.0, 20.0, 20.0, 20.0, // 20% - Taux normal (majorité)
                        10.0, 10.0,              // 10% - Taux intermédiaire
                        5.5,                     // 5.5% - Taux réduit
                        0.0                      // 0% - Entreprises exonérées
                    ]
                    facture.tva = tvaOptions.randomElement() ?? 20.0
                    
                    // Insérer la facture en premier
                    modelContext.insert(facture)

                    // 3-10 lignes par facture
                    let nombreLignes = Int.random(in: 3...10)
                    var lignesCreees: [LigneFacture] = []
                    
                    for _ in 0..<nombreLignes {
                        guard let produit = createdProduits.randomElement() else { continue }
                        
                        let quantite = Double.random(in: 5...50) // Quantités importantes pour grandes enseignes
                        let prixAvecVariation = produit.prixUnitaire * Double.random(in: 0.95...1.05) // Petite variation de prix
                        
                        let ligne = LigneFacture(
                            designation: produit.designation,
                            quantite: quantite,
                            prixUnitaire: prixAvecVariation
                        )
                        
                        modelContext.insert(ligne)
                        
                        if ligne.isValidModel {
                            // Établir la relation bidirectionnelle
                            ligne.facture = facture
                            ligne.produit = produit  // Ajouter la relation produit
                            facture.lignes.append(ligne)
                            lignesCreees.append(ligne)
                            totalLignes += 1
                            
                            // Vérifier que produitId est bien défini
                            assert(ligne.produit?.id != nil, "ProduitID manquant")
                        } else {
                            print("⚠️ LigneFacture non valide ignorée: \(ligne.designation)")
                        }
                    }
                    
                    // Valider la facture APRÈS avoir ajouté les lignes
                    if !lignesCreees.isEmpty && facture.isValidModel {
                        totalFactures += 1
                        let sousTotal = lignesCreees.reduce(0) { $0 + ($1.quantite * $1.prixUnitaire) }
                        print("  ✓ Facture \(numero): \(lignesCreees.count) lignes, sous-total: \(String(format: "%.2f", sousTotal))€, total TTC: \(String(format: "%.2f", facture.totalTTC))€")
                    } else if lignesCreees.isEmpty {
                        print("⚠️ Facture \(numero) créée sans lignes")
                    } else {
                        print("⚠️ Facture \(numero) invalide après ajout des lignes")
                    }
                    
                    // Sauvegarder après chaque facture pour assurer la persistance des relations
                    try modelContext.save()
                }
            }
            
            print("✅ \(totalFactures) factures créées avec \(totalLignes) lignes produits au total")
        } catch {
            print("⚠️ Erreur création factures : \(error)")
        }

        await fetchData()
        print("🎉 Génération de données réalistes terminée!")
    }
    
    /// Génère une entreprise fictive réaliste
    private func generateRealisticCompany() async {
        let entreprises = [
            ("SARL Bio Vert", "Distribution", "Fruits et légumes biologiques"),
            ("SAS Les Primeurs", "Agroalimentaire", "Primeurs et maraîchage"),
            ("EURL Jardin Frais", "Distribution", "Produits frais de saison"),
            ("SA Terroir & Saveurs", "Grande surface", "Grossiste en fruits et légumes")
        ]
        
        guard let (nom, domaine, certification) = entreprises.randomElement() else { return }
        
        do {
            let descriptor = FetchDescriptor<EntrepriseModel>()
            let entreprises = try modelContext.fetch(descriptor)
            
            if let entreprise = entreprises.first {
                // Met à jour l'entreprise existante
                entreprise.nom = nom
                entreprise.domaine = domaine
                entreprise.telephone = "0590 12 34 56"
                entreprise.email = "contact@\(nom.lowercased().replacingOccurrences(of: " ", with: "")).fr"
                entreprise.siret = generateRandomSIRET()
                entreprise.numeroTVA = generateRandomTVA()
                entreprise.adresseRue = "Zone Industrielle Les Jardins"
                entreprise.adresseCodePostal = "97110"
                entreprise.adresseVille = "Pointe-à-Pitre"
                entreprise.adressePays = "Guadeloupe"
                entreprise.certificationTexte = certification
                entreprise.iban = "FR76 1234 5678 9012 3456 7890 123"
                entreprise.bic = "AGRIFRPP"
            } else {
                // Crée une nouvelle entreprise
                let entreprise = EntrepriseModel()
                entreprise.nom = nom
                entreprise.domaine = domaine
                entreprise.telephone = "0590 12 34 56"
                entreprise.email = "contact@\(nom.lowercased().replacingOccurrences(of: " ", with: "")).fr"
                entreprise.siret = generateRandomSIRET()
                entreprise.numeroTVA = generateRandomTVA()
                entreprise.adresseRue = "Zone Industrielle Les Jardins"
                entreprise.adresseCodePostal = "97110"
                entreprise.adresseVille = "Pointe-à-Pitre"
                entreprise.adressePays = "Guadeloupe"
                entreprise.certificationTexte = certification
                entreprise.iban = "FR76 1234 5678 9012 3456 7890 123"
                entreprise.bic = "AGRIFRPP"
                modelContext.insert(entreprise)
            }
            
            try modelContext.save()
            print("✅ Entreprise fictive créée: \(nom)")
        } catch {
            print("⚠️ Erreur création entreprise : \(error)")
        }
    }
    
    /// Génère un numéro de téléphone aléatoire
    private func generateRandomPhone() -> String {
        let prefixes = ["01", "02", "03", "04", "05", "06", "07", "09"]
        let prefix = prefixes.randomElement() ?? "01"
        let numbers = (0..<8).map { _ in String(Int.random(in: 0...9)) }.joined()
        return "\(prefix) \(numbers.prefix(2)) \(numbers.dropFirst(2).prefix(2)) \(numbers.dropFirst(4).prefix(2)) \(numbers.suffix(2))"
    }
    
    /// Génère une adresse aléatoire
    private func generateRandomAddress() -> String {
        let rues = [
            "Avenue du Commerce", "Rue des Halles", "Boulevard de la Liberté",
            "Place du Marché", "Rue de la République", "Avenue Jean Jaurès",
            "Rue Victor Hugo", "Boulevard des Alliés", "Place de la Gare",
            "Rue du Général de Gaulle", "Avenue de la Paix", "Rue Gambetta"
        ]
        let numero = Int.random(in: 1...200)
        let rue = rues.randomElement() ?? "Rue du Commerce"
        return "\(numero) \(rue)"
    }
    
    /// Génère un SIRET fictif mais au bon format
    private func generateRandomSIRET() -> String {
        let numbers = (0..<14).map { _ in String(Int.random(in: 0...9)) }.joined()
        return "\(numbers.prefix(3)) \(numbers.dropFirst(3).prefix(3)) \(numbers.dropFirst(6).prefix(3)) \(numbers.suffix(5))"
    }
    
    /// Génère un numéro de TVA fictif mais au bon format
    private func generateRandomTVA() -> String {
        let numbers = (0..<11).map { _ in String(Int.random(in: 0...9)) }.joined()
        return "FR\(numbers)"
    }
}

// MARK: - CRUD Factures DTO
extension DataService {
    func addFactureDTO(_ dto: FactureDTO) async {
        do {
            let clientDescriptor = FetchDescriptor<ClientModel>(predicate: #Predicate { $0.id == dto.clientId })
            let client = try modelContext.fetch(clientDescriptor).first
            
            let ligneDescriptor = FetchDescriptor<LigneFacture>(predicate: #Predicate { ligne in
                dto.ligneIds.contains(ligne.id)
            })
            let lignes = try modelContext.fetch(ligneDescriptor)
            
            _ = FactureModel.fromDTO(dto, context: modelContext, client: client, lignes: lignes)
            await saveContext()
            await fetchData()
        } catch {
            print("Erreur lors de l'ajout de la facture: \(error)")
        }
    }

    func updateFactureDTO(_ dto: FactureDTO) async {
        do {
            let descriptor = FetchDescriptor<FactureModel>(predicate: #Predicate { $0.id == dto.id })
            if let facture = try modelContext.fetch(descriptor).first {
                facture.updateFromDTO(dto)
                await saveContext()
                await fetchData()
            }
        } catch {
            print("Erreur lors de la mise à jour de la facture: \(error)")
        }
    }

    func deleteFactureDTO(id: UUID) async {
        do {
            let descriptor = FetchDescriptor<FactureModel>(predicate: #Predicate { $0.id == id })
            guard let facture = try modelContext.fetch(descriptor).first,
                  facture.isValidModel else {
                print("⚠️ Facture non trouvée ou invalidée: \(id)")
                return
            }
            
            // Supprimer d'abord toutes les lignes de facture
            let lignes = facture.lignes.filter { $0.isValidModel }
            for ligne in lignes {
                modelContext.delete(ligne)
            }
            
            // Ensuite supprimer la facture
            modelContext.delete(facture)
            
            await saveContext()
            await fetchData()
        } catch {
            print("Erreur lors de la suppression de la facture: \(error)")
        }
    }
    
    func addLigneDTO(_ dto: LigneFactureDTO) async {
        let ligne = LigneFacture.fromDTO(dto)
        modelContext.insert(ligne)
        await saveContext()
        await fetchData()
    }
    
    /// Récupère le modèle Client persistant à partir de l'UUID.
    func fetchClientModel(id: UUID) async -> ClientModel? {
        let descriptor = FetchDescriptor<ClientModel>(predicate: #Predicate { $0.id == id })
        do {
            if let client = try modelContext.fetch(descriptor).first {
                return client.isValidModel ? client : nil
            }
            return nil
        } catch {
            print("Erreur lors de la récupération du client avec id \(id): \(error)")
            return nil
        }
    }

    /// Récupère le modèle Facture persistant à partir de l'UUID.
    func fetchFactureModel(id: UUID) async -> FactureModel? {
        let descriptor = FetchDescriptor<FactureModel>(predicate: #Predicate { $0.id == id })
        do {
            if let facture = try modelContext.fetch(descriptor).first {
                // Vérifier si la facture est encore valide
                return facture.isValidModel ? facture : nil
            }
            return nil
        } catch {
            print("Erreur lors de la récupération de la facture avec id \(id): \(error)")
            return nil
        }
    }

    /// Récupère le modèle Produit persistant à partir de l'UUID.
    func fetchProduitModel(id: UUID) async -> ProduitModel? {
        let descriptor = FetchDescriptor<ProduitModel>(predicate: #Predicate { $0.id == id })
        do {
            if let produit = try modelContext.fetch(descriptor).first {
                return produit.isValidModel ? produit : nil
            }
            return nil
        } catch {
            print("Erreur lors de la récupération du produit avec id \(id): \(error)")
            return nil
        }
    }

    /// Récupère le modèle LigneFacture persistant à partir de l'UUID.
    func fetchLigneModel(id: UUID) async -> LigneFacture? {
        let descriptor = FetchDescriptor<LigneFacture>(predicate: #Predicate { $0.id == id })
        do {
            return try modelContext.fetch(descriptor).first
        } catch {
            print("Erreur lors de la récupération de la ligne avec id \(id): \(error)")
            return nil
        }
    }
    
    /// Récupère le modèle Entreprise persistant à partir de l'UUID.
    func fetchEntrepriseModel(id: UUID) async -> EntrepriseModel? {
        let descriptor = FetchDescriptor<EntrepriseModel>(predicate: #Predicate { $0.id == id })
        do {
            return try modelContext.fetch(descriptor).first
        } catch {
            print("Erreur lors de la récupération de l'entreprise avec id \(id): \(error)")
            return nil
        }
    }
}

// MARK: - Extension ClientDTO pour export dictionnaire
extension ClientDTO {
    func toDictionary() -> [String: Any] {
        [
            "id": id.uuidString,
            "nom": nom,
            "entreprise": entreprise,
            "email": email
            // Ajoute ici les autres champs nécessaires (téléphone, adresse, etc.)
        ]
    }
}

// MARK: - SwiftData Models are now in separate files under Models/

// Models are now defined in separate files: Models/ClientModel.swift, Models/FactureModel.swift, etc.

// MARK: - CRUD LignesFactures DTO
extension DataService {
    func fetchLignesFactures() async -> [LigneFactureDTO] {
        do {
            let lignes = try modelContext.fetch(FetchDescriptor<LigneFacture>())
            return lignes.map { $0.toDTO() }
        } catch {
            print("Erreur lors de la récupération des lignes de facture: \(error)")
            return []
        }
    }
    // MARK: - Private DTO Fetchers
    private func fetchClientDTOs() async -> [ClientDTO] {
        do {
            let descriptor = FetchDescriptor<ClientModel>(sortBy: [SortDescriptor(\ClientModel.nom)])
            let models = try modelContext.fetch(descriptor)
            return models.map { $0.toDTO() }
        } catch {
            print("Erreur lors de la récupération des clients: \(error)")
            return []
        }
    }

     func fetchFactureDTOs() async -> [FactureDTO] {
        do {
            let descriptor = FetchDescriptor<FactureModel>(sortBy: [SortDescriptor(\FactureModel.dateFacture, order: .reverse)])
            let models = try modelContext.fetch(descriptor)
            return models.map { $0.toDTO() }
        } catch {
            print("Erreur lors de la récupération des factures: \(error)")
            return []
        }
    }

    private func fetchProduitDTOs() async -> [ProduitDTO] {
        do {
            let descriptor = FetchDescriptor<ProduitModel>(sortBy: [SortDescriptor(\ProduitModel.designation)])
            let models = try modelContext.fetch(descriptor)
            return models.map { $0.toDTO() }
        } catch {
            print("Erreur lors de la récupération des produits: \(error)")
            return []
        }
    }

    private func fetchLigneDTOs() async -> [LigneFactureDTO] {
        do {
            let descriptor = FetchDescriptor<LigneFacture>()
            let models = try modelContext.fetch(descriptor)
            return models.map { $0.toDTO() }
        } catch {
            print("Erreur lors de la récupération des lignes: \(error)")
            return []
        }
    }

    // MARK: - Public DTO Fetcher
    func fetchEntrepriseDTO() async -> EntrepriseDTO? {
        do {
            let descriptor = FetchDescriptor<EntrepriseModel>()
            if let model = try modelContext.fetch(descriptor).first {
                return model.toDTO()
            } else {
                return nil
            }
        } catch {
            print("Erreur lors de la récupération de l'entreprise: \(error)")
            return nil
        }
    }
}
// MARK: - Mock Data for Preview
extension FactureDTO {
    static func mock() -> FactureDTO {
        FactureDTO(
            id: UUID(),
            numero: "F2025-001",
            dateFacture: Date(),
            dateEcheance: Calendar.current.date(byAdding: .day, value: 30, to: Date()),
            datePaiement: nil,
            tva: 8.5,
            conditionsPaiement: "30 jours",
            remisePourcentage: 10.0,
            statut: "envoyée",
            notes: "Exemple de facture de test",
            notesCommentaireFacture: "Livraison rapide",
            clientId: UUID(),
            ligneIds: []
        )
    }
}

extension FactureModel {
    static func mock() -> FactureModel {
        let facture = FactureModel()
        facture.numero = "F2025-001"
        facture.dateFacture = Date()
        facture.dateEcheance = Calendar.current.date(byAdding: .day, value: 30, to: Date())!
        facture.tva = 8.5
        facture.conditionsPaiement = .virement
        facture.remisePourcentage = 10.0
        facture.notes = "Exemple de facture"
        facture.notesCommentaireFacture = "Livraison rapide"
        facture.statut = .envoyee
        return facture
    }
}

extension EntrepriseDTO {
    static func mock() -> EntrepriseDTO {
        EntrepriseDTO(
            id: UUID(),
            nom: "Exemple SARL",
            nomContact: "Jean Testeur",
            nomDirigeant: "Marie Directrice",
            telephone: "0123456789",
            email: "contact@exemple.com",
            siret: "12345678900000",
            numeroTVA: "FR123456789",
            iban: "FR7612345987650123456789014",
            bic: "BNPAFRPP",
            adresseRue: "1 rue du Test",
            adresseCodePostal: "75000",
            adresseVille: "Paris",
            adressePays: "France",
            certificationTexte: "Certification ISO 9001",
            logo: nil,
            prefixeFacture: "F",
            prochainNumero: 1,
            tvaTauxDefaut: 20.0,
            delaiPaiementDefaut: 30
        )
    }
}

extension DataService {
    static func previewMock() -> DataService {
        let mock = DataService()
        mock.factures = [FactureDTO.mock()]
        mock.lignes = []
        mock.entreprise = EntrepriseDTO.mock()
        mock.clients = [
            ClientDTO(
                id: UUID(),
                nom: "Client Test",
                entreprise: "Entreprise Test",
                email: "client@test.com",
                telephone: "0601020304",
                siret: "11223344556677",
                numeroTVA: "FR11223344",
                adresse: "12 rue du Client",
                adresseRue: "12 rue du Client",
                adresseCodePostal: "75001",
                adresseVille: "Paris",
                adressePays: "France"
            )
        ]
        mock.produits = [
            ProduitDTO(
                id: UUID(),
                designation: "Produit Test",
                details: "Produit de démonstration",
                prixUnitaire: 42.0,
                icon: nil,
                iconImageData: nil
            )
        ]
        return mock
    }
}


