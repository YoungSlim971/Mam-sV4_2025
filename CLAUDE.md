# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a macOS invoicing application built with SwiftUI and SwiftData called "Facturation" (French for "Billing"). The app helps manage clients, invoices, products, and business information for a company named ExoTROPIC.

## Build & Development Commands

### Building the Project
- **Build**: `⌘ + B` in Xcode
- **Run**: `⌘ + R` in Xcode
- **Clean**: `⌘ + Shift + K` in Xcode

### Requirements
- macOS 14.0+ (Sonoma)
- Xcode 15.0+
- Swift 5.9+

### Dependencies
The project uses Swift Package Manager with these external dependencies:
- **CoreXLSX**: For Excel file import functionality  
- **XMLCoder**: XML parsing support for CoreXLSX
- **ZIPFoundation**: Archive handling for Excel files

## Architecture

### Core Pattern
- **Architecture**: Clean Architecture with MVVM pattern
- **UI Framework**: SwiftUI for macOS  
- **Data Layer**: SwiftData with Repository pattern
- **Business Logic**: Use Cases for domain operations
- **Data Transfer**: DTO pattern for import/export operations

### Architecture Layers

```
                    ┌─────────────────────────────────────────────────────────┐
                    │                  PRESENTATION LAYER                     │
                    │  ┌─────────────────┐  ┌─────────────────┐              │
                    │  │ SwiftUI Views   │  │ ViewModels      │              │
                    │  │ - SecureViews   │  │ - State Mgmt    │              │
                    │  │ - Components    │  │ - UI Logic      │              │
                    │  └─────────────────┘  └─────────────────┘              │
                    └─────────────────────────────────────────────────────────┘
                                            │
                    ┌─────────────────────────────────────────────────────────┐
                    │                   USE CASES LAYER                       │
                    │  ┌─────────────────┐  ┌─────────────────┐              │
                    │  │ Client UseCase  │  │ Facture UseCase │              │
                    │  │ - Add/Update    │  │ - Create/Update │              │
                    │  │ - Validation    │  │ - Line Items    │              │
                    │  └─────────────────┘  └─────────────────┘              │
                    │  ┌─────────────────┐  ┌─────────────────┐              │
                    │  │ Produit UseCase │  │ Stats UseCase   │              │
                    │  │ - CRUD Ops      │  │ - Analytics     │              │
                    │  │ - Search        │  │ - Reporting     │              │
                    │  └─────────────────┘  └─────────────────┘              │
                    └─────────────────────────────────────────────────────────┘
                                            │
                    ┌─────────────────────────────────────────────────────────┐
                    │                  REPOSITORY LAYER                       │
                    │  ┌─────────────────┐  ┌─────────────────┐              │
                    │  │ Protocols       │  │ Implementations │              │
                    │  │ - ClientRepo    │  │ - SecureRepos   │              │
                    │  │ - FactureRepo   │  │ - Error Handle  │              │
                    │  └─────────────────┘  └─────────────────┘              │
                    └─────────────────────────────────────────────────────────┘
                                            │
                    ┌─────────────────────────────────────────────────────────┐
                    │                    DATA LAYER                           │
                    │  ┌─────────────────┐  ┌─────────────────┐              │
                    │  │ SecureDataSvc   │  │ SwiftData       │              │
                    │  │ - Async/Await   │  │ - Models        │              │
                    │  │ - Error Handle  │  │ - Persistence   │              │
                    │  └─────────────────┘  └─────────────────┘              │
                    └─────────────────────────────────────────────────────────┘

    ┌─────────────────┐                                      ┌─────────────────┐
    │ DTOs            │  ←──── Cross-Cutting Concerns ────→  │ Validation      │
    │ - Data Transfer │                                       │ - SIRET/TVA     │
    │ - JSON Support  │                                       │ - Business Rule │
    │ - Security      │                                       │ - UI Validation │
    └─────────────────┘                                      └─────────────────┘
```

### Data Flow Diagram

```
User Input (SwiftUI View)
    ↓
Validation (Real-time + Submit)
    ↓
Use Case (Business Logic)
    ↓
Repository (Data Access Abstraction)
    ↓
SecureDataService (Data Processing)
    ↓
SwiftData (Persistence)
    ↓
DTO Conversion (Secure Data Transfer)
    ↓
Back to Presentation Layer
```

