import XCTest
@testable import Facturation
import DataLayer

@MainActor
final class SecureArchitectureIntegrationTests: XCTestCase {
    
    var dataService: SecureDataService!
    var clientRepository: SecureClientRepository!
    var factureRepository: SecureFactureRepository!
    var produitRepository: SecureProduitRepository!
    var dependencyContainer: DependencyContainer!
    
    override func setUp() {
        super.setUp()
        // Utilise SecureDataService en mémoire pour l'isolation des tests
        dataService = SecureDataService()
        clientRepository = SecureClientRepository(dataService: dataService)
        factureRepository = SecureFactureRepository(dataService: dataService)
        produitRepository = SecureProduitRepository(dataService: dataService)
        dependencyContainer = DependencyContainer()
    }
    
    override func tearDown() {
        dataService = nil
        clientRepository = nil
        factureRepository = nil
        produitRepository = nil
        dependencyContainer = nil
        super.tearDown()
    }
    
    // MARK: - Client Integration Tests
    
    func testClientUseCaseIntegration() async throws {
        // Given
        let addClientUseCase = AddClientUseCase(repository: clientRepository)
        let fetchClientsUseCase = FetchClientsUseCase(repository: clientRepository)
        let updateClientUseCase = UpdateClientUseCase(repository: clientRepository)
        let deleteClientUseCase = DeleteClientUseCase(repository: clientRepository)
        
        // When - Add client
        let addResult = await addClientUseCase.execute(
            nom: "Dupont",
            prenom: "Jean",
            email: "jean.dupont@example.com",
            telephone: "0123456789",
            adresse: "123 Rue de la Paix",
            ville: "Paris",
            codePostal: "75001",
            pays: "France",
            siret: "40483304800010", // SIRET valide
            tva: "FR00123456789"
        )
        
        // Then - Verify add success
        switch addResult {
        case .success(let clientId):
            XCTAssertNotNil(clientId)
            
            // When - Fetch clients
            let fetchResult = await fetchClientsUseCase.execute()
            
            // Then - Verify fetch
            switch fetchResult {
            case .success(let clients):
                XCTAssertEqual(clients.count, 1)
                let client = clients.first!
                XCTAssertEqual(client.nom, "Dupont")
                XCTAssertEqual(client.entreprise, "SARL Test")
                XCTAssertEqual(client.email, "jean.dupont@example.com")
                
                // When - Update client
                var updatedClient = client
                updatedClient.telephone = "0987654321"
                let updateResult = await updateClientUseCase.execute(client: updatedClient)
                
                // Then - Verify update
                switch updateResult {
                case .success(let success):
                    XCTAssertTrue(success)
                    
                    // When - Delete client
                    let deleteResult = await deleteClientUseCase.execute(clientId: client.id)
                    
                    // Then - Verify delete
                    switch deleteResult {
                    case .success(let success):
                        XCTAssertTrue(success)
                        
                        // Final verification - no clients left
                        let finalFetchResult = await fetchClientsUseCase.execute()
                        switch finalFetchResult {
                        case .success(let finalClients):
                            XCTAssertEqual(finalClients.count, 0)
                        case .failure(let error):
                            XCTFail("Final fetch failed: \(error)")
                        }
                    case .failure(let error):
                        XCTFail("Delete failed: \(error)")
                    }
                case .failure(let error):
                    XCTFail("Update failed: \(error)")
                }
            case .failure(let error):
                XCTFail("Fetch failed: \(error)")
            }
        case .failure(let error):
            XCTFail("Add client failed: \(error)")
        }
    }
    
    // MARK: - Facture Integration Tests
    
    func testFactureUseCaseIntegration() async throws {
        // Given - Create a client first
        let addClientUseCase = AddClientUseCase(repository: clientRepository)
        let clientResult = await addClientUseCase.execute(
            nom: "TestClient",
            prenom: "Test",
            email: "test@example.com",
            telephone: "0123456789",
            adresse: "Test Address",
            ville: "Test City",
            codePostal: "12345",
            pays: "France",
            siret: "40483304800010",
            tva: "FR00123456789"
        )
        
        guard case .success(let clientId) = clientResult else {
            XCTFail("Failed to create test client")
            return
        }
        
        // When - Create facture
        let createFactureUseCase = CreateFactureUseCase(repository: factureRepository)
        let fetchFacturesUseCase = FetchFacturesUseCase(repository: factureRepository)
        
        let factureResult = await createFactureUseCase.execute(clientId: clientId, tva: 20.0)
        
        // Then - Verify facture creation
        switch factureResult {
        case .success(let factureId):
            XCTAssertNotNil(factureId)
            
            // Verify facture was saved
            let fetchResult = await fetchFacturesUseCase.execute()
            switch fetchResult {
            case .success(let factures):
                XCTAssertEqual(factures.count, 1)
                let facture = factures.first!
                XCTAssertEqual(facture.clientId, clientId)
                XCTAssertEqual(facture.tva, 20.0)
                XCTAssertEqual(facture.statut, StatutFacture.brouillon.rawValue)
            case .failure(let error):
                XCTFail("Fetch factures failed: \(error)")
            }
        case .failure(let error):
            XCTFail("Create facture failed: \(error)")
        }
    }
    
    // MARK: - Produit Integration Tests
    
