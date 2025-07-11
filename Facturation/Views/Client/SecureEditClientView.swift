import SwiftUI
import DataLayer

struct SecureEditClientView: View {
    @Environment(\.dismiss) private var dismiss
    let client: ClientDTO
    let factures: [FactureDTO]
    let lignes: [LigneFactureDTO]
    let onUpdate: (ClientDTO) async -> Void
    let onDelete: (UUID) async -> Void
    
    @State private var nom: String
    @State private var prenom: String
    @State private var email: String
    @State private var telephone: String
    @State private var adresse: String
    @State private var ville: String
    @State private var codePostal: String
    @State private var pays: String
    @State private var siret: String
    @State private var numeroTVA: String
    
    init(client: ClientDTO, factures: [FactureDTO], lignes: [LigneFactureDTO], onUpdate: @escaping (ClientDTO) async -> Void, onDelete: @escaping (UUID) async -> Void) {
        self.client = client
        self.factures = factures
        self.lignes = lignes
        self.onUpdate = onUpdate
        self.onDelete = onDelete
        
        _nom = State(initialValue: client.nom)
        _prenom = State(initialValue: client.entreprise)
        _email = State(initialValue: client.email)
        _telephone = State(initialValue: client.telephone)
        _adresse = State(initialValue: client.adresse)
        _ville = State(initialValue: client.adresseVille)
        _codePostal = State(initialValue: client.adresseCodePostal)
        _pays = State(initialValue: client.adressePays)
        _siret = State(initialValue: client.siret)
        _numeroTVA = State(initialValue: client.numeroTVA)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Informations personnelles") {
                    TextField("Nom", text: $nom)
                    TextField("Prénom/Entreprise", text: $prenom)
                    TextField("Email", text: $email)
                    TextField("Téléphone", text: $telephone)
                }
                
                Section("Adresse") {
                    TextField("Adresse", text: $adresse)
                    TextField("Ville", text: $ville)
                    TextField("Code postal", text: $codePostal)
                    TextField("Pays", text: $pays)
                }
                
                Section("Informations fiscales") {
                    TextField("SIRET", text: $siret)
                    TextField("Numéro TVA", text: $numeroTVA)
                }
            }
            .navigationTitle("Modifier le client")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Enregistrer") {
                        Task {
                            await saveClient()
                        }
                    }
                }
            }
        }
    }
    
    private func saveClient() async {
        let updatedClient = ClientDTO(
            id: client.id,
            nom: nom,
            entreprise: prenom,
            email: email,
            telephone: telephone,
            siret: siret,
            numeroTVA: numeroTVA,
            adresse: adresse,
            adresseRue: adresse,
            adresseCodePostal: codePostal,
            adresseVille: ville,
            adressePays: pays
        )
        
        await onUpdate(updatedClient)
        dismiss()
    }
}