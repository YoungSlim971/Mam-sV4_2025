import XCTest
import SwiftUI
import Utilities
@testable import Facturation
import DataLayer

@MainActor
final class FormValidationUITests: XCTestCase {
    
    var dataService: SecureDataService!
    var dependencyContainer: DependencyContainer!
    
    override func setUp() {
        super.setUp()
        dataService = SecureDataService()
        dependencyContainer = DependencyContainer(dataService: dataService)
    }
    
    override func tearDown() {
        dataService = nil
        dependencyContainer = nil
        super.tearDown()
    }
    
    // MARK: - Client Form Validation Tests
    
    func testClientFormValidation_RequiredFields() async {
        // Given - Create view model to test validation
        let viewModel = ClientFormValidator()
        
        // When - All fields are empty
        let result1 = viewModel.validateAll(
            nom: "",
            prenom: "",
            email: "",
            telephone: "",
            adresse: "",
            ville: "",
            codePostal: "",
            siret: "",
            numeroTVA: ""
        )
        
        // Then - Should have validation errors
        XCTAssertFalse(result1.isValid)
        XCTAssertEqual(result1.errors.count, 7) // 7 required fields
        XCTAssertTrue(result1.errors.contains { $0.field == "nom" && $0.message == "Le nom est requis" })
        XCTAssertTrue(result1.errors.contains { $0.field == "prenom" && $0.message == "Le prénom est requis" })
        XCTAssertTrue(result1.errors.contains { $0.field == "email" && $0.message == "L'email est requis" })
        XCTAssertTrue(result1.errors.contains { $0.field == "telephone" && $0.message == "Le téléphone est requis" })
        XCTAssertTrue(result1.errors.contains { $0.field == "adresse" && $0.message == "L'adresse est requise" })
        XCTAssertTrue(result1.errors.contains { $0.field == "ville" && $0.message == "La ville est requise" })
        XCTAssertTrue(result1.errors.contains { $0.field == "codePostal" && $0.message == "Le code postal est requis" })
    }
    
    func testClientFormValidation_ValidRequiredFields() async {
        // Given
        let viewModel = ClientFormValidator()
        
        // When - All required fields are valid
        let result = viewModel.validateAll(
            nom: "Dupont",
            prenom: "Jean",
            email: "jean.dupont@example.com",
            telephone: "0123456789",
            adresse: "123 Rue de la Paix",
            ville: "Paris",
            codePostal: "75001",
            siret: "",
            numeroTVA: ""
        )
        
        // Then - Should be valid
        XCTAssertTrue(result.isValid)
        XCTAssertEqual(result.errors.count, 0)
    }
    
    func testClientFormValidation_EmailFormat() async {
        // Given
        let viewModel = ClientFormValidator()
        
        // When - Invalid email formats
        let invalidEmails = [
            "invalid-email",
            "@example.com",
            "test@",
            "test.example.com",
            "test@.com",
            "test@example."
        ]
        
        for invalidEmail in invalidEmails {
            let result = viewModel.validateEmail(invalidEmail)
            
            // Then - Should be invalid
            XCTAssertFalse(result.isValid, "Email '\(invalidEmail)' should be invalid")
            XCTAssertEqual(result.message, "Format d'email invalide")
        }
        
        // When - Valid email formats
        let validEmails = [
            "test@example.com",
            "jean.dupont@company.fr",
            "user+tag@domain.co.uk",
            "123@456.org"
        ]
        
        for validEmail in validEmails {
            let result = viewModel.validateEmail(validEmail)
            
            // Then - Should be valid
            XCTAssertTrue(result.isValid, "Email '\(validEmail)' should be valid")
            XCTAssertNil(result.message)
        }
    }
    