    func testProduitUseCaseIntegration() async throws {
        // Given
        let addProduitUseCase = AddProduitUseCase(repository: produitRepository)
        let fetchProduitsUseCase = FetchProduitsUseCase(repository: produitRepository)
        let searchProduitsUseCase = SearchProduitsUseCase(repository: produitRepository)
        
        // When - Add produit
        let addResult = await addProduitUseCase.execute(
            designation: "Ordinateur Portable",
            details: "MacBook Pro 16 pouces",
            prixUnitaire: 2499.99
        )
        
        // Then - Verify add success
        switch addResult {
        case .success(let success):
            XCTAssertTrue(success)
            
            // When - Fetch produits
            let fetchResult = await fetchProduitsUseCase.execute()
            
            // Then - Verify fetch
            switch fetchResult {
            case .success(let produits):
                XCTAssertEqual(produits.count, 1)
                let produit = produits.first!
                XCTAssertEqual(produit.designation, "Ordinateur Portable")
                XCTAssertEqual(produit.details, "MacBook Pro 16 pouces")
                XCTAssertEqual(produit.prixUnitaire, 2499.99)
                
                // When - Search produits
                let searchResult = await searchProduitsUseCase.execute(searchText: "MacBook")
                
                // Then - Verify search
                switch searchResult {
                case .success(let searchedProduits):
                    XCTAssertEqual(searchedProduits.count, 1)
                    XCTAssertEqual(searchedProduits.first?.designation, "Ordinateur Portable")
                case .failure(let error):
                    XCTFail("Search failed: \(error)")
                }
            case .failure(let error):
                XCTFail("Fetch failed: \(error)")
            }
        case .failure(let error):
            XCTFail("Add produit failed: \(error)")
        }
    }
    
    // MARK: - Cross-Entity Integration Tests
    
    func testCompleteInvoiceWorkflow() async throws {
        // Given - Create dependencies
        let addClientUseCase = AddClientUseCase(repository: clientRepository)
        let addProduitUseCase = AddProduitUseCase(repository: produitRepository)
        let createFactureUseCase = CreateFactureUseCase(repository: factureRepository)
        let addLigneUseCase = AddLigneUseCase(repository: factureRepository)
        
        // Step 1: Create client
        let clientResult = await addClientUseCase.execute(
            nom: "Entreprise ABC",
            prenom: "Contact",
            email: "contact@abc.com",
            telephone: "0123456789",
            adresse: "123 Business Street",
            ville: "Business City",
            codePostal: "12345",
            pays: "France",
            siret: "40483304800010",
            tva: "FR00123456789"
        )
        
        guard case .success(let clientId) = clientResult else {
            XCTFail("Failed to create client")
            return
        }
        
        // Step 2: Create produit
        let produitResult = await addProduitUseCase.execute(
            designation: "Service Consulting",
            details: "Consultation technique",
            prixUnitaire: 500.0
        )
        
        guard case .success(_) = produitResult else {
            XCTFail("Failed to create produit")
            return
        }
        
        // Step 3: Create facture
        let factureResult = await createFactureUseCase.execute(clientId: clientId, tva: 20.0)
        
        guard case .success(let facture) = factureResult else {
            XCTFail("Failed to create facture")
            return
        }
        let factureId = facture.id
        
        // Step 4: Add ligne to facture
        let ligneDTO = LigneFactureDTO(
            id: UUID(),
            designation: "Service Consulting",
            quantite: 2.0,
            prixUnitaire: 500.0,
            referenceCommande: "REF-001",
            dateCommande: Date(),
            produitId: nil,
            factureId: factureId
        )
        
        let ligneResult = await addLigneUseCase.execute(ligne: ligneDTO)
        
        // Then - Verify complete workflow
        switch ligneResult {
        case .success(let success):
            XCTAssertTrue(success)
            
            // Verify final state
            let fetchFacturesUseCase = FetchFacturesUseCase(repository: factureRepository)
            let fetchLignesUseCase = FetchLignesUseCase(repository: factureRepository)
            
            let facturesResult = await fetchFacturesUseCase.execute()
            let lignesResult = await fetchLignesUseCase.execute()
            
            guard case .success(let factures) = facturesResult,
                  case .success(let lignes) = lignesResult else {
                XCTFail("Failed to fetch final state")
                return
            }
            
            XCTAssertEqual(factures.count, 1)
            XCTAssertEqual(lignes.count, 1)
            
            let facture = factures.first!
            let ligne = lignes.first!
            
            XCTAssertEqual(facture.clientId, clientId)
            XCTAssertEqual(ligne.factureId, Optional(factureId))
            XCTAssertEqual(ligne.quantite * ligne.prixUnitaire, 1000.0) // 2 * 500
            
        case .failure(let error):
            XCTFail("Add ligne failed: \(error)")
        }
    }
    
    // MARK: - Error Handling Integration Tests
    
    func testErrorHandlingIntegration() async throws {
        // Given
        let deleteClientUseCase = DeleteClientUseCase(repository: clientRepository)
        let nonExistentClientId = UUID()
        
        // When - Try to delete non-existent client
        let deleteResult = await deleteClientUseCase.execute(clientId: nonExistentClientId)
        
        // Then - Should handle error gracefully
        switch deleteResult {
        case .success(_):
            XCTFail("Should not succeed when deleting non-existent client")
        case .failure(let error):
            // Error should be handled gracefully without crashing
            XCTAssertNotNil(error)
        }
    }
}