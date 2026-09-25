// lib/modele/alimentation/etat_recettes.dart
//
// L'état des RECETTES (Riverpod) et sa PERSISTANCE : le livre et la
// planification — deux tables (`recettesAlim`, `planAlim`) et les réglages
// (`reglagesRecettes`, `versionRecettes`).
//
// Le parcours : une RECETTE (écrite à la main, macros calculées par la
// base) → « À la liste » (ce qui manque, moins le garde-manger) → le MODE
// CUISINE → « C'est prêt » : ce qu'on mange va au JOURNAL, les RESTES au
// garde-manger (en portions), le garde-manger est DÉCOMPTÉ. La SEMAINE :
// des repas prévus (recette, produit, autre chose), la liste de la semaine,
// la cuisine en lot, les rappels de décongélation.
//
// Les MINUTEURS du mode cuisine vivent à part ([minuteursProvider]) : ils
// survivent à l'écran (on peut revenir à la recette pendant que le riz
// cuit) et deviennent des notifications si l'app passe derrière
// (`systeme/rappels_recettes.dart`) ; ils ne sont pas enregistrés.
//
// Premier lancement : un livre vide — « Recettes de départ » en ajoute huit
// d'un toucher (valeurs du FCÉN). Sans dépôt (tests, captures) : la
// DÉMONSTRATION (ces huit recettes, déjà cuisinées, et une semaine prévue).

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../utils/dates.dart';
import '../depot.dart';
import '../etat_habitudes.dart';
import '../etat_sante.dart';
import '../modeles.dart';
import 'alimentation.dart';
import 'calculs_recettes.dart';
import 'courses.dart';
import 'etat_alimentation.dart';
import 'etat_courses.dart';
import 'nutriments.dart';
import 'recettes.dart';

final recettesProvider = NotifierProvider<RecettesNotifier, EtatRecettes>(
  RecettesNotifier.new,
);

class RecettesNotifier extends Notifier<EtatRecettes> {
  Depot? _depot;
  int _compteur = 0;

  @override
  EtatRecettes build() {
    final auj = ref.read(aujourdhuiProvider);
    final depot = ref.watch(depotProvider);
    _depot = depot;
    if (depot == null) return GraineRecettes.demonstration(auj);
    try {
      final document = depot.lire();
      if (document != null && document.containsKey('versionRecettes')) {
        return EtatRecettes.depuisDocument(document);
      }
    } catch (_) {
      return const EtatRecettes();
    }
    const graine = EtatRecettes();
    try {
      depot.ecrire(graine.versDocument());
    } catch (_) {}
    return graine;
  }

  String nouvelId(String prefixe) =>
      '$prefixe-${DateTime.now().microsecondsSinceEpoch}-${++_compteur}';

  DateTime get _maintenant => ref.read(horlogeProvider)();

  void _muter(EtatRecettes nouvel) {
    state = nouvel;
    try {
      _depot?.ecrire(nouvel.versDocument());
    } catch (_) {}
  }

  // ── Le livre ──────────────────────────────────────────────────────────────

  /// Ajoute [r], ou la remplace si elle existe déjà.
  void enregistrer(Recette r) {
    final existe = state.recettes.any((x) => x.id == r.id);
    _muter(
      state.copierAvec(
        recettes: existe
            ? [for (final x in state.recettes) x.id == r.id ? r : x]
            : [...state.recettes, r],
      ),
    );
  }

  /// Supprime [id] et ses repas prévus à venir (les passés restent : ils
  /// ne comptent plus nulle part).
  void supprimer(String id) {
    final auj = jourDe(_maintenant);
    _muter(
      state.copierAvec(
        recettes: [
          for (final r in state.recettes)
            if (r.id != id) r,
        ],
        plan: [
          for (final p in state.plan)
            if (p.recetteId != id || p.jour.isBefore(auj)) p,
        ],
      ),
    );
  }

  /// Ajoute les recettes de départ qui manquent (par nom) ; leur nombre.
  int ajouterRecettesDeDepart() {
    final noms = {for (final r in state.recettes) r.nom.toLowerCase()};
    final nouvelles = [
      for (final r in GraineRecettes.depart(_maintenant))
        if (!noms.contains(r.nom.toLowerCase())) r,
    ];
    if (nouvelles.isEmpty) return 0;
    _muter(state.copierAvec(recettes: [...state.recettes, ...nouvelles]));
    return nouvelles.length;
  }

