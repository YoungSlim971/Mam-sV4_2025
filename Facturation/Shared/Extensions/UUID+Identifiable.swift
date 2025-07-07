
import Foundation

// Rend UUID conforme à Identifiable pour pouvoir l'utiliser avec .sheet(item:), etc.
// Bien que cela soit inclus dans les versions récentes de Swift, l'ajouter explicitement
// garantit la compatibilité et résout les erreurs de compilation si le projet
// est configuré pour une version de Swift antérieure.
extension UUID: Identifiable {
    public var id: UUID { self }
}
