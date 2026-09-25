// lib/modele/alimentation/etat_alimentation.dart
//
// L'état de l'ALIMENTATION (Riverpod) et sa PERSISTANCE : chaque changement
// est écrit dans le dépôt SQLite (`depot.dart`) — trois tables
// (`journalAlim`, `produitsAlim`, `eauAlim`) et le profil (`profilAlim`).
//
// Premier lancement : rien de noté, un profil vide (les objectifs sont une
// estimation tant que sexe, âge et taille manquent ; le poids vient des
// Mesures des Sports). Sans dépôt (tests, captures), c'est la
// DÉMONSTRATION : la journée de la maquette (1 640 kcal sur 2 200, 112 /
// 150 g de protéines, 190 / 260 de glucides, 48 / 70 de lipides, 5 verres
// sur 8), et trois semaines d'historique.
//
// Atteindre l'objectif d'eau coche l'habitude « Boire 2 L d'eau » (si le
// profil le veut), comme une séance coche « Entraînement ».

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../utils/dates.dart';
import '../calculs_habitudes.dart';
import '../depot.dart';
import '../etat_habitudes.dart';
import '../etat_sante.dart';
import '../modeles.dart';
import '../sports/etat_sport.dart';
import '../sports/sport.dart';
import 'alimentation.dart';
import 'calculs_alimentation.dart';
import 'nutriments.dart';

final alimentationProvider =
    NotifierProvider<AlimentationNotifier, EtatAlimentation>(
      AlimentationNotifier.new,
    );

/// Le poids connu [jour] : la dernière pesée d'avant (sinon la première),
/// sinon celui du profil sportif ; `null` si on n'en sait rien.
double? poidsAu(EtatSport sport, DateTime jour) {
  for (final m in sport.mesures.reversed) {
    if (m.poids != null && !jourDe(m.date).isAfter(jourDe(jour))) {
      return m.poids;
    }
  }
  return sport.mesures.where((m) => m.poids != null).firstOrNull?.poids ??
      sport.profil.poids;
}

/// Les besoins d'un jour (profil, poids des Mesures, séances des Sports,
/// ajustement d'après le journal).
final besoinsProvider = Provider.family<Besoins, DateTime>((ref, jour) {
  final etat = ref.watch(alimentationProvider);
  final sport = ref.watch(sportProvider);
  final auj = ref.watch(aujourdhuiProvider);
  return besoinsDu(
    profil: etat.profil,
    poids: poidsAu(sport, jour),
    seances: sport.journal,
    programmes: sport.programmes,
    journal: etat.journal,
    mesures: sport.mesures,
    jour: jourDe(jour),
    aujourdhui: auj,
  );
});

class AlimentationNotifier extends Notifier<EtatAlimentation> {
  Depot? _depot;
  int _compteur = 0;

  @override
  EtatAlimentation build() {
    final auj = ref.read(aujourdhuiProvider);
    final depot = ref.watch(depotProvider);
    _depot = depot;
    if (depot == null) return GraineAlimentation.demonstration(auj);
    try {
      final document = depot.lire();
      if (document != null && document.containsKey('versionAlim')) {
        return EtatAlimentation.depuisDocument(document);
      }
    } catch (_) {
      return const EtatAlimentation();
    }
    const graine = EtatAlimentation();
    try {
      depot.ecrire(graine.versDocument());
    } catch (_) {}
    return graine;
  }

  /// Un identifiant neuf (« ent-1727…-3 »).
  String nouvelId(String prefixe) =>
      '$prefixe-${DateTime.now().microsecondsSinceEpoch}-${++_compteur}';

  void _muter(EtatAlimentation nouvel) {
    state = nouvel;
    try {
      _depot?.ecrire(nouvel.versDocument());
    } catch (_) {}
  }

  // ── Le profil ─────────────────────────────────────────────────────────────

  void modifierProfil(ProfilNutrition p) => _muter(state.copierAvec(profil: p));

  // ── Le journal ────────────────────────────────────────────────────────────

  void ajouter(EntreeJournal e) =>
      _muter(state.copierAvec(journal: [...state.journal, e]));

  void modifier(EntreeJournal e) => _muter(
    state.copierAvec(
      journal: [for (final x in state.journal) x.id == e.id ? e : x],
    ),
  );

