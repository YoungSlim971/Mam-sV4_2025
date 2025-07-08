import SwiftUI
import Charts
import AppKit
import DataLayer

struct InvoiceStatusChartView: View {
    @ObservedObject var statsService: StatistiquesService
    @Binding var selectedInvoiceStatusFilter: StatutFacture?
    @State private var selectedSector: StatutFacture?

    var body: some View {
        VStack(alignment: .leading) {
            headerSection
            
            if statsService.repartitionStatuts.isEmpty {
                emptyStateView
            } else {
                chartContentView
            }
        }
        .padding()
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 1)
    }
    
    private var headerSection: some View {
        Text("Répartition des Statuts")
            .font(.headline)
            .foregroundColor(.primary)
            .padding(.bottom, 5)
    }
    
    private var emptyStateView: some View {
        Text("Aucune donnée de statut de facture pour le moment.")
            .font(.caption)
            .foregroundColor(.secondary)
            .frame(height: 120)
            .frame(maxWidth: .infinity)
            .background(Color.blue.opacity(0.2))
            .cornerRadius(8)
    }
    
    private var chartContentView: some View {
        HStack(spacing: 16) {
            pieChartView
            legendView
        }
        .frame(height: 120)
        .padding(.trailing)
    }
    
    private var pieChartView: some View {
        Chart(filteredChartData, id: \.key) { status, factures in
            SectorMark(
                angle: .value("Count", factures.count),
                innerRadius: 40,
                outerRadius: 60
            )
            .foregroundStyle(status.color)
            .annotation(position: .overlay) {
                VStack {
                    Text("\(factures.count)")
                        .font(.caption)
                        .foregroundStyle(.white)
                    Text("\(totalAmount(for: factures))")
                        .font(.caption2)
                        .foregroundStyle(.white)
                }
            }
        }
        .chartLegend(.hidden)
        .frame(height: 120)
        .onTapGesture {
            handleChartTap()
        }
    }
    
    private var legendView: some View {
        VStack(alignment: .leading, spacing: 8) {
            legendItem(color: .green, title: "Payée")
            legendItem(color: .blue, title: "Envoyée")
            legendItem(color: .red, title: "En Retard")
        }
    }
    
    private func legendItem(color: Color, title: String) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
            Text(title)
                .font(.caption)
                .foregroundColor(.primary)
        }
    }
    
    private var filteredChartData: [(key: StatutFacture, value: [FactureDTO])] {
        statsService.repartitionStatuts
            .filter { !$0.value.isEmpty }
            .sorted(by: { $0.key.rawValue < $1.key.rawValue })
    }
    
    private func totalAmount(for factures: [FactureDTO]) -> String {
        let total = factures.reduce(0) { partial, facture in
            partial + facture.calculateTotalTTC(with: statsService.lignes)
        }
        return total.euroFormatted
    }
    
    private func handleChartTap() {
        if selectedInvoiceStatusFilter != nil {
            selectedInvoiceStatusFilter = nil
        } else if let firstStatus = filteredChartData.first?.key {
            selectedInvoiceStatusFilter = firstStatus
        }
    }
}

#Preview {
    InvoiceStatusChartView(
        statsService: StatistiquesService(),
        selectedInvoiceStatusFilter: .constant(nil)
    )
}
