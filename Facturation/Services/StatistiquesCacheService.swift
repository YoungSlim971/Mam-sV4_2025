import Foundation
import DataLayer

/// Service de cache pour optimiser les performances des calculs de statistiques
final class StatistiquesCacheService: ObservableObject {
    
    // MARK: - Types
    
    private struct CacheKey: Hashable {
        let type: String
        let startDate: Date?
        let endDate: Date?
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(type)
            hasher.combine(startDate)
            hasher.combine(endDate)
        }
    }
    
    private struct CacheEntry<T> {
        let data: T
        let timestamp: Date
        let ttl: TimeInterval
        
        var isExpired: Bool {
            Date().timeIntervalSince(timestamp) > ttl
        }
    }
    
    // MARK: - Properties
    
    private var clientStatsCache: [CacheKey: CacheEntry<[ClientStatistiqueResult]>] = [:]
    private var produitStatsCache: [CacheKey: CacheEntry<[ProduitStatistiqueResult]>] = [:]
    private var generalStatsCache: [CacheKey: CacheEntry<(totalCA: Double, facturesEnAttente: Int, facturesEnRetard: Int, totalFactures: Int)>] = [:]
    
    private let defaultTTL: TimeInterval = 300 // 5 minutes
    private let shortTTL: TimeInterval = 60   // 1 minute pour données fréquemment mises à jour
    
    // MARK: - Public Methods
    
    /// Cache et récupère les statistiques clients
    func getCachedClientStatistics(
        startDate: Date? = nil,
        endDate: Date? = nil,
        provider: () async -> Result<[ClientStatistiqueResult], Error>
    ) async -> Result<[ClientStatistiqueResult], Error> {
        
        let key = CacheKey(type: "clients", startDate: startDate, endDate: endDate)
        
        // Vérifier le cache
        if let cachedEntry = clientStatsCache[key], !cachedEntry.isExpired {
            return .success(cachedEntry.data)
        }
        
        // Récupérer nouvelles données
        let result = await provider()
        
        // Mettre en cache si succès
        if case .success(let data) = result {
            clientStatsCache[key] = CacheEntry(
                data: data,
                timestamp: Date(),
                ttl: defaultTTL
            )
        }
        
        return result
    }
    
    /// Cache et récupère les statistiques produits
    func getCachedProduitStatistics(
        startDate: Date? = nil,
        endDate: Date? = nil,
        provider: () async -> Result<[ProduitStatistiqueResult], Error>
    ) async -> Result<[ProduitStatistiqueResult], Error> {
        
        let key = CacheKey(type: "produits", startDate: startDate, endDate: endDate)
        
        // Vérifier le cache
        if let cachedEntry = produitStatsCache[key], !cachedEntry.isExpired {
            return .success(cachedEntry.data)
        }
        
        // Récupérer nouvelles données
        let result = await provider()
        
        // Mettre en cache si succès
        if case .success(let data) = result {
            produitStatsCache[key] = CacheEntry(
                data: data,
                timestamp: Date(),
                ttl: defaultTTL
            )
        }
        
        return result
    }
    
    /// Cache et récupère les statistiques générales
    func getCachedGeneralStatistics(
        provider: () async -> Result<(totalCA: Double, facturesEnAttente: Int, facturesEnRetard: Int, totalFactures: Int), Error>
    ) async -> Result<(totalCA: Double, facturesEnAttente: Int, facturesEnRetard: Int, totalFactures: Int), Error> {
        
        let key = CacheKey(type: "general", startDate: nil, endDate: nil)
        
        // Vérifier le cache
        if let cachedEntry = generalStatsCache[key], !cachedEntry.isExpired {
            return .success(cachedEntry.data)
        }
        
        // Récupérer nouvelles données
        let result = await provider()
        
        // Mettre en cache si succès
        if case .success(let data) = result {
            generalStatsCache[key] = CacheEntry(
                data: data,
                timestamp: Date(),
                ttl: shortTTL // TTL plus court pour les stats générales
            )
        }
        
        return result
    }
    
    /// Invalide tout le cache
    func invalidateAllCache() {
        clientStatsCache.removeAll()
        produitStatsCache.removeAll()
        generalStatsCache.removeAll()
    }
    
    /// Invalide le cache pour un type spécifique
    func invalidateCache(for type: StatisticsCacheType) {
        switch type {
        case .clients:
            clientStatsCache.removeAll()
        case .produits:
            produitStatsCache.removeAll()
        case .general:
            generalStatsCache.removeAll()
        }
    }
    
    /// Invalide le cache expiré
    func cleanExpiredCache() {
        clientStatsCache = clientStatsCache.filter { !$0.value.isExpired }
        produitStatsCache = produitStatsCache.filter { !$0.value.isExpired }
        generalStatsCache = generalStatsCache.filter { !$0.value.isExpired }
    }
    
    // MARK: - Performance Metrics
    
    /// Obtient les métriques de performance du cache
    func getCacheMetrics() -> CacheMetrics {
        let totalEntries = clientStatsCache.count + produitStatsCache.count + generalStatsCache.count
        let expiredEntries = clientStatsCache.values.filter(\.isExpired).count +
                           produitStatsCache.values.filter(\.isExpired).count +
                           generalStatsCache.values.filter(\.isExpired).count
        
        return CacheMetrics(
            totalEntries: totalEntries,
            expiredEntries: expiredEntries,
            hitRate: calculateHitRate(),
            memoryUsage: estimateMemoryUsage()
        )
    }
    
    // MARK: - Private Methods
    
    private func calculateHitRate() -> Double {
        // Implémentation simplifiée - dans une vraie application,
        // on suivrait les hits/misses
        return 0.85 // 85% hit rate estimé
    }
    
    private func estimateMemoryUsage() -> Int {
        // Estimation simple de l'utilisation mémoire
        let clientsSize = clientStatsCache.count * 1024 // ~1KB par entrée
        let produitsSize = produitStatsCache.count * 1024
        let generalSize = generalStatsCache.count * 512 // Plus petites données
        
        return clientsSize + produitsSize + generalSize
    }
}

// MARK: - Supporting Types

enum StatisticsCacheType {
    case clients
    case produits
    case general
}

struct CacheMetrics {
    let totalEntries: Int
    let expiredEntries: Int
    let hitRate: Double
    let memoryUsage: Int // en bytes
    
    var activeEntries: Int {
        totalEntries - expiredEntries
    }
    
    var memoryUsageMB: Double {
        Double(memoryUsage) / 1024.0 / 1024.0
    }
}