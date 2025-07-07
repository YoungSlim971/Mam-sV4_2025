import SwiftUI
import AppKit

struct QuickActionsSection: View {
    @State private var showingNewFacture = false
    @State private var showingNewClient = false
    @Binding var showingSettings: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Actions Rapides")
                .font(.title2)
                .fontWeight(.semibold)

            HStack(spacing: 15) {
                QuickActionButton(
                    title: "Nouvelle Facture",
                    icon: "plus.circle.fill",
                    color: .blue
                ) {
                    showingNewFacture = true
                }

                QuickActionButton(
                    title: "Nouveau Client",
                    icon: "person.badge.plus",
                    color: .green
                ) {
                    showingNewClient = true
                }

                QuickActionButton(
                    title: "Export PDF",
                    icon: "arrow.up.doc.fill",
                    color: .orange
                ) {
                    // Action export
                }

                QuickActionButton(
                    title: "Paramètres",
                    icon: "gear.circle.fill",
                    color: .gray
                ) {
                    showingSettings = true
                }
            }
        }
        .sheet(isPresented: $showingNewFacture) {
            AddFactureView()
        }
        .sheet(isPresented: $showingNewClient) {
            AddClientView(onCreate: { _ in
                showingNewClient = false
            })
        }
        .sheet(isPresented: $showingSettings) {
            NavigationStack {
                ParametresView(onClose: {
                    showingSettings = false
                })
            }
        }
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)

                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 1)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    QuickActionsSection(showingSettings: .constant(false))
}