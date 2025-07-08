import Foundation
import SwiftData
import Logging

// Note: We can't import the actual model classes here since they're in the main app
// This service will work with protocols or be initialized with the container

@MainActor
public final class PersistenceService: ObservableObject {
    private let logger = Logger(label: "com.facturation.datalayer.persistence")
    
    @Published public var modelContainer: ModelContainer
    @Published public var modelContext: ModelContext
    
    public init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        self.modelContext = modelContainer.mainContext
        logger.info("PersistenceService initialized with provided container")
    }
    
    /// Initialise le service de persistance avec un schéma donné
    public init<T: PersistentModel>(withSchema modelTypes: [T.Type]) throws {
        logger.info("Initializing PersistenceService with schema")
        
        do {
            let schema = Schema(modelTypes.map { $0.self as any PersistentModel.Type })
            
            // Configuration explicite pour la persistance sur disque
            let configuration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false
            )
            
            let container = try ModelContainer(for: schema, configurations: configuration)
            self.modelContainer = container
            self.modelContext = container.mainContext
            
            logger.info("Persistance SwiftData initialisée avec succès sur disque")
            
        } catch {
            logger.error("Erreur lors de l'initialisation de la persistance principale", metadata: ["error": "\(error)"])
            
            // Tentative avec configuration par défaut
            do {
                let schema = Schema(modelTypes.map { $0.self as any PersistentModel.Type })
                let container = try ModelContainer(for: schema)
                self.modelContainer = container
                self.modelContext = container.mainContext
                logger.warning("Utilisation de la configuration par défaut SwiftData")
                
            } catch {
                // Dernier recours: stockage en mémoire seulement
                do {
                    let schema = Schema(modelTypes.map { $0.self as any PersistentModel.Type })
                    let container = try ModelContainer(for: schema, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
                    self.modelContainer = container
                    self.modelContext = container.mainContext
                    logger.critical("ATTENTION: Utilisation du stockage en mémoire uniquement. Les données ne seront PAS persistées!")
                } catch {
                    logger.critical("Impossible d'initialiser SwiftData", metadata: ["error": "\(error)"])
                    throw DataLayerError.persistenceInitializationFailed(error.localizedDescription)
                }
            }
        }
    }
    
    public func resetContainer<T: PersistentModel>(withSchema modelTypes: [T.Type]) throws {
        logger.info("Resetting container")
        do {
            let schema = Schema(modelTypes.map { $0.self as any PersistentModel.Type })
            let newContainer = try ModelContainer(for: schema)
            
            self.modelContainer = newContainer
            self.modelContext = newContainer.mainContext
            logger.info("Container reset successfully")
        } catch {
            logger.error("Failed to reset ModelContainer", metadata: ["error": "\(error)"])
            throw DataLayerError.containerResetFailed(error.localizedDescription)
        }
    }

    public var container: ModelContainer {
        return modelContainer
    }
    
    /// Vérifie si la persistance sur disque est active ou si on utilise le stockage en mémoire
    public var isPersistenceActive: Bool {
        return !modelContainer.configurations.contains { config in
            config.isStoredInMemoryOnly
        }
    }
    
    /// Retourne le statut de persistance pour information
    public func getPersistenceStatus() -> String {
        if isPersistenceActive {
            return "✅ Persistance sur disque active - Données sauvegardées"
        } else {
            return "🔴 Stockage en mémoire seulement - Données perdues à la fermeture"
        }
    }
    
    /// Sauvegarde le contexte
    public func save() throws {
        do {
            try modelContext.save()
            logger.debug("Context saved successfully")
        } catch {
            logger.error("Failed to save context", metadata: ["error": "\(error)"])
            throw DataLayerError.dataSaveFailed(error.localizedDescription)
        }
    }
    
    /// Insert un modèle dans le contexte
    public func insert<T: PersistentModel>(_ model: T) {
        modelContext.insert(model)
        logger.debug("Model inserted", metadata: ["type": "\(type(of: model))"])
    }
    
    /// Supprime un modèle du contexte
    public func delete<T: PersistentModel>(_ model: T) {
        modelContext.delete(model)
        logger.debug("Model deleted", metadata: ["type": "\(type(of: model))"])
    }
    
    /// Fetch des modèles avec un descripteur
    public func fetch<T: PersistentModel>(_ descriptor: FetchDescriptor<T>) throws -> [T] {
        do {
            let results = try modelContext.fetch(descriptor)
            logger.debug("Fetched models", metadata: ["type": "\(T.self)", "count": "\(results.count)"])
            return results
        } catch {
            logger.error("Failed to fetch models", metadata: ["type": "\(T.self)", "error": "\(error)"])
            throw DataLayerError.dataFetchFailed(error.localizedDescription)
        }
    }
}