// Views/Dashboard/AveragePaymentDelayView.swift
import SwiftUI

struct AveragePaymentDelayView: View {
    @ObservedObject var statsService: StatistiquesService

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
                Text("Paiement moyen: \(statsService.delaisPaiementMoyen) jours")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
        }
        .padding()
        .background(Color.systemBackground)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 1)
    }
}
