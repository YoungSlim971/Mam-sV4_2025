import XCTest
import SwiftData
@testable import Facturation

@MainActor
final class ModelValidationServiceTests: XCTestCase {
    var container: ModelContainer!
    var context: ModelContext!
    let service = ModelValidationService.shared

    override func setUp() {
        let schema = Schema([
            ClientModel.self,
            EntrepriseModel.self,
            FactureModel.self,
            ProduitModel.self,
            LigneFacture.self
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        container = try! ModelContainer(for: schema, configurations: [config])
        context = container.mainContext
    }

    override func tearDown() {
        container = nil
        context = nil
    }

    func testIsValid() throws {
        let client = ClientModel()
        client.nom = "Test"
        context.insert(client)
        try context.save()

        XCTAssertTrue(service.isValid(client))

        context.delete(client)
        try context.save()

        XCTAssertFalse(service.isValid(client))
    }

    func testSafeAccess() throws {
        let client = ClientModel()
        client.nom = "Valid"
        context.insert(client)
        try context.save()

        let name = service.safeAccess(client, accessor: { $0.nom }, fallback: "none")
        XCTAssertEqual(name, "Valid")

        context.delete(client)
        try context.save()

        let fallback = service.safeAccess(client, accessor: { $0.nom }, fallback: "none")
        XCTAssertEqual(fallback, "none")
    }

    func testSafeAccessOptional() throws {
        let client = ClientModel()
        client.nom = "Valid"
        context.insert(client)
        try context.save()

        let name: String? = service.safeAccess(client, accessor: { $0.nom })
        XCTAssertEqual(name, "Valid")

        context.delete(client)
        try context.save()

        let nilName: String? = service.safeAccess(client, accessor: { $0.nom })
        XCTAssertNil(nilName)
    }

    func testSpecificModelValidation() throws {
        // Client
        let client = ClientModel()
        client.nom = "C"
        context.insert(client)

        // Produit
        let produit = ProduitModel(designation: "P", prixUnitaire: 1)
        context.insert(produit)

        // Facture with line
        let facture = FactureModel(client: client, numero: "F1")
        context.insert(facture)
        let ligne = LigneFacture(designation: "L", quantite: 1, prixUnitaire: 1)
        context.insert(ligne)
        ligne.facture = facture
        facture.lignes.append(ligne)
        try context.save()

        XCTAssertTrue(service.isValidClient(client))
        XCTAssertTrue(service.isValidProduit(produit))
        XCTAssertTrue(service.isValidLigne(ligne))
        XCTAssertTrue(service.isValidFacture(facture))

        // Delete and validate again
        context.delete(facture)
        context.delete(client)
        context.delete(produit)
        context.delete(ligne)
        try context.save()

        XCTAssertFalse(service.isValidClient(client))
        XCTAssertFalse(service.isValidProduit(produit))
        XCTAssertFalse(service.isValidLigne(ligne))
        XCTAssertFalse(service.isValidFacture(facture))
    }
}

