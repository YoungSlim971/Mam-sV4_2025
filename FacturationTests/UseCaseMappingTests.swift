import XCTest
@testable import Facturation

final class UseCaseMappingTests: XCTestCase {
    var container: ModelContainer!
    var repository: FactureRepositorySwiftData!
    var creerFacture: CreerFactureUseCase!
    var ajouterLigne: AjouterLigneUseCase!

    @MainActor override func setUp() {
        let schema = Schema([Facture.self, LigneFacture.self, Client.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        container = try! ModelContainer(for: schema, configurations: [config])
        repository = FactureRepositorySwiftData(context: container.mainContext)
        creerFacture = CreerFactureUseCase(repository: repository)
        ajouterLigne = AjouterLigneUseCase(repository: repository)
    }

    @MainActor func testCreerFactureUseCase() throws {
        let client = Client()
        client.nom = "Test"
        let facture = try creerFacture.execute(client: client)
        XCTAssertEqual(facture.client?.nom, "Test")
        XCTAssertEqual(facture.lignes.count, 0)
    }

    @MainActor func testAjouterLigneUseCase() throws {
        let client = Client()
        let facture = try creerFacture.execute(client: client)
        let ligne = try ajouterLigne.execute(facture: facture, designation: "Prod", quantite: 2, prixUnitaire: 5)
        XCTAssertEqual(facture.lignes.count, 1)
        XCTAssertEqual(ligne.total, 10)
    }

    @MainActor func testFactureDTOMapping() throws {
        let client = Client()
        client.nom = "T"
        let facture = try creerFacture.execute(client: client)
        _ = try ajouterLigne.execute(facture: facture, designation: "X", quantite: 1, prixUnitaire: 3)
        let dto = facture.toDTO()
        let context = container.mainContext
        let mapped = Facture.fromDTO(dto, context: context, client: client)
        XCTAssertEqual(mapped.numero, facture.numero)
        XCTAssertEqual(mapped.lignes.count, facture.lignes.count)
    }
}
