import SwiftUI
import DataLayer

struct SecureAddClientView: View {
    @Environment(\.dismiss) private var dismiss
    let onClientAdded: (ClientDTO) async -> Void
    
    @State private var nom = ""
    @State private var entreprise = ""
    @State private var email = ""
    @State private var telephone = ""
    @State private var adresse = ""
    @State private var ville = ""
    @State private var codePostal = ""
    @State private var pays = "France"
    @State private var siret = ""
    @State private var numeroTVA = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Informations personnelles") {
                    TextField("Nom", text: $nom)
                    TextField("Entreprise", text: $entreprise)
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
            .navigationTitle("Nouveau client")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Ajouter") {
                        Task {
                            await addClient()
                        }
                    }
                    .disabled(nom.isEmpty || email.isEmpty)
                }
            }
        }
    }
    
    private func addClient() async {
        let client = ClientDTO(
            id: UUID(),
            nom: nom,
            entreprise: entreprise,
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
        
        await onClientAdded(client)
        dismiss()
    }
}