    func testClientFormValidation_PhoneFormat() async {
        // Given
        let viewModel = ClientFormValidator()
        
        // When - Invalid phone numbers
        let invalidPhones = [
            "123",
            "abc123",
            "01 23",
            "12345"
        ]
        
        for invalidPhone in invalidPhones {
            let result = viewModel.validateTelephone(invalidPhone)
            
            // Then - Should be invalid
            XCTAssertFalse(result.isValid, "Phone '\(invalidPhone)' should be invalid")
            XCTAssertEqual(result.message, "Le numéro de téléphone doit contenir au moins 8 chiffres")
        }
        
        // When - Valid phone numbers
        let validPhones = [
            "0123456789",
            "01 23 45 67 89",
            "+33123456789",
            "0987654321"
        ]
        
        for validPhone in validPhones {
            let result = viewModel.validateTelephone(validPhone)
            
            // Then - Should be valid
            XCTAssertTrue(result.isValid, "Phone '\(validPhone)' should be valid")
            XCTAssertNil(result.message)
        }
    }
    
    func testClientFormValidation_CodePostalFormat() async {
        // Given
        let viewModel = ClientFormValidator()
        
        // When - Invalid postal codes
        let invalidCodes = [
            "123",
            "abcde",
            "123456",
            "1234a",
            ""
        ]
        
        for invalidCode in invalidCodes {
            let result = viewModel.validateCodePostal(invalidCode)
            
            // Then - Should be invalid
            XCTAssertFalse(result.isValid, "Postal code '\(invalidCode)' should be invalid")
            if invalidCode.isEmpty {
                XCTAssertEqual(result.message, "Le code postal est requis")
            } else {
                XCTAssertEqual(result.message, "Le code postal doit contenir 5 chiffres")
            }
        }
        
        // When - Valid postal codes
        let validCodes = ["75001", "69000", "13000", "59000"]
        
        for validCode in validCodes {
            let result = viewModel.validateCodePostal(validCode)
            
            // Then - Should be valid
            XCTAssertTrue(result.isValid, "Postal code '\(validCode)' should be valid")
            XCTAssertNil(result.message)
        }
    }
    
    func testClientFormValidation_SIRETFormat() async {
        // Given
        let viewModel = ClientFormValidator()
        
        // When - Invalid SIRET numbers
        let invalidSIRETs = [
            "123",
            "12345678901234", // Wrong check digit
            "abcd1234567890",
            "123456789012345" // Too long
        ]
        
        for invalidSIRET in invalidSIRETs {
            let result = viewModel.validateSiret(invalidSIRET)
            
            // Then - Should be invalid (unless empty)
            if !invalidSIRET.isEmpty {
                XCTAssertFalse(result.isValid, "SIRET '\(invalidSIRET)' should be invalid")
                XCTAssertEqual(result.message, "SIRET invalide (14 chiffres requis)")
            }
        }
        
        // When - Valid SIRET number
        let validSIRET = "40483304800010" // Valid SIRET with correct Luhn check
        let result = viewModel.validateSiret(validSIRET)
        
        // Then - Should be valid
        XCTAssertTrue(result.isValid, "SIRET '\(validSIRET)' should be valid")
        XCTAssertNil(result.message)
        
        // When - Empty SIRET (optional field)
        let emptyResult = viewModel.validateSiret("")
        XCTAssertTrue(emptyResult.isValid, "Empty SIRET should be valid (optional)")
        XCTAssertNil(emptyResult.message)
    }
    
