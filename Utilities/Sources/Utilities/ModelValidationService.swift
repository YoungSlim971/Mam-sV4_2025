import Foundation
import SwiftData
import Logging

/// Service centralisé pour valider que les modèles SwiftData ne sont pas invalidés
@MainActor
public final class ModelValidationService {
    
    public static let shared = ModelValidationService()
    private let logger = Logger(label: "com.facturation.utilities.model-validation")
    
    private init() {}
    
    // MARK: - Validation Methods
    
    /// Vérifie si un modèle SwiftData est encore valide (non supprimé/invalidé)
    public func isValid<T: PersistentModel>(_ model: T?) -> Bool {
        guard let model = model else { return false }
        
        do {
            // Tentative d'accès à une propriété de base pour détecter l'invalidation
            _ = model.persistentModelID
            return true
        } catch {
            logger.warning("Modèle invalidé détecté", metadata: ["type": "\(type(of: model))", "error": "\(error)"])
            return false
        }
    }
    
    /// Vérifie si une collection de modèles est valide
    public func areValid<T: PersistentModel>(_ models: [T]) -> Bool {
        return models.allSatisfy { isValid($0) }
    }
    
    /// Filtre une collection pour ne garder que les modèles valides
    public func filterValid<T: PersistentModel>(_ models: [T]) -> [T] {
        return models.filter { isValid($0) }
    }
    
    // MARK: - Safe Access Methods
    
    /// Accès sécurisé à une propriété d'un modèle
    public func safeAccess<T: PersistentModel, R>(_ model: T?, accessor: (T) -> R, fallback: R) -> R {
        guard let model = model, isValid(model) else {
            return fallback
        }
        
        do {
            return accessor(model)
        } catch {
            logger.warning("Erreur d'accès au modèle", metadata: ["error": "\(error)"])
            return fallback
        }
    }
    
    /// Accès sécurisé optionnel à une propriété d'un modèle
    public func safeAccess<T: PersistentModel, R>(_ model: T?, accessor: (T) -> R) -> R? {
        guard let model = model, isValid(model) else {
            return nil
        }
        
        do {
            return accessor(model)
        } catch {
            logger.warning("Erreur d'accès au modèle", metadata: ["error": "\(error)"])
            return nil
        }
    }
    
    // MARK: - Specific Model Validation
    
    /// Vérifie si un modèle de type PersistentModel est valide avec ses propriétés de base
    public func isValidModel<T: PersistentModel>(_ model: T?, requiredProperties: [(T) throws -> Any]) -> Bool {
        guard let model = model, isValid(model) else { return false }
        
        do {
            // Vérification des propriétés requises
            for propertyAccessor in requiredProperties {
                _ = try propertyAccessor(model)
            }
            return true
        } catch {
            logger.warning("Modèle invalidé lors de la vérification des propriétés", metadata: ["type": "\(type(of: model))", "error": "\(error)"])
            return false
        }
    }
}