  // ── La planification ──────────────────────────────────────────────────────

  RepasPrevu planifier({
    required DateTime jour,
    required MomentRepas moment,
    String? recetteId,
    String? produitId,
    String? libre,
    double? portions,
  }) {
    final p = RepasPrevu(
      id: nouvelId('plan'),
      jour: jourDe(jour),
      moment: moment,
      recetteId: recetteId,
      produitId: produitId,
      libre: libre,
      portions: portions ?? state.reglages.personnes.toDouble(),
    );
    // Le plan ne garde que le dernier mois.
    final limite = plusJours(jourDe(_maintenant), -31);
    _muter(
      state.copierAvec(
        plan: [
          for (final x in state.plan)
            if (!x.jour.isBefore(limite)) x,
          p,
        ],
      ),
    );
    return p;
  }

  void modifierPrevu(RepasPrevu p) => _muter(
    state.copierAvec(plan: [for (final x in state.plan) x.id == p.id ? p : x]),
  );

  void retirerPrevu(String id) => _muter(
    state.copierAvec(
      plan: [
        for (final x in state.plan)
          if (x.id != id) x,
      ],
    ),
  );

  void modifierReglages(ReglagesRecettes r) =>
      _muter(state.copierAvec(reglages: r));

  // ── Cuisiner, manger ──────────────────────────────────────────────────────

  /// « C'est prêt » : [recette] cuisinée pour [portions] ; [mangees] au
  /// journal (aujourd'hui, à [moment]) ; le reste rangé à [restesA] (sous
  /// le nom [nomRestes]) ; le garde-manger décompté ([decomptes] choisis :
  /// ce qu'il en reste, ou fini). Rend l'entrée du journal, s'il y en a une.
  EntreeJournal? cuisiner({
    required Recette recette,
    required double portions,
    required double mangees,
    required MomentRepas moment,
    required Emplacement? restesA,
    required String nomRestes,
    List<Decompte> decomptes = const [],
  }) {
    final maintenant = _maintenant;
    final auj = jourDe(maintenant);
    final r = state.recette(recette.id) ?? recette;
    enregistrer(r.copierAvec(cuisinee: [...r.cuisinee, auj]));

    EntreeJournal? entree;
    if (mangees > 0) {
      final alimentation = ref.read(alimentationProvider.notifier);
      entree = entreeDeRecette(
        id: alimentation.nouvelId('ent'),
        recette: r,
        portions: mangees,
        jour: auj,
        moment: moment,
        ajoutee: maintenant,
      );
      alimentation.ajouter(entree);
    }

    final courses = ref.read(coursesProvider.notifier);
    for (final d in decomptes) {
      if (d.fini) {
        courses.finir(d.article.id);
      } else {
        courses.utiliser(d.article.id, d.reste!.valeur);
      }
    }
    final reste = portions - mangees;
    if (restesA != null && reste > 1e-6) {
      courses.ranger([
        ArticleGardeManger(
          id: courses.nouvelId('gm'),
          nom: nomRestes,
          emplacement: restesA,
          rayon: Rayon.autre,
          entre: maintenant,
          quantite: Quantite(reste),
          peremption: restesJusquau(maintenant, restesA),
          recetteId: r.id,
        ),
      ]);
    }
    return entree;
  }

  /// Note [portions] de [recette] ([jour], [moment]) ; prises dans les
  /// restes si [depuisRestes] (le plus pressé d'abord).
  EntreeJournal noter({
    required Recette recette,
    required double portions,
    required DateTime jour,
    required MomentRepas moment,
    bool depuisRestes = false,
  }) {
    final alimentation = ref.read(alimentationProvider.notifier);
    final entree = entreeDeRecette(
      id: alimentation.nouvelId('ent'),
      recette: recette,
      portions: portions,
      jour: jour,
      moment: moment,
      ajoutee: _maintenant,
    );
    alimentation.ajouter(entree);
    if (depuisRestes) {
      final courses = ref.read(coursesProvider.notifier);
      var aPrendre = portions;
      for (final a in restesDe(
        ref.read(coursesProvider).gardeManger,
        recette.id,
      )) {
        if (aPrendre <= 1e-6) break;
        final dispo = a.quantite?.valeur ?? 0;
        if (dispo <= aPrendre + 1e-6) {
          courses.finir(a.id);
          aPrendre -= dispo;
        } else {
          courses.utiliser(a.id, dispo - aPrendre);
          aPrendre = 0;
        }
      }
    }
    return entree;
  }
}

