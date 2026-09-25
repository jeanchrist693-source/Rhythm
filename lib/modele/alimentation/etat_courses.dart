// lib/modele/alimentation/etat_courses.dart
//
// L'état des ACHATS (Riverpod) et sa PERSISTANCE : la liste de courses, le
// garde-manger, les épiceries passées, ce qui est sorti (fini ou jeté) —
// quatre tables (`listeCourses`, `gardeManger`, `achatsAlim`,
// `sortiesAlim`) et les réglages (`reglagesCourses`, `versionCourses`).
//
// Le parcours : la LISTE (fusionnée) → au MAGASIN, chaque article va au
// panier avec son prix, sa taxe, sa consigne → « Terminer » enregistre
// l'épicerie (l'historique des prix, le budget) → RANGER : chaque aliment
// entre au garde-manger là où il se garde le mieux, avec sa date → fini ou
// jeté, il sort (le gaspillage se compte) ; un ESSENTIEL fini revient seul
// sur la liste (réassort).
//
// Premier lancement : tout est vide. Sans dépôt (tests, captures) : une
// DÉMONSTRATION (une liste, un garde-manger dont trois aliments expirent
// bientôt, deux mois d'épiceries, un budget).

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../utils/dates.dart';
import '../depot.dart';
import '../etat_habitudes.dart';
import '../etat_sante.dart';
import 'calculs_courses.dart';
import 'conservation.dart';
import 'courses.dart';
import 'taxes.dart';

final coursesProvider = NotifierProvider<CoursesNotifier, EtatCourses>(
  CoursesNotifier.new,
);

class CoursesNotifier extends Notifier<EtatCourses> {
  Depot? _depot;
  int _compteur = 0;

  @override
  EtatCourses build() {
    final auj = ref.read(aujourdhuiProvider);
    final depot = ref.watch(depotProvider);
    _depot = depot;
    if (depot == null) return GraineCourses.demonstration(auj);
    try {
      final document = depot.lire();
      if (document != null && document.containsKey('versionCourses')) {
        return EtatCourses.depuisDocument(document);
      }
    } catch (_) {
      return const EtatCourses();
    }
    const graine = EtatCourses();
    try {
      depot.ecrire(graine.versDocument());
    } catch (_) {}
    return graine;
  }

  String nouvelId(String prefixe) =>
      '$prefixe-${DateTime.now().microsecondsSinceEpoch}-${++_compteur}';

  DateTime get _maintenant => ref.read(horlogeProvider)();

  void _muter(EtatCourses nouvel) {
    state = nouvel;
    try {
      _depot?.ecrire(nouvel.versDocument());
    } catch (_) {}
  }

  // ── La liste ──────────────────────────────────────────────────────────────

  /// Ajoute (ou fusionne) un article ; rend l'article et s'il a été
  /// fusionné.
  (ArticleListe, bool) ajouter(
    String nom, {
    required Rayon rayon,
    Quantite? quantite,
    String? origine,
  }) {
    final (liste, article, fusionne) = ajouterALaListe(
      state.liste,
      id: nouvelId('art'),
      nom: nom,
      rayon: rayon,
      maintenant: _maintenant,
      quantite: quantite,
      origine: origine,
    );
    _muter(state.copierAvec(liste: liste));
    return (article, fusionne);
  }

  /// Ajoute ce que des recettes demandent (nom, rayon, quantités à
  /// acheter, recettes d'origine) — fusionné avec la liste ; le nombre
  /// d'articles touchés.
  int ajouterBesoins(
    List<(String, Rayon, List<Quantite>, List<String>)> besoins,
  ) {
    var liste = state.liste;
    for (final (nom, rayon, quantites, origines) in besoins) {
      for (final q in quantites.isEmpty ? const <Quantite?>[null] : quantites) {
        (liste, _, _) = ajouterALaListe(
          liste,
          id: nouvelId('art'),
          nom: nom,
          rayon: rayon,
          maintenant: _maintenant,
          quantite: q,
          origines: origines,
        );
      }
    }
    _muter(state.copierAvec(liste: liste));
    return besoins.length;
  }

