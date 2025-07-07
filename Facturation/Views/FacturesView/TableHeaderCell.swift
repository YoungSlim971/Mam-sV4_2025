import SwiftUI

struct TableHeaderCell: View {
    let text: String
    let width: CGFloat?
    let alignment: Alignment
    
    var body: some View {
        Text(text)
            .font(.caption)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .frame(width: width, alignment: alignment)
    }
}
