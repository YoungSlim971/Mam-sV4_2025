// Views/Parametres/ParametresView.swift
import SwiftUI
import Utilities
import DataLayer
struct ParametresView: View {
    var onClose: () -> Void
    @EnvironmentObject private var dependencyContainer: DependencyContainer
    @State private var entreprise: EntrepriseDTO?
    @State private var editableEntreprise = EditableEntreprise()
    @State private var hasChanges = false
    @State private var showingSaveAlert = false
    @State private var showingResetAlert = false
    @State private var isEditing = false
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 30) {
                    ParametresHeaderSection()

                    if isEditing {
                        EntrepriseFormView(
                            editableEntreprise: $editableEntreprise,
                            hasChanges: $hasChanges,
                            onSave: saveChanges,
                            onCancel: {
                                resetChanges()
                                isEditing = false
                            }
                        )
                    } else {
                        if let entreprise = entreprise {
                            EntrepriseDetailView(entreprise: entreprise, onEdit: { isEditing = true })
                        }
                    }

                    AboutSection()

                    Spacer(minLength: 100)
                }
                .padding()
            }
            .navigationTitle("Paramètres")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button("← Retour") {
                        onClose()
                    }
                }
            }
            .onAppear {
                Task {
                    await loadEntreprise()
                    if let entreprise = entreprise, entreprise.nom.isEmpty {
                        isEditing = true
                    }
                }
            }
            .alert("Paramètres sauvegardés", isPresented: $showingSaveAlert) {
                Button("OK") { }
            } message: {
                Text("Les paramètres de votre entreprise ont été mis à jour avec succès.")
            }
        }
    }

    private func loadEntreprise() async {
        isLoading = true
        errorMessage = nil
        
        let result = await dependencyContainer.fetchEntrepriseUseCase.execute()
        
        switch result {
        case .success(let entrepriseData):
            entreprise = entrepriseData
            if let entrepriseData = entrepriseData {
                editableEntreprise = EditableEntreprise(from: entrepriseData)
            }
            hasChanges = false
        case .failure(let error):
            errorMessage = "Erreur lors du chargement: \(error.localizedDescription)"
        }
        
        isLoading = false
    }

    private func saveChanges() {
        guard var updatedEntreprise = entreprise else { return }

        // Appliquer la logique "N/A"
        editableEntreprise.prepareForSave()
        editableEntreprise.applyTo(&updatedEntreprise)
        
        Task {
            isLoading = true
            errorMessage = nil
            
            let result = await dependencyContainer.updateEntrepriseUseCase.execute(entreprise: updatedEntreprise)
            
            switch result {
            case .success:
                entreprise = updatedEntreprise
                hasChanges = false
                isEditing = false
                showingSaveAlert = true
            case .failure(let error):
                errorMessage = "Erreur lors de la sauvegarde: \(error.localizedDescription)"
            }
            
            isLoading = false
        }
    }

    private func resetChanges() {
        Task { await loadEntreprise() }
    }
}

// MARK: - Vue Formulaire
struct EntrepriseFormView: View {
    @Binding var editableEntreprise: EditableEntreprise
    @Binding var hasChanges: Bool
    var onSave: () -> Void
    var onCancel: () -> Void

    var body: some View {
        VStack(spacing: 30) {
            EntrepriseInfoSection(editableEntreprise: $editableEntreprise, hasChanges: $hasChanges)
            AdresseSection(editableEntreprise: $editableEntreprise, hasChanges: $hasChanges)
            LegalSection(editableEntreprise: $editableEntreprise, hasChanges: $hasChanges)
            FacturationParametersSection(editableEntreprise: $editableEntreprise, hasChanges: $hasChanges)
            BankingSection(editableEntreprise: $editableEntreprise, hasChanges: $hasChanges)
            ActionsSection(
                hasChanges: hasChanges,
                onSave: onSave,
                onReset: onCancel
            )
        }
    }
}

// MARK: - Vue Consultation
struct EntrepriseDetailView: View {
    let entreprise: EntrepriseDTO
    var onEdit: () -> Void

