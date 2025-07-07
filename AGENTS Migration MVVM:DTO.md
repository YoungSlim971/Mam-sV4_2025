Exemple de Modèle « Facture » avec Architecture Découplée (Use Cases & DTO)

Modèle SwiftData : Facture (et Client) Actuel

Le modèle Facture ci-dessous illustre une classe SwiftData (@Model) représentant une facture, avec ses propriétés, relations et logique métier de base :
    •    Propriétés principales : identifiant unique (id: UUID), numéro de référence (numero), dates (dateFacture, dateEcheance, datePaiement), taux de TVA (tva), statut (statut: StatutFacture), conditions de paiement (conditionsPaiement: ConditionsPaiement), remise globale (remisePourcentage), notes fixes et optionnelles (notes, NotesCommentaireFacture). Par exemple, datePaiement utilise un property observer (didSet) pour passer automatiquement le statut en Payée si la date de paiement est renseignée et antérieure/égale à aujourd’hui.
    •    Enumération StatutFacture : définit les différents statuts possibles (Brouillon, Envoyée, Payée, En Retard, Annulée), chacun associé à une couleur et une icône SF Symbol (pour l’affichage SwiftUI). De même, l’énumération ConditionsPaiement liste les modes de paiement (Virement, Chèque, Espèces, Carte) avec leur pictogramme. Ces enums sont marquées CaseIterable, Codable afin d’être facilement utilisables dans l’UI et sérialisables.
    •    Relations entre modèles : la classe Facture a une relation vers un Client (client: Client?) et une relation one-to-many vers les LigneFacture (lignes: [LigneFacture]). Le mot-clé @Relationship est utilisé pour définir ces associations. Par exemple, on peut définir une relation un-à-plusieurs avec suppression en cascade sur les lignes associées (@Relationship(deleteRule: .cascade)), comme illustré dans l’exemple ci-dessous ￼ ￼. Le paramètre inverse assure la cohérence bidirectionnelle : ici inverse: \Client.factures indique que la classe Client possède de son côté une propriété factures (tableau de Facture). Nota : la classe Client (non montrée) comporterait typiquement des champs comme nom, coordonnées, etc., ainsi qu’une propriété @Relationship var factures: [Facture] = [] pour le lien inverse.
    •    Calculs et logique métier interne : Facture calcule ses totaux via des propriétés calculées sousTotal, montantTVA et totalTTC. Ces calculs parcourent les lignes associées (chaque LigneFacture ayant un total individuel = prix * quantité) et appliquent la TVA puis la remise éventuelle. Ce genre de propriété dérivée est considérée comme de la logique métier du domaine (ex. calcul d’un total restant) qu’il est important de tester unitairement ￼ ￼. La classe LigneFacture définit de son côté ses champs (désignation, quantité, prix unitaire, référence et date de commande, éventuel lien vers un Produit) ainsi qu’un calcul total (montant de la ligne).

@Model final class Facture {
    @Attribute(.unique) var id: UUID
    var numero: String
    var dateFacture: Date
    var dateEcheance: Date?
    var datePaiement: Date? {
        didSet {
            if let date = datePaiement, date <= Date() {
                statut = .payee  // Marquer comme payée automatiquement
            }
        }
    }
    var tva: Double
    var conditionsPaiement: ConditionsPaiement = .virement
    var remisePourcentage: Double = 0.0
    var statut: StatutFacture
    var notes: String
    var NotesCommentaireFacture: String?
    @Relationship(inverse: \Client.factures) var client: Client?
    @Relationship(deleteRule: .cascade, inverse: \LigneFacture.facture) 
    var lignes: [LigneFacture] = []
    // initialiseur et autres propriétés (sousTotal, montantTVA, totalTTC) ...
}

