# Guide d'Architecture Sécurisée - Facturation App

## Vue d'ensemble

Cette application utilise maintenant une architecture Clean Architecture complètement sécurisée où **aucune donnée n'est jamais exposée directement aux vues**. Toutes les opérations métier passent par des Use Cases qui garantissent la sécurité et l'intégrité des données.

## Principes de Sécurité

### 1. **Isolation des Données**
- Les vues n'ont **jamais** accès direct aux données
- Toutes les données transitent par des Use Cases
- Les repositories encapsulent complètement l'accès aux données

### 2. **Injection de Dépendances**
- `DependencyContainer` gère tous les Use Cases
- Aucun singleton DataService exposé aux vues
- Testabilité maximale grâce à l'injection

### 3. **Gestion d'Erreurs Robuste**
- Tous les Use Cases retournent des `Result<T, Error>`
- Gestion gracieuse des erreurs dans les vues
- Logging sécurisé des erreurs

## Structure de l'Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                           VIEWS LAYER                          │
│  SecureContentView, SecureClientsView, SecureFacturesView...   │
│                    ↓ (Use Cases only)                          │
└─────────────────────────────────────────────────────────────────┘
                                  ↓
┌─────────────────────────────────────────────────────────────────┐
│                        USE CASES LAYER                         │
│  FetchClientsUseCase, CreateFactureUseCase, UpdateClient...    │
│                    ↓ (Repository protocols)                    │
└─────────────────────────────────────────────────────────────────┘
                                  ↓
┌─────────────────────────────────────────────────────────────────┐
│                      REPOSITORIES LAYER                        │
│  SecureClientRepository, SecureFactureRepository...            │
│                    ↓ (Secure Data Service)                     │
└─────────────────────────────────────────────────────────────────┘
                                  ↓
┌─────────────────────────────────────────────────────────────────┐
│                      DATA ACCESS LAYER                         │
│                    SecureDataService                           │
│                    ↓ (SwiftData Context)                       │
└─────────────────────────────────────────────────────────────────┘
```

## Composants Sécurisés

### Views Sécurisées

#### `SecureContentView`
- Point d'entrée principal
- Injection du `DependencyContainer`
- Navigation sécurisée entre les sections

#### `SecureClientsView`
- Gestion des clients via Use Cases uniquement
- État local pour les données (jamais d'exposition directe)
- Gestion d'erreurs intégrée

#### `SecureFacturesView`
- Gestion des factures via Use Cases
- Filtrage et tri côté vue (données locales)
- Opérations CRUD sécurisées

#### `SecureDashboardView`
- Statistiques via Use Cases
- Chargement asynchrone sécurisé
- Pas d'accès direct aux données

### Use Cases Sécurisés

#### Clients
- `FetchClientsUseCase` : Récupération sécurisée des clients
- `AddClientUseCase` : Ajout avec validation
- `UpdateClientUseCase` : Mise à jour sécurisée
- `DeleteClientUseCase` : Suppression contrôlée
- `SearchClientsUseCase` : Recherche sécurisée

#### Factures
- `FetchFacturesUseCase` : Récupération des factures
- `CreateFactureUseCase` : Création avec génération de numéro
- `UpdateFactureUseCase` : Mise à jour sécurisée
- `DeleteFactureUseCase` : Suppression contrôlée
- `GetFacturesByStatusUseCase` : Filtrage par statut

#### Statistiques
- `GetStatistiquesUseCase` : Statistiques générales
- `GetStatistiquesParPeriodeUseCase` : Statistiques par période
- `GetCAParMoisUseCase` : Chiffre d'affaires mensuel

### Repositories Sécurisés

#### `SecureClientRepository`
- Encapsulation complète des opérations clients
- Gestion d'erreurs avec try/catch
- Conversion automatique Model ↔ DTO

#### `SecureFactureRepository`
- Opérations factures sécurisées
- Génération automatique de numéros
- Validation des relations client

#### `SecureDataService`
- Accès direct à SwiftData
- Gestion des contextes
- Récupération gracieuse des erreurs

## Flux de Données Sécurisé

### Exemple : Ajout d'un Client

```swift
// 1. Vue appelle le Use Case
let result = await dependencyContainer.addClientUseCase.execute(
    nom: "Dupont",
    prenom: "Jean",
    email: "jean@example.com",
    // ... autres paramètres
)

// 2. Use Case valide et appelle le Repository
switch result {
case .success(let success):
    if success {
        // Rechargement des données
        await loadData()
    }
case .failure(let error):
    // Gestion d'erreur
    errorMessage = error.localizedDescription
}
```

### Exemple : Récupération de Statistiques

```swift
// 1. Vue appelle le Use Case
let result = await dependencyContainer.getStatistiquesUseCase.execute()

// 2. Use Case appelle le Repository
switch result {
case .success(let stats):
    // Mise à jour de l'état local
    self.statistiques = stats
case .failure(let error):
    // Gestion d'erreur
    self.errorMessage = error.localizedDescription
}
```

## Avantages de cette Architecture

### 1. **Sécurité Maximale**
- Aucune exposition directe des données
- Contrôle total sur les opérations
- Validation à chaque niveau

### 2. **Testabilité**
- Use Cases facilement testables
- Repositories mockables
- Injection de dépendances

### 3. **Maintenabilité**
- Séparation claire des responsabilités
- Faible couplage entre les couches
- Évolution facilitée

### 4. **Performance**
- Chargement asynchrone
- Gestion d'état optimisée
- Pas de surcharge mémoire

## Migration depuis l'Ancienne Architecture

### Étapes Complétées ✅

1. **Création des Repositories sécurisés**
   - `SecureClientRepository`
   - `SecureFactureRepository`
   - `SecureProduitRepository`
   - `SecureEntrepriseRepository`
   - `SecureStatistiquesRepository`

2. **Création des Use Cases complets**
   - 25+ Use Cases créés
   - Gestion d'erreurs intégrée
   - Validation métier

3. **Création des Vues sécurisées**
   - `SecureContentView`
   - `SecureClientsView`
   - `SecureFacturesView`
   - `SecureDashboardView`

4. **Dependency Injection**
   - `DependencyContainer` centralisé
   - Injection dans toutes les vues
   - Gestion du cycle de vie

### Utilisation

Pour utiliser la nouvelle architecture sécurisée :

```swift
// Dans l'App principal
@main
struct FacturationApp: App {
    var body: some Scene {
        WindowGroup {
            SecureContentView()  // ← Utiliser la vue sécurisée
        }
    }
}
```

## Bonnes Pratiques

### 1. **Jamais d'Accès Direct aux Données**
```swift
// ❌ INTERDIT
@EnvironmentObject private var dataService: DataService
let clients = dataService.clients

// ✅ CORRECT
@EnvironmentObject private var dependencyContainer: DependencyContainer
let result = await dependencyContainer.fetchClientsUseCase.execute()
```

### 2. **Gestion d'Erreurs Systématique**
```swift
// ✅ TOUJOURS gérer les erreurs
let result = await useCase.execute()
switch result {
case .success(let data):
    // Traiter les données
case .failure(let error):
    // Gérer l'erreur
}
```

### 3. **État Local dans les Vues**
```swift
// ✅ État local pour les données
@State private var clients: [ClientDTO] = []
@State private var isLoading = false
@State private var errorMessage: String?
```

Cette architecture garantit une sécurité maximale et une maintenabilité excellente pour l'application Facturation.