    var body: some View {
        VStack(spacing: 40) {
            InfoBlock(title: "Informations de l'entreprise", fields: [
                ("Nom", entreprise.nom),
                ("Domaine d'activité", entreprise.domaine ?? "—"),
                ("Dirigeant", entreprise.nomDirigeant ?? "—"),
                ("Contact Facturation", entreprise.nomContact ?? "—"),
                ("Email", entreprise.email),
                ("Téléphone", entreprise.telephone)
            ])

            InfoBlock(title: "Adresse de facturation", fields: [
                ("Rue", entreprise.adresseRue),
                ("Ville", "\(entreprise.adresseCodePostal) \(entreprise.adresseVille)"),
                ("Pays", entreprise.adressePays)
            ])

            InfoBlock(title: "Informations légales", fields: [
                ("SIRET", entreprise.siret),
                ("Numéro de TVA", entreprise.numeroTVA),
                ("Certification", entreprise.certificationTexte)
            ])

            InfoBlock(title: "Informations bancaires", fields: [
                ("IBAN", entreprise.iban),
                ("BIC", entreprise.bic ?? "—")
            ])

            InfoBlock(title: "Paramètres de facturation", fields: [
                ("Préfixe Facture", entreprise.prefixeFacture),
                ("Prochain Numéro", "\(entreprise.prochainNumero)"),
                ("TVA par défaut", "\(entreprise.tvaTauxDefaut.formatted(.number.precision(.fractionLength(1))))%"),
                ("Délai de paiement", "\(entreprise.delaiPaiementDefaut) jours")
            ])

            Button(action: onEdit) {
                Label("Modifier mes informations", systemImage: "pencil")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}

struct InfoBlock: View {
    let title: String
    let fields: [(String, String)]

    var body: some View {
        VStack(spacing: 15) {
            HStack {
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
            }

            VStack(spacing: 12) {
                ForEach(fields, id: \.0) { field in
                    HStack {
                        Text(field.0)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(field.1)
                            .fontWeight(.semibold)
                            .multilineTextAlignment(.trailing)
                    }
                }
            }
            .padding()
            .background(Color.systemBackground)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 1)
        }
    }
}


// MARK: - Editable Entreprise Model
struct EditableEntreprise {
    var nom: String = "Mon Entreprise"
    var nomContact: String = "" // Nouveau champ
    var nomDirigeant: String = "" // Nouveau champ
    var telephone: String = ""
    var email: String = ""
    var siret: String = ""
    var numeroTVA: String = ""
    var iban: String = ""
    var bic: String = ""

    // Adresse
    var adresseRue: String = ""
    var adresseCodePostal: String = ""
    var adresseVille: String = ""
    var adressePays: String = "France"

    // Certification
    var certificationTexte: String = "" // Nouveau champ
    
    // Domaine d'activité
    var domaine: String = ""

    // Logo de l'entreprise
    var logo: Data?

    // Paramètres de facturation
    var prefixeFacture: String = "F"
    var prochainNumero: Int = 1
    var tvaTauxDefaut: Double = 20.0
    var delaiPaiementDefaut: Int = 30

    init() {
        // Initialisation par défaut
    }

    init(from entreprise: EntrepriseDTO) {
        self.nom = entreprise.nom
        self.nomContact = entreprise.nomContact ?? ""
        self.nomDirigeant = entreprise.nomDirigeant ?? ""
        self.telephone = entreprise.telephone
        self.email = entreprise.email
        self.siret = entreprise.siret
        self.numeroTVA = entreprise.numeroTVA
        self.iban = entreprise.iban
        self.bic = entreprise.bic ?? ""
        self.adresseRue = entreprise.adresseRue
        self.adresseCodePostal = entreprise.adresseCodePostal
        self.adresseVille = entreprise.adresseVille
        self.adressePays = entreprise.adressePays
        self.certificationTexte = entreprise.certificationTexte
        self.domaine = entreprise.domaine ?? ""
        self.logo = entreprise.logo
        self.prefixeFacture = entreprise.prefixeFacture
        self.prochainNumero = entreprise.prochainNumero
        self.tvaTauxDefaut = entreprise.tvaTauxDefaut
        self.delaiPaiementDefaut = entreprise.delaiPaiementDefaut
    }

    mutating func prepareForSave() {
        if nom.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { nom = "N/A" }
        if nomContact.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { nomContact = "N/A" } // Préparation du nouveau champ
        if nomDirigeant.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { nomDirigeant = "N/A" } // Préparation du nouveau champ
        if telephone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { telephone = "N/A" }
        if email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { email = "N/A" }
        if siret.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { siret = "N/A" }
        if numeroTVA.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { numeroTVA = "N/A" }
        if iban.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { iban = "N/A" }
        if bic.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { bic = "N/A" }
        if adresseRue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { adresseRue = "N/A" }
        if adresseCodePostal.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { adresseCodePostal = "N/A" }
        if adresseVille.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { adresseVille = "N/A" }
        if adressePays.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { adressePays = "N/A" }
        if certificationTexte.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { certificationTexte = "N/A" } // Préparation du nouveau champ
        if domaine.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { domaine = "N/A" } // Préparation du nouveau champ
        if prefixeFacture.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { prefixeFacture = "F" }
        // Pas de préparation spéciale pour le logo, on laisse tel quel
    }


    func applyTo(_ entreprise: inout EntrepriseDTO) {
        entreprise.nom = nom
        entreprise.nomContact = nomContact.isEmpty || nomContact == "N/A" ? nil : nomContact
        entreprise.nomDirigeant = nomDirigeant.isEmpty || nomDirigeant == "N/A" ? nil : nomDirigeant
        entreprise.telephone = telephone
        entreprise.email = email
        entreprise.siret = siret
        entreprise.numeroTVA = numeroTVA
        entreprise.iban = iban
        entreprise.bic = bic.isEmpty || bic == "N/A" ? nil : bic
        entreprise.adresseRue = adresseRue
        entreprise.adresseCodePostal = adresseCodePostal
        entreprise.adresseVille = adresseVille
        entreprise.adressePays = adressePays
        entreprise.certificationTexte = certificationTexte
        entreprise.domaine = domaine.isEmpty || domaine == "N/A" ? nil : domaine
        entreprise.logo = logo
        entreprise.prefixeFacture = prefixeFacture
        entreprise.prochainNumero = prochainNumero
        entreprise.tvaTauxDefaut = tvaTauxDefaut
        entreprise.delaiPaiementDefaut = delaiPaiementDefaut
    }
}

// MARK: - Parametres Header Section Content
struct ParametresHeaderSectionContent: View {
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Paramètres")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Configuration de votre entreprise")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "gear.circle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.blue.gradient)
            }

