import Foundation
import DataLayer

/// Use case for getting general statistics with caching
@MainActor
final class GetStatistiquesUseCase {
    private let repository: StatistiquesRepository
    private let cacheService: StatistiquesCacheService
    
    init(repository: StatistiquesRepository, cacheService: StatistiquesCacheService = StatistiquesCacheService()) {
        self.repository = repository
        self.cacheService = cacheService
    }
    
    func execute() async -> Result<(totalCA: Double, facturesEnAttente: Int, facturesEnRetard: Int, totalFactures: Int), Error> {
        // Utilise le cache pour optimiser les performances
        return await cacheService.getCachedGeneralStatistics {
            do {
                let stats = await repository.getStatistiques()
                return .success(stats)
            } catch {
                return .failure(error)
            }
        }
    }
}

/// Use case for getting statistics by period
@MainActor
final class GetStatistiquesParPeriodeUseCase {
    private let repository: StatistiquesRepository
    
    init(repository: StatistiquesRepository) {
        self.repository = repository
    }
    
    func execute(startDate: Date, endDate: Date) async -> Result<(totalCA: Double, facturesEnAttente: Int, facturesEnRetard: Int, totalFactures: Int), Error> {
        do {
            let stats = await repository.getStatistiquesParPeriode(startDate: startDate, endDate: endDate)
            return .success(stats)
        } catch {
            return .failure(error)
        }
    }
}

/// Use case for getting statistics by client
@MainActor
final class GetStatistiquesParClientUseCase {
    private let repository: StatistiquesRepository
    
    init(repository: StatistiquesRepository) {
        self.repository = repository
    }
    
    func execute(clientId: UUID) async -> Result<(totalCA: Double, facturesEnAttente: Int, facturesEnRetard: Int, totalFactures: Int), Error> {
        do {
            let stats = await repository.getStatistiquesParClient(clientId: clientId)
            return .success(stats)
        } catch {
            return .failure(error)
        }
    }
}

/// Use case for getting monthly revenue
@MainActor
final class GetCAParMoisUseCase {
    private let repository: StatistiquesRepository
    
    init(repository: StatistiquesRepository) {
        self.repository = repository
    }
    
    func execute(annee: Int) async -> Result<[Double], Error> {
        do {
            let ca = await repository.getCAParMois(annee: annee)
            return .success(ca)
        } catch {
            return .failure(error)
        }
    }
}

/// Use case for getting invoice count by status
@MainActor
final class GetFacturesParStatutUseCase {
    private let repository: StatistiquesRepository
    
    init(repository: StatistiquesRepository) {
        self.repository = repository
    }
    
    func execute() async -> Result<[StatutFacture: Int], Error> {
        do {
            let stats = await repository.getFacturesParStatut()
            return .success(stats)
        } catch {
            return .failure(error)
        }
    }
}

/// Structure for product statistics result
public struct ProduitStatistiqueResult: Identifiable {
    public let id = UUID()
    public let produit: ProduitDTO
    public let quantiteVendue: Double
    public let chiffreAffaires: Double
    
    public init(produit: ProduitDTO, quantiteVendue: Double, chiffreAffaires: Double) {
        self.produit = produit
        self.quantiteVendue = quantiteVendue
        self.chiffreAffaires = chiffreAffaires
    }
}

/// Use case for getting product statistics with caching
@MainActor
final class GetStatistiquesProduitsUseCase {
    private let repository: StatistiquesRepository
    private let cacheService: StatistiquesCacheService
    
    init(repository: StatistiquesRepository, cacheService: StatistiquesCacheService = StatistiquesCacheService()) {
        self.repository = repository
        self.cacheService = cacheService
    }
    
    func execute(startDate: Date? = nil, endDate: Date? = nil) async -> Result<[ProduitStatistiqueResult], Error> {
        // Utilise le cache pour optimiser les performances
        return await cacheService.getCachedProduitStatistics(startDate: startDate, endDate: endDate) {
            do {
                // Utilisation de la vraie implémentation du repository
                let statistiques = await repository.getStatistiquesProduits(startDate: startDate, endDate: endDate)
                
                // Conversion en format attendu par le use case
                let results = statistiques.map { stat in
                    ProduitStatistiqueResult(
                        produit: stat.produit,
                        quantiteVendue: stat.quantiteVendue,
                        chiffreAffaires: stat.chiffreAffaires
                    )
                }
                
                return .success(results)
            } catch {
                return .failure(error)
            }
        }
    }
}

/// Structure for client statistics result
public struct ClientStatistiqueResult: Identifiable {
    public let id = UUID()
    public let client: ClientDTO
    public let chiffreAffaires: Double
    public let nombreFactures: Int
    
    public init(client: ClientDTO, chiffreAffaires: Double, nombreFactures: Int) {
        self.client = client
        self.chiffreAffaires = chiffreAffaires
        self.nombreFactures = nombreFactures
    }
}

/// Use case for getting client statistics with caching
@MainActor
final class GetStatistiquesClientsUseCase {
    private let repository: StatistiquesRepository
    private let cacheService: StatistiquesCacheService
    
    init(repository: StatistiquesRepository, cacheService: StatistiquesCacheService = StatistiquesCacheService()) {
        self.repository = repository
        self.cacheService = cacheService
    }
    
    func execute(startDate: Date? = nil, endDate: Date? = nil) async -> Result<[ClientStatistiqueResult], Error> {
        // Utilise le cache pour optimiser les performances
        return await cacheService.getCachedClientStatistics(startDate: startDate, endDate: endDate) {
            do {
                // Utilisation de la vraie implémentation du repository
                let statistiques = await repository.getStatistiquesClients(startDate: startDate, endDate: endDate)
                
                // Conversion en format attendu par le use case
                let results = statistiques.map { stat in
                    ClientStatistiqueResult(
                        client: stat.client,
                        chiffreAffaires: stat.chiffreAffaires,
                        nombreFactures: stat.nombreFactures
                    )
                }
                
                return .success(results)
            } catch {
                return .failure(error)
            }
        }
    }
}