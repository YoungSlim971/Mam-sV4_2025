import Foundation
import DataLayer

/// Dependency injection container for managing repositories and use cases
@MainActor
final class DependencyContainer: ObservableObject {
    
    // MARK: - Services
    private let cacheService: StatistiquesCacheService
    
    // MARK: - Repositories
    private let clientRepository: ClientRepository
    private let factureRepository: FactureRepository
    private let produitRepository: ProduitRepository
    private let entrepriseRepository: EntrepriseRepository
    let statistiquesRepository: StatistiquesRepository // Exposé pour les tests
    
    // MARK: - Client Use Cases
    lazy var fetchClientsUseCase = FetchClientsUseCase(repository: clientRepository)
    lazy var addClientUseCase = AddClientUseCase(repository: clientRepository)
    lazy var updateClientUseCase = UpdateClientUseCase(repository: clientRepository)
    lazy var deleteClientUseCase = DeleteClientUseCase(repository: clientRepository)
    lazy var searchClientsUseCase = SearchClientsUseCase(repository: clientRepository)
    lazy var getClientUseCase = GetClientUseCase(repository: clientRepository)
    
    // MARK: - Facture Use Cases
    lazy var fetchFacturesUseCase = FetchFacturesUseCase(repository: factureRepository)
    lazy var createFactureUseCase = CreateFactureUseCase(repository: factureRepository)
    lazy var updateFactureUseCase = UpdateFactureUseCase(repository: factureRepository)
    lazy var deleteFactureUseCase = DeleteFactureUseCase(repository: factureRepository)
    lazy var searchFacturesUseCase = SearchFacturesUseCase(repository: factureRepository)
    lazy var getFacturesByStatusUseCase = GetFacturesByStatusUseCase(repository: factureRepository)
    lazy var getFacturesByDateRangeUseCase = GetFacturesByDateRangeUseCase(repository: factureRepository)
    lazy var getFacturesForClientUseCase = GetFacturesForClientUseCase(repository: factureRepository)
    lazy var getFactureUseCase = GetFactureUseCase(repository: factureRepository)
    
    // MARK: - Produit Use Cases
    lazy var fetchProduitsUseCase = FetchProduitsUseCase(repository: produitRepository)
    lazy var addProduitUseCase = AddProduitUseCase(repository: produitRepository)
    lazy var updateProduitUseCase = UpdateProduitUseCase(repository: produitRepository)
    lazy var deleteProduitUseCase = DeleteProduitUseCase(repository: produitRepository)
    lazy var searchProduitsUseCase = SearchProduitsUseCase(repository: produitRepository)
    lazy var getProduitUseCase = GetProduitUseCase(repository: produitRepository)
    
    // MARK: - Entreprise Use Cases
    lazy var fetchEntrepriseUseCase = FetchEntrepriseUseCase(repository: entrepriseRepository)
    lazy var updateEntrepriseUseCase = UpdateEntrepriseUseCase(repository: entrepriseRepository)
    lazy var createEntrepriseUseCase = CreateEntrepriseUseCase(repository: entrepriseRepository)
    lazy var getEntrepriseUseCase = GetEntrepriseUseCase(repository: entrepriseRepository)
    
    // MARK: - Ligne Facture Use Cases
    lazy var fetchLignesUseCase = FetchLignesUseCase(repository: factureRepository)
    lazy var addLigneUseCase = AddLigneUseCase(repository: factureRepository)
    lazy var updateLigneUseCase = UpdateLigneUseCase(repository: factureRepository)
    lazy var deleteLigneUseCase = DeleteLigneUseCase(repository: factureRepository)
    
    // MARK: - Statistiques Use Cases
    lazy var getStatistiquesUseCase = GetStatistiquesUseCase(repository: statistiquesRepository, cacheService: cacheService)
    lazy var getStatistiquesParPeriodeUseCase = GetStatistiquesParPeriodeUseCase(repository: statistiquesRepository)
    lazy var getStatistiquesParClientUseCase = GetStatistiquesParClientUseCase(repository: statistiquesRepository)
    lazy var getCAParMoisUseCase = GetCAParMoisUseCase(repository: statistiquesRepository)
    lazy var getFacturesParStatutUseCase = GetFacturesParStatutUseCase(repository: statistiquesRepository)
    lazy var getStatistiquesProduitsUseCase = GetStatistiquesProduitsUseCase(repository: statistiquesRepository, cacheService: cacheService)
    lazy var getStatistiquesClientsUseCase = GetStatistiquesClientsUseCase(repository: statistiquesRepository, cacheService: cacheService)
    
    // MARK: - Legacy Use Cases (for backward compatibility)
    // Removed legacy use cases that conflict with new architecture
    
    // MARK: - Initialization
    init(dataService: SecureDataService = SecureDataService.shared) {
        self.cacheService = StatistiquesCacheService()
        self.clientRepository = SecureClientRepository(dataService: dataService)
        self.factureRepository = SecureFactureRepository(dataService: dataService)
        self.produitRepository = SecureProduitRepository(dataService: dataService)
        self.entrepriseRepository = SecureEntrepriseRepository(dataService: dataService)
        self.statistiquesRepository = SecureStatistiquesRepository(dataService: dataService)
    }
    
    // MARK: - Cache Management
    
    /// Invalide le cache des statistiques
    func invalidateStatisticsCache() {
        cacheService.invalidateAllCache()
    }
    
    /// Invalide le cache spécifique à un type de statistiques
    func invalidateCache(for type: StatisticsCacheType) {
        cacheService.invalidateCache(for: type)
    }
    
    /// Nettoie le cache expiré
    func cleanExpiredCache() {
        cacheService.cleanExpiredCache()
    }
    
    /// Obtient les métriques de performance du cache
    func getCacheMetrics() -> CacheMetrics {
        return cacheService.getCacheMetrics()
    }
    
    // MARK: - Shared Instance
    static let shared = DependencyContainer()
}