            Divider()
        }
    }
}

private struct ParametresHeaderSection: View {
    var body: some View {
        ParametresHeaderSectionContent()
    }
}

// MARK: - Entreprise Info Section
struct EntrepriseInfoSection: View {
    @Binding var editableEntreprise: EditableEntreprise
    @Binding var hasChanges: Bool

    @State private var showingImagePicker = false
    @State private var selectedImage: NSImage?

    var body: some View {
        VStack(spacing: 15) {
            HStack {
                Text("Informations de l'entreprise")
                    .font(.title2)
                    .fontWeight(.semibold)

                Spacer()

                if !editableEntreprise.nom.isEmpty {
                    Text("Obligatoire")
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(4)
                }
            }

            VStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Nom de l'entreprise *")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    TextField("Nom de votre entreprise", text: $editableEntreprise.nom)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onChange(of: editableEntreprise.nom) { _, _ in hasChanges = true }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Domaine d'activité")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    TextField("Exploitation agricole, Informatique, Services...", text: $editableEntreprise.domaine)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onChange(of: editableEntreprise.domaine) { _, _ in hasChanges = true }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Nom du dirigeant")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    TextField("Nom du chef d'entreprise", text: $editableEntreprise.nomDirigeant)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onChange(of: editableEntreprise.nomDirigeant) { _, _ in hasChanges = true }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Contact facturation")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    TextField("Personne à contacter pour la facture", text: $editableEntreprise.nomContact)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onChange(of: editableEntreprise.nomContact) { _, _ in hasChanges = true }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Email professionnel")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    TextField("contact@entreprise.com", text: $editableEntreprise.email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
//                        .autocapitalization(.none)
                        .onChange(of: editableEntreprise.email) { _, _ in hasChanges = true }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Téléphone")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    TextField("01 23 45 67 89", text: $editableEntreprise.telephone)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onChange(of: editableEntreprise.telephone) { _, _ in hasChanges = true }
                }