Dans cet exemple, la facture est créée via un initialiseur qui assigne par défaut certaines valeurs (par exemple, dateFacture = Date() à la création, dateEcheance = +30 jours, statut = .brouillon, etc.). On notera que l’ajout d’une ligne à une facture doit se faire avec précaution : il faut d’abord insérer la nouvelle LigneFacture dans le contexte (context.insert) avant d’établir la relation (nouvelleLigne.facture = facture puis facture.lignes.append(nouvelleLigne)), afin d’éviter des erreurs d’exécution. Le code présenté gérait cela via une extension sur ModelContext fournissant des méthodes utilitaires creerNouvelleFacture(...) et ajouterLigne(...) respectant l’ordre d’opération adéquat (insertion puis liaison, suivi d’un save() sécurisé).

Découpler la Logique Métier avec des Use Cases

Afin d’améliorer l’architecture, on souhaite découpler la logique métier du reste de l’application en introduisant des use cases. Un Use Case (ou cas d’utilisation) représente une opération métier unique du domaine – par exemple « Créer une nouvelle facture », « Ajouter une ligne à une facture », « Marquer une facture comme payée », etc. Selon les principes de l’architecture propre (Clean Architecture), les use cases font partie de la couche domaine et encapsulent les règles métier indépendamment de toute interface utilisateur ou détail technique ￼ ￼.

Concrètement, un use case est souvent implémenté comme une classe ou fonction spécifique qui coordonne les échanges entre les couches (domaine, données, UI) pour réaliser une tâche métier ￼. Par exemple, on peut définir un protocole AjouterLigneUseCase avec une méthode execute(facture: Facture, ...) implémentée par une classe concrète. Celle-ci ferait appel aux services de persistence (par ex. un repository ou le ModelContext) pour insérer la nouvelle ligne et mettre à jour la facture, le tout sans que la Vue ou même le modèle Facture n’aient besoin de connaître ces détails. Un use case se déclenche généralement en réponse à une action de l’utilisateur ou un événement (ex: l’utilisateur appuie sur “Ajouter”) et aboutit à une modification du modèle ou de l’état de l’application ￼.

Avantages : En isolant ainsi chaque règle métier dans un use case dédié, on obtient un code plus modulaire et maintenable. Chaque use case peut être développé et testé indépendamment, ce qui facilite les tests unitaires (on peut par exemple injecter un faux repository en entrée du use case). La logique métier se trouve séparée de l’interface et du stockage, ce qui réduit les duplications et le couplage fort ￼. Cette séparation respecte le principe de responsabilité unique et rend l’application plus robuste face aux changements (on peut modifier l’implémentation interne d’un use case sans impacter l’UI, ou changer le système de stockage sans altérer la logique métier).

Exemple d’implémentation d’un Use Case : pour illustrer, implémentons un cas d’utilisation « Ajouter une ligne de produit à une Facture ». On peut créer une classe ou structure dédiée, à laquelle on fournira les dépendances nécessaires (ici, probablement un accès au contexte de données ou à un repository gérant les factures). Cette classe aura une méthode execute qui réalise l’ajout de la ligne en respectant la logique métier (y compris les validations éventuelles) :

protocol AjouterLigneUseCase {
    func execute(facture: Facture, designation: String, quantite: Double, prixUnitaire: Double) throws 
}

struct AjouterLigneUseCaseImpl: AjouterLigneUseCase {
    /// On peut injecter un repository ou le contexte SwiftData requis
    let contexte: ModelContext  // ou bien un protocole abstraction de la DB

    func execute(facture: Facture, designation: String, quantite: Double, prixUnitaire: Double) throws {
        // 1. Créer la nouvelle ligne (sans l'attacher encore à la facture)
        let nouvelleLigne = LigneFacture(designation: designation, quantite: quantite, prixUnitaire: prixUnitaire)
        // 2. Insérer la ligne dans le contexte de données
        contexte.insert(nouvelleLigne)
        // 3. Établir la relation avec la facture existante
        nouvelleLigne.facture = facture
        facture.lignes.append(nouvelleLigne)
        // 4. Sauvegarder le contexte (propager les changements persistents)
        try contexte.save()
    }
}

