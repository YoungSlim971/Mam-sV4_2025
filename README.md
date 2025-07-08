# Facturation

## Project Overview & Key Features
Facturation is a macOS application for managing clients, invoices and products for the business **ExoTROPIC**. It uses SwiftUI for the interface and SwiftData for persistence. Key features include:

- CRUD management for clients, invoices and products
- PDF invoice generation with custom layouts
- Excel and PDF import for existing data
- Real‑time statistics with charts
- French localisation with TVA and SIRET compliance

## Requirements
- macOS 14.0 (Sonoma) or later
- Xcode 15.0 or later

## Build & Run
1. Open `Facturation.xcodeproj` in Xcode.
2. Select the **Facturation** scheme.
3. Build with **⌘B** and run with **⌘R**.

## Clean Architecture Layout
The project follows a Clean Architecture approach. The main layers are:

- **Models** – SwiftData entities representing the domain objects.
- **UseCases** – Business rules implemented as standalone operations.
- **Repositories** – Protocols and implementations that provide data access.
- **DTO** – Data transfer objects for import and export.
- **Services** – Utilities such as `DataService` and PDF/Excel importers.
- **Views** & **ViewModels** – SwiftUI screens and MVVM state holders.

Each layer depends only on the layers below it, making the codebase modular and testable.