### Migration Status
The codebase is transitioning from legacy MVVM to Clean Architecture:
- **Current**: `DataService` (singleton) still handles legacy operations
- **New**: Use Cases and Repository pattern for new features
- **DTO Layer**: Implemented for JSON import/export operations

## Data Models

### Core Models (`Models/`)
- **`Facture`**: Invoice entity with status tracking, VAT calculations, and line items
- **`LigneFacture`**: Invoice line items with quantity, unit price, and product references  
- **`Client`**: Customer entity with contact info and address details
- **`Entreprise`**: Company settings and invoice numbering configuration
- **`Produit`**: Product catalog with pricing and descriptions
- **`Statistiques`**: Statistics and analytics data model

### Model Relationships
- `Facture` ↔ `Client` (many-to-one)
- `Facture` ↔ `LigneFacture` (one-to-many, cascade delete)
- `LigneFacture` ↔ `Produit` (many-to-one, optional)

### Important Enums
- `StatutFacture`: Invoice status (brouillon, envoyee, payee, EnRetard, annulee)
- `ConditionsPaiement`: Payment methods (virement, cheque, espece, carte)

### ViewModels (`ViewModels/`)
- **`EditableFacture`**: Editable wrapper for invoice editing
- **`EditableLigneFacture`**: Editable wrapper for invoice line items

### Data Transfer Objects (`DTO/`)
- **`FactureDTO`**: Data transfer object for invoice import/export with JSON support
- **`LigneFactureDTO`**: Data transfer object for invoice line items
- **`ClientDTO`**: Data transfer object for client data
- **`EntrepriseDTO`**: Data transfer object for company settings
- **`ProduitDTO`**: Data transfer object for product catalog

### Use Cases (`UseCases/`)
- **`CreerFactureUseCase`**: Business logic for creating new invoices
- **`AjouterLigneUseCase`**: Business logic for adding lines to invoices

### Repositories (`Domain/Repositories/`)
- **`FactureRepository`**: Protocol defining invoice data access operations
- **`FactureRepositorySwiftData`**: SwiftData implementation of invoice repository

## Data Service (`Services/DataService.swift`)

### Key Features
- **Singleton Pattern**: `DataService.shared`
- **Published Properties**: `@Published var clients, factures, produits`
- **Async/Await**: All CRUD operations are async
- **Resilient Init**: Handles SwiftData container failures with fallback to in-memory storage

### Common Operations
```swift
// Fetching data
await dataService.fetchClients()
await dataService.fetchFactures()

// CRUD operations
await dataService.addClient(client)
await dataService.updateFacture(facture)
await dataService.deleteClient(client)

// Utilities
let stats = dataService.getStatistiques()
let numero = await dataService.genererNumeroFacture()
```

## Modern Architecture Usage

### Clean Architecture Implementation

The application follows Clean Architecture principles with clear separation of concerns:

```
┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐
│ Presentation    │ │ Use Cases       │ │ Repositories    │ │ Data Layer      │
│ (SwiftUI Views) │─│ (Business Logic)│─│ (Data Access)   │─│ (SwiftData)     │
└─────────────────┘ └─────────────────┘ └─────────────────┘ └─────────────────┘
                              │                                         │
                    ┌─────────────────┐                     ┌─────────────────┐
                    │ DTOs            │                     │ Secure Services │
                    │ (Data Transfer) │                     │ (SecureDataSvc) │
                    └─────────────────┘                     └─────────────────┘
```

### Dependency Injection Pattern

The `DependencyContainer` manages all dependencies with lazy initialization:

```swift
// Initialize dependency container
let container = DependencyContainer.shared

// Use cases are automatically wired with repositories
let addClientUseCase = container.addClientUseCase
let fetchFacturesUseCase = container.fetchFacturesUseCase

// In SwiftUI views
@EnvironmentObject private var dependencyContainer: DependencyContainer

// Execute use cases with proper error handling
let result = await dependencyContainer.addClientUseCase.execute(
    nom: "Dupont",
    prenom: "Jean",
    entreprise: "ABC Corp",
    email: "jean@abc.com",
    telephone: "0123456789",
    adresse: "123 Rue Test",
    ville: "Paris",
    codePostal: "75001",
    pays: "France",
    siret: "40483304800010",
    numeroTVA: "FR00123456789"
)

switch result {
case .success(let clientId):
    // Handle success
case .failure(let error):
    // Handle error
}
```