                // Logo de l'entreprise
                VStack(alignment: .leading, spacing: 4) {
                    Text("Logo de l'entreprise")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    if let logoData = editableEntreprise.logo, let nsImage = NSImage(data: logoData) {
                        Image(nsImage: nsImage)
                            .resizable()
                            .frame(width: 80, height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .padding(.bottom, 4)
                    }
                    Button("Choisir un logo...") {
                        showingImagePicker = true
                    }
                }
                .sheet(isPresented: $showingImagePicker) {
                    ImagePicker(image: $selectedImage)
                        .onDisappear {
                            if let img = selectedImage {
                                editableEntreprise.logo = img.tiffRepresentation
                                hasChanges = true
                            }
                        }
                }
            }
            .padding()
            .background(Color.systemBackground)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 1)
        }
    }
}

// MARK: - Adresse Section
struct AdresseSection: View {
    @Binding var editableEntreprise: EditableEntreprise
    @Binding var hasChanges: Bool

    var body: some View {
        VStack(spacing: 15) {
            HStack {
                Text("Adresse de facturation")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
            }

            VStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Rue")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    TextField("123 rue de la République", text: $editableEntreprise.adresseRue)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onChange(of: editableEntreprise.adresseRue) { _, _ in hasChanges = true }
                }

                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Code postal")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        TextField("75001", text: $editableEntreprise.adresseCodePostal)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .onChange(of: editableEntreprise.adresseCodePostal) { _, _ in hasChanges = true }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Ville")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        TextField("Paris", text: $editableEntreprise.adresseVille)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .onChange(of: editableEntreprise.adresseVille) { _, _ in hasChanges = true }
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Pays")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    TextField("France", text: $editableEntreprise.adressePays)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onChange(of: editableEntreprise.adressePays) { _, _ in hasChanges = true }
                }
            }
            .padding()
            .background(Color.systemBackground)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 1)
        }
    }
}

// MARK: - Legal Section
struct LegalSection: View {
    @Binding var editableEntreprise: EditableEntreprise
    @Binding var hasChanges: Bool

    var body: some View {
        VStack(spacing: 15) {
            HStack {
                Text("Informations légales")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
            }

            VStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("SIRET")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    TextField("12345678901234", text: $editableEntreprise.siret)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onChange(of: editableEntreprise.siret) { _, _ in hasChanges = true }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Numéro de TVA")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    TextField("FR12345678901", text: $editableEntreprise.numeroTVA)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
//                        .autocapitalization(.allCharacters)
                        .onChange(of: editableEntreprise.numeroTVA) { _, _ in hasChanges = true }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Certification (ex: Bio)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    TextField("Certification Biologique", text: $editableEntreprise.certificationTexte)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onChange(of: editableEntreprise.certificationTexte) { _, _ in hasChanges = true }
                }
            }
            .padding()
            .background(Color.systemBackground)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 1)
        }
    }
}

// MARK: - Facturation Parameters Section
struct FacturationParametersSection: View {
    @Binding var editableEntreprise: EditableEntreprise
    @Binding var hasChanges: Bool

    var body: some View {
        VStack(spacing: 15) {
            HStack {
                Text("Paramètres de facturation")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
            }

            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Préfixe des factures")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        TextField("F", text: $editableEntreprise.prefixeFacture)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .onChange(of: editableEntreprise.prefixeFacture) { _, _ in hasChanges = true }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Prochain numéro")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        TextField("1", value: $editableEntreprise.prochainNumero, format: .number)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .onChange(of: editableEntreprise.prochainNumero) { _, _ in hasChanges = true }
                    }
                }

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("TVA par défaut (%)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        TextField("20", value: $editableEntreprise.tvaTauxDefaut, format: .number)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .onChange(of: editableEntreprise.tvaTauxDefaut) { _, newValue in
                                hasChanges = true
                                // Valider que le taux de TVA respecte la réglementation française
                                if !Validator.isValidTVARate(newValue) {
                                    // Ajuster au taux valide le plus proche
                                    let validRates: [Double] = [0.0, 2.1, 5.5, 10.0, 20.0]
                                    if let closestRate = validRates.min(by: { abs($0 - newValue) < abs($1 - newValue) }) {
                                        editableEntreprise.tvaTauxDefaut = closestRate
                                    }
                                }
                            }
                        Text("Taux valides : 0%, 2.1%, 5.5%, 10%, 20%")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Délai de paiement (jours)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        TextField("30", value: $editableEntreprise.delaiPaiementDefaut, format: .number)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .onChange(of: editableEntreprise.delaiPaiementDefaut) { _, _ in hasChanges = true }
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Aperçu de numérotation")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)

                    Text("\(editableEntreprise.prefixeFacture)\(Calendar.current.component(.year, from: Date()))-\(String(format: "%04d", editableEntreprise.prochainNumero))")
                        .font(.headline)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            .padding()
            .background(Color.systemBackground)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 1)
        }
    }
}

