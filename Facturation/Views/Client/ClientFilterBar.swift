// Views/Clients/ClientFilterBar.swift
import SwiftUI

struct ClientFilterBar: View {
    @Binding var sortOrder: ClientsView.SortOrder
    let clientsCount: Int

    var body: some View {
        HStack(spacing: 15) {
            Menu {
                ForEach(ClientsView.SortOrder.allCases, id: \.self) { order in
                    Button(order.rawValue) { sortOrder = order }
                }
            } label: {
                HStack {
                    Image(systemName: "arrow.up.arrow.down.circle")
                    Text(sortOrder.rawValue)
                    Image(systemName: "chevron.down").font(.caption)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.systemGray6)
                .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())

            Spacer()

            Text("\(clientsCount) client\(clientsCount > 1 ? "s" : "")")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
        .padding(.bottom, 10)
    }
}

