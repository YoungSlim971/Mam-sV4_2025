
//
//  Persistence+Validation.swift
//  Facturation
//
//  Created by Gemini on 06/07/2025.
//

import Foundation
import SwiftData

extension PersistentModel {
    /**
     Vérifie si l'instance du modèle est toujours valide et existe dans le contexte de données.

     Cette vérification est cruciale dans les applications SwiftUI, en particulier sur macOS avec plusieurs fenêtres,
     pour éviter les crashs fatals de type "SwiftData/BackingData.swift:866: Fatal error".
     L'erreur se produit lorsqu'on tente d'accéder aux propriétés d'un objet qui a été supprimé
     du `modelContext` (par exemple, via une autre fenêtre, une tâche en arrière-plan ou une suppression en cascade).

     - Returns: `true` si le modèle a un `modelContext` et peut être retrouvé via son `persistentModelID`.
                `false` si le modèle a été invalidé ou supprimé.
    */
    var isValidModel: Bool {
        guard let context = self.modelContext else {
            // Si le contexte est nil, l'objet est soit en cours de création, soit détaché.
            // On le considère comme invalide car il n'est pas dans le store.
            return false
        }
        // Tente de récupérer l'objet dans le contexte en utilisant son ID persistant.
        // Si la récupération réussit (l'objet n'est pas nil), le modèle existe toujours.
        return context.model(for: self.persistentModelID) != nil
    }
}