  void retirer(String id) => _muter(
    state.copierAvec(
      journal: [
        for (final x in state.journal)
          if (x.id != id) x,
      ],
    ),
  );

  /// Recopie le [moment] de [depuis] sur [vers] (« Comme hier ») ; le
  /// nombre d'aliments copiés.
  int copierMoment(DateTime depuis, DateTime vers, MomentRepas moment) {
    final source = state.entreesDu(depuis, moment);
    if (source.isEmpty) return 0;
    final maintenant = ref.read(horlogeProvider)();
    _muter(
      state.copierAvec(
        journal: [
          ...state.journal,
          for (final e in source)
            e.copiee(
              id: nouvelId('ent'),
              jour: jourDe(vers),
              ajoutee: maintenant,
            ),
        ],
      ),
    );
    return source.length;
  }

  // ── L'eau ─────────────────────────────────────────────────────────────────

  /// [verres] bus [jour] ; le nom de l'habitude cochée du même coup.
  String? fixerEau(DateTime jour, int verres) {
    final cle = cleJour(jour);
    final eau = {...state.eau};
    if (verres <= 0) {
      eau.remove(cle);
    } else {
      eau[cle] = verres;
    }
    _muter(state.copierAvec(eau: eau));
    if (!state.profil.lienHabitudeEau) return null;
    // Pas `besoinsProvider` (il dépend de ce notifier) : le même calcul.
    final sport = ref.read(sportProvider);
    final vises = verresVises(
      state.profil,
      poidsAu(sport, jour) ?? 70,
      minutesSportDu(sport.journal, jour),
    );
    if (verres < vises) return null;
    return _cocherHabitudeEau(jourDe(jour));
  }

  String? _cocherHabitudeEau(DateTime jour) {
    try {
      final habitudes = ref.read(habitudesProvider);
      final auj = jourDe(ref.read(aujourdhuiProvider));
      if (jour.isAfter(auj)) return null;
      final h =
          habitudes.parId('hab-eau') ??
          habitudes.aConstruire
              .where((h) => RegExp(r'\beau\b').hasMatch(h.nom.toLowerCase()))
              .firstOrNull;
      if (h == null || h.aLiberer || estFaite(h, jour)) return null;
      ref.read(habitudesProvider.notifier).basculer(h.id, jour);
      return h.nom;
    } catch (_) {
      return null;
    }
  }

  // ── Mes produits ──────────────────────────────────────────────────────────

  /// Ajoute [p], ou le remplace s'il existe déjà.
  void enregistrerProduit(Produit p) {
    final existe = state.produits.any((x) => x.id == p.id);
    _muter(
      state.copierAvec(
        produits: existe
            ? [for (final x in state.produits) x.id == p.id ? p : x]
            : [...state.produits, p],
      ),
    );
  }

  void supprimerProduit(String id) => _muter(
    state.copierAvec(
      produits: [
        for (final p in state.produits)
          if (p.id != id) p,
      ],
    ),
  );
}

// ═══ La graine ══════════════════════════════════════════════════════════════

