import XCTest
@testable import Facturation
import DataLayer

@MainActor
final class StatisticsPerformanceTests: XCTestCase {
    
    var dataService: SecureDataService!
    var statistiquesRepository: SecureStatistiquesRepository!
    var clientRepository: SecureClientRepository!
    var factureRepository: SecureFactureRepository!
    
    override func setUp() {
        super.setUp()
        dataService = SecureDataService()
        statistiquesRepository = SecureStatistiquesRepository(dataService: dataService)
        clientRepository = SecureClientRepository(dataService: dataService)
        factureRepository = SecureFactureRepository(dataService: dataService)
    }
    
    override func tearDown() {
        dataService = nil
        statistiquesRepository = nil
        clientRepository = nil
        factureRepository = nil
        super.tearDown()
    }
    
    // MARK: - Data Setup Helpers
    
    private func createTestClients(count: Int) async -> [UUID] {
        var clientIds: [UUID] = []
        
        for i in 0..<count {
            let clientId = UUID()
            let client = ClientDTO(
                id: clientId,
                nom: "Client\(i)",
                entreprise: "Entreprise\(i)",
                email: "client\(i)@example.com",
                telephone: "012345678\(i % 10)",
                siret: "40483304800010", // SIRET valide
                numeroTVA: "FR00123456789",
                adresse: "Adresse \(i)",
                adresseRue: "Rue \(i)",
                adresseCodePostal: "1234\(i % 10)",
                adresseVille: "Ville\(i)",
                adressePays: "France"
            )
            
            _ = await clientRepository.addClient(client)
            clientIds.append(clientId)
        }
        
        return clientIds
    }
    
    private func createTestFactures(clientIds: [UUID], facturesPerClient: Int) async {
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())
        