// ═══ Les minuteurs du mode cuisine ══════════════════════════════════════════

class MinuteurCuisine {
  const MinuteurCuisine({
    required this.id,
    required this.libelle,
    required this.fin,
    required this.duree,
    this.sonne = false,
  });

  final String id;

  /// « Chili sin carne · étape 4 ».
  final String libelle;
  final DateTime fin;
  final Duration duree;

  /// L'alerte a été donnée.
  final bool sonne;

  MinuteurCuisine copierAvec({DateTime? fin, bool? sonne}) => MinuteurCuisine(
    id: id,
    libelle: libelle,
    fin: fin ?? this.fin,
    duree: duree,
    sonne: sonne ?? this.sonne,
  );
}

final minuteursProvider =
    NotifierProvider<MinuteursNotifier, List<MinuteurCuisine>>(
      MinuteursNotifier.new,
    );

class MinuteursNotifier extends Notifier<List<MinuteurCuisine>> {
  int _compteur = 0;

  @override
  List<MinuteurCuisine> build() => const [];

  MinuteurCuisine demarrer(String libelle, Duration duree) {
    final m = MinuteurCuisine(
      id: 'min-${DateTime.now().microsecondsSinceEpoch}-${++_compteur}',
      libelle: libelle,
      fin: ref.read(horlogeProvider)().add(duree),
      duree: duree,
    );
    state = [...state, m];
    return m;
  }

  /// Une minute de plus (repart s'il avait sonné).
  void ajouterMinute(String id) {
    final maintenant = ref.read(horlogeProvider)();
    state = [
      for (final m in state)
        if (m.id != id)
          m
        else
          m.copierAvec(
            fin: (m.fin.isBefore(maintenant) ? maintenant : m.fin).add(
              const Duration(minutes: 1),
            ),
            sonne: false,
          ),
    ];
  }

  void sonner(String id) => state = [
    for (final m in state) m.id == id ? m.copierAvec(sonne: true) : m,
  ];

  void arreter(String id) => state = [
    for (final m in state)
      if (m.id != id) m,
  ];
}

// ═══ La graine ══════════════════════════════════════════════════════════════

Ingredient _base(
  String nom,
  int code,
  double grammes,
  List<double> n, {
  double? nombre,
  String? mesure,
}) => Ingredient(
  nom: nom,
  source: SourceIngredient.base,
  code: code,
  grammes: grammes,
  nombre: nombre,
  mesure: mesure,
  nutriments: Nutriments(
    kcal: n[0],
    proteines: n[1],
    glucides: n[2],
    lipides: n[3],
    fibres: n[4],
    sucres: n[5],
    sodium: n[6],
    satures: n[7],
  ),
);

Ingredient _libre(String nom) => Ingredient(nom: nom);

