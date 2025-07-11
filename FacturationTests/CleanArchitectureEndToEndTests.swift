import XCTest
import SwiftData
import DataLayer
@testable import Facturation

/// Tests end-to-end pour valider l'architecture Clean complète
@MainActor
final class CleanArchitectureEndToEndTests: XCTestCase {
    
    var dependencyContainer: DependencyContainer!
    var secureDataService: SecureDataService!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Initialize with in-memory data service for testing
        secureDataService = SecureDataService()
        dependencyContainer = DependencyContainer(dataService: secureDataService)
    }
    
    override func tearDown() {
        dependencyContainer = nil
        secureDataService = nil
        super.tearDown()
    }
    
    // MARK: - Test complet du flux Clients
    
    func testClientWorkflowEndToEnd() async throws {
        // Given - Use cases pour clients
        let addClientUseCase = dependencyContainer.addClientUseCase
        let fetchClientsUseCase = dependencyContainer.fetchClientsUseCase
        let getStatistiquesClientsUseCase = dependencyContainer.getStatistiquesClientsUseCase
        
        // When - Ajouter un client
        let addResult = await addClientUseCase.execute(
            nom: "Test Client E2E",
            prenom: "Contact",
            email: "e2e@test.com",
            telephone: "0123456789",
            adresse: "123 Test Street",
            ville: "Test City",
            codePostal: "12345",
            pays: "France",
            siret: "40483304800010",
            tva: "FR00123456789"
        )
        
        // Then - Client ajouté avec succès
        XCTAssertNoThrow(try addResult.get())
        let clientId = try addResult.get()
        XCTAssertNotNil(clientId)
        
        // When - Récupérer les clients
        let fetchResult = await fetchClientsUseCase.execute()
        
        // Then - Client présent dans la liste
        XCTAssertNoThrow(try fetchResult.get())
        let clients = try fetchResult.get()
        XCTAssertTrue(clients.contains { $0.id == clientId })
        
        // When - Obtenir statistiques clients
        let statsResult = await getStatistiquesClientsUseCase.execute()
        
        // Then - Statistiques disponibles
        XCTAssertNoThrow(try statsResult.get())
        let stats = try statsResult.get()
        XCTAssertTrue(stats.contains { $0.client.id == clientId })
    }
    
    // MARK: - Test complet du flux Produits
    
    func testProduitWorkflowEndToEnd() async throws {
        // Given - Use cases pour produits
        let addProduitUseCase = dependencyContainer.addProduitUseCase
        let fetchProduitsUseCase = dependencyContainer.fetchProduitsUseCase
        let getStatistiquesProduitsUseCase = dependencyContainer.getStatistiquesProduitsUseCase
        
        // When - Ajouter un produit
        let addResult = await addProduitUseCase.execute(
            designation: "Produit Test E2E",
            details: "Description du produit test",
            prixUnitaire: 100.0
        )
        
        // Then - Produit ajouté avec succès
        XCTAssertNoThrow(try addResult.get())
        let success = try addResult.get()
        XCTAssertTrue(success)
        
        // When - Récupérer les produits
        let fetchResult = await fetchProduitsUseCase.execute()
        
        // Then - Produit présent dans la liste
        XCTAssertNoThrow(try fetchResult.get())
        let produits = try fetchResult.get()
        XCTAssertTrue(produits.contains { $0.designation == "Produit Test E2E" })
        
        // When - Obtenir statistiques produits
        let statsResult = await getStatistiquesProduitsUseCase.execute()
        
        // Then - Statistiques disponibles (même si vides)
        XCTAssertNoThrow(try statsResult.get())
        let stats = try statsResult.get()
        // Les stats peuvent être vides car aucune facture n'a été créée
        XCTAssertNotNil(stats)
    }
    
    // MARK: - Test complet du flux Factures
    
    func testFactureWorkflowEndToEnd() async throws {
        // Given - Créer d'abord un client et un produit
        let clientId = try await createTestClient()
        let produitId = try await createTestProduit()
        
        // Given - Use cases pour factures
        let createFactureUseCase = dependencyContainer.createFactureUseCase
        let fetchFacturesUseCase = dependencyContainer.fetchFacturesUseCase
        let addLigneUseCase = dependencyContainer.addLigneUseCase
        
        // When - Créer une facture
        let factureResult = await createFactureUseCase.execute(clientId: clientId, tva: 20.0)
        
        // Then - Facture créée avec succès
        XCTAssertNoThrow(try factureResult.get())
        let facture = try factureResult.get()
        let factureId = facture.id
        XCTAssertNotNil(factureId)
        
        // When - Ajouter une ligne à la facture
        let ligneDTO = LigneFactureDTO(
            id: UUID(),
            designation: "Test Product Line",
            quantite: 2.0,
            prixUnitaire: 100.0,
            produitId: produitId,
            factureId: factureId
        )
        let ligneResult = await addLigneUseCase.execute(ligne: ligneDTO)
        
        // Then - Ligne ajoutée avec succès
        XCTAssertNoThrow(try ligneResult.get())
        let success = try ligneResult.get()
        XCTAssertTrue(success)
        
        // When - Récupérer les factures
        let fetchResult = await fetchFacturesUseCase.execute()
        
        // Then - Facture présente dans la liste
        XCTAssertNoThrow(try fetchResult.get())
        let factures = try fetchResult.get()
        XCTAssertTrue(factures.contains { $0.id == factureId })
        
        // Vérifier que la facture contient la ligne
        if let facture = factures.first(where: { $0.id == factureId }) {
            XCTAssertTrue(facture.ligneIds.contains(ligneDTO.id))
        }
    }
    
    // MARK: - Test complet des statistiques intégrées
    
    func testStatistiquesIntegrationEndToEnd() async throws {
        // Given - Créer des données test complètes
        let clientId = try await createTestClient()
        let produitId = try await createTestProduit()
        let factureId = try await createTestFactureWithLigne(clientId: clientId, produitId: produitId)
        
        // Given - Use cases pour statistiques
        let getStatistiquesUseCase = dependencyContainer.getStatistiquesUseCase
        let getStatistiquesClientsUseCase = dependencyContainer.getStatistiquesClientsUseCase
        let getStatistiquesProduitsUseCase = dependencyContainer.getStatistiquesProduitsUseCase
        
        // When - Obtenir statistiques générales
        let statsGeneralesResult = await getStatistiquesUseCase.execute()
        
        // Then - Statistiques générales disponibles
        XCTAssertNoThrow(try statsGeneralesResult.get())
        let statsGenerales = try statsGeneralesResult.get()
        XCTAssertGreaterThan(statsGenerales.totalFactures, 0)
        XCTAssertGreaterThan(statsGenerales.totalCA, 0)
        
        // When - Obtenir statistiques clients
        let statsClientsResult = await getStatistiquesClientsUseCase.execute()
        
        // Then - Statistiques clients cohérentes
        XCTAssertNoThrow(try statsClientsResult.get())
        let statsClients = try statsClientsResult.get()
        XCTAssertTrue(statsClients.contains { $0.client.id == clientId })
        
        if let clientStat = statsClients.first(where: { $0.client.id == clientId }) {
            XCTAssertGreaterThan(clientStat.chiffreAffaires, 0)
            XCTAssertGreaterThan(clientStat.nombreFactures, 0)
        }
        
        // When - Obtenir statistiques produits
        let statsProduitsResult = await getStatistiquesProduitsUseCase.execute()
        
        // Then - Statistiques produits cohérentes
        XCTAssertNoThrow(try statsProduitsResult.get())
        let statsProduits = try statsProduitsResult.get()
        XCTAssertTrue(statsProduits.contains { $0.produit.id == produitId })
        
        if let produitStat = statsProduits.first(where: { $0.produit.id == produitId }) {
            XCTAssertGreaterThan(produitStat.chiffreAffaires, 0)
            XCTAssertGreaterThan(produitStat.quantiteVendue, 0)
        }
    }
    
    // MARK: - Test de performance de l'architecture
    
    func testArchitecturePerformance() async throws {
        // Given - Créer un grand nombre d'entités
        var clientIds: [UUID] = []
        var produitIds: [UUID] = []
        
        // Mesurer les performances de création en batch
        measure {
            Task {
                // Créer 10 clients
                for i in 1...10 {
                    if let clientId = try? await createTestClient(suffix: "\(i)") {
                        clientIds.append(clientId)
                    }
                }
                
                // Créer 10 produits
                for i in 1...10 {
                    if let produitId = try? await createTestProduit(suffix: "\(i)") {
                        produitIds.append(produitId)
                    }
                }
            }
        }
        
        // Then - Performance acceptable
        XCTAssertEqual(clientIds.count, 10)
        XCTAssertEqual(produitIds.count, 10)
    }
    
    // MARK: - Méthodes helper
    
    private func createTestClient(suffix: String = "") async throws -> UUID {
        let result = await dependencyContainer.addClientUseCase.execute(
            nom: "Test Client\(suffix)",
            prenom: "Contact",
            email: "test\(suffix)@example.com",
            telephone: "0123456789",
            adresse: "123 Test Street",
            ville: "Test City",
            codePostal: "12345",
            pays: "France",
            siret: "40483304800010",
            tva: "FR00123456789"
        )
        return try result.get()
    }
    
    private func createTestProduit(suffix: String = "") async throws -> UUID {
        let result = await dependencyContainer.addProduitUseCase.execute(
            designation: "Test Product\(suffix)",
            details: "Test product description",
            prixUnitaire: 100.0
        )
        let success = try result.get()
        guard success else {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create test product"])
        }
        
        // Récupérer le produit créé
        let fetchResult = await dependencyContainer.fetchProduitsUseCase.execute()
        let produits = try fetchResult.get()
        guard let produit = produits.first(where: { $0.designation == "Test Product\(suffix)" }) else {
            throw NSError(domain: "TestError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Created product not found"])
        }
        return produit.id
    }
    
    private func createTestFactureWithLigne(clientId: UUID, produitId: UUID) async throws -> UUID {
        // Créer facture
        let factureResult = await dependencyContainer.createFactureUseCase.execute(clientId: clientId, tva: 20.0)
        let facture = try factureResult.get()
        let factureId = facture.id
        
        // Ajouter ligne
        let ligneDTO = LigneFactureDTO(
            id: UUID(),
            designation: "Test Product Line",
            quantite: 2.0,
            prixUnitaire: 100.0,
            produitId: produitId,
            factureId: factureId
        )
        let ligneResult = await dependencyContainer.addLigneUseCase.execute(ligne: ligneDTO)
        _ = try ligneResult.get()
        
        return factureId
    }
}