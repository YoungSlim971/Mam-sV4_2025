import Foundation
import SwiftData

/// Service centralisé pour valider que les modèles SwiftData ne sont pas invalidés
@MainActor
final class ModelValidationService {
    
    static let shared = ModelValidationService()
    
    private init() {}
    
    // MARK: - Validation Methods
    
    /// Vérifie si un modèle SwiftData est encore valide (non supprimé/invalidé)
    func isValid<T: PersistentModel>(_ model: T?) -> Bool {
        guard let model = model else { return false }
        
        do {
            // Tentative d'accès à une propriété de base pour détecter l'invalidation
            _ = model.persistentModelID
            return true
        } catch {
            print("⚠️ Modèle invalidé détecté: \(type(of: model)) - \(error)")
            return false
        }
    }
    
    /// Vérifie si une collection de modèles est valide
    func areValid<T: PersistentModel>(_ models: [T]) -> Bool {
        return models.allSatisfy { isValid($0) }
    }
    
    /// Filtre une collection pour ne garder que les modèles valides
    func filterValid<T: PersistentModel>(_ models: [T]) -> [T] {
        return models.filter { isValid($0) }
    }
    
    // MARK: - Safe Access Methods
    
    /// Accès sécurisé à une propriété d'un modèle
    func safeAccess<T: PersistentModel, R>(_ model: T?, accessor: (T) -> R, fallback: R) -> R {
        guard let model = model, isValid(model) else {
            return fallback
        }
        
        do {
            return accessor(model)
        } catch {
            print("⚠️ Erreur d'accès au modèle: \(error)")
            return fallback
        }
    }
    
    /// Accès sécurisé optionnel à une propriété d'un modèle
    func safeAccess<T: PersistentModel, R>(_ model: T?, accessor: (T) -> R) -> R? {
        guard let model = model, isValid(model) else {
            return nil
        }
        
        do {
            return accessor(model)
        } catch {
            print("⚠️ Erreur d'accès au modèle: \(error)")
            return nil
        }
    }
    
    // MARK: - Specific Model Validation
    
    /// Vérifie si un FactureModel est valide et a ses relations intactes
    func isValidFacture(_ facture: FactureModel?) -> Bool {
        guard let facture = facture, isValid(facture) else { return false }
        
        do {
            // Vérification des propriétés critiques
            _ = facture.id
            _ = facture.numero
            _ = facture.dateFacture
            
            // Vérification de la relation client si elle existe
            if let client = facture.client {
                _ = client.id
            }
            
            // Vérification des lignes
            for ligne in facture.lignes {
                _ = ligne.id
            }
            
            return true
        } catch {
            print("⚠️ FactureModel invalidé: \(error)")
            return false
        }
    }
    
    /// Vérifie si un ClientModel est valide
    func isValidClient(_ client: ClientModel?) -> Bool {
        guard let client = client, isValid(client) else { return false }
        
        do {
            _ = client.id
            _ = client.nom
            return true
        } catch {
            print("⚠️ ClientModel invalidé: \(error)")
            return false
        }
    }
    
    /// Vérifie si un ProduitModel est valide
    func isValidProduit(_ produit: ProduitModel?) -> Bool {
        guard let produit = produit, isValid(produit) else { return false }
        
        do {
            _ = produit.id
            _ = produit.designation
            return true
        } catch {
            print("⚠️ ProduitModel invalidé: \(error)")
            return false
        }
    }
    
    /// Vérifie si une LigneFacture est valide
    func isValidLigne(_ ligne: LigneFacture?) -> Bool {
        guard let ligne = ligne, isValid(ligne) else { return false }
        
        do {
            _ = ligne.id
            _ = ligne.designation
            return true
        } catch {
            print("⚠️ LigneFacture invalidé: \(error)")
            return false
        }
    }
}

