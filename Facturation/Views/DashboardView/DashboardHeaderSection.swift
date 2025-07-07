import SwiftUI

struct DashboardHeaderSection: View {
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Tableau de Bord")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Aperçu de votre activité")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(Date.now, style: .date)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(Date.now, style: .time)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            Divider()
        }
    }
}

#Preview {
    DashboardHeaderSection()
}