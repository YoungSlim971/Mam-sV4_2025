import SwiftUI
import DataLayer

struct ChartsSection: View {
    @ObservedObject var statsService: StatistiquesService_DTO
    @Environment(\.horizontalSizeClass) var sizeClass
    @State private var selectedSector: StatutFacture?

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            sectionHeader
            chartsLayout
            AveragePaymentDelayView()
        }
    }
    
    private var sectionHeader: some View {
        Text("Tendances")
            .font(.title2)
            .fontWeight(.semibold)
    }
    
    @ViewBuilder
    private var chartsLayout: some View {
        if sizeClass == .compact {
            compactLayout
        } else {
            regularLayout
        }
    }
    
    private var compactLayout: some View {
        VStack(spacing: 20) {
            MonthlyRevenueChartView(statsService: statsService)
            InvoiceStatusChartView(
                statsService: statsService,
                selectedInvoiceStatusFilter: $selectedSector
            )
        }
    }
    
    private var regularLayout: some View {
        HStack(spacing: 20) {
            MonthlyRevenueChartView(statsService: statsService)
                .frame(maxWidth: .infinity)

            InvoiceStatusChartView(
                statsService: statsService,
                selectedInvoiceStatusFilter: $selectedSector
            )
            .frame(maxWidth: .infinity)
        }
    }
}

#Preview {
    ChartsSection(statsService: StatistiquesService_DTO())
}