Dans cet exemple, le use case encapsule toute la logique d’ajout d’une ligne : la création de l’objet, l’insertion dans la base locale, la mise à jour de l’agrégat Facture, et la gestion d’erreur en cas d’échec de la sauvegarde. La Vue ou le ViewModel n’auront plus qu’à appeler ajouterLigneUseCase.execute(facture, "Produit X", 2, 49.99) lorsqu’il faut ajouter une ligne, sans se soucier des détails de persistence. On pourrait écrire de la même manière un use case CreerFactureUseCase pour générer une nouvelle facture vierge (en calculant automatiquement le prochain numéro disponible, comme le fait creerNouvelleFacture dans l’extension précédente).

À noter : Dans une architecture inspirée de Clean Architecture, on introduit souvent une couche Repository comme intermédiaire entre la couche domaine (use cases) et la couche de données. Ici, pour simplifier, on utilise directement ModelContext, mais idéalement le use case pourrait appeler un FactureRepository (protocol abstrait) ayant des méthodes comme addLine(to: Facture, ...) ou saveInvoice(_) – dont l’implémentation concrète utiliserait SwiftData en coulisse. Cela permettrait de facilement changer de backend de stockage sans modifier les use cases (ex: remplacer SwiftData par une API ou autre base, en ne changeant que le repository concret). Cette idée est évoquée par Azamsharp lorsqu’il propose d’introduire un protocole DataAccess pour découpler la logique SwiftData du reste ￼ ￼, ce qui améliore la testabilité et la flexibilité de l’application.

En résumé, découpler la logique métier avec des use cases signifie que nos classes Facture et Client ne contiendront plus de comportements complexes autres que de simples propriétés/calculs, et que toute opération notable sera implémentée dans un service ou interactor dédié. Cette approche correspond à la couche Domain de l’architecture propre, où les cas d’utilisation représentent les actions possibles sur nos entités métier, indépendantes des détails de l’UI ou de la base de données ￼ ￼.

Utilisation de DTO pour l’Import/Export JSON

Les DTO (Data Transfer Objects) sont des structures de données simplifiées utilisées pour les échanges de données, par exemple l’encodage/décodage en JSON lors de l’import/export ou de la communication réseau. Puisque vous souhaitez que les DTO soient utilisés pour l’import/export JSON, nous allons introduire des types FactureDTO, LigneFactureDTO (et éventuellement ClientDTO) correspondant aux modèles du domaine, mais conçus spécifiquement pour la sérialisation. L’idée est de dissocier la représentation persistante interne (liée à SwiftData, avec ses relations complexes) de la représentation externe (typiquement un format JSON plat ou imbriqué) afin de gagner en flexibilité et éviter d’exposer les détails internes.

Cette pratique est recommandée dans de nombreux cas : « Utiliser des types DTO dédiés pour le décodage JSON permet de mapper proprement la réponse API puis de convertir les données dans nos modèles SwiftData selon les besoins » ￼. En introduisant une telle couche de transfert, on isole la logique de décodage/encodage du reste de l’application, ce qui garde nos modèles propres (ils ne contiennent pas de code de parsing JSON, ni d’hypothèses sur la structure externe des données) ￼. Par exemple, en cas de réponse JSON complexe ou de schéma différent, on peut adapter les DTO sans toucher aux entités métier. C’est particulièrement utile lorsque les données proviennent d’une API tierce ou d’un autre système sur lequel on n’a pas la maîtrise ￼.

Définition des DTO : On définit généralement les DTO comme des struct Swift conformant à Codable (pour la sérialisation facile). Ils contiennent uniquement les champs nécessaires à l’échange. Pour notre cas, on peut définir un FactureDTO qui contient des propriétés équivalentes à Facture (mais types bruts sans lien direct avec SwiftData), et de même un LigneFactureDTO. Par exemple :

