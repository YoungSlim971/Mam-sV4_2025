import SwiftUI

struct DeveloperView: View {
    @EnvironmentObject private var dataService: DataService
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var showResetConfirmation = false

    @State private var isAuthenticated: Bool = false
    @AppStorage("developerUsername") private var storedUsername: String = "admin"
    @AppStorage("developerPassword") private var storedPassword: String = "420STUDIO"
    @AppStorage("isDebugMode") private var isDebugMode: Bool = false

    @State private var newUsername: String = ""
    @State private var newPassword: String = ""
    @State private var showCredentialResetConfirmation: Bool = false

    var body: some View {
        Group {
            if isAuthenticated || isDebugMode {
                VStack(spacing: 30) {
                    Text("Outils Développeur")
                        .font(.system(size: 22, weight: .bold))
                        .padding(.top, 24)

                    Text("🤖")
                        .font(.system(size: 80))
                        .padding(.bottom, 10)

                    Text("Cette vue permet de générer des données d’entraînement, réinitialiser l’application, ou repartir sur une base SwiftData totalement propre. Utile pour le debug ou les tests.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 10)

                    Button("Générer des données d’entraînement") {
                        Task {
                            await dataService.generateTrainingData()
                            alertMessage = "Données d’entraînement créées"
                            showingAlert = true
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    Text("Ajoute des clients, factures et produits fictifs pour tester rapidement l’application.")
                        .font(.caption)
                        .foregroundColor(.gray)

                    Button("Réinitialiser l’application") {
                        Task {
                            await dataService.clearAllData()
                            alertMessage = "Toutes les données ont été supprimées"
                            showingAlert = true
                        }
                    }
                    .buttonStyle(.bordered)
                    Text("Supprime toutes les données utilisateurs (clients, factures, produits) mais conserve la structure de base.")
                        .font(.caption)
                        .foregroundColor(.gray)

                    Button("Réinitialiser complètement la base (resetContainer)") {
                        showResetConfirmation = true
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    Text("Détruit la base SwiftData, réinitialise le contexte. À utiliser après un refactoring ou une migration.")
                        .font(.caption)
                        .foregroundColor(.gray)
                    .alert("⚠️ Attention", isPresented: $showResetConfirmation) {
                        Button("Réinitialiser", role: .destructive) {
                            dataService.resetContainer()
                            alertMessage = "Base de données réinitialisée (container reset)"
                            showingAlert = true
                        }
                        Button("Annuler", role: .cancel) {}
                    } message: {
                        Text("Cette action va SUPPRIMER TOUTES les données de l’application de façon IRRÉVERSIBLE. Continuer ?")
                    }

                    Spacer()

                    // New section for credential management
                    credentialManagementSection
                }
                .padding()
                .navigationTitle("Développeur")
                .alert(alertMessage, isPresented: $showingAlert) {
                    Button("OK", role: .cancel) { }
                }
            } else {
                SecureLoginView {
                    isAuthenticated = true
                }
            }
        }
        .onAppear {
            // Initialize newUsername and newPassword with current stored values
            newUsername = storedUsername
            newPassword = storedPassword
        }
    }

    // New computed property for credential management section
    private var credentialManagementSection: some View {
        VStack(spacing: 20) {
            Divider()
            Text("Gestion des Accès Développeur")
                .font(.headline)

            Toggle(isOn: $isDebugMode) {
                Text("Bypass Login (Mode Debug)")
            }
            .toggleStyle(.switch)
            .padding(.horizontal)

            VStack(alignment: .leading, spacing: 10) {
                Text("Modifier les identifiants")
                    .font(.subheadline)

                TextField("Nouvel identifiant", text: $newUsername)
                    .textFieldStyle(.roundedBorder)

                SecureField("Nouveau mot de passe", text: $newPassword)
                    .textFieldStyle(.roundedBorder)

                HStack {
                    Button("Enregistrer les identifiants") {
                        storedUsername = newUsername
                        storedPassword = newPassword
                        alertMessage = "Identifiants mis à jour."
                        showingAlert = true
                    }
                    .buttonStyle(.bordered)

                    Button("Réinitialiser les identifiants par défaut") {
                        showCredentialResetConfirmation = true
                    }
                    .buttonStyle(.bordered)
                    .tint(.orange)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
        }
        .alert("Réinitialiser les identifiants", isPresented: $showCredentialResetConfirmation) {
            Button("Réinitialiser", role: .destructive) {
                storedUsername = "admin"
                storedPassword = "420STUDIO"
                newUsername = "admin"
                newPassword = "420STUDIO"
                alertMessage = "Identifiants réinitialisés par défaut."
                showingAlert = true
            }
            Button("Annuler", role: .cancel) {}
        } message: {
            Text("Êtes-vous sûr de vouloir réinitialiser les identifiants aux valeurs par défaut (admin / 420STUDIO) ?")
        }
    }
}

#Preview {
    DeveloperView()
        .environmentObject(DataService.shared)
}