### Use Cases Pattern

All business logic is encapsulated in Use Cases with Result-based error handling:

```swift
// Client operations
let fetchClientsUseCase = FetchClientsUseCase(repository: clientRepository)
let addClientUseCase = AddClientUseCase(repository: clientRepository)
let updateClientUseCase = UpdateClientUseCase(repository: clientRepository)
let deleteClientUseCase = DeleteClientUseCase(repository: clientRepository)

// Facture operations with automatic number generation
let createFactureUseCase = CreateFactureUseCase(repository: factureRepository)
let result = await createFactureUseCase.execute(clientId: clientId, tva: 20.0)

// Add lines to invoice
let addLigneUseCase = AddLigneUseCase(repository: factureRepository)
let ligneDTO = LigneFactureDTO(
    id: UUID(),
    designation: "Service Consulting",
    quantite: 2.0,
    prixUnitaire: 500.0,
    referenceCommande: "REF-001",
    dateCommande: Date(),
    produitId: nil,
    factureId: factureId
)
let ligneResult = await addLigneUseCase.execute(ligne: ligneDTO)

// Statistics and analytics
let getStatistiquesUseCase = GetStatistiquesUseCase(repository: statistiquesRepository)
let stats = await getStatistiquesUseCase.execute()
```

### Repository Pattern

Repositories provide abstraction over data access with secure implementations:

```swift
// Protocol-based repository definitions
protocol ClientRepository {
    func fetchClients() async -> [ClientDTO]
    func addClient(_ client: ClientDTO) async -> Bool
    func updateClient(_ client: ClientDTO) async -> Bool
    func deleteClient(id: UUID) async -> Bool
    func searchClients(searchText: String) async -> [ClientDTO]
}

// Secure implementations using SecureDataService
class SecureClientRepository: ClientRepository {
    private let dataService: SecureDataService
    
    init(dataService: SecureDataService = SecureDataService.shared) {
        self.dataService = dataService
    }
    
    func fetchClients() async -> [ClientDTO] {
        do {
            return try await dataService.fetchClients()
        } catch {
            print("Error fetching clients: \(error)")
            return []
        }
    }
}
```

### DTO Conversion and Secure Data Access

All data access uses DTOs for security and type safety:

```swift
// Export to JSON with DTOs
let clientDTO = ClientDTO(
    id: UUID(),
    nom: "Dupont",
    entreprise: "ABC Corp",
    email: "jean@abc.com",
    // ... other fields
)
let jsonData = try JSONEncoder().encode(clientDTO)

// Import from JSON
let clientDTO = try JSONDecoder().decode(ClientDTO.self, from: jsonData)

// Convert to SwiftData models only when necessary
let client = Client.fromDTO(clientDTO, context: context)

// Views work exclusively with DTOs for security
struct ClientListView: View {
    @State private var clients: [ClientDTO] = []
    
    var body: some View {
        List(clients, id: \.id) { client in
            ClientRowView(client: client)
        }
    }
}
```

### Validation Patterns

Comprehensive validation is implemented at multiple layers:

```swift
// Real-time field validation in views
@State private var emailError: String?

private func validateEmail() {
    let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
    if trimmedEmail.isEmpty {
        emailError = "L'email est requis"
    } else if !Validator.isValidEmail(trimmedEmail) {
        emailError = "Format d'email invalide"
    } else {
        emailError = nil
    }
}

// Business logic validation in Use Cases
class AddClientUseCase {
    func execute(nom: String, email: String, siret: String, numeroTVA: String) async -> Result<UUID, UseCaseError> {
        // Validate business rules
        guard !nom.isEmpty else {
            return .failure(.validationError("Le nom est requis"))
        }
        
        guard Validator.isValidEmail(email) else {
            return .failure(.validationError("Format d'email invalide"))
        }
        
        // Optional field validation
        if !siret.isEmpty && !Validator.isValidSIRET(siret) {
            return .failure(.validationError("SIRET invalide"))
        }
        
        if !numeroTVA.isEmpty && !Validator.isValidTVA(numeroTVA) {
            return .failure(.validationError("Numéro TVA invalide"))
        }
        
        // Proceed with business logic
        let clientDTO = ClientDTO(/* ... */)
        let success = await repository.addClient(clientDTO)
        
        return success ? .success(clientDTO.id) : .failure(.repositoryError("Échec de l'ajout"))
    }
}
```