struct FactureDTO: Codable {
    var id: UUID
    var numero: String
    var dateFacture: Date
    var dateEcheance: Date?
    var datePaiement: Date?
    var tva: Double
    var conditionsPaiement: String   // on peut utiliser RawValue de l'enum
    var remisePourcentage: Double
    var statut: String
    var notes: String
    var notesCommentaire: String?
    var clientId: UUID?             // ou informations du client
    var lignes: [LigneFactureDTO]
}

struct LigneFactureDTO: Codable {
    var designation: String
    var quantite: Double
    var prixUnitaire: Double
    var referenceCommande: String?
    var dateCommande: Date?
}

Ici, on a choisi de stocker dans le DTO uniquement l’identifiant du client (clientId) pour référencer le client associé à la facture. Alternativement, si l’on souhaite un JSON autonome, on pourrait inclure un sous-objet client avec quelques infos du client (ou un ClientDTO complet). Le choix dépend du contexte d’import/export : s’il s’agit de transférer des factures vers une autre instance de l’application, on peut supposer que les clients correspondants existent déjà (d’où l’usage d’un ID). S’il s’agit d’exporter pour un usage indépendant (sauvegarde, envoi externe), inclure les données du client dans le JSON peut être pertinent.

Mapping entre Model et DTO : Il faut écrire la conversion dans les deux sens. On peut ajouter des initialiseurs ou extensions pour faciliter cela : par ex. une extension sur Facture pour produire un FactureDTO, et une méthode statique sur Facture (ou dans un service de mapping) pour créer une Facture à partir d’un DTO. Le mapping consiste à copier les valeurs simples et à convertir les champs complexes (par ex. transformer le statut .envoyee en sa chaîne "Envoyée" si on choisit de stocker des String en JSON). Pour les relations, il faudra :
    •    lors de l’export JSON : convertir chaque LigneFacture du tableau lignes en LigneFactureDTO équivalent, et inclure la référence au client (selon l’option choisie, ID ou objet).
    •    lors de l’import JSON : rechercher le Client correspondant à clientId (si fourni) ou en créer un nouveau si nécessaire, créer une nouvelle instance de Facture dans le contexte (en appelant, par exemple, le use case de création de facture), puis créer chaque LigneFacture à partir des données du DTO et l’ajouter à la facture (éventuellement en utilisant le use case AjouterLigneUseCase pour respecter la logique d’insertion).

Voici un exemple simplifié d’extension pour la conversion :

extension Facture {
    func toDTO() -> FactureDTO {
        return FactureDTO(
            id: id,
            numero: numero,
            dateFacture: dateFacture,
            dateEcheance: dateEcheance,
            datePaiement: datePaiement,
            tva: tva,
            conditionsPaiement: conditionsPaiement.rawValue,  // stocker le string
            remisePourcentage: remisePourcentage,
            statut: statut.rawValue,
            notes: notes,
            notesCommentaire: NotesCommentaireFacture,
            clientId: client?.id,
            lignes: lignes.map { $0.toDTO() }
        )
    }
}

extension LigneFacture {
    func toDTO() -> LigneFactureDTO {
        return LigneFactureDTO(
            designation: designation,
            quantite: quantite,
            prixUnitaire: prixUnitaire,
            referenceCommande: referenceCommande,
            dateCommande: dateCommande
        )
    }
}

Pour l’import, on pourrait créer une fonction dans un service d’import qui parcourt un tableau de FactureDTO décodés depuis JSON et les persiste via SwiftData. Un pseudo-code pourrait être :

