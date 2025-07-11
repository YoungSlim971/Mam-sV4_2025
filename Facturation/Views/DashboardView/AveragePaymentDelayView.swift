// Views/Dashboard/AveragePaymentDelayView.swift
import SwiftUI
import DataLayer

struct AveragePaymentDelayView: View {
    @EnvironmentObject private var dependencyContainer: DependencyContainer
    @State private var delaisMoyen: Int = 0
    @State private var isLoading = false

    var body: some View {
        VStack(alignment: .leading) {
            Text("Délai moyen de paiement")
                .font(.headline)
                .foregroundColor(.primary)
                .padding(.bottom, 5)

            HStack {
                Image(systemName: "hourglass")
                    .font(.title2)
                    .foregroundColor(.orange)
                
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Text("Paiement moyen: \(delaisMoyen) jours")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 1)
        .onAppear {
            Task {
                await loadDelaisPaiement()
            }
        }
    }
    
    private func loadDelaisPaiement() async {
        isLoading = true
        // TODO: Implémenter le calcul du délai moyen de paiement
        // Pour l'instant, on utilise une valeur par défaut
        delaisMoyen = 30
        isLoading = false
    }
}

#Preview {
    AveragePaymentDelayView()
        .environmentObject(DependencyContainer.shared)
}