## View Structure

### Main Views (`Views/`)
- **Dashboard**: Overview with statistics and recent activity (DashboardView/)
- **Clients**: Client management (list, add, edit, delete) (Client/)
- **Factures**: Invoice management with status filtering (FacturesView/)
- **Parametres**: Company settings and configuration (Parametres/)
- **Produits**: Product catalog management (Produits/)
- **Stats**: Charts and analytics (Stats/)
- **Developer**: Developer tools and debugging (Developer/)

### Navigation
- Modern sidebar-based navigation with `ModernContentView` as root
- Tab-based structure with enum `NavigationTab`

### Shared Components (`Shared/`)
- **Components/**: Reusable UI components (AppButton, AppCard, AppTextField, WindowManager)
- **Extensions/**: Utility extensions for common tasks

## Validation Patterns

The application implements comprehensive validation at multiple layers to ensure data integrity and user experience:

### Real-time UI Validation

Real-time validation provides immediate feedback to users as they type:

```swift
// Field-specific validation with error state management
@State private var emailError: String?
@State private var siretError: String?

// Real-time validation on field change
AppTextField("Email*", text: $email, errorMessage: emailError)
    .onChange(of: email) { _, _ in validateEmail() }

private func validateEmail() {
    let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
    if trimmedEmail.isEmpty {
        emailError = "L'email est requis"
    } else if !Validator.isValidEmail(trimmedEmail) {
        emailError = "Format d'email invalide"
    } else {
        emailError = nil
    }
}
```

### Comprehensive Form Validation

Complete form validation before submission:

```swift
var isFormValid: Bool {
    return validateAll() &&
           !nom.isEmpty && !prenom.isEmpty && !email.isEmpty && 
           !telephone.isEmpty && !adresse.isEmpty && !ville.isEmpty && 
           !codePostal.isEmpty
}

private func validateAll() -> Bool {
    validateNom()
    validatePrenom()
    validateEmail()
    validateTelephone()
    validateAdresse()
    validateVille()
    validateCodePostal()
    validateSiret()      // Optional field
    validateNumeroTVA()  // Optional field
    
    return nomError == nil && prenomError == nil && emailError == nil && 
           telephoneError == nil && adresseError == nil && villeError == nil && 
           codePostalError == nil && siretError == nil && numeroTVAError == nil
}
```

### Business Rule Validation

The `Validator` utility class implements French business validation rules:

```swift
// SIRET validation with Luhn algorithm
static func isValidSIRET(_ siret: String) -> Bool {
    let cleanedSiret = siret.filter(\.isWholeNumber)
    guard cleanedSiret.count == 14 else { return false }
    
    // Luhn algorithm for checksum validation
    let digits = cleanedSiret.compactMap { Int(String($0)) }
    var sum = 0
    
    for (index, digit) in digits.enumerated() {
        let multiplier = (index % 2 == 0) ? 1 : 2
        let product = digit * multiplier
        sum += (product > 9) ? (product - 9) : product
    }
    
    return sum % 10 == 0
}

// French TVA validation
static func isValidTVA(_ tva: String) -> Bool {
    let cleanedTVA = tva.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
    
    // Format: FR + 11 characters (letters or digits)
    guard cleanedTVA.hasPrefix("FR") && cleanedTVA.count == 13 else {
        return false
    }
    
    let identifier = String(cleanedTVA.dropFirst(2))
    return identifier.count == 11 && identifier.allSatisfy { $0.isLetter || $0.isWholeNumber }
}

// Email validation with regex
static func isValidEmail(_ email: String) -> Bool {
    let emailRegex = #"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"#
    return email.range(of: emailRegex, options: .regularExpression) != nil
}

// IBAN validation with Modulo 97 algorithm
static func isValidIBAN(_ iban: String) -> Bool {
    let cleanedIBAN = iban.replacingOccurrences(of: " ", with: "").uppercased()
    guard cleanedIBAN.count >= 15 && cleanedIBAN.count <= 34 else { return false }
    
    // Rearrange IBAN: move first 4 characters to end
    let rearranged = String(cleanedIBAN.dropFirst(4)) + String(cleanedIBAN.prefix(4))
    
    // Convert letters to numbers (A=10, B=11, ..., Z=35)
    let converted = rearranged.compactMap { char in
        if char.isLetter {
            return String(char.asciiValue! - 65 + 10)
        } else {
            return String(char)
        }
    }.joined()
    
    // Calculate modulo 97
    guard let number = Int(converted) else { return false }
    return number % 97 == 1
}
```

### Use Case Layer Validation

Business logic validation in Use Cases provides an additional security layer:

```swift
class AddClientUseCase {
    func execute(nom: String, email: String, siret: String, numeroTVA: String) async -> Result<UUID, UseCaseError> {
        // Validate required business rules
        guard !nom.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return .failure(.validationError("Le nom du client est requis"))
        }
        
        guard Validator.isValidEmail(email) else {
            return .failure(.validationError("L'adresse email n'est pas valide"))
        }
        
        // Validate optional fields only if provided
        if !siret.isEmpty {
            guard Validator.isValidSIRET(siret) else {
                return .failure(.validationError("Le numéro SIRET n'est pas valide"))
            }
        }
        
        if !numeroTVA.isEmpty {
            guard Validator.isValidTVA(numeroTVA) else {
                return .failure(.validationError("Le numéro de TVA n'est pas valide"))
            }
        }
        
        // Additional business validation
        let existingClients = await repository.fetchClients()
        if existingClients.contains(where: { $0.email.lowercased() == email.lowercased() }) {
            return .failure(.businessRuleError("Un client avec cette adresse email existe déjà"))
        }
        
        if !siret.isEmpty && existingClients.contains(where: { $0.siret == siret }) {
            return .failure(.businessRuleError("Un client avec ce numéro SIRET existe déjà"))
        }
        
        // Proceed with creation if all validations pass
        let clientDTO = ClientDTO(/* ... */)
        let success = await repository.addClient(clientDTO)
        
        return success ? .success(clientDTO.id) : .failure(.repositoryError("Impossible d'ajouter le client"))
    }
}
```

### Error Handling Patterns

Structured error handling with user-friendly messages:

```swift
enum UseCaseError: LocalizedError {
    case validationError(String)
    case businessRuleError(String)
    case repositoryError(String)
    case networkError(String)
    