    func testClientFormValidation_TVAFormat() async {
        // Given
        let viewModel = ClientFormValidator()
        
        // When - Invalid TVA numbers
        let invalidTVAs = [
            "123",
            "FR123", // Too short
            "DE12345678901", // Wrong country code for French validation
            "FR123456789012345" // Too long
        ]
        
        for invalidTVA in invalidTVAs {
            let result = viewModel.validateNumeroTVA(invalidTVA)
            
            // Then - Should be invalid (unless empty)
            if !invalidTVA.isEmpty {
                XCTAssertFalse(result.isValid, "TVA '\(invalidTVA)' should be invalid")
                XCTAssertEqual(result.message, "Numéro TVA invalide (format: FR + 11 caractères)")
            }
        }
        
        // When - Valid TVA numbers
        let validTVAs = [
            "FR12345678901",
            "FR00123456789"
        ]
        
        for validTVA in validTVAs {
            let result = viewModel.validateNumeroTVA(validTVA)
            
            // Then - Should be valid
            XCTAssertTrue(result.isValid, "TVA '\(validTVA)' should be valid")
            XCTAssertNil(result.message)
        }
        
        // When - Empty TVA (optional field)
        let emptyResult = viewModel.validateNumeroTVA("")
        XCTAssertTrue(emptyResult.isValid, "Empty TVA should be valid (optional)")
        XCTAssertNil(emptyResult.message)
    }
    
    // MARK: - Real-time Validation Tests
    
    func testRealTimeValidation_EmailField() async {
        // Given
        let viewModel = ClientFormValidator()
        
        // Simulate typing "jean.dupont@example.com"
        let typingSequence = [
            "j",
            "je",
            "jea",
            "jean",
            "jean.",
            "jean.d",
            "jean.du",
            "jean.dup",
            "jean.dupo",
            "jean.dupon",
            "jean.dupont",
            "jean.dupont@",
            "jean.dupont@e",
            "jean.dupont@ex",
            "jean.dupont@exa",
            "jean.dupont@exam",
            "jean.dupont@examp",
            "jean.dupont@exampl",
            "jean.dupont@example",
            "jean.dupont@example.",
            "jean.dupont@example.c",
            "jean.dupont@example.co",
            "jean.dupont@example.com"
        ]
        
        var validationResults: [Bool] = []
        
        // When - Validate each step
        for email in typingSequence {
            let result = viewModel.validateEmail(email)
            validationResults.append(result.isValid)
        }
        
        // Then - Only the final complete email should be valid
        let lastResult = validationResults.last!
        XCTAssertTrue(lastResult, "Complete email should be valid")
        
        // Most intermediate steps should be invalid
        let intermediateResults = Array(validationResults.dropLast())
        let invalidCount = intermediateResults.filter { !$0 }.count
        XCTAssertGreaterThan(invalidCount, 15, "Most intermediate email states should be invalid")
    }
    
    func testFormSubmission_WithInvalidData() async {
        // Given
        let viewModel = ClientFormValidator()
        
        // When - Try to submit with invalid data
        let result = viewModel.validateAll(
            nom: "",
            prenom: "Jean",
            email: "invalid-email",
            telephone: "123",
            adresse: "Test Address",
            ville: "Paris",
            codePostal: "1234", // Invalid
            siret: "123", // Invalid
            numeroTVA: "invalid" // Invalid
        )
        
        // Then - Should not be valid
        XCTAssertFalse(result.isValid)
        XCTAssertGreaterThan(result.errors.count, 0)
        
        // Verify specific errors
        XCTAssertTrue(result.errors.contains { $0.field == "nom" })
        XCTAssertTrue(result.errors.contains { $0.field == "email" })
        XCTAssertTrue(result.errors.contains { $0.field == "telephone" })
        XCTAssertTrue(result.errors.contains { $0.field == "codePostal" })
        XCTAssertTrue(result.errors.contains { $0.field == "siret" })
        XCTAssertTrue(result.errors.contains { $0.field == "numeroTVA" })
    }
    
    // MARK: - Integration Tests with UI State
    
