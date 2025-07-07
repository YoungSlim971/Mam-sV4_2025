import Foundation

enum FactureError: Error {
    case invalidClient
    case invalidTVA
}

struct CreerFactureUseCase {
    let repository: FactureRepository

    func execute(client: ClientModel, tva: Double = 20.0) throws -> FactureModel {
        // guard client.isValid else { throw FactureError.invalidClient } // TODO: Add validation
        guard tva >= 0 else { throw FactureError.invalidTVA }
        let numero = try repository.genererNumeroFacture()
        let facture = try repository.createFacture(client: client, numero: numero)
        facture.tva = tva
        return facture
    }
}
