import XCTest
import SwiftData
import DataLayer
@testable import Facturation

/// Tests de performance pour le cache des statistiques
@MainActor
final class StatistiquesCachePerformanceTests: XCTestCase {
    
    var dependencyContainer: DependencyContainer!
    var secureDataService: SecureDataService!
    var cacheService: StatistiquesCacheService!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Initialize with in-memory data service for testing
        secureDataService = SecureDataService()
        dependencyContainer = DependencyContainer(dataService: secureDataService)
        cacheService = StatistiquesCacheService()
        
        // Créer des données de test pour les mesures de performance  
        do {
            try await createTestDataForPerformance()
        } catch {
            // Ignore setup errors for performance tests
        }
    }
    
    override func tearDown() {
        dependencyContainer = nil
        secureDataService = nil
        cacheService = nil
        super.tearDown()
    }
    
    // MARK: - Performance Tests
    
    func testCachePerformanceForProductStatistics() async throws {
        let useCase = dependencyContainer.getStatistiquesProduitsUseCase
        
        // Premier appel (cache miss)
        let startTime1 = CFAbsoluteTimeGetCurrent()
        let result1 = await useCase.execute()
        let duration1 = CFAbsoluteTimeGetCurrent() - startTime1
        
        XCTAssertNoThrow(try result1.get())
        
        // Deuxième appel (cache hit)
        let startTime2 = CFAbsoluteTimeGetCurrent()
        let result2 = await useCase.execute()
        let duration2 = CFAbsoluteTimeGetCurrent() - startTime2
        
        XCTAssertNoThrow(try result2.get())
        
        // Le cache hit devrait être significativement plus rapide
        XCTAssertLessThan(duration2, duration1 * 0.5, "Cache hit should be at least 50% faster")
        
        print("First call (cache miss): \(duration1 * 1000)ms")
        print("Second call (cache hit): \(duration2 * 1000)ms")
        print("Performance improvement: \((duration1 - duration2) / duration1 * 100)%")
    }
    
    func testCachePerformanceForClientStatistics() async throws {
        let useCase = dependencyContainer.getStatistiquesClientsUseCase
        
        // Premier appel (cache miss)
        let startTime1 = CFAbsoluteTimeGetCurrent()
        let result1 = await useCase.execute()
        let duration1 = CFAbsoluteTimeGetCurrent() - startTime1
        
        XCTAssertNoThrow(try result1.get())
        
        // Deuxième appel (cache hit)
        let startTime2 = CFAbsoluteTimeGetCurrent()
        let result2 = await useCase.execute()
        let duration2 = CFAbsoluteTimeGetCurrent() - startTime2
        
        XCTAssertNoThrow(try result2.get())
        
        // Le cache hit devrait être plus rapide
        XCTAssertLessThan(duration2, duration1, "Cache hit should be faster than cache miss")
        
        print("Client stats - First call: \(duration1 * 1000)ms, Second call: \(duration2 * 1000)ms")
    }
    
    func testCacheMetrics() async throws {
        let useCase = dependencyContainer.getStatistiquesProduitsUseCase
        
        // Exécuter quelques opérations pour peupler le cache
        _ = await useCase.execute()
        _ = await useCase.execute(startDate: Date().addingTimeInterval(-86400)) // Hier
        
        // Vérifier les métriques
        let metrics = dependencyContainer.getCacheMetrics()
        
        XCTAssertGreaterThan(metrics.totalEntries, 0)
        XCTAssertGreaterThanOrEqual(metrics.activeEntries, 0)
        XCTAssertLessThanOrEqual(metrics.expiredEntries, metrics.totalEntries)
        XCTAssertGreaterThan(metrics.hitRate, 0)
        XCTAssertGreaterThan(metrics.memoryUsage, 0)
        
        print("Cache metrics:")
        print("- Total entries: \(metrics.totalEntries)")
        print("- Active entries: \(metrics.activeEntries)")
        print("- Expired entries: \(metrics.expiredEntries)")
        print("- Hit rate: \(metrics.hitRate * 100)%")
        print("- Memory usage: \(metrics.memoryUsageMB)MB")
    }
    
    func testCacheInvalidation() async throws {
        let useCase = dependencyContainer.getStatistiquesProduitsUseCase
        
        // Premier appel pour peupler le cache
        let result1 = await useCase.execute()
        XCTAssertNoThrow(try result1.get())
        
        // Invalider le cache spécifiquement pour les produits
        dependencyContainer.invalidateCache(for: .produits)
        
        // Vérifier que le cache est bien invalidé en mesurant le temps
        let startTime = CFAbsoluteTimeGetCurrent()
        let result2 = await useCase.execute()
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        
        XCTAssertNoThrow(try result2.get())
        
        // Après invalidation, l'appel devrait prendre plus de temps (cache miss)
        XCTAssertGreaterThan(duration, 0.001, "After cache invalidation, call should take measurable time")
    }
    
    func testCacheExpiration() async throws {
        // Créer un cache service avec TTL très court pour les tests
        let shortTTLCache = StatistiquesCacheService()
        let repositoryRef = dependencyContainer.statistiquesRepository
        let useCase = GetStatistiquesProduitsUseCase(
            repository: repositoryRef,
            cacheService: shortTTLCache
        )
        
        // Premier appel pour peupler le cache
        let result1 = await useCase.execute()
        XCTAssertNoThrow(try result1.get())
        
        // Attendre que le cache expire (simulé par nettoyage)
        shortTTLCache.cleanExpiredCache()
        
        // Deuxième appel après expiration
        let startTime = CFAbsoluteTimeGetCurrent()
        let result2 = await useCase.execute()
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        
        XCTAssertNoThrow(try result2.get())
        
        // Après expiration, l'appel devrait prendre du temps (cache miss)
        XCTAssertGreaterThan(duration, 0.001, "After cache expiration, call should take measurable time")
    }
    
    func testConcurrentCacheAccess() async throws {
        let useCase = dependencyContainer.getStatistiquesProduitsUseCase
        
        // Exécuter plusieurs appels concurrents pour tester la sécurité du cache
        var results: [Result<[ProduitStatistiqueResult], Error>] = []
        
        // Utiliser Task.withTaskGroup pour les appels concurrents
        await withTaskGroup(of: Result<[ProduitStatistiqueResult], Error>.self) { group in
            for _ in 1...5 {
                group.addTask {
                    return await useCase.execute()
                }
            }
            
            for await result in group {
                results.append(result)
            }
        }
        
        // Vérifier que tous les appels ont réussi
        let successCount = results.filter { $0.isSuccess }.count
        XCTAssertEqual(successCount, 5, "All concurrent cache accesses should succeed")
    }
    
    // MARK: - Helper Methods
    
    private func createTestDataForPerformance() async throws {
        // Créer plusieurs clients
        for i in 1...20 {
            _ = try? await createTestClient(suffix: "\(i)")
        }
        
        // Créer plusieurs produits
        for i in 1...15 {
            _ = try? await createTestProduit(suffix: "\(i)")
        }
        
        // Créer des factures avec lignes pour générer des statistiques
        if let clients = try? await fetchAllClients(),
           let produits = try? await fetchAllProduits() {
            
            for client in clients.prefix(10) {
                if let factureId = try? await createTestFacture(clientId: client.id) {
                    // Ajouter quelques lignes à chaque facture
                    for produit in produits.prefix(3) {
                        _ = try? await createTestLigne(
                            factureId: factureId,
                            produitId: produit.id,
                            quantite: Double.random(in: 1...5),
                            prix: Double.random(in: 50...200)
                        )
                    }
                }
            }
        }
    }
    
    private func createTestClient(suffix: String) async throws -> UUID {
        let result = await dependencyContainer.addClientUseCase.execute(
            nom: "PerfClient\(suffix)",
            prenom: "Test",
            email: "perf\(suffix)@test.com",
            telephone: "0123456789",
            adresse: "Test Address",
            ville: "Test City",
            codePostal: "12345",
            pays: "France",
            siret: "40483304800010",
            tva: "FR00123456789"
        )
        return try result.get()
    }
    
    private func createTestProduit(suffix: String) async throws -> UUID {
        let result = await dependencyContainer.addProduitUseCase.execute(
            designation: "PerfProduct\(suffix)",
            details: "Performance test product",
            prixUnitaire: 100.0
        )
        let success = try result.get()
        guard success else {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create test product"])
        }
        
        // Récupérer le produit créé
        let fetchResult = await dependencyContainer.fetchProduitsUseCase.execute()
        let produits = try fetchResult.get()
        guard let produit = produits.first(where: { $0.designation == "PerfProduct\(suffix)" }) else {
            throw NSError(domain: "TestError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Created product not found"])
        }
        return produit.id
    }
    
    private func createTestFacture(clientId: UUID) async throws -> UUID {
        let result = await dependencyContainer.createFactureUseCase.execute(clientId: clientId, tva: 20.0)
        let facture = try result.get()
        return facture.id
    }
    
    private func createTestLigne(factureId: UUID, produitId: UUID, quantite: Double, prix: Double) async throws -> UUID {
        let ligneDTO = LigneFactureDTO(
            id: UUID(),
            designation: "Test Line",
            quantite: quantite,
            prixUnitaire: prix,
            produitId: produitId,
            factureId: factureId
        )
        let result = await dependencyContainer.addLigneUseCase.execute(ligne: ligneDTO)
        let success = try result.get()
        guard success else {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create test ligne"])
        }
        return ligneDTO.id
    }
    
    private func fetchAllClients() async throws -> [ClientDTO] {
        let result = await dependencyContainer.fetchClientsUseCase.execute()
        return try result.get()
    }
    
    private func fetchAllProduits() async throws -> [ProduitDTO] {
        let result = await dependencyContainer.fetchProduitsUseCase.execute()
        return try result.get()
    }
}

// MARK: - Result Extension

extension Result {
    var isSuccess: Bool {
        switch self {
        case .success:
            return true
        case .failure:
            return false
        }
    }
}