    func testFormValidation_IntegrationWithUIState() async {
        // Given - Test data that simulates user input
        let testCases: [(input: ClientFormInput, expectedValid: Bool, description: String)] = [
            (
                input: ClientFormInput(
                    nom: "Dupont",
                    prenom: "Jean",
                    email: "jean.dupont@example.com",
                    telephone: "0123456789",
                    adresse: "123 Rue Test",
                    ville: "Paris",
                    codePostal: "75001",
                    siret: "",
                    numeroTVA: ""
                ),
                expectedValid: true,
                description: "Valid form with required fields only"
            ),
            (
                input: ClientFormInput(
                    nom: "Dupont",
                    prenom: "Jean",
                    email: "jean.dupont@example.com",
                    telephone: "0123456789",
                    adresse: "123 Rue Test",
                    ville: "Paris",
                    codePostal: "75001",
                    siret: "40483304800010",
                    numeroTVA: "FR00123456789"
                ),
                expectedValid: true,
                description: "Valid form with all fields including optional ones"
            ),
            (
                input: ClientFormInput(
                    nom: "",
                    prenom: "Jean",
                    email: "jean.dupont@example.com",
                    telephone: "0123456789",
                    adresse: "123 Rue Test",
                    ville: "Paris",
                    codePostal: "75001",
                    siret: "",
                    numeroTVA: ""
                ),
                expectedValid: false,
                description: "Invalid form - missing required nom"
            ),
            (
                input: ClientFormInput(
                    nom: "Dupont",
                    prenom: "Jean",
                    email: "invalid-email",
                    telephone: "0123456789",
                    adresse: "123 Rue Test",
                    ville: "Paris",
                    codePostal: "75001",
                    siret: "",
                    numeroTVA: ""
                ),
                expectedValid: false,
                description: "Invalid form - invalid email format"
            )
        ]
        
        let viewModel = ClientFormValidator()
        
        for testCase in testCases {
            // When
            let result = viewModel.validateAll(
                nom: testCase.input.nom,
                prenom: testCase.input.prenom,
                email: testCase.input.email,
                telephone: testCase.input.telephone,
                adresse: testCase.input.adresse,
                ville: testCase.input.ville,
                codePostal: testCase.input.codePostal,
                siret: testCase.input.siret,
                numeroTVA: testCase.input.numeroTVA
            )
            
            // Then
            XCTAssertEqual(result.isValid, testCase.expectedValid, testCase.description)
        }
    }
    
    // MARK: - Performance Tests for UI Validation
    
    func testFormValidation_Performance() async {
        // Given
        let viewModel = ClientFormValidator()
        let validInput = ClientFormInput(
            nom: "Dupont",
            prenom: "Jean",
            email: "jean.dupont@example.com",
            telephone: "0123456789",
            adresse: "123 Rue Test",
            ville: "Paris",
            codePostal: "75001",
            siret: "40483304800010",
            numeroTVA: "FR00123456789"
        )
        
        // When & Then - Measure performance of validation
        measure {
            for _ in 0..<1000 {
                _ = viewModel.validateAll(
                    nom: validInput.nom,
                    prenom: validInput.prenom,
                    email: validInput.email,
                    telephone: validInput.telephone,
                    adresse: validInput.adresse,
                    ville: validInput.ville,
                    codePostal: validInput.codePostal,
                    siret: validInput.siret,
                    numeroTVA: validInput.numeroTVA
                )
            }
        }
    }
}

// MARK: - Supporting Types

struct ClientFormInput {
    let nom: String
    let prenom: String
    let email: String
    let telephone: String
    let adresse: String
    let ville: String
    let codePostal: String
    let siret: String
    let numeroTVA: String
}

struct ValidationError {
    let field: String
    let message: String
}

struct ValidationResult {
    let isValid: Bool
    let errors: [ValidationError]
    let message: String?
    
    init(isValid: Bool, message: String? = nil) {
        self.isValid = isValid
        self.message = message
        self.errors = []
    }
    
    init(isValid: Bool, errors: [ValidationError]) {
        self.isValid = isValid
        self.errors = errors
        self.message = nil
    }
}

@MainActor
class ClientFormValidator: ObservableObject {
    
    func validateAll(nom: String, prenom: String, email: String, telephone: String, 
                    adresse: String, ville: String, codePostal: String, 
                    siret: String, numeroTVA: String) -> ValidationResult {
        
        var errors: [ValidationError] = []
        
        // Validate required fields
        if nom.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append(ValidationError(field: "nom", message: "Le nom est requis"))
        }
        
