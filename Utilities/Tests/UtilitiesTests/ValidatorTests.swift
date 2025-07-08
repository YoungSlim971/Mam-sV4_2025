import XCTest
@testable import Utilities

final class ValidatorTests: XCTestCase {

    func testValidSIRET() {
        // SIRET valide
        XCTAssertTrue(Validator.isValidSIRET("73282932000074"))
        
        // SIRET invalide - mauvaise longueur
        XCTAssertFalse(Validator.isValidSIRET("123456789"))
        
        // SIRET invalide - caractères non numériques
        XCTAssertFalse(Validator.isValidSIRET("7328293200007A"))
        
        // SIRET invalide - somme de contrôle incorrecte
        XCTAssertFalse(Validator.isValidSIRET("73282932000075"))
    }

    func testValidTVA() {
        // TVA française valide
        XCTAssertTrue(Validator.isValidTVA("FR23334175221"))
        
        // TVA avec espaces
        XCTAssertTrue(Validator.isValidTVA("FR 23 334175221"))
        
        // TVA invalide - mauvais format
        XCTAssertFalse(Validator.isValidTVA("DE123456789"))
        
        // TVA invalide - trop courte
        XCTAssertFalse(Validator.isValidTVA("FR123456"))
    }

    func testValidIBAN() {
        // IBAN français valide
        XCTAssertTrue(Validator.isValidIBAN("FR1420041010050500013M02606"))
        
        // IBAN avec espaces
        XCTAssertTrue(Validator.isValidIBAN("FR14 2004 1010 0505 0001 3M02 606"))
        
        // IBAN invalide - trop court
        XCTAssertFalse(Validator.isValidIBAN("FR14200410"))
        
        // IBAN invalide - checksum incorrect
        XCTAssertFalse(Validator.isValidIBAN("FR1520041010050500013M02606"))
    }

    func testValidTVARate() {
        // Taux valides
        XCTAssertTrue(Validator.isValidTVARate(0.0))
        XCTAssertTrue(Validator.isValidTVARate(2.1))
        XCTAssertTrue(Validator.isValidTVARate(5.5))
        XCTAssertTrue(Validator.isValidTVARate(10.0))
        XCTAssertTrue(Validator.isValidTVARate(20.0))
        
        // Taux invalides
        XCTAssertFalse(Validator.isValidTVARate(15.0))
        XCTAssertFalse(Validator.isValidTVARate(-5.0))
        XCTAssertFalse(Validator.isValidTVARate(25.0))
    }
}