// MARK: - Banking Section
struct BankingSection: View {
    @Binding var editableEntreprise: EditableEntreprise
    @Binding var hasChanges: Bool

    var body: some View {
        VStack(spacing: 15) {
            HStack {
                Text("Informations bancaires")
                    .font(.title2)
                    .fontWeight(.semibold)

                Spacer()

                Text("Optionnel")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(4)
            }

            VStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("IBAN")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    TextField("FR76 1234 5678 9012 3456 7890 123", text: $editableEntreprise.iban)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
//                        .autocapitalization(.allCharacters)
                        .onChange(of: editableEntreprise.iban) { _, _ in hasChanges = true }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("BIC")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    TextField("BNPAFRPP", text: $editableEntreprise.bic)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
//                        .autocapitalization(.allCharacters)
                        .onChange(of: editableEntreprise.bic) { _, _ in hasChanges = true }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Information")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)

                    Text("Ces informations apparaîtront sur vos factures pour faciliter les paiements de vos clients.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
            }
            .padding()
            .background(Color.systemBackground)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 1)
        }
    }
}

// MARK: - Actions Section
struct ActionsSection: View {
    let hasChanges: Bool
    let onSave: () -> Void
    let onReset: () -> Void

    var body: some View {
        VStack(spacing: 15) {
            HStack {
                Text("Actions")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
            }

            VStack(spacing: 12) {
                HStack(spacing: 15) {
                    Button(action: onReset) {
                        Label("Annuler les modifications", systemImage: "arrow.counterclockwise")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color(NSColor.controlColor))
                            .foregroundColor(.primary)
                            .cornerRadius(10)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(!hasChanges)

                    Button(action: onSave) {
                        Label("Sauvegarder", systemImage: "checkmark.circle.fill")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(hasChanges ? Color.blue : Color.systemGray4)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(!hasChanges)
                }

                if hasChanges {
                    Text("Vous avez des modifications non sauvegardées")
                        .font(.caption)
                        .foregroundColor(.orange)
                        .padding(.top, 4)
                }
            }
            .padding()
            .background(Color.systemBackground)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 1)
        }
    }
}

// MARK: - About Section
struct AboutSection: View {
    @EnvironmentObject private var dependencyContainer: DependencyContainer
    @State private var statistiques = (totalFactures: 0, totalClients: 0)
    @State private var isLoading = false

    var body: some View {
        VStack(spacing: 15) {
            HStack {
                Text("À propos")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
            }

            VStack(spacing: 12) {
                HStack {
                    Text("Version de l'application")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Base de données")
                    Spacer()
                    Text("\(statistiques.totalFactures) factures, \(statistiques.totalClients) clients")
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Technologie")
                    Spacer()
                    Text("SwiftUI + SwiftData")
                        .foregroundColor(.secondary)
                }

                Divider()

                VStack(spacing: 4) {
                    Text("Facturation Pro")
                        .font(.headline)
                        .fontWeight(.semibold)

                    Text("Application de facturation professionnelle pour macOS")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding()
            .background(Color.systemBackground)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 1)
        }
        .onAppear {
            Task { await loadStatistiques() }
        }
    }

    @preconcurrency
    private func loadStatistiques() async {
        isLoading = true
        
        let statsResult = await dependencyContainer.getStatistiquesUseCase.execute()
        let clientsResult = await dependencyContainer.fetchClientsUseCase.execute()
        
        switch (statsResult, clientsResult) {
        case (.success(let stats), .success(let clients)):
            statistiques = (stats.totalFactures, clients.count)
        default:
            // En cas d'erreur, on garde les valeurs par défaut
            statistiques = (0, 0)
        }
        
        isLoading = false
    }
}

#Preview {
    ParametresView(onClose: {})
        .environmentObject(DependencyContainer.shared)
}


