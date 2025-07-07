import SwiftUI

struct TotalRow: View {
    let label: String
    let amount: Double
    let isMain: Bool
    var color: Color = .primary
    
    var body: some View {
        HStack(spacing: 20) {
            Text("\(label) :")
                .font(isMain ? .callout : .caption)
                .fontWeight(isMain ? .bold : .medium)
                .foregroundColor(color)
            
            Text(amount, format: .currency(code: "EUR"))
                .font(isMain ? .callout : .caption)
                .fontWeight(isMain ? .bold : .medium)
                .foregroundColor(color)
                .frame(width: 80, alignment: .trailing)
        }
    }
}