abstract final class GraineAlimentation {
  /// La démonstration (tests, captures) : la journée de la maquette et
  /// trois semaines d'historique, plus deux produits.
  static EtatAlimentation demonstration(DateTime aujourdhui) {
    final auj = jourDe(aujourdhui);
    var n = 0;
    EntreeJournal e(
      DateTime jour,
      MomentRepas moment,
      String nom,
      double kcal,
      double p,
      double g,
      double l, {
      int h = 8,
      SourceEntree source = SourceEntree.rapide,
      int? code,
      double? grammes,
      String? produit,
      double? portions,
      String? portion,
    }) => EntreeJournal(
      id: 'demo-${++n}',
      jour: jour,
      moment: moment,
      nom: nom,
      source: source,
      code: code,
      produitId: produit,
      grammes: grammes,
      portions: portions,
      portion: portion,
      nutriments: Nutriments(kcal: kcal, proteines: p, glucides: g, lipides: l),
      ajoutee: DateTime(jour.year, jour.month, jour.day, h, n % 50),
    );

    final journal = <EntreeJournal>[];
    // Trois semaines : des journées de 2 050 à 2 350 kcal.
    for (var k = 21; k >= 1; k--) {
      final j = plusJours(auj, -k);
      final v = (k * 37) % 7;
      journal
        ..add(
          e(
            j,
            MomentRepas.dejeuner,
            'Gruau',
            300 + v * 5,
            11,
            50,
            6,
            source: SourceEntree.base,
            code: 1414,
            grammes: 250,
          ),
        )
        ..add(
          e(
            j,
            MomentRepas.dejeuner,
            'Banane',
            105,
            1.3,
            27,
            0.4,
            source: SourceEntree.base,
            code: 1704,
            grammes: 118,
          ),
        )
        ..add(
          e(
            j,
            MomentRepas.diner,
            k.isEven ? 'Bol poulet, riz, légumes' : 'Sandwich au thon',
            700 + v * 10,
            52,
            80,
            18,
            h: 12,
          ),
        )
        ..add(
          e(
            j,
            MomentRepas.collation,
            'Yogourt grec',
            250,
            25,
            14,
            8,
            h: 15,
            source: SourceEntree.produit,
            produit: 'prod-yogourt',
            portions: 1,
            portion: '175 g',
          ),
        )
        ..add(
          e(
            j,
            MomentRepas.souper,
            k % 3 == 0 ? 'Saumon, patates douces' : 'Chili sin carne',
            700 + v * 15,
            40,
            85,
            20,
            h: 18,
          ),
        );
    }
    // Aujourd'hui, la maquette : déjeuner 520, dîner 740, collation 380 ;
    // le souper reste à planifier.
    journal
      ..add(
        e(
          auj,
          MomentRepas.dejeuner,
          'Gruau',
          225,
          8,
          38,
          4,
          h: 7,
          source: SourceEntree.base,
          code: 1414,
          grammes: 250,
        ),
      )
      ..add(
        e(
          auj,
          MomentRepas.dejeuner,
          'Banane',
          105,
          1,
          27,
          0,
          h: 7,
          source: SourceEntree.base,
          code: 1704,
          grammes: 118,
        ),
      )
      ..add(
        e(
          auj,
          MomentRepas.dejeuner,
          "Beurre d'arachide",
          190,
          8,
          6,
          16,
          h: 7,
          source: SourceEntree.base,
          code: 6289,
          grammes: 31.5,
        ),
      )
      ..add(
        e(
          auj,
          MomentRepas.diner,
          'Bol poulet, riz, légumes',
          740,
          60,
          85,
          18,
          h: 7,
        ),
      )
      ..add(
        e(
          auj,
          MomentRepas.collation,
          'Yogourt grec',
          290,
          33,
          14,
          9,
          h: 7,
          source: SourceEntree.produit,
          produit: 'prod-yogourt',
          portions: 2,
          portion: '175 g',
        ),
      )
      ..add(
        e(
          auj,
          MomentRepas.collation,
          'Bleuets',
          90,
          2,
          20,
          1,
          h: 7,
          source: SourceEntree.base,
          code: 1705,
          grammes: 150,
        ),
      );
    return EtatAlimentation(
      profil: const ProfilNutrition(
        sexe: Sexe.homme,
        anneeNaissance: 1998,
        taille: 178,
        objectif: ObjectifPoids.prendre,
        manuels: ObjectifsManuels(
          kcal: 2200,
          proteines: 150,
          glucides: 260,
          lipides: 70,
        ),
        verresEau: 8,
      ),
      journal: journal,
      produits: const [
        Produit(
          id: 'prod-yogourt',
          nom: 'Yogourt grec nature 2 %',
          portion: '175 g',
          grammesPortion: 175,
          parPortion: Nutriments(
            kcal: 145,
            proteines: 16.5,
            glucides: 7,
            lipides: 4.5,
          ),
        ),
        Produit(
          id: 'prod-barre',
          nom: 'Barre protéinée',
          marque: 'Chocolat et arachides',
          portion: '1 barre (60 g)',
          grammesPortion: 60,
          parPortion: Nutriments(
            kcal: 230,
            proteines: 20,
            glucides: 22,
            lipides: 8,
            fibres: 3,
            sucres: 5,
            sodium: 180,
            satures: 3,
          ),
        ),
      ],
      eau: {
        for (var k = 21; k >= 1; k--)
          cleJour(plusJours(auj, -k)): 6 + (k * 5) % 4,
        cleJour(auj): 5,
      },
    );
  }
}
