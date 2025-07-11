import XCTest
import Utilities
@testable import Facturation

final class ValidatorTests: XCTestCase {

    func testIsValidSIRET() {
        // Valid SIRETs
        XCTAssertTrue(Validator.isValidSIRET("40483304800010"))
        XCTAssertTrue(Validator.isValidSIRET("35600000000000")) // Example with many zeros
        XCTAssertTrue(Validator.isValidSIRET("12345678901239")) // Another valid example

        // Invalid SIRETs
        XCTAssertFalse(Validator.isValidSIRET("12345678901234")) // Invalid Luhn
        XCTAssertFalse(Validator.isValidSIRET("1234567890123"))  // Too short
        XCTAssertFalse(Validator.isValidSIRET("123456789012345")) // Too long
        XCTAssertFalse(Validator.isValidSIRET("ABCDEFGHIJKLMN")) // Non-numeric
        XCTAssertFalse(Validator.isValidSIRET(""))             // Empty
        XCTAssertFalse(Validator.isValidSIRET(" "))            // Whitespace
        XCTAssertFalse(Validator.isValidSIRET("404 833 048 00010")) // With spaces (should be cleaned)
    }

    func testIsValidTVA() {
        // Valid TVAs (French format FR + 2 chars + 9 digits)
        XCTAssertTrue(Validator.isValidTVA("FR00123456789"))
        XCTAssertTrue(Validator.isValidTVA("FRAB123456789"))
        XCTAssertTrue(Validator.isValidTVA("FRXX123456789"))
        XCTAssertTrue(Validator.isValidTVA("FR 00 123456789")) // With spaces (should be cleaned)

        // Invalid TVAs
        XCTAssertFalse(Validator.isValidTVA("FR123456789"))   // Too short (missing 2 chars)
        XCTAssertFalse(Validator.isValidTVA("FR0012345678"))  // Too short (missing 1 digit)
        XCTAssertFalse(Validator.isValidTVA("FR001234567890")) // Too long
        XCTAssertFalse(Validator.isValidTVA("GB12345678901")) // Wrong country code
        XCTAssertFalse(Validator.isValidTVA("FR00ABCDEFGHI")) // Invalid characters
        XCTAssertFalse(Validator.isValidTVA(""))              // Empty
        XCTAssertFalse(Validator.isValidTVA(" "))             // Whitespace
    }

    func testIsValidIBAN() {
        // Valid IBANs (examples from various countries)
        XCTAssertTrue(Validator.isValidIBAN("FR1420041010050500013M02606")) // France
        XCTAssertTrue(Validator.isValidIBAN("DE89370400440532013000")) // Germany
        XCTAssertTrue(Validator.isValidIBAN("GB33BUKB20201530012345")) // UK
        XCTAssertTrue(Validator.isValidIBAN("NL91ABNA0417164300")) // Netherlands
        XCTAssertTrue(Validator.isValidIBAN("BE68539007547034")) // Belgium
        XCTAssertTrue(Validator.isValidIBAN("FR 14 2004 1010 0505 0001 3M02 606")) // With spaces (should be cleaned)

        // Invalid IBANs
        XCTAssertFalse(Validator.isValidIBAN("FR1420041010050500013M02607")) // Invalid checksum
        XCTAssertFalse(Validator.isValidIBAN("FR1420041010050500013M0260"))  // Too short
        XCTAssertFalse(Validator.isValidIBAN("FR1420041010050500013M026060")) // Too long
        XCTAssertFalse(Validator.isValidIBAN("XX1420041010050500013M02606")) // Invalid country code
        XCTAssertFalse(Validator.isValidIBAN("FR1420041010050500013M0260G")) // Invalid character
        XCTAssertFalse(Validator.isValidIBAN(""))              // Empty
        XCTAssertFalse(Validator.isValidIBAN(" "))             // Whitespace
    }

}
