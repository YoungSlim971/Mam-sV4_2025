import SwiftUI
import DataLayer


/// Carte affichant un produit avec actions édition, suppression, navigation
@MainActor
struct ProduitCard: View {
    let produit: ProduitDTO
    @State private var isHovering = false
    /// Callback appelé quand on clique sur le bouton éditer
    var onEdit: () -> Void
    /// Callback appelé quand on clique sur le bouton supprimer
    var onDelete: () -> Void
    /// Callback appelé quand on clique n'importe où ailleurs sur la carte (détail/édition)
    var onTap: () -> Void
    /// Callback optionnel appelé quand on clique sur le bouton retour
    var onBack: (() -> Void)?

    var body: some View {
        ZStack {
            Button(action: onTap) {
                HStack(spacing: 24) {
                    // Icone à gauche
                    ZStack {
                        if let icon = produit.icon, !icon.isEmpty {
                            Text(icon)
                                .font(.system(size: 38))
                                .frame(width: 54, height: 54)
                                .background(
                                    Circle()
                                        .fill(Color(nsColor: .controlBackgroundColor))
                                        .shadow(color: .black.opacity(0.07), radius: 4, x: 0, y: 2)
                                )
                        } else {
                            Image(systemName: "shippingbox")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 54, height: 54)
                                .foregroundColor(.accentColor)
                                .padding(12)
                                .background(
                                    Circle()
                                        .fill(Color(nsColor: .controlBackgroundColor))
                                        .shadow(color: .black.opacity(0.07), radius: 4, x: 0, y: 2)
                                )
                        }
                    }

                    // Bloc principal (désignation + prix)
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(alignment: .firstTextBaseline, spacing: 12) {
                            Text(produit.designation)
                                .font(.title2.weight(.heavy))
                                .foregroundColor(.primary)
                                .lineLimit(2)
                            Text(produit.prixUnitaire, format: .currency(code: "EUR"))
                                .font(.title3.bold())
                                .foregroundColor(.primary)
                        }
                        if let details = produit.details, !details.isEmpty {
                            Text(details)
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(produit.designation), prix \(produit.prixUnitaire, format: .currency(code: "EUR"))\(produit.details != nil && !produit.details!.isEmpty ? ", \(produit.details!)" : "")")

                    Spacer()
                }
                .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .buttonStyle(.plain)

            // ... hover/boutons d’action
            HStack(spacing: 12) {
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(isHovering ? .accentColor : .primary)
                        .scaleEffect(isHovering ? 1.1 : 1)
                        .animation(.easeInOut(duration: 0.15), value: isHovering)
                }
                .buttonStyle(.borderless)
                .help("Modifier ce produit")

                Button(role: .destructive, action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(isHovering ? .red : .primary)
                        .scaleEffect(isHovering ? 1.1 : 1)
                        .animation(.easeInOut(duration: 0.15), value: isHovering)
                }
                .buttonStyle(.borderless)
                .help("Supprimer ce produit")
            }
            .padding(.trailing, 28)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .opacity(isHovering ? 1 : 0)
            .accessibilityHidden(!isHovering)
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 18)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(isHovering ? Color(nsColor: .selectedContentBackgroundColor).opacity(0.32) : Color(nsColor: .controlBackgroundColor))
                .shadow(color: isHovering ? .black.opacity(0.11) : .black.opacity(0.05), radius: isHovering ? 12 : 3, y: 2)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(isHovering ? Color.accentColor.opacity(0.7) : Color.clear, lineWidth: 1.5)
                        .shadow(color: isHovering ? Color.accentColor.opacity(0.4) : Color.clear, radius: 6, x: 0, y: 0)
                )
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.18)) {
                isHovering = hovering
            }
        }
        .overlay(alignment: .topLeading) {
            if let onBack = onBack {
                Button(action: onBack) {
                    HStack(spacing: 4) {
                        Image(systemName: "xmark")
                        Text("Fermer")
                    }
                    .font(.callout.weight(.medium))
                    .foregroundColor(.accentColor)
                    .padding(8)
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())
                .allowsHitTesting(true)
                .help("Fermer la carte")
            }
        }
    }
}

#if DEBUG
struct ProduitCard_Previews: PreviewProvider {
    static var previews: some View {
        ProduitCard(
            produit: ProduitDTO(
                id: UUID(),
                designation: "Bananes DESSERTS",
                details: "Kg",
                prixUnitaire: 1.45,
                icon: "🍌",
                iconImageData: nil
            ),
            onEdit: {},
            onDelete: {},
            onTap: {}
        )
        .frame(maxWidth: 500)
        .padding()
        .background(Color(nsColor: .windowBackgroundColor))
    }
}
#endif