        for clientId in clientIds {
            for i in 0..<facturesPerClient {
                // Créer des factures réparties sur l'année
                let month = (i % 12) + 1
                var dateComponents = DateComponents()
                dateComponents.year = currentYear
                dateComponents.month = month
                dateComponents.day = 15
                let factureDate = calendar.date(from: dateComponents) ?? Date()
                
                let factureId = UUID()
                let facture = FactureDTO(
                    id: factureId,
                    numero: "FAC\(String(format: "%04d", i))",
                    dateFacture: factureDate,
                    dateEcheance: Calendar.current.date(byAdding: .day, value: 30, to: factureDate),
                    datePaiement: i % 3 == 0 ? factureDate : nil, // 1/3 des factures payées
                    tva: 20.0,
                    conditionsPaiement: ConditionsPaiement.virement.rawValue,
                    remisePourcentage: 0.0,
                    statut: i % 3 == 0 ? StatutFacture.payee.rawValue : StatutFacture.envoyee.rawValue,
                    notes: "Facture test \(i)",
                    notesCommentaireFacture: nil,
                    clientId: clientId,
                    ligneIds: []
                )
                
                _ = await factureRepository.addFacture(facture)
                
                // Ajouter des lignes à chaque facture
                for j in 0..<3 { // 3 lignes par facture
                    let ligneId = UUID()
                    let ligne = LigneFactureDTO(
                        id: ligneId,
                        designation: "Produit \(j)",
                        quantite: Double(j + 1),
                        prixUnitaire: 100.0 + Double(j * 50),
                        referenceCommande: "REF-\(i)-\(j)",
                        dateCommande: factureDate,
                        produitId: nil,
                        factureId: factureId
                    )
                    
                    _ = await factureRepository.addLigne(ligne)
                }
            }
        }
    }
    
    // MARK: - Performance Tests
    
    func testBasicStatisticsPerformance() async {
        // Given - Create test data
        let clientIds = await createTestClients(count: 100)
        await createTestFactures(clientIds: clientIds, facturesPerClient: 10)
        
        // When & Then - Measure performance
        measure {
            let expectation = XCTestExpectation(description: "Statistics calculation")
            
            Task {
                let startTime = CFAbsoluteTimeGetCurrent()
                let stats = await statistiquesRepository.getStatistiques()
                let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
                
                // Verify results are reasonable
                XCTAssertGreaterThan(stats.totalCA, 0)
                XCTAssertGreaterThan(stats.totalFactures, 0)
                
                // Performance assertion - should complete in under 1 second
                XCTAssertLessThan(timeElapsed, 1.0, "Statistics calculation took too long: \(timeElapsed)s")
                
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 5.0)
        }
    }
    
    func testCAParMoisPerformance() async {
        // Given - Create test data
        let clientIds = await createTestClients(count: 50)
        await createTestFactures(clientIds: clientIds, facturesPerClient: 20)
        
        // When & Then - Measure performance
        measure {
            let expectation = XCTestExpectation(description: "CA par mois calculation")
            
            Task {
                let startTime = CFAbsoluteTimeGetCurrent()
                let currentYear = Calendar.current.component(.year, from: Date())
                let caParMois = await statistiquesRepository.getCAParMois(annee: currentYear)
                let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
                
                // Verify results
                XCTAssertEqual(caParMois.count, 12)
                XCTAssertGreaterThan(caParMois.reduce(0, +), 0)
                
                // Performance assertion - should complete in under 2 seconds
                XCTAssertLessThan(timeElapsed, 2.0, "CA par mois calculation took too long: \(timeElapsed)s")
                
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 10.0)
        }
    }
    
    func testFacturesParStatutPerformance() async {
        // Given - Create test data
        let clientIds = await createTestClients(count: 30)
        await createTestFactures(clientIds: clientIds, facturesPerClient: 15)
        
        // When & Then - Measure performance
        measure {
            let expectation = XCTestExpectation(description: "Factures par statut calculation")
            
            Task {
                let startTime = CFAbsoluteTimeGetCurrent()
                let facturesParStatut = await statistiquesRepository.getFacturesParStatut()
                let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
                
                // Verify results
                XCTAssertGreaterThan(facturesParStatut.count, 0)
                let totalFactures = facturesParStatut.values.reduce(0, +)
                XCTAssertGreaterThan(totalFactures, 0)
                
                // Performance assertion - should complete in under 1 second
                XCTAssertLessThan(timeElapsed, 1.0, "Factures par statut calculation took too long: \(timeElapsed)s")
                
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 5.0)
        }
    }
    
    func testStatistiquesParPeriodePerformance() async {
        // Given - Create test data
        let clientIds = await createTestClients(count: 25)
        await createTestFactures(clientIds: clientIds, facturesPerClient: 12)
        
        let calendar = Calendar.current
        let currentDate = Date()
        let startDate = calendar.date(byAdding: .month, value: -6, to: currentDate)!
        let endDate = currentDate
        
        // When & Then - Measure performance
        measure {
            let expectation = XCTestExpectation(description: "Statistiques par période calculation")
            
            Task {
                let startTime = CFAbsoluteTimeGetCurrent()
                let statsParPeriode = await statistiquesRepository.getStatistiquesParPeriode(
                    startDate: startDate,
                    endDate: endDate
                )
                let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
                
                // Verify results
                XCTAssertGreaterThanOrEqual(statsParPeriode.totalCA, 0)
                XCTAssertGreaterThanOrEqual(statsParPeriode.totalFactures, 0)
                
                // Performance assertion - should complete in under 1.5 seconds
                XCTAssertLessThan(timeElapsed, 1.5, "Statistiques par période calculation took too long: \(timeElapsed)s")
                
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 5.0)
        }
    }
    
    func testConcurrentStatisticsCalculation() async {
        // Given - Create test data
        let clientIds = await createTestClients(count: 20)
        await createTestFactures(clientIds: clientIds, facturesPerClient: 8)
        
        // When & Then - Test concurrent access
        measure {
            let expectation = XCTestExpectation(description: "Concurrent statistics calculation")
            expectation.expectedFulfillmentCount = 4
            
            let startTime = CFAbsoluteTimeGetCurrent()
            
            // Launch multiple concurrent statistics calculations
            Task {
                _ = await statistiquesRepository.getStatistiques()
                expectation.fulfill()
            }
            
            Task {
                let currentYear = Calendar.current.component(.year, from: Date())
                _ = await statistiquesRepository.getCAParMois(annee: currentYear)
                expectation.fulfill()
            }
            
            Task {
                _ = await statistiquesRepository.getFacturesParStatut()
                expectation.fulfill()
            }
            
            Task {
                let calendar = Calendar.current
                let startDate = calendar.date(byAdding: .month, value: -3, to: Date())!
                _ = await statistiquesRepository.getStatistiquesParPeriode(
                    startDate: startDate,
                    endDate: Date()
                )
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 10.0)
            
            let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
            
            // Performance assertion - concurrent operations should complete in reasonable time
            XCTAssertLessThan(timeElapsed, 5.0, "Concurrent statistics calculations took too long: \(timeElapsed)s")
        }
    }
    
    func testLargeDatasetPerformance() async {
        // Given - Create large dataset
        let clientIds = await createTestClients(count: 200)
        await createTestFactures(clientIds: clientIds, facturesPerClient: 25)
        
        // When & Then - Test with large dataset
        let expectation = XCTestExpectation(description: "Large dataset performance")
        
        Task {
            let startTime = CFAbsoluteTimeGetCurrent()
            
            // Test multiple operations
            async let statsResult = statistiquesRepository.getStatistiques()
            async let caResult = statistiquesRepository.getCAParMois(annee: Calendar.current.component(.year, from: Date()))
            async let statutResult = statistiquesRepository.getFacturesParStatut()
            
            let (stats, ca, statuts) = await (statsResult, caResult, statutResult)
            
            let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
            
            // Verify results with large dataset
            XCTAssertGreaterThan(stats.totalFactures, 4000) // 200 clients * 25 factures
            XCTAssertEqual(ca.count, 12)
            XCTAssertGreaterThan(statuts.count, 0)
            
            // Performance assertion - should handle large dataset in reasonable time
            XCTAssertLessThan(timeElapsed, 10.0, "Large dataset processing took too long: \(timeElapsed)s")
            
            print("Large dataset performance: \(timeElapsed)s for \(stats.totalFactures) factures")
            
            expectation.fulfill()
        }
        
        await fulfillment(of: [expectation], timeout: 30.0)
    }
    
    // MARK: - Memory Performance Tests
    
    func testMemoryUsageWithLargeDataset() async {
        // Given - Monitor memory before
        let memoryBefore = getMemoryUsage()
        
        // When - Create and process large dataset
        let clientIds = await createTestClients(count: 100)
        await createTestFactures(clientIds: clientIds, facturesPerClient: 50)
        
        _ = await statistiquesRepository.getStatistiques()
        let currentYear = Calendar.current.component(.year, from: Date())
        _ = await statistiquesRepository.getCAParMois(annee: currentYear)
        _ = await statistiquesRepository.getFacturesParStatut()
        
        // Then - Check memory usage
        let memoryAfter = getMemoryUsage()
        let memoryIncrease = memoryAfter - memoryBefore
        
        print("Memory usage increase: \(memoryIncrease) MB")
        
        // Memory should not increase excessively (less than 100MB for this test)
        XCTAssertLessThan(memoryIncrease, 100.0, "Memory usage increased too much: \(memoryIncrease) MB")
    }
    
    // MARK: - Helper Methods
    
    private func getMemoryUsage() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return Double(info.resident_size) / 1024.0 / 1024.0 // Convert to MB
        } else {
            return 0.0
        }
    }
}