  void modifierArticle(ArticleListe a) => _muter(
    state.copierAvec(
      liste: [for (final x in state.liste) x.id == a.id ? a : x],
    ),
  );

  void retirerArticle(String id) => _muter(
    state.copierAvec(
      liste: [
        for (final x in state.liste)
          if (x.id != id) x,
      ],
    ),
  );

  /// Vide la liste (sauf ce qui est au panier).
  void viderListe() => _muter(
    state.copierAvec(
      liste: [
        for (final x in state.liste)
          if (x.auPanier) x,
      ],
    ),
  );

  // ── Le magasin ────────────────────────────────────────────────────────────

  void mettreAuPanier(String id, LignePanier p) {
    final a = state.article(id);
    if (a == null) return;
    modifierArticle(a.copierAvec(panier: () => p));
  }

  void retirerDuPanier(String id) {
    final a = state.article(id);
    if (a == null) return;
    modifierArticle(a.copierAvec(panier: () => null));
  }

  void choisirMagasin(String? magasin) =>
      modifierReglages(state.reglages.copierAvec(magasin: () => magasin));

  /// Termine l'épicerie : ce qui est au panier devient un [Achat] (et
  /// quitte la liste). `null` si le panier est vide.
  Achat? terminer({required String? magasin}) {
    final panier = [
      for (final a in state.liste)
        if (a.auPanier) a,
    ];
    if (panier.isEmpty) return null;
    final maintenant = _maintenant;
    final achat = Achat(
      id: nouvelId('ach'),
      date: maintenant,
      magasin: magasin,
      lignes: [
        for (final a in panier)
          LigneAchat(
            nom: a.nom,
            rayon: a.rayon,
            panier: a.panier!,
            quantites: a.quantites,
          ),
      ],
      caisse: caisseDuPanier(panier, baremeAu(maintenant)),
    );
    _muter(
      state.copierAvec(
        liste: [
          for (final a in state.liste)
            if (!a.auPanier) a,
        ],
        achats: [...state.achats, achat],
      ),
    );
    return achat;
  }

  void supprimerAchat(String id) => _muter(
    state.copierAvec(
      achats: [
        for (final a in state.achats)
          if (a.id != id) a,
      ],
    ),
  );

  // ── Le garde-manger ───────────────────────────────────────────────────────

  void ranger(List<ArticleGardeManger> articles) {
    if (articles.isEmpty) return;
    _muter(state.copierAvec(gardeManger: [...state.gardeManger, ...articles]));
  }

  void modifierRange(ArticleGardeManger a) => _muter(
    state.copierAvec(
      gardeManger: [for (final x in state.gardeManger) x.id == a.id ? a : x],
    ),
  );

  /// Un repère de conservation appris de l'IA pour [nom] (hors du guide) :
  /// gardé, il sert désormais partout (rangement, fiche, déplacement).
  void apprendreConservation(String nom, Conservation c) {
    final cle = cleConservation(nom);
    if (cle.isEmpty) return;
    _muter(
      state.copierAvec(
        conservations: {
          ...state.conservations,
          cle: Conservation(
            [cle],
            c.rayon,
            c.ideal,
            c.conseil,
            frigo: c.frigo,
            congelo: c.congelo,
            ambiant: c.ambiant,
            ouvert: c.ouvert,
          ),
        },
      ),
    );
  }

  /// Ouvert aujourd'hui : la date ne peut que raccourcir.
  void ouvrir(String id) {
    final a = state.enReserve(id);
    if (a == null) return;
    final le = jourDe(_maintenant);
    final g = conservationDArticle(a, apprises: state.conservations);
    modifierRange(
      a.copierAvec(
        ouvertLe: () => le,
        peremption: () => peremptionApresOuverture(g, a.peremption, le),
      ),
    );
  }

  /// Déplacé (au congélateur, décongelé au frigo…) : la date suit.
  void deplacer(String id, Emplacement ou) {
    final a = state.enReserve(id);
    if (a == null || a.emplacement == ou) return;
    final le = jourDe(_maintenant);
    modifierRange(
      a.copierAvec(
        emplacement: ou,
        peremption: () => peremptionApresDeplacement(
          a,
          ou,
          le,
          apprises: state.conservations,
        ),
      ),
    );
  }