func importInvoices(from data: Data, into context: ModelContext) throws {
    let decoder = JSONDecoder()
    let dtos = try decoder.decode([FactureDTO].self, from: data)
    for dto in dtos {
        // Trouver ou créer le Client
        let client: Client? = dto.clientId.flatMap { try? context.fetch(.init(predicate: #Predicate<Client> { $0.id == $0.clientId }))?.first }
            ?? /* sinon, éventuellement créer un nouveau Client à partir d'infos du DTO */
        // Créer la nouvelle Facture
        let facture = Facture(client: client ?? Client(nom: "Nouveau", ...), numero: dto.numero, 
                              conditionsPaiement: ConditionsPaiement(rawValue: dto.conditionsPaiement) ?? .virement,
                              remisePourcentage: dto.remisePourcentage)
        facture.dateFacture = dto.dateFacture
        facture.dateEcheance = dto.dateEcheance
        facture.notes = dto.notes
        if let statutStr = StatutFacture(rawValue: dto.statut) {
            facture.statut = statutStr
        }
        context.insert(facture)
        // Ajouter les lignes
        dto.lignes.forEach { ligneDTO in 
            // réutilisation éventuelle du use case AjouterLigne
            let ligne = LigneFacture(designation: ligneDTO.designation, quantite: ligneDTO.quantite, prixUnitaire: ligneDTO.prixUnitaire,
                                     referenceCommande: ligneDTO.referenceCommande, dateCommande: ligneDTO.dateCommande)
            context.insert(ligne)
            ligne.facture = facture
            facture.lignes.append(ligne)
        }
    }
    try context.save()
}

Dans cet exemple, on voit que le mapping inverse repose sur la correspondance des champs du DTO vers le modèle. On utilise l’id du client pour le retrouver via une requête SwiftData (ou on en crée un nouveau si nécessaire). On crée la Facture et on l’insère, puis on crée chacune des lignes. On aurait aussi pu utiliser directement nos use cases (CreerFactureUseCase, AjouterLigneUseCase) à la place d’accéder directement au contexte, ce qui serait préférable pour rester cohérent avec la séparation de couches.

Enfin, soulignons que cette approche via DTO facilite la maintenance : si plus tard la structure de stockage change ou si on veut utiliser un autre système (par ex. envoyer/recevoir les factures via une API REST), il suffira d’adapter le mapping, sans toucher aux entités Facture et LigneFacture elles-mêmes. De plus, cela évite d’avoir du code JSON partout dans les modèles. Un développeur sur Reddit confirme cette pratique : dans son application SwiftData, les modèles n’ont pas de code réseau ou JSON intégré ; à la place, il utilise un service d’import qui télécharge des objets DTO puis les insère en base via les modèles SwiftData ￼. De même, Azamsharp suggère la création d’un composant Importer pour gérer l’import de données JSON, justement pour séparer ce code du reste de l’app et garder celle-ci propre et testable ￼. Cette stratégie renforce l’architecture en couches : la logique d’accès aux données externes (fichiers JSON, API) est confinée dans un service spécialisé, les use cases orchestrent la logique métier pure, et les modèles SwiftData restent simples et focalisés sur la représentation locale des données.

En conclusion, en adoptant des use cases pour la logique métier et des DTO pour les échanges JSON, on obtient une architecture mieux structurée :
    •    Les modèles (Facture, Client, etc.) sont réduits à leur rôle de conteneurs de données (avec quelques calculs basiques),
    •    Les use cases gèrent les opérations métier (création, mises à jour, validations) de manière réutilisable et testable indépendamment de l’UI ou de la base,
    •    Les DTO/Services d’import-export s’occupent de la conversion vers et depuis les formats externes (JSON), sans impacter les modèles internes.

Cette séparation des préoccupations rend le code plus clair, facilite les tests unitaires et prépare l’application à évoluer (changement de format de données, de source de données ou d’UI) en limitant l’impact aux couches concernées et en évitant les effets de bord. Les cas d’utilisation bien définis et les DTO appropriés contribuent à une application modulaire, maintenable et évolutive, conformément aux principes des architectures modernes.  ￼ ￼
