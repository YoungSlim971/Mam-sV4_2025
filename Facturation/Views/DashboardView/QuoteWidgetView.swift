import SwiftUI

struct QuoteWidgetView: View {
    @State private var currentQuote: (text: String, author: String) = ("", "")

    let quotes: [(text: String, author: String)] = [
        ("La seule façon de faire du bon travail est d'aimer ce que vous faites.", "Steve Jobs"),
        ("La terre rit en fleurs.", "Ralph Waldo Emerson"),
        ("La nature ne se presse pas, et pourtant tout s’accomplit.", "Lao Tzu"),
        ("En chaque promenade avec la nature on reçoit bien plus que ce que l’on cherche.", "John Muir"),
        ("Regarde profondément dans la nature, et tu comprendras mieux tout le reste.", "Albert Einstein"),
        ("La nature n’est pas un lieu à visiter, c’est chez soi.", "Gary Snyder"),
        ("Ce n’est pas du temps perdu que de s’allonger parfois dans l’herbe… écouter le murmure de l’eau…", "John Lubbock"),
        ("Il n’y a pas de Wi‑Fi dans la forêt, mais tu trouveras une bien meilleure connexion.", "Ralph Smart"),
        ("Il n’existe pas d’amour envers la terre ; nous la possédons, et la préserver est un prêt pour nos enfants.", "Chef Seattle"),
        ("Là où les fleurs s’épanouissent, jaillit l’espoir.", "Lady Bird Johnson"),
        ("Il n’a jamais manqué un printemps où les bourgeons oublient de fleurir.", "Margaret Elizabeth Sangster"),
        ("Tourne ton visage vers le soleil et l’ombre restera derrière toi.", "Helen Keller"),
        ("Il y a quelque chose d’infiniment curatif dans les refrains répétés de la nature.", "Rachel Carson"),
        ("Laisse la pluie t’embrasser, t’endormir avec ses gouttes argentées.", "Langston Hughes"),
        ("Tu peux couper toutes les fleurs, mais tu ne peux empêcher le printemps de revenir.", "Pablo Neruda"),
        ("Une fleur est un mauvais herbe instruite.", "Luther Burbank"),
        ("Un arbre se reconnaît à ses fruits.", "Évangile de Matthieu 12:33"),
        ("Si tu aimes vraiment la nature, tu verras la beauté partout.", "Vincent van Gogh"),
        ("Un voyage de mille lieues commence par un pas.", "Lao Tzu"),
        ("Fais seulement confiance à un seul maître : la nature.", "Rembrandt"),
        ("La poésie de la Terre ne meurt jamais.", "John Keats"),
        ("Nous n’héritons pas la terre de nos ancêtres, nous l’empruntons à nos enfants.", "Chef Seattle"),
        ("Il y a toujours des fleurs pour ceux qui veulent les voir.", "Henri Matisse"),
        ("L’air frais est aussi bon pour l’esprit que pour le corps. La nature semble nous parler…", "John Lubbock"),
        ("Ce que nous appelons hasard de la nature n’est souvent qu’ordre non reconnu.", "William Blake"),
        ("Laisse la pluie tomber : le mieux qu’on puisse faire quand elle tombe est de la laisser tomber.", "Henry Wadsworth Longfellow"),
        ("Nature est l’art de Dieu.", "Dante Alighieri"),
        ("Vis au soleil, nage dans la mer, bois l’air sauvage.", "Ralph Waldo Emerson"),
        ("La nature porte toujours les couleurs de l’esprit.", "Ralph Waldo Emerson"),
        ("Le meilleur remède pour ceux qui ont peur, sont seuls ou malheureux, c’est de sortir… avec les cieux, la nature et Dieu.", "Anne Frank"),
        ("Oublie pas que la Terre aime sentir tes pieds nus et que le vent veut jouer avec tes cheveux.", "Khalil Gibran"),
        ("Le désert n’est pas un luxe, mais une nécessité pour l’esprit humain.", "Edward Abbey"),
        ("Nous devons explorer cette Terre comme des enfants, guidés par la curiosité sans peur.", "Laurel Bleadon Maffei"),
        ("La paix de la nature coule en toi comme le soleil coule dans les arbres.", "John Muir"),
        ("L’homme le plus riche est celui qui se contente de peu, car le contentement est la richesse de la nature.", "Socrate"),
        ("Marcher comme si tu embrassais la Terre avec tes pieds.", "Thich Nhat Hanh"),
        ("L’intelligence de la Terre est sous nos pieds autant que dans le ciel au-dessus de nos têtes.", "Henry David Thoreau"),
        ("Gravis les montagnes et reçois leurs bonnes nouvelles.", "John Muir"),
        ("Des heures en pleine nature renforcent la résilience et la confiance.", "David Suzuki"),
        ("Laissez la forêt être votre école, elle enseigne plus que n’importe quel livre.", "John Lubbock")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("« \(currentQuote.text) »")
                .font(.title3)
                .fontWeight(.medium)
                .italic()
                .minimumScaleFactor(0.7)
                .lineLimit(3)
                .padding(.horizontal)

            Text("- \(currentQuote.author)")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .onAppear(perform: selectRandomQuote)
        .onTapGesture(perform: selectRandomQuote) // Change quote on tap
    }

    private func selectRandomQuote() {
        if let randomQuote = quotes.randomElement() {
            currentQuote = randomQuote
        }
    }
}

#Preview {
    QuoteWidgetView()
}