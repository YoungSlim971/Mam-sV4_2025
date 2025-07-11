// Views/Produits/SecureProduitsView.swift
import SwiftUI
import DataLayer

struct SecureProduitsView: View {
    @EnvironmentObject private var dependencies: DependencyContainer
    @Binding var searchText: String
    @State private var showingAddProduitSheet = false
    @State private var editingProduit: ProduitDTO?
    @State private var selectedProduitDetail: ProduitDTO?
    @State private var produits: [ProduitDTO] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    var filteredProduits: [ProduitDTO] {
        guard !searchText.isEmpty else { return produits }
        return produits.filter { produit in
            produit.designation.localizedCaseInsensitiveContains(searchText) ||
            (produit.details ?? "").localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            VStack {
                if isLoading {
                    ProgressView("Chargement des produits...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if produits.isEmpty {
                    ContentUnavailableView(
                        "Aucun produit",
                        systemImage: "cube.box",
                        description: Text("Ajoutez votre premier produit pour commencer.")
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(filteredProduits) { produit in
                                SecureProduitCard(
                                    produit: produit,
                                    onEdit: {
                                        editingProduit = produit
                                    },
                                    onDelete: {
                                        deleteProduit(produit)
                                    },
                                    onTap: {
                                        selectedProduitDetail = produit
                                    }
                                )
                                .padding(.horizontal)
                            }
                        }
                        .padding(.vertical)
                    }
                }
                
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }
            }
            .navigationTitle("Produits")
            .toolbar {
                SecureProduitToolbarContent(showingAddProduitSheet: $showingAddProduitSheet)
            }
            .sheet(isPresented: $showingAddProduitSheet) {
                SecureAddProduitView(onProduitAdded: { produit in
                    await addProduit(produit)
                })
                .environmentObject(dependencies)
            }
            .sheet(item: $editingProduit) { produit in
                SecureEditProduitView(
                    produit: produit,
                    onUpdate: { updatedProduit in
                        await updateProduit(updatedProduit)
                    },
                    onDelete: { id in
                        await deleteProduitById(id)
                    }
                )
                .environmentObject(dependencies)
            }
            .sheet(item: $selectedProduitDetail) { produit in
                SecureProductDetailsView(produit: produit, onClose: { selectedProduitDetail = nil })
                    .environmentObject(dependencies)
            }
            .onAppear {
                loadProduits()
            }
        }
    }
    
    private func loadProduits() {
        Task {
            isLoading = true
            errorMessage = nil
            
            let result = await dependencies.fetchProduitsUseCase.execute()
            switch result {
            case .success(let fetchedProduits):
                produits = fetchedProduits
            case .failure(let error):
                errorMessage = "Erreur lors du chargement des produits: \(error.localizedDescription)"
            }
            
            isLoading = false
        }
    }
    
    private func addProduit(_ produit: ProduitDTO) async {
        let result = await dependencies.addProduitUseCase.execute(designation: produit.designation, details: produit.details, prixUnitaire: produit.prixUnitaire)
        switch result {
        case .success:
            loadProduits()
        case .failure(let error):
            errorMessage = "Erreur lors de l'ajout du produit: \(error.localizedDescription)"
        }
    }
    
    private func updateProduit(_ produit: ProduitDTO) async {
        let result = await dependencies.updateProduitUseCase.execute(produit: produit)
        switch result {
        case .success:
            loadProduits()
        case .failure(let error):
            errorMessage = "Erreur lors de la mise à jour du produit: \(error.localizedDescription)"
        }
    }

    private func deleteProduit(_ produit: ProduitDTO) {
        Task {
            await deleteProduitById(produit.id)
        }
    }
    
    private func deleteProduitById(_ id: UUID) async {
        let result = await dependencies.deleteProduitUseCase.execute(produitId: id)
        switch result {
        case .success:
            loadProduits()
        case .failure(let error):
            errorMessage = "Erreur lors de la suppression du produit: \(error.localizedDescription)"
        }
    }
}

// MARK: - Secure Produit Card
struct SecureProduitCard: View {
    let produit: ProduitDTO
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onTap: () -> Void
    
    @State private var isHovered = false
    @State private var showingDeleteAlert = false
    
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text(produit.designation)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(produit.details ?? "")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                HStack {
                    Text("Prix: \(produit.prixUnitaire.formattedEuros)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                    
                    Spacer()
                    
                    if 0 > 0 { // stock not available in DTO
                        Text("Stock: \(0)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Rupture de stock")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }
            
            Spacer()
            
            VStack(spacing: 8) {
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .foregroundColor(.blue)
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: { showingDeleteAlert = true }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.systemBackground)
                .shadow(
                    color: .black.opacity(isHovered ? 0.1 : 0.05),
                    radius: isHovered ? 8 : 4,
                    x: 0,
                    y: isHovered ? 4 : 2
                )
        )
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isHovered)
        .onHover { hovering in isHovered = hovering }
        .onTapGesture {
            onTap()
        }
        .alert("Supprimer le produit ?", isPresented: $showingDeleteAlert) {
            Button("Supprimer", role: .destructive) {
                onDelete()
            }
            Button("Annuler", role: .cancel) { }
        } message: {
            Text("Êtes-vous sûr de vouloir supprimer ce produit ? Cette action est irréversible.")
        }
    }
}

// MARK: - Secure Produit Toolbar Content
struct SecureProduitToolbarContent: ToolbarContent {
    @Binding var showingAddProduitSheet: Bool
    
    var body: some ToolbarContent {
        ToolbarItem(placement: .automatic) {
            Button(action: { showingAddProduitSheet = true }) {
                Label("Ajouter un produit", systemImage: "plus")
            }
        }
    }
}