        if prenom.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append(ValidationError(field: "prenom", message: "Le prénom est requis"))
        }
        
        let emailResult = validateEmail(email)
        if !emailResult.isValid {
            errors.append(ValidationError(field: "email", message: emailResult.message ?? "Email invalide"))
        }
        
        let phoneResult = validateTelephone(telephone)
        if !phoneResult.isValid {
            errors.append(ValidationError(field: "telephone", message: phoneResult.message ?? "Téléphone invalide"))
        }
        
        if adresse.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append(ValidationError(field: "adresse", message: "L'adresse est requise"))
        }
        
        if ville.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append(ValidationError(field: "ville", message: "La ville est requise"))
        }
        
        let codePostalResult = validateCodePostal(codePostal)
        if !codePostalResult.isValid {
            errors.append(ValidationError(field: "codePostal", message: codePostalResult.message ?? "Code postal invalide"))
        }
        
        // Validate optional fields if provided
        let siretResult = validateSiret(siret)
        if !siretResult.isValid {
            errors.append(ValidationError(field: "siret", message: siretResult.message ?? "SIRET invalide"))
        }
        
        let tvaResult = validateNumeroTVA(numeroTVA)
        if !tvaResult.isValid {
            errors.append(ValidationError(field: "numeroTVA", message: tvaResult.message ?? "Numéro TVA invalide"))
        }
        
        return ValidationResult(isValid: errors.isEmpty, errors: errors)
    }
    
    func validateEmail(_ email: String) -> ValidationResult {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedEmail.isEmpty {
            return ValidationResult(isValid: false, message: "L'email est requis")
        }
        
        let emailRegex = #"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"#
        let isValid = trimmedEmail.range(of: emailRegex, options: .regularExpression) != nil
        
        return ValidationResult(isValid: isValid, message: isValid ? nil : "Format d'email invalide")
    }
    
    func validateTelephone(_ telephone: String) -> ValidationResult {
        let trimmedPhone = telephone.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedPhone.isEmpty {
            return ValidationResult(isValid: false, message: "Le téléphone est requis")
        }
        
        let digitCount = trimmedPhone.filter(\.isWholeNumber).count
        let isValid = digitCount >= 8
        
        return ValidationResult(isValid: isValid, message: isValid ? nil : "Le numéro de téléphone doit contenir au moins 8 chiffres")
    }
    
    func validateCodePostal(_ codePostal: String) -> ValidationResult {
        let trimmedCode = codePostal.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedCode.isEmpty {
            return ValidationResult(isValid: false, message: "Le code postal est requis")
        }
        
        let isValid = trimmedCode.count == 5 && trimmedCode.allSatisfy(\.isWholeNumber)
        
        return ValidationResult(isValid: isValid, message: isValid ? nil : "Le code postal doit contenir 5 chiffres")
    }
    
    func validateSiret(_ siret: String) -> ValidationResult {
        let trimmedSiret = siret.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // SIRET is optional, empty is valid
        if trimmedSiret.isEmpty {
            return ValidationResult(isValid: true)
        }
        
        let isValid = Validator.isValidSIRET(trimmedSiret)
        
        return ValidationResult(isValid: isValid, message: isValid ? nil : "SIRET invalide (14 chiffres requis)")
    }
    
    func validateNumeroTVA(_ numeroTVA: String) -> ValidationResult {
        let trimmedTVA = numeroTVA.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // TVA is optional, empty is valid
        if trimmedTVA.isEmpty {
            return ValidationResult(isValid: true)
        }
        
        let isValid = Validator.isValidTVA(trimmedTVA)
        
        return ValidationResult(isValid: isValid, message: isValid ? nil : "Numéro TVA invalide (format: FR + 11 caractères)")
    }
}