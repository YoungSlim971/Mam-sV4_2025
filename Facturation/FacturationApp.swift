// App/FacturationApp.swift
import SwiftUI
import DataLayer

@main
struct FacturationApp: App {
    @StateObject private var dataService = DataService.shared

    var body: some Scene {
        WindowGroup {
            ModernContentView()
                .environmentObject(dataService)
                .frame(minWidth: 1200, minHeight: 800)
        }
        .windowResizability(.contentSize)
        .commands {
            // Commandes personnalisées pour le menu
            CommandGroup(after: .newItem) {
                Button("Nouvelle Facture") {
                    // Action pour nouvelle facture
                }
                .keyboardShortcut("n", modifiers: [.command, .shift])

                Button("Nouveau Client") {
                    // Action pour nouveau client
                }
                .keyboardShortcut("c", modifiers: [.command, .shift])
            }

            CommandGroup(replacing: .help) {
                Button("À propos de Facturation Pro") {
                    // Action pour à propos
                }
            }
        }
    }
}

// Extension pour les raccourcis clavier globaux
extension FacturationApp {
    // Gestionnaire des raccourcis clavier
    private func handleKeyboardShortcuts() {
        // Implémentation des raccourcis clavier si nécessaire
    }
}
