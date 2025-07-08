import Foundation
import SwiftData

public protocol FactureRepository {
    func genererNumeroFacture(client: ClientModel) throws -> String
    func createFacture(client: ClientModel, numero: String) throws -> FactureModel
}