  /// Une partie utilisée : il en reste [reste] (même unité).
  void utiliser(String id, double reste) {
    final a = state.enReserve(id);
    final q = a?.quantite;
    if (a == null || q == null) return;
    if (reste <= 0) {
      finir(id);
      return;
    }
    modifierRange(
      a.copierAvec(
        quantite: () => Quantite(reste, q.unite),
        prix: () => a.prix == null ? null : a.prix! * reste / q.valeur,
      ),
    );
  }

  /// Fini (mangé) : il sort ; un essentiel revient sur la liste. Rend
  /// l'article de la liste s'il y est revenu.
  ArticleListe? finir(String id) => _sortir(id, jete: false);

  /// Jeté : il sort, et sa valeur compte au gaspillage.
  ArticleListe? jeter(String id) => _sortir(id, jete: true);

  ArticleListe? _sortir(String id, {required bool jete}) {
    final a = state.enReserve(id);
    if (a == null) return null;
    final maintenant = _maintenant;
    var etat = state.copierAvec(
      gardeManger: [
        for (final x in state.gardeManger)
          if (x.id != id) x,
      ],
      sorties: [
        ...state.sorties,
        Sortie(
          id: nouvelId('sor'),
          date: maintenant,
          nom: a.nom,
          rayon: a.rayon,
          jete: jete,
          valeur: jete ? (a.prix ?? 0) : 0,
        ),
      ],
    );
    ArticleListe? retour;
    // Le réassort : un essentiel qui n'est plus au garde-manger revient sur
    // la liste (une seule fois).
    final encore = dejaAuGardeManger(etat.gardeManger, a.nom);
    if (a.essentiel && encore.isEmpty) {
      final (liste, article, _) = ajouterALaListe(
        etat.liste,
        id: nouvelId('art'),
        nom: a.nom,
        rayon: a.rayon,
        maintenant: maintenant,
        origine: kOrigineReassort,
      );
      etat = etat.copierAvec(liste: liste);
      retour = article;
    }
    _muter(etat);
    return retour;
  }

  void retirerDuGardeManger(String id) => _muter(
    state.copierAvec(
      gardeManger: [
        for (final x in state.gardeManger)
          if (x.id != id) x,
      ],
    ),
  );

  /// Remet un aliment du garde-manger sur la liste.
  ArticleListe remettreSurLaListe(ArticleGardeManger a) =>
      ajouter(a.nom, rayon: a.rayon).$1;

  // ── Réglages ──────────────────────────────────────────────────────────────

  void modifierReglages(ReglagesCourses r) =>
      _muter(state.copierAvec(reglages: r));
}

/// L'origine d'un article revenu seul sur la liste.
const String kOrigineReassort = 'réassort';

// ═══ La démonstration ═══════════════════════════════════════════════════════