abstract final class GraineRecettes {
  /// Les recettes de départ : huit plats simples, du déjeuner au souper,
  /// d'ici et d'ailleurs — valeurs du FCÉN (générées depuis le fichier).
  static List<Recette> depart(DateTime creee) => [
    Recette(
      id: 'depart-gruau',
      nom: "Gruau aux bleuets et à l'érable",
      creee: creee,
      moments: const {MomentRepas.dejeuner},
      portions: 2,
      preparation: 2,
      cuisson: 7,
      ingredients: [
        _base(
          "Gros flocons d'avoine",
          1462,
          110.9,
          [431.4, 15.7, 75.6, 7.8, 11.4, 0, 4.4, 1.3],
          nombre: 1,
          mesure: '250 ml',
        ),
        _base(
          'Lait 2 %',
          61,
          515.6,
          [242.3, 17, 22.7, 9.3, 0, 21.7, 278.4, 6.2],
          nombre: 2,
          mesure: '250 ml',
        ),
        _base(
          'Bleuets',
          1705,
          153.2,
          [87.3, 1.1, 22.2, 0.5, 4, 15.3, 1.5, 0],
          nombre: 1,
          mesure: '250 ml',
        ),
        _base(
          "Sirop d'érable",
          4326,
          40,
          [108.8, 0, 26.9, 0.1, 0, 26.4, 0.4, 0],
          nombre: 2,
          mesure: '15 ml',
        ),
        _libre('Cannelle'),
      ],
      etapes: const [
        'Dans une casserole, porter le lait à frémissement.',
        "Ajouter les flocons d'avoine et cuire 5 minutes à feu doux, en remuant.",
        'Retirer du feu, couvrir et laisser reposer 2 minutes.',
        "Servir avec les bleuets, le sirop d'érable et une pincée de cannelle.",
      ],
    ),
    Recette(
      id: 'depart-omelette',
      nom: 'Omelette aux épinards',
      creee: creee,
      moments: const {MomentRepas.dejeuner, MomentRepas.diner},
      portions: 1,
      preparation: 5,
      cuisson: 5,
      ingredients: [
        _base(
          'Œufs',
          125,
          136.8,
          [207.9, 16.8, 1.1, 14.5, 0, 1.1, 166.9, 4.9],
          nombre: 3,
          mesure: '1 oeuf moyen',
        ),
        _base(
          'Épinards',
          2213,
          31.7,
          [7.3, 0.9, 1.1, 0.1, 0.7, 0.1, 25, 0],
          nombre: 1,
          mesure: '250 ml',
        ),
        _base('Cheddar', 119, 20, [83.6, 4.7, 2.1, 6.4, 0, 0, 156.8, 4.1]),
        _base(
          'Huile de canola',
          451,
          4.6,
          [40.7, 0, 0, 4.6, 0, 0, 0, 0.3],
          nombre: 1,
          mesure: '5 ml',
        ),
        _libre('Sel et poivre'),
      ],
      etapes: const [
        'Battre les œufs avec le sel et le poivre.',
        "Chauffer l'huile dans une poêle à feu moyen ; y faire tomber les épinards 1 minute.",
        'Verser les œufs et cuire 3 minutes, sans remuer.',
        "Parsemer de cheddar, plier l'omelette en deux et servir.",
      ],
    ),
    Recette(
      id: 'depart-bol-poulet',
      nom: 'Bol poulet, riz et légumes',
      creee: creee,
      moments: const {MomentRepas.diner, MomentRepas.souper},
      portions: 4,
      preparation: 15,
      cuisson: 20,
      ingredients: [
        _base('Poitrines de poulet', 841, 600, [
          720,
          135,
          0,
          15.6,
          0,
          0,
          270,
          3.6,
        ]),
        _base(
          'Riz blanc à grain long',
          4471,
          195.5,
          [713.6, 13.9, 156.4, 1.4, 2, 0.2, 9.8, 0.4],
          nombre: 1,
          mesure: '250 ml',
        ),
        _base('Brocoli', 2374, 300, [102, 8.4, 19.8, 1.2, 7.2, 5.1, 99, 0.3]),
        _base(
          'Carottes',
          2380,
          122,
          [50, 1.1, 11.7, 0.2, 2.9, 5.7, 84.2, 0],
          nombre: 2,
          mesure: '1 moyen',
        ),
        _base(
          'Ail',
          2394,
          6,
          [8.9, 0.4, 2, 0, 0.1, 0.1, 1, 0],
          nombre: 2,
          mesure: '1 gousse',
        ),
        _base(
          'Huile de canola',
          451,
          14.2,
          [125.7, 0, 0, 14.2, 0, 0, 0, 1.1],
          nombre: 1,
          mesure: '15 ml',
        ),
        _base(
          'Sauce soya',
          3403,
          32.4,
          [17.2, 2.6, 1.6, 0.2, 0.2, 0.1, 1779.7, 0],
          nombre: 2,
          mesure: '15 ml',
        ),
      ],
      etapes: const [
        "Rincer le riz, puis le cuire à couvert dans 500 ml d'eau, 18 minutes à feu doux.",
        "Couper le poulet en cubes et le faire dorer dans l'huile 8 minutes.",
        "Ajouter le brocoli, les carottes en rondelles et l'ail haché ; sauter 5 minutes.",
        'Arroser de sauce soya et servir sur le riz.',
      ],
    ),
    Recette(
      id: 'depart-chili',
      nom: 'Chili sin carne',
      creee: creee,
      moments: const {MomentRepas.diner, MomentRepas.souper},
      portions: 4,
      preparation: 15,
      cuisson: 35,
      seCongele: true,
      ingredients: [
        _base(
          'Haricots rouges en conserve',
          7081,
          333.8,
          [413.9, 26.7, 71.8, 3.7, 18.4, 12.7, 771.1, 0.7],
          nombre: 2,
          mesure: '250 ml',
        ),
        _base(
          'Tomates en conserve',
          2462,
          760.8,
          [121.7, 6.1, 26.6, 1.5, 6.1, 19, 874.9, 0],
          nombre: 3,
          mesure: '250 ml',
        ),
        _base(
          'Oignon',
          2401,
          150,
          [60, 1.6, 13.9, 0.1, 2.5, 6.3, 6, 0],
          nombre: 1,
          mesure: '1 gros',
        ),
        _base(
          'Poivron rouge',
          2484,
          119,
          [30.9, 1.2, 7.1, 0.4, 1.7, 5, 4.8, 0.1],
          nombre: 1,
          mesure: '1 moyen (7cm long, 6.4cm dia)',
        ),
        _base(
          'Maïs en grains surgelé',
          2391,
          173.3,
          [152.5, 5.2, 35.9, 1.4, 3.3, 4.3, 5.2, 0.2],
          nombre: 1,
          mesure: '250 ml',
        ),
        _base(
          'Huile de canola',
          451,
          14.2,
          [125.7, 0, 0, 14.2, 0, 0, 0, 1.1],
          nombre: 1,
          mesure: '15 ml',
        ),
        _base(
          'Assaisonnement au chili',
          7203,
          6.9,
          [23.1, 0.7, 3.9, 0.5, 0.7, 0.6, 318.5, 0],
          nombre: 1,
          mesure: '15 ml',
        ),
        _libre('Cumin moulu'),
      ],
      etapes: const [
        "Hacher l'oignon et le poivron, puis les faire revenir dans l'huile 5 minutes.",
        "Ajouter l'assaisonnement au chili et le cumin ; cuire 1 minute en remuant.",
        'Ajouter les tomates, les haricots rincés et le maïs ; porter à ébullition.',
        'Laisser mijoter 25 à 30 minutes à feu doux, en remuant de temps en temps.',
      ],
    ),
    Recette(
      id: 'depart-pate-chinois',
      nom: 'Pâté chinois',
      creee: creee,
      moments: const {MomentRepas.souper},
      portions: 6,
      preparation: 20,
      cuisson: 50,
      region: 'Québécoise',
      seCongele: true,
      ingredients: [
        _base('Bœuf haché maigre', 2683, 450, [
          931.5,
          88.2,
          0,
          61.6,
          0,
          0,
          283.5,
          24.8,
        ]),
        _base(
          'Oignon',
          2401,
          150,
          [60, 1.6, 13.9, 0.1, 2.5, 6.3, 6, 0],
          nombre: 1,
          mesure: '1 gros',
        ),
        _base('Pommes de terre', 2417, 1000, [770, 20, 175, 1, 15, 8, 60, 0]),
        _base(
          'Lait 2 %',
          61,
          128.9,
          [60.6, 4.3, 5.7, 2.3, 0, 5.4, 69.6, 1.5],
          nombre: 0.5,
          mesure: '250 ml',
        ),
        _base(
          'Beurre',
          118,
          28.8,
          [206.5, 0.2, 0, 23.4, 0, 0, 185.2, 14.8],
          nombre: 2,
          mesure: '15 ml',
        ),
        _base(
          'Maïs en crème',
          2389,
          405.8,
          [292.1, 6.9, 73.4, 1.6, 5.3, 13, 1059, 0.4],
          nombre: 1.5,
          mesure: '250 ml',
        ),
        _base(
          'Maïs en grains surgelé',
          2391,
          173.3,
          [152.5, 5.2, 35.9, 1.4, 3.3, 4.3, 5.2, 0.2],
          nombre: 1,
          mesure: '250 ml',
        ),
        _libre('Sel et poivre'),
      ],
      etapes: const [
        "Peler les pommes de terre et les cuire 20 minutes dans l'eau bouillante salée.",
        "Pendant ce temps, faire revenir le bœuf et l'oignon haché 8 minutes ; saler et poivrer.",
        'Égoutter les pommes de terre et les écraser avec le lait et le beurre.',
        'Dans un plat de 20 cm, étager le bœuf, le maïs en crème, le maïs en grains, puis la purée.',
        "Cuire au four à 190 °C (375 °F) 30 minutes, jusqu'à ce que le dessus dore.",
      ],
    ),
    Recette(
      id: 'depart-saumon',
      nom: 'Saumon et patates douces',
      creee: creee,
      moments: const {MomentRepas.souper},
      portions: 2,
      preparation: 10,
      cuisson: 30,
      ingredients: [
        _base('Saumon', 3049, 300, [426, 59.4, 0, 18.9, 0, 0, 132, 3]),
        _base(
          'Patates douces',
          2240,
          260,
          [223.6, 4.2, 52.3, 0.3, 7.8, 10.9, 143, 0],
          nombre: 2,
          mesure: '1 moyen (12.7cm x 5.1cm dia)',
        ),
        _base('Haricots verts', 2370, 200, [
          62,
          3.6,
          14,
          0.4,
          5.4,
          6.6,
          12,
          0.2,
        ]),
        _base(
          "Huile d'olive",
          422,
          13.7,
          [121.2, 0, 0, 13.7, 0, 0, 0.3, 1.9],
          nombre: 1,
          mesure: '15 ml',
        ),
        _base(
          'Jus de citron',
          1589,
          15.5,
          [3.4, 0, 1.1, 0, 0, 0.4, 0.2, 0],
          nombre: 1,
          mesure: '15 ml',
        ),
        _libre('Sel et poivre'),
      ],
      etapes: const [
        'Préchauffer le four à 200 °C (400 °F).',
        "Couper les patates douces en cubes, les enrober de la moitié de l'huile et les rôtir 15 minutes.",
        "Ajouter le saumon et les haricots verts arrosés du reste de l'huile ; poursuivre 12 minutes.",
        'Arroser de jus de citron, saler, poivrer et servir.',
      ],
    ),
    Recette(
      id: 'depart-smoothie',
      nom: 'Smoothie protéiné',
      creee: creee,
      moments: const {MomentRepas.collation, MomentRepas.dejeuner},
      portions: 1,
      preparation: 5,
      ingredients: [
        _base(
          'Yogourt grec 2 %',
          7469,
          175,
          [120.8, 17, 7, 3.5, 0, 6, 89.2, 1.9],
          nombre: 1,
          mesure: '175 g',
        ),
        _base(
          'Banane',
          1704,
          118,
          [105, 1.3, 26.9, 0.4, 2, 14.4, 1.2, 0.1],
          nombre: 1,
          mesure: '1 moyen (18cm à 20cm long)',
        ),
        _base(
          'Bleuets',
          1705,
          76.6,
          [43.7, 0.5, 11.1, 0.2, 2, 7.7, 0.8, 0],
          nombre: 1,
          mesure: '125 ml',
        ),
        _base(
          'Lait 2 %',
          61,
          128.9,
          [60.6, 4.3, 5.7, 2.3, 0, 5.4, 69.6, 1.5],
          nombre: 0.5,
          mesure: '250 ml',
        ),
      ],
      etapes: const [
        'Mettre tous les ingrédients au mélangeur.',
        "Mélanger 1 minute, jusqu'à ce que ce soit lisse.",
      ],
    ),
    Recette(
      id: 'depart-riz-colle',
      nom: 'Riz collé aux pois',
      creee: creee,
      moments: const {MomentRepas.diner, MomentRepas.souper},
      portions: 6,
      preparation: 10,
      cuisson: 35,
      region: 'Haïtienne',
      seCongele: true,
      ingredients: [
        _base(
          'Riz blanc à grain long',
          4471,
          391,
          [1427.2, 27.8, 312.8, 2.7, 3.9, 0.4, 19.6, 0.8],
          nombre: 2,
          mesure: '250 ml',
        ),
        _base(
          'Haricots rouges en conserve',
          7081,
          333.8,
          [413.9, 26.7, 71.8, 3.7, 18.4, 12.7, 771.1, 0.7],
          nombre: 2,
          mesure: '250 ml',
        ),
        _base(
          'Oignon',
          2401,
          150,
          [60, 1.6, 13.9, 0.1, 2.5, 6.3, 6, 0],
          nombre: 1,
          mesure: '1 gros',
        ),
        _base(
          'Ail',
          2394,
          9,
          [13.4, 0.6, 3, 0, 0.2, 0.1, 1.5, 0],
          nombre: 3,
          mesure: '1 gousse',
        ),
        _base(
          'Huile de canola',
          451,
          28.4,
          [251.3, 0, 0, 28.4, 0, 0, 0, 2.1],
          nombre: 2,
          mesure: '15 ml',
        ),
        _libre('Thym'),
        _libre('Clous de girofle'),
      ],
      etapes: const [
        "Faire revenir l'oignon et l'ail hachés dans l'huile 3 minutes.",
        'Ajouter les haricots égouttés, le thym et les clous de girofle ; cuire 5 minutes.',
        "Ajouter le riz rincé et 750 ml d'eau salée ; porter à ébullition.",
        'Couvrir et cuire à feu doux 20 minutes, sans soulever le couvercle.',
      ],
    ),
  ];