// MARK: - Secure Add Produit View
struct SecureAddProduitView: View {
    @Environment(\.dismiss) private var dismiss
    let onProduitAdded: (ProduitDTO) async -> Void
    
    @State private var nom = ""
    @State private var description = ""
    @State private var prix: Double = 0.0
    @State private var stock: Int = 0
    @State private var unite = "pièce"
    
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var isFormValid: Bool {
        !nom.isEmpty && !description.isEmpty && prix > 0
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Informations du produit") {
                    TextField("Nom du produit", text: $nom)
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Tarification") {
                    HStack {
                        Text("Prix")
                        Spacer()
                        TextField("0.00", value: $prix, format: .currency(code: "EUR"))
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Stock")
                        Spacer()
                        TextField("0", value: $stock, format: .number)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Unité")
                        Spacer()
                        TextField("pièce", text: $unite)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Nouveau produit")
            // .navigationBarTitleDisplayMode(.inline) // Not available on macOS
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Ajouter") {
                        Task {
                            await addProduit()
                        }
                    }
                    .disabled(!isFormValid || isLoading)
                }
            }
            .disabled(isLoading)
        }
    }
    
    private func addProduit() async {
        isLoading = true
        errorMessage = nil
        
        let produit = ProduitDTO(
            id: UUID(),
            designation: nom,
            details: description,
            prixUnitaire: prix
        )
        
        await onProduitAdded(produit)
        
        isLoading = false
        dismiss()
    }
}

// MARK: - Secure Edit Produit View
struct SecureEditProduitView: View {
    @Environment(\.dismiss) private var dismiss
    let produit: ProduitDTO
    let onUpdate: (ProduitDTO) async -> Void
    let onDelete: (UUID) async -> Void
    
    @State private var nom: String
    @State private var description: String
    @State private var prix: Double
    @State private var stock: Int
    @State private var unite: String
    
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingDeleteAlert = false
    
    init(produit: ProduitDTO, onUpdate: @escaping (ProduitDTO) async -> Void, onDelete: @escaping (UUID) async -> Void) {
        self.produit = produit
        self.onUpdate = onUpdate
        self.onDelete = onDelete
        
        _nom = State(initialValue: produit.designation)
        _description = State(initialValue: produit.details ?? "")
        _prix = State(initialValue: produit.prixUnitaire)
        _stock = State(initialValue: 0)
        _unite = State(initialValue: "unité")
    }
    
    var isFormValid: Bool {
        !nom.isEmpty && !description.isEmpty && prix > 0
    }
    
    var hasChanges: Bool {
        nom != produit.designation ||
        description != produit.details ?? "" ||
        prix != produit.prixUnitaire ||
        stock != 0 ||
        unite != "unité"
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Informations du produit") {
                    TextField("Nom du produit", text: $nom)
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Tarification") {
                    HStack {
                        Text("Prix")
                        Spacer()
                        TextField("0.00", value: $prix, format: .currency(code: "EUR"))
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Stock")
                        Spacer()
                        TextField("0", value: $stock, format: .number)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Unité")
                        Spacer()
                        TextField("pièce", text: $unite)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Modifier le produit")
            // .navigationBarTitleDisplayMode(.inline) // Not available on macOS
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    HStack {
                        Button("Supprimer") {
                            showingDeleteAlert = true
                        }
                        .foregroundColor(.red)
                        
                        Button("Enregistrer") {
                            Task {
                                await updateProduit()
                            }
                        }
                        .disabled(!isFormValid || !hasChanges || isLoading)
                    }
                }
            }
            .disabled(isLoading)
            .alert("Supprimer le produit", isPresented: $showingDeleteAlert) {
                Button("Supprimer", role: .destructive) {
                    Task {
                        await deleteProduit()
                    }
                }
                Button("Annuler", role: .cancel) { }
            } message: {
                Text("Êtes-vous sûr de vouloir supprimer ce produit ? Cette action est irréversible.")
            }
        }
    }
    
    private func updateProduit() async {
        isLoading = true
        errorMessage = nil
        
        let updatedProduit = ProduitDTO(
            id: produit.id,
            designation: nom,
            details: description,
            prixUnitaire: prix
        )
        
        await onUpdate(updatedProduit)
        
        isLoading = false
        dismiss()
    }
    
    private func deleteProduit() async {
        isLoading = true
        errorMessage = nil
        
        await onDelete(produit.id)
        
        isLoading = false
        dismiss()
    }
}

// MARK: - Secure Product Details View
struct SecureProductDetailsView: View {
    let produit: ProduitDTO
    let onClose: () -> Void
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(produit.designation)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text(produit.details ?? "Aucune description disponible")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Détails")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        HStack {
                            Text("Prix")
                                .fontWeight(.medium)
                            Spacer()
                            Text(produit.prixUnitaire.formattedEuros)
                                .foregroundColor(.green)
                                .fontWeight(.semibold)
                        }
                        
                        HStack {
                            Text("Stock")
                                .fontWeight(.medium)
                            Spacer()
                            Text("\(0) \("unité")")
                                .foregroundColor(0 > 0 ? .primary : .red)
                                .fontWeight(.semibold)
                        }
                        
                        HStack {
                            Text("Unité")
                                .fontWeight(.medium)
                            Spacer()
                            Text("unité")
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.controlBackgroundColor))
                    .cornerRadius(10)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Détails du produit")
            // .navigationBarTitleDisplayMode(.inline) // Not available on macOS
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fermer") {
                        onClose()
                    }
                }
            }
        }
    }
}
