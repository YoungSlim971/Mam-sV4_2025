import SwiftUI

struct SecureLoginView: View {
    @AppStorage("developerUsername") private var storedUsername: String = "admin"
    @AppStorage("developerPassword") private var storedPassword: String = "420STUDIO"
    @AppStorage("isDebugMode") private var isDebugMode: Bool = false

    @State private var username: String = ""
    @State private var password: String = ""
    @State private var errorMessage: String? = nil

    @FocusState private var focusedField: Field?

    enum Field: Hashable {
        case username
        case password
    }

    var onLoginSuccess: () -> Void

    var body: some View {
        VStack {
            AppCard {
                VStack(spacing: AppTheme.Spacing.xl) {
                    Text("Accès Développeur")
                        .font(AppTheme.Typography.title2)
                        .fontWeight(.bold)
                        .foregroundColor(AppTheme.Colors.textPrimary)

                    Text("🤖")
                        .font(.system(size: 60))
                        .padding(.bottom, 10)

                    Text("Veuillez vous connecter pour accéder aux outils développeur.")
                        .font(AppTheme.Typography.body)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .multilineTextAlignment(.center)

                    VStack(spacing: AppTheme.Spacing.md) {
                        AppTextField(
                            "Identifiant",
                            text: $username,
                            icon: "person.fill"
                        )
                        .focused($focusedField, equals: .username)
                        .onSubmit { focusedField = .password }

                        SecureField("Mot de passe", text: $password)
                            .textFieldStyle(.plain)
                            .padding(AppTheme.Spacing.md)
                            .background(AppTheme.Colors.surfaceSecondary)
                            .cornerRadius(AppTheme.CornerRadius.medium)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                                    .stroke(AppTheme.Colors.border, lineWidth: 1)
                            )
                            .focused($focusedField, equals: .password)
                            .onSubmit(performLogin)

                        if let errorMessage = errorMessage {
                            Text(errorMessage)
                                .font(AppTheme.Typography.caption)
                                .foregroundColor(AppTheme.Colors.error)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }

                    Button("Se connecter", action: performLogin)
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)

                    if isDebugMode {
                        Button("Bypass Login (Debug Mode)") {
                            onLoginSuccess()
                        }
                        .buttonStyle(.link)
                        .font(.caption)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                }
                .padding(AppTheme.Spacing.xl)
            }
            .frame(maxWidth: 400)
            .shadow(radius: 10)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.Colors.background)
        .onAppear {
            focusedField = .username
        }
    }

    private func performLogin() {
        if username == storedUsername && password == storedPassword {
            errorMessage = nil
            onLoginSuccess()
        } else {
            errorMessage = "Identifiant ou mot de passe incorrect."
        }
    }
}

#Preview {
    SecureLoginView(onLoginSuccess: { print("Login Success!") })
}