  /// La démonstration (tests, captures) : les recettes de départ, déjà
  /// cuisinées, et une semaine prévue à partir de demain (le souper
  /// d'aujourd'hui reste « À planifier », comme dans la maquette).
  static EtatRecettes demonstration(DateTime aujourdhui) {
    final auj = jourDe(aujourdhui);
    final creee = plusJours(auj, -40);
    final cuisinees = <String, List<int>>{
      'depart-chili': [12, 5],
      'depart-bol-poulet': [10, 3],
      'depart-omelette': [1],
      'depart-gruau': [2],
      'depart-pate-chinois': [20],
      'depart-smoothie': [6],
    };
    final recettes = [
      for (final r in depart(creee))
        r.copierAvec(
          cuisinee: [
            for (final j in cuisinees[r.id] ?? const <int>[])
              plusJours(auj, -j),
          ],
        ),
    ];
    var n = 0;
    RepasPrevu p(
      int jour,
      MomentRepas moment, {
      String? recette,
      String? produit,
      String? libre,
    }) => RepasPrevu(
      id: 'demo-plan-${++n}',
      jour: plusJours(auj, jour),
      moment: moment,
      recetteId: recette,
      produitId: produit,
      libre: libre,
    );
    return EtatRecettes(
      recettes: recettes,
      plan: [
        p(1, MomentRepas.diner, recette: 'depart-bol-poulet'),
        p(1, MomentRepas.souper, recette: 'depart-pate-chinois'),
        p(2, MomentRepas.dejeuner, recette: 'depart-omelette'),
        p(2, MomentRepas.souper, recette: 'depart-chili'),
        p(3, MomentRepas.diner, recette: 'depart-chili'),
        p(3, MomentRepas.collation, produit: 'prod-barre'),
        p(3, MomentRepas.souper, libre: 'Souper chez des amis'),
        p(4, MomentRepas.diner, recette: 'depart-pate-chinois'),
        p(4, MomentRepas.souper, recette: 'depart-saumon'),
        p(5, MomentRepas.diner, recette: 'depart-chili'),
        p(5, MomentRepas.souper, recette: 'depart-riz-colle'),
        p(6, MomentRepas.dejeuner, recette: 'depart-gruau'),
        p(6, MomentRepas.souper, recette: 'depart-bol-poulet'),
      ],
    );
  }
}