    var errorDescription: String? {
        switch self {
        case .validationError(let message):
            return "Erreur de validation: \(message)"
        case .businessRuleError(let message):
            return "Règle métier: \(message)"
        case .repositoryError(let message):
            return "Erreur de données: \(message)"
        case .networkError(let message):
            return "Erreur réseau: \(message)"
        }
    }
}

// Error handling in views
switch result {
case .success(let clientId):
    // Handle success
case .failure(let error):
    errorMessage = error.localizedDescription
    showErrorAlert = true
}
```

### Testing Validation Patterns

Comprehensive validation testing ensures reliability:

```swift
// Unit tests for validation logic
func testSIRETValidation() {
    XCTAssertTrue(Validator.isValidSIRET("40483304800010"))  // Valid SIRET
    XCTAssertFalse(Validator.isValidSIRET("12345678901234")) // Invalid checksum
    XCTAssertFalse(Validator.isValidSIRET("123"))            // Too short
}

// UI validation tests
func testFormValidation_RequiredFields() {
    let validator = ClientFormValidator()
    let result = validator.validateAll(
        nom: "",        // Missing required field
        email: "invalid-email",  // Invalid format
        siret: "123"    // Invalid SIRET
    )
    
    XCTAssertFalse(result.isValid)
    XCTAssertTrue(result.errors.contains { $0.field == "nom" })
    XCTAssertTrue(result.errors.contains { $0.field == "email" })
    XCTAssertTrue(result.errors.contains { $0.field == "siret" })
}
```

## PDF Generation

The app includes comprehensive PDF generation capabilities using:
- **Core Graphics**: For custom PDF layouts
- **PDFKit**: For PDF handling and display
- **PDFService**: Handles PDF creation and formatting with advanced layout
- **PageLayoutCalculator**: Calculates optimal page layouts for invoices
- **InvoicePageContent**: Structures invoice content for PDF generation
- **ClientFacturesPDFView**: SwiftUI view for client-specific PDF generation

## Extensions & Utilities

### Extensions (`Extensions/`)
- **`MacOSColors.swift`**: macOS-specific color adaptations
- **`Extensions.swift`**: Double, Date, String formatting utilities
- **`Client+Extensions.swift`**: Client-specific computed properties and methods

### Key Utilities
- Euro currency formatting
- French date formatting
- Email/SIRET validation
- Address formatting helpers

## Testing

### Test Structure
- **`FacturationTests/`**: Contains unit tests
- **`ImportPDFTests.swift`**: PDF import functionality tests

### Running Tests
- Use `⌘ + U` in Xcode to run all tests
- Individual test methods can be run via Xcode test navigator
- **Test Target**: `FacturationTests` with PDF import testing capabilities

### Testing Infrastructure
- Tests use in-memory SwiftData containers for isolation
- PDF and Excel import functionality is thoroughly tested
- XCTest framework with Vision and PDFKit testing support

## Import/Export Features

### Supported Formats
- **Excel Import**: `ExcelImporter.swift` with CoreXLSX dependency for importing client and invoice data
- **PDF Import**: `PDFImporter.swift` for extracting invoice data from PDF documents using Vision framework
- **JSON Export**: Built-in export functionality for clients and invoices

### Additional Services
- **StatistiquesService**: Handles statistics calculations and data aggregation
- **DataService**: Centralized data management with async/await patterns

## Special Considerations

### SwiftData Gotchas
- Always insert entities into ModelContext before establishing relationships
- Use `@Relationship(inverse:)` for bidirectional relationships
- Handle container initialization failures gracefully
- **Resilient initialization**: DataService implements fallback to in-memory storage if persistent storage fails
- **Migration handling**: Automatic schema migration with error recovery

### macOS Specifics
- Window minimum size: 1200x800
- Uses native macOS UI patterns and colors
- Supports keyboard shortcuts and menu commands

### French Localization
- UI is primarily in French
- Handles French business requirements (SIRET, TVA, etc.)
- Uses European number formatting
- Company name: ExoTROPIC (default business entity)

## Development Notes

### Code Style
- Swift naming conventions throughout
- Extensive use of computed properties for derived values
- Async/await pattern for all data operations
- SwiftUI view composition with clear separation of concerns

### Error Handling
- Comprehensive error handling in DataService
- Fallback mechanisms for data persistence failures
- User-friendly error messages in French

## Current Project Status

### Key Features Implemented
- Complete CRUD operations for clients, invoices, and products
- Modern SwiftUI interface with macOS-specific adaptations
- Advanced PDF generation with custom layouts
- Excel/PDF import capabilities with Vision framework
- Comprehensive statistics and analytics
- Robust data persistence with SwiftData
- French business compliance (SIRET, TVA validation)

### External Dependencies
- **CoreXLSX**: For Excel file import functionality
- **XMLCoder**: XML parsing support for CoreXLSX
- **ZIPFoundation**: Archive handling for Excel files
- **Vision**: For PDF text extraction and processing (Apple framework)
- **PDFKit**: For PDF document handling (Apple framework)

### Asset Management
- Extensive sunset image collection (37 images in ViewModels/Assets.xcassets/Sunsets/)
- Complete app icon set with multiple resolutions
- Organized asset catalogs for maintainability

This codebase represents a complete, production-ready macOS invoicing application with robust data management, PDF generation, and import/export capabilities. The architecture is actively evolving from MVVM to Clean Architecture patterns for improved maintainability and testability.

## Development Guidelines

### Architecture Migration
- **New features**: Implement using Use Cases and Repository patterns
- **Legacy code**: Gradually migrate from DataService to new architecture
- **Testing**: Use Cases enable better unit testing with dependency injection
- **DTO usage**: Required for all JSON import/export operations

### Code Patterns
- Always insert SwiftData entities into ModelContext before establishing relationships
- Use DTOs for external data exchange, not for internal domain operations  
- Implement business logic in Use Cases, not in Views or Models
- Repository protocols enable testability and decoupling from SwiftData