abstract final class GraineCourses {
  static EtatCourses demonstration(DateTime aujourdhui) {
    final auj = jourDe(aujourdhui);
    DateTime a(int jours, [int h = 17]) {
      final j = plusJours(auj, -jours);
      return DateTime(j.year, j.month, j.day, h, 20);
    }

    var n = 0;
    ArticleListe l(
      String nom,
      Rayon rayon, [
      List<Quantite> q = const [],
      List<String> origines = const [],
    ]) => ArticleListe(
      id: 'demo-art-${++n}',
      nom: nom,
      rayon: rayon,
      ajoute: a(1, 12),
      quantites: q,
      origines: origines,
    );

    LigneAchat la(
      String nom,
      Rayon rayon,
      double pu, {
      double nombre = 1,
      StatutTaxe statut = StatutTaxe.detaxe,
      bool auPoids = false,
      double consigne = 0,
    }) => LigneAchat(
      nom: nom,
      rayon: rayon,
      panier: LignePanier(
        prixUnitaire: pu,
        nombre: nombre,
        statut: statut,
        auPoids: auPoids,
        consigneUnitaire: consigne,
      ),
    );

    Achat achat(int jours, String magasin, List<LigneAchat> lignes) {
      final date = a(jours);
      return Achat(
        id: 'demo-ach-$jours',
        date: date,
        magasin: magasin,
        lignes: lignes,
        caisse: Caisse.de([
          for (final x in lignes)
            (
              prix: x.panier.prix,
              statut: x.panier.statut,
              consigne: x.panier.consigne,
            ),
        ], baremeAu(date)),
      );
    }

    List<LigneAchat> semaine(int k) => [
      la(
        'Bananes',
        Rayon.fruits,
        1.69 + (k % 2) * 0.1,
        auPoids: true,
        nombre: 1.2,
      ),
      la('Lait 2 %', Rayon.laitiers, 6.49 - (k % 3) * 0.3),
      la('Yogourt grec', Rayon.laitiers, 5.99),
      la(
        'Poitrines de poulet',
        Rayon.viandes,
        13.2 - (k % 2) * 1.1,
        auPoids: true,
        nombre: 0.9,
      ),
      la('Pain de blé entier', Rayon.boulangerie, 3.99),
      la('Épinards', Rayon.legumes, 3.49),
      la('Œufs', Rayon.laitiers, 4.79 + (k % 2) * 0.4),
      if (k.isEven)
        la('Croustilles', Rayon.collations, 4.49, statut: StatutTaxe.tpsTvq),
      if (k % 3 == 0)
        la('Barres tendres', Rayon.collations, 3.99, statut: StatutTaxe.tps),
      if (k % 3 == 1)
        la(
          'Eau pétillante',
          Rayon.boissons,
          1.29,
          nombre: 6,
          statut: StatutTaxe.tpsTvq,
          consigne: 0.10,
        ),
      if (k % 2 == 1)
        la(
          'Savon à vaisselle',
          Rayon.entretien,
          3.79,
          statut: StatutTaxe.tpsTvq,
        ),
    ];

    final magasins = ['Maxi', 'IGA', 'Super C', 'Maxi'];
    final achats = [
      for (var k = 8; k >= 1; k--)
        achat(k * 7 - 3, magasins[k % 4], semaine(k)),
    ];

    return EtatCourses(
      liste: [
        l('Bananes', Rayon.fruits, const [Quantite(6)]),
        l(
          'Lait 2 %',
          Rayon.laitiers,
          const [Quantite(2, Unite.l)],
          const [kOrigineReassort],
        ),
        l(
          'Poitrines de poulet',
          Rayon.viandes,
          const [Quantite(1, Unite.kg)],
          const ['Bol poulet'],
        ),
        l('Riz basmati', Rayon.cereales, const [Quantite(1, Unite.paquet)]),
        l('Brocoli', Rayon.legumes, const [Quantite(2)]),
        l('Oignons', Rayon.legumes, const [Quantite(3)], const ['Chili']),
        l('Croustilles', Rayon.collations),
        l('Papier hygiénique', Rayon.hygiene),
      ],
      gardeManger: [
        ArticleGardeManger(
          id: 'demo-gm-1',
          nom: 'Yogourt grec',
          emplacement: Emplacement.frigo,
          rayon: Rayon.laitiers,
          entre: a(9),
          peremption: plusJours(auj, 1),
          prix: 5.99,
          essentiel: true,
        ),
        ArticleGardeManger(
          id: 'demo-gm-2',
          nom: 'Épinards',
          emplacement: Emplacement.frigo,
          rayon: Rayon.legumes,
          entre: a(4),
          peremption: auj,
          ouvertLe: plusJours(auj, -2),
          prix: 3.49,
        ),
        ArticleGardeManger(
          id: 'demo-gm-3',
          nom: 'Poitrines de poulet',
          emplacement: Emplacement.frigo,
          rayon: Rayon.viandes,
          entre: a(2),
          quantite: const Quantite(900, Unite.g),
          peremption: plusJours(auj, 2),
          prix: 11.88,
        ),
        ArticleGardeManger(
          id: 'demo-gm-4',
          nom: 'Œufs',
          emplacement: Emplacement.frigo,
          rayon: Rayon.laitiers,
          entre: a(4),
          quantite: const Quantite(8),
          peremption: plusJours(auj, 24),
          prix: 4.79,
          essentiel: true,
        ),
        ArticleGardeManger(
          id: 'demo-gm-5',
          nom: 'Lait 2 %',
          emplacement: Emplacement.frigo,
          rayon: Rayon.laitiers,
          entre: a(4),
          quantite: const Quantite(1, Unite.l),
          peremption: plusJours(auj, 5),
          prix: 6.49,
          essentiel: true,
        ),
        ArticleGardeManger(
          id: 'demo-gm-6',
          nom: 'Cheddar',
          emplacement: Emplacement.frigo,
          rayon: Rayon.laitiers,
          entre: a(12),
          peremption: plusJours(auj, 23),
          prix: 7.99,
        ),
        ArticleGardeManger(
          id: 'demo-gm-7',
          nom: 'Bananes',
          emplacement: Emplacement.comptoir,
          rayon: Rayon.fruits,
          entre: a(4),
          quantite: const Quantite(3),
          peremption: plusJours(auj, 1),
          prix: 2.03,
        ),
        ArticleGardeManger(
          id: 'demo-gm-8',
          nom: 'Bœuf haché maigre',
          emplacement: Emplacement.congelateur,
          rayon: Rayon.viandes,
          entre: a(20),
          quantite: const Quantite(450, Unite.g),
          peremption: plusJours(auj, 70),
          prix: 6.5,
        ),
        ArticleGardeManger(
          id: 'demo-gm-9',
          nom: 'Bleuets surgelés',
          emplacement: Emplacement.congelateur,
          rayon: Rayon.surgeles,
          entre: a(30),
          peremption: plusJours(auj, 300),
          prix: 5.49,
        ),
        ArticleGardeManger(
          id: 'demo-gm-10',
          nom: 'Pain de blé entier',
          emplacement: Emplacement.armoire,
          rayon: Rayon.boulangerie,
          entre: a(4),
          peremption: plusJours(auj, 2),
          prix: 3.99,
        ),
        ArticleGardeManger(
          id: 'demo-gm-11',
          nom: 'Gruau',
          emplacement: Emplacement.armoire,
          rayon: Rayon.cereales,
          entre: a(40),
          peremption: plusJours(auj, 150),
          prix: 4.29,
          essentiel: true,
        ),
        ArticleGardeManger(
          id: 'demo-gm-12',
          nom: "Beurre d'arachide",
          emplacement: Emplacement.armoire,
          rayon: Rayon.condiments,
          entre: a(25),
          ouvertLe: plusJours(auj, -20),
          peremption: plusJours(auj, 40),
          prix: 5.99,
        ),
        ArticleGardeManger(
          id: 'demo-gm-13',
          nom: 'Pommes de terre',
          emplacement: Emplacement.armoire,
          rayon: Rayon.legumes,
          entre: a(6),
          quantite: const Quantite(2, Unite.kg),
          peremption: plusJours(auj, 8),
          prix: 3.99,
        ),
        ArticleGardeManger(
          id: 'demo-gm-14',
          nom: 'Tomates',
          emplacement: Emplacement.comptoir,
          rayon: Rayon.legumes,
          entre: a(3),
          quantite: const Quantite(4),
          peremption: plusJours(auj, 3),
          prix: 3.29,
        ),
      ],
      achats: achats,
      sorties: [
        Sortie(
          id: 'demo-sor-1',
          date: a(6),
          nom: 'Coriandre',
          rayon: Rayon.legumes,
          jete: true,
          valeur: 1.99,
        ),
        Sortie(
          id: 'demo-sor-2',
          date: a(3),
          nom: 'Fraises',
          rayon: Rayon.fruits,
          jete: true,
          valeur: 4.99,
        ),
        Sortie(
          id: 'demo-sor-3',
          date: a(2),
          nom: 'Pain de blé entier',
          rayon: Rayon.boulangerie,
          jete: false,
        ),
      ],
      reglages: const ReglagesCourses(budgetMois: 600, magasin: 'Maxi'),
    );
  }
}
