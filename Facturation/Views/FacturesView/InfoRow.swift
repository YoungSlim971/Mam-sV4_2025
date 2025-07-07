import SwiftUI

struct InfoRow: View {
    let label: String
    let value: String
    var formatter: DateFormatter? = nil
    var isBold: Bool = false
    var alignment: HorizontalAlignment = .leading
    var valueColor: Color = .primary
    
    init(label: String, value: String, isBold: Bool = false, alignment: HorizontalAlignment = .leading, valueColor: Color = .primary) {
        self.label = label
        self.value = value
        self.isBold = isBold
        self.alignment = alignment
        self.valueColor = valueColor
    }
    
    init(label: String, value: Date, formatter: DateFormatter, alignment: HorizontalAlignment = .leading, valueColor: Color = .primary) {
        self.label = label
        self.value = formatter.string(from: value)
        self.formatter = formatter
        self.alignment = alignment
        self.valueColor = valueColor
    }
    
    var body: some View {
        HStack {
            if alignment == .trailing {
                Spacer()
            }
            
            if !label.isEmpty {
                Text("\(label) :")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fontWeight(isBold ? .medium : .regular)
            }
            
            Text(value)
                .font(.caption)
                .fontWeight(isBold ? .bold : .regular)
                .foregroundColor(valueColor)
            
            if alignment == .leading {
                Spacer()
